// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:cryptowallet/utils/alt_ens.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:elliptic/elliptic.dart';
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:leb128/leb128.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';

import 'package:bitcoin_flutter/bitcoin_flutter.dart' hide Wallet;
import 'package:cbor/cbor.dart' as cbor;
import 'package:cryptowallet/addressToBytes.dart';
import 'package:cryptowallet/utils/app_config.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hex/hex.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app_config.dart';

Future<int> _getFileCoinNonce(
  String addressPrefix,
  String baseUrl,
) async {
  try {
    final pref = Hive.box(secureStorageKey);
    String mnemonic = pref.get(currentMmenomicKey);
    final fileCoinDetails = await getFileCoinFromMemnomic(
      mnemonic,
      addressPrefix,
    );
    final response = await http.get(Uri.parse(
        '$baseUrl/actor/balance?actor=${Uri.encodeQueryComponent(fileCoinDetails['address'])}'));
    final responseBody = response.body;
    if (response.statusCode ~/ 100 == 4 || response.statusCode ~/ 100 == 5) {
      throw Exception(responseBody);
    }

    return jsonDecode(responseBody)['data']['nonce'];
  } catch (e) {
    return 0;
  }
}

Future getFileCoinTransactionFee(
  String addressPrefix,
  String baseUrl,
) async {
  Map<String, dynamic> fileCoinFees = await _getFileCoinGas(
    addressPrefix,
    baseUrl,
  );

  return ((fileCoinFees['GasPremium'] + fileCoinFees['GasFeeCap']) *
          fileCoinFees['GasLimit']) /
      pow(10, fileCoinDecimals);
}

Future<Map<String, dynamic>> _getFileCoinGas(
  String addressPrefix,
  String baseUrl,
) async {
  try {
    final pref = Hive.box(secureStorageKey);
    String mnemonic = pref.get(currentMmenomicKey);
    final fileCoinDetails =
        await getFileCoinFromMemnomic(mnemonic, addressPrefix);
    final response = await http.get(Uri.parse(
        '$baseUrl/recommend/fee?method=Send&actor=${Uri.encodeQueryComponent(fileCoinDetails['address'])}'));
    final responseBody = response.body;
    if (response.statusCode ~/ 100 == 4 || response.statusCode ~/ 100 == 5) {
      throw Exception(responseBody);
    }

    Map jsonDecodedBody = jsonDecode(responseBody);

    return {
      'GasLimit': jsonDecodedBody['data']['gas_limit'],
      'GasPremium': int.tryParse(jsonDecodedBody['data']['gas_premium']) ?? 0,
      'GasFeeCap': int.tryParse(jsonDecodedBody['data']['gas_cap']) ?? 0,
    };
  } catch (e) {
    return {};
  }
}

bool validateFilecoinAddress(String address) {
  try {
    const checksumHashLength = 4;
    const fileCoinPrefixs = ['f', 't'];
    if (!fileCoinPrefixs.contains(address.substring(0, 1))) {
      return false;
    }
    final protocol = address[1];
    final protocolByte = Leb128.encodeUnsigned(int.parse(protocol));
    final raw = address.substring(2);
    if (protocol == '1' || protocol == '2' || protocol == '3') {
      List<int> payloadCksm = Base32.decode(raw);

      if (payloadCksm.length < checksumHashLength) {
        throw Exception('Invalid address length');
      }

      Uint8List payload = payloadCksm.sublist(0, payloadCksm.length - 4);

      Uint8List checksum = payloadCksm.sublist(payload.length);

      List<int> byteList = List.from(protocolByte)..addAll(payload);
      Uint8List bytes = Uint8List.fromList(byteList);

      if (!_validateChecksum(bytes, checksum)) {
        throw Exception('Invalid address checksum');
      }

      return true;
    } else if (protocol == '0') {
      const maxInt64StringLength = 19;
      if (raw.length > maxInt64StringLength) {
        throw Exception('Invalid ID address length');
      }
      final payload = Leb128.encodeUnsigned(int.parse(raw));
      final bytes = [...protocolByte, ...payload];
      if (kDebugMode) {
        print(bytes);
      }
      return true;
    }
    return false;
  } catch (e) {
    return false;
  }
}

_validateChecksum(Uint8List bytes, Uint8List checksum) {
  return seqEqual(_getChecksum(bytes), checksum);
}

Uint8List _getChecksum(Uint8List data) {
  return blake2bHash(data, digestSize: 4);
}

int calculateRecId(
    Uint8List message, Uint8List signature, Uint8List publicKey) {
  var r = signature.sublist(0, 32);
  var s = signature.sublist(32);

  for (var i = 0; i < 4; i++) {
    var k = recoverPublicKey(message, signature, i);
    if (k != null && publicKey == k) {
      return i;
    }
  }

  throw Exception("No recid found");
}

BigInt hashToInt(Uint8List message) {
  var sha256Hash = sha256.convert(message).bytes;

  var keccakHash = sha3(HEX.encode(sha256Hash));

  var hexString = keccakHash;
  var bigInt = BigInt.parse(hexString, radix: 16);

  return bigInt;
}

Uint8List recoverPublicKey(Uint8List message, Uint8List signature, int recid) {
  final secp256k1 = getSecp256k1();
  var n = secp256k1.n;
  var G = secp256k1.G;
  var x = G.X;

  var r = BigInt.parse(HEX.encode(signature.sublist(0, 32)), radix: 16);
  var s = BigInt.parse(HEX.encode(signature.sublist(32)), radix: 16);
  var e = hashToInt(message);

  var i = BigInt.from(recid ~/ 2);
  var x1 = r + (i * n);
  if (x1 >= secp256k1.p) return null;

  var R = Point(
      x1,
      x1.modPow(BigInt.from(3), secp256k1.p) *
          secp256k1.b.modPow(BigInt.from(2), secp256k1.p) %
          secp256k1.p);

  var Q =
      G * (n + BigInt.from(1) - s) * r.modInverse(n) + R * s * r.modInverse(n);

  if (!Q.isInfinity) {
    if (Q.x == x) {
      return encodePublicKey(Q);
    } else {
      return encodePublicKey(Point(x, secp256k1.p - Q.y));
    }
  }

  return null;
}

Uint8List encodePublicKey(Point publicKey) {
  var x = BigInt.from(publicKey.x);
  var y = BigInt.from(publicKey.y);

  var result = Uint8List(65);
  result[0] = 0x04;
  result.setRange(1, 33, padLeftTo32Bytes(x));
  result.setRange(33, 65, padLeftTo32Bytes(y));

  return result;
}

Uint8List padLeftTo32Bytes(BigInt n) {
  var hexStr = n.toRadixString(16);
  if (hexStr.length % 2 != 0) hexStr = '0$hexStr';

  var bytes = HEX.decode(hexStr);
  if (bytes.length < 32) {
    var padding = Uint8List(32 - bytes.length);
    bytes = padding + bytes;
  }

  return bytes;
}

Future<Map> sendFilecoin(
  String destinationAddress,
  int filecoinToSend, {
  String baseUrl,
  String addressPrefix,
  List<String> references = const [],
}) async {
  final pref = Hive.box(secureStorageKey);
  String mnemonic = pref.get(currentMmenomicKey);
  final fileCoinDetails =
      await getFileCoinFromMemnomic(mnemonic, addressPrefix);
  final nonce = await _getFileCoinNonce(
    addressPrefix,
    baseUrl,
  );

  final msg = {
    "Version": 0,
    "To": destinationAddress,
    "From": fileCoinDetails['address'],
    "Nonce": nonce,
    "Value": '$filecoinToSend',
    "GasLimit": 0,
    "GasFeeCap": "0",
    "GasPremium": "100000",
    "Method": 0,
    "Params": ""
  };

  // msg.addAll(await _getFileCoinGas(addressPrefix, baseUrl));

  final to = addressAsBytes(msg['To']);
  final from = addressAsBytes(msg['From']);
  final value = serializeBigNum(msg['Value']);
  final gasfeecap = serializeBigNum(msg['GasFeeCap']);
  final gaspremium = serializeBigNum(msg['GasPremium']);
  final gaslimit = msg['GasLimit'];

  final method = msg['Method'];
  final params = msg['Params'];

  List<int> bytes = base64.decode(params);

  final messageToEncode = [
    0,
    to,
    from,
    nonce,
    value,
    gaslimit,
    gasfeecap,
    gaspremium,
    method,
    bytes
  ];
  cbor.init();
  final output = cbor.OutputStandard();
  final encoder = cbor.Encoder(output);
  output.clear();
  encoder.writeArray(messageToEncode);
  final unsignedMessage = output.getDataAsList();
  Uint8List privateKey = HEX.decode(fileCoinDetails['privateKey']);

  final messageDigest = getDigest(Uint8List.fromList(unsignedMessage));
  final sign = ECPair.fromPrivateKey(privateKey).sign(messageDigest);
  const recid = 0; // FIXME: get recid from signature
  final cid = base64.encode([...sign, recid]);

  const signTypeSecp = 1;

  final rawSign = {
    "Message": msg,
    "Signature": {
      "Type": signTypeSecp,
      "Data": cid,
    },
  };

  final response = await http.post(
    Uri.parse('$baseUrl/message'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'cid': cid,
      'raw': json.encode(rawSign),
    }),
  );

  final responseBody = response.body;
  if (response.statusCode ~/ 100 == 4 || response.statusCode ~/ 100 == 5) {
    throw Exception(responseBody);
  }

  Map jsonDecodedBody = json.decode(responseBody) as Map;
  if (jsonDecodedBody['code'] ~/ 100 != 2) {
    throw Exception(jsonDecodedBody['detail']);
  }

  return {'txid': jsonDecodedBody['data'].toString()};
}
