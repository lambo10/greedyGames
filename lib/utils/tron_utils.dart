// ignore_for_file: constant_identifier_names

import 'dart:convert';

import 'package:eth_sig_util/util/utils.dart';
import 'package:hex/hex.dart';
import 'package:bs58check/bs58check.dart' as bs58check;
import 'package:http/http.dart';

import 'app_config.dart';

const ADDRESS_PREFIX = '41';
String tronAddressToHex(String address) {
  if (isHexString(address)) {
    return address.replaceFirst('0x', ADDRESS_PREFIX).toUpperCase();
  }
  return HEX.encode(bs58check.decode(address)).toUpperCase();
}

sendTron(
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

  Map txInfo = json.decode(request.body);
}
