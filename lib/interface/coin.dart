// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:cryptowallet/utils/app_config.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../main.dart';

abstract class Coin {
  void validateAddress(String address);
  Future<Map> fromMnemonic(String mnemonic);
  Map toJson();
  Future<double> getBalance(bool skipNetworkRequest);
  Future<String> transferToken(String amount, String to);
  Future<Map> getTransactions() async {
    final address = await address_();
    return {
      'trx': jsonDecode(pref.get(savedTransKey())),
      'currentUser': address
    };
  }

  Future<double> getMaxTransfer() async {
    return await getBalance(true);
  }

  String savedTransKey() => '${default__()} Details';

  int decimals();
  String name_();
  String symbol_();
  String blockExplorer_();
  String default__();
  Future<String> address_();
  Future<double> getTransactionFee(String amount, String to);

  String image_();
  String contractAddress() {
    return null;
  }

  bool noPrice() {
    return null;
  }
}
