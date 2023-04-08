// ignore_for_file: constant_identifier_names

import 'dart:convert';

import 'package:bitbox/bitbox.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:eth_sig_util/util/utils.dart';
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
  print(tronDetails);
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

  print(txInfo);
}
//  static signString(message, privateKey, useTronHeader = true) {
//         message = message.replace(/^0x/, '');
//         const value ={
//             toHexString: function() {
//                 return '0x' + privateKey
//             },
//             value: privateKey
//         }
//         const signingKey = new SigningKey(value);
//         const messageBytes = [
//             ...toUtf8Bytes(useTronHeader ? TRX_MESSAGE_HEADER : ETH_MESSAGE_HEADER),
//             ...utils.code.hexStr2byteArray(message)
//         ];
//         const messageDigest = keccak256(messageBytes);
//         const signature = signingKey.signDigest(messageDigest);
//         const signatureHex = [
//             '0x',
//             signature.r.substring(2),
//             signature.s.substring(2),
//             Number(signature.v).toString(16)
//         ].join('');
//         return signatureHex
//     }