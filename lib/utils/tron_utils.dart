// ignore_for_file: constant_identifier_names

import 'dart:convert';

import 'package:bitcoin_flutter/bitcoin_flutter.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart';
import 'package:bs58check/bs58check.dart' as bs58check;
import 'package:hive/hive.dart';
import 'package:http/http.dart';

import 'app_config.dart';

const TRX_FEE_LIMIT = 150000000;
const TRX_ADDRESS_PREFIX = '41';
const TRX_MESSAGE_HEADER = '\x19TRON Signed Message:\n32';

String tronAddressToHex(String address) {
  if (isHexString(address)) {
    return address.replaceFirst('0x', TRX_ADDRESS_PREFIX).toUpperCase();
  }
  return HEX.encode(bs58check.decode(address)).toUpperCase();
}

sendTron(
  String api,
  int amount,
  String from,
  String to,
) async {
  final pref = Hive.box(secureStorageKey);
  final mnemonic = pref.get(currentMmenomicKey);
  final tronDetails = await getTronFromMemnomic(mnemonic);
  final txInfo = await tronTrxInfo(api, amount, from, to);
  final ecPair = ECPair.fromPrivateKey(HEX.decode(tronDetails['privateKey']));
  final signatureSinged = ecPair.sign(HEX.decode(txInfo['txID']));
  final signature = '${HEX.encode(signatureSinged)}00';
  txInfo['signature'] = [signature];
  final txSent = await sendRawTransaction(api, txInfo);
  print(txSent);
  return {
    'txid': txSent['txID'],
  };
}

Future<Map> sendRawTransaction(String api, Map txInfo) async {
  final httpFromApi = Uri.parse('$api/wallet/broadcasttransaction');
  final request = await post(
    httpFromApi,
    headers: {
      'Content-Type': 'application/json',
      'TRON-PRO-API-KEY': tronGridApiKey,
    },
    body: json.encode(txInfo),
  );

  if (request.statusCode ~/ 100 == 4 || request.statusCode ~/ 100 == 5) {
    throw Exception(request.body);
  }

  return json.decode(request.body);
}

Future<Map> tronTrxInfo(
  String api,
  int amount,
  String from,
  String to,
) async {
  final httpFromApi = Uri.parse('$api/wallet/createtransaction');
  final request = await post(
    httpFromApi,
    headers: {
      'Content-Type': 'application/json',
      'TRON-PRO-API-KEY': tronGridApiKey,
    },
    body: json.encode({
      'to_address': tronAddressToHex(to),
      'owner_address': tronAddressToHex(from),
      'amount': amount
    }),
  );

  if (request.statusCode ~/ 100 == 4 || request.statusCode ~/ 100 == 5) {
    throw Exception(request.body);
  }

  return json.decode(request.body);
}
