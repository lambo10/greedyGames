import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:cryptowallet/config/illustrations.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:elliptic/elliptic.dart';
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart';
import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:leb128/leb128.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' hide Wallet;
import 'package:cbor/cbor.dart' as cbor;
import 'package:cryptowallet/addressToBytes.dart';
import 'package:sacco/utils/ecc_secp256k1.dart';
import 'package:secp256k1/secp256k1.dart';
import 'package:cryptowallet/model/seed_phrase_root.dart';
import 'package:cryptowallet/screens/navigator_service.dart';
import 'package:cryptowallet/screens/open_app_pin_failed.dart';
import 'package:cryptowallet/screens/security.dart';
import 'package:cryptowallet/screens/wallet.dart';
import 'package:cryptowallet/utils/cid.dart';
import 'package:cryptowallet/utils/app_config.dart';
import 'package:wallet/wallet.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:cryptowallet/utils/wc_connector.dart';
import 'package:cryptowallet/utils/web_notifications.dart';
import 'package:cryptowallet/validate_tezos.dart';
import 'package:dartez/dartez.dart';
import 'package:crypto/crypto.dart';
import 'package:flotus/flotus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_js/extensions/fetch.dart';
import 'package:flutter_js/extensions/xhr.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hash/hash.dart';
import 'package:hex/hex.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path/path.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

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

  msg.addAll(await _getFileCoinGas(addressPrefix, baseUrl));

  const signTypeSecp = 1;

  final response = await http.post(
    Uri.parse('$baseUrl/message'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'cid': cid,
      'raw': json.encode({
        "Message": msg,
        "Signature": {
          "Type": signTypeSecp,
          "Data": sign,
        },
      })
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

const CID_PREFIX = [0x01, 0x71, 0xa0, 0xe4, 0x02, 0x20];
_messageCid({String msg}) {
  // blake2bHash(stringBytes, digestSize: 32);
}
// function getCID(message) {
//     const blakeCtx = blake.blake2bInit(32);
//     blake.blake2bUpdate(blakeCtx, message);
//     const hash = Buffer.from(blake.blake2bFinal(blakeCtx));
//     return Buffer.concat([CID_PREFIX, hash]);
// }