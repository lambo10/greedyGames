// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:leb128/leb128.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'package:bitcoin_flutter/bitcoin_flutter.dart' hide Wallet;
import 'package:cbor/cbor.dart' as cbor;
import 'package:cryptowallet/utils/addressToBytes.dart';
import 'package:cryptowallet/utils/app_config.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/crypto.dart';

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

String transactionSignLotus(Map msg, String privateKeyHex) {
  final to = addressAsBytes(msg['To']);
  final from = addressAsBytes(msg['From']);
  final value = serializeBigNum(msg['Value']);
  final gasfeecap = serializeBigNum(msg['GasFeeCap']);
  final gaspremium = serializeBigNum(msg['GasPremium']);
  final gaslimit = msg['GasLimit'];
  int method = msg['Method'];
  final params = msg['Params'];
  int nonce = msg['Nonce'];
  int version = msg['Version'];

  final messageToEncode = [
    version ?? 0,
    to,
    from,
    nonce ?? 0,
    value,
    gaslimit,
    gasfeecap,
    gaspremium,
    method ?? 0,
    base64.decode(params ?? '')
  ];
  cbor.init();
  final output = cbor.OutputStandard();
  final encoder = cbor.Encoder(output);
  output.clear();
  encoder.writeArray(messageToEncode);
  final unsignedMessage = output.getDataAsList();
  Uint8List privateKey = HEX.decode(privateKeyHex);

  final messageDigest = getDigest(Uint8List.fromList(unsignedMessage));
  final signature = ECPair.fromPrivateKey(privateKey).sign(messageDigest);

  final recid = sign(messageDigest, privateKey).v - 27;

  final cid = base64.encode([...signature, recid]);
  return cid;
}

// curl baseurl post estimate message gas
// {
//   "id": 1,
//   "jsonrpc": "2.0",
//   "method": "Filecoin.GasEstimateMessageGas",
//   "params": [
//     {
//       "From": "f01234",
//       "GasFeeCap": "0",
//       "GasLimit": 9,
//       "GasPremium": "0",
//       "Method": 1,
//       "Nonce": 42,
//       "Params": "Ynl0ZSBhcnJheQ==",
//       "To": "f01234",
//       "Value": "0",
//       "Version": 42
//     },
//   ]
// }
Future<Map> sendFilecoin(
  String destinationAddress,
  BigInt filecoinToSend, {
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
  final cid = transactionSignLotus(msg, fileCoinDetails['privateKey']);
  const signTypeSecp = 1;

  final response = await http.post(
    Uri.parse(baseUrl),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      "id": 1,
      "jsonrpc": "2.0",
      "method": "Filecoin.MpoolPush",
      "params": [
        {
          "Message": msg,
          "Signature": {
            "Type": signTypeSecp,
            "Data": cid,
          },
        }
      ]
    }),
  );

  final responseBody = response.body;
  if (response.statusCode ~/ 100 == 4 || response.statusCode ~/ 100 == 5) {
    throw Exception(responseBody);
  }

  Map jsonDecodedBody = json.decode(responseBody) as Map;

  return {'txid': jsonDecodedBody['result']['/']};
}
