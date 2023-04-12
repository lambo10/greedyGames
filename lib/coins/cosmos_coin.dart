// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:math';

import 'package:bech32/bech32.dart';
import 'package:flutter/foundation.dart';
import 'package:sacco/sacco.dart' as cosmos;
import 'package:hive/hive.dart';
import 'package:http/http.dart';

import '../interface/coin.dart';
import '../utils/alt_ens.dart';
import '../utils/app_config.dart';

final pref = Hive.box(secureStorageKey);
const cosmosDecimals = 6;

class CosmosCoin extends Coin {
  String bech32Hrp;
  String lcdUrl;
  String blockExplorer;
  String symbol;
  String default_;
  String image;
  String name;

  @override
  Future<String> address_() async {
    final details = await fromMnemonic(pref.get(currentMmenomicKey));
    return details['address'];
  }

  @override
  String blockExplorer_() {
    return blockExplorer;
  }

  @override
  String default__() {
    return default_;
  }

  @override
  String image_() {
    return image;
  }

  @override
  String name_() {
    return name;
  }

  @override
  String symbol_() {
    return symbol;
  }

  CosmosCoin({
    this.blockExplorer,
    this.symbol,
    this.default_,
    this.image,
    this.name,
    this.bech32Hrp,
    this.lcdUrl,
  });

  CosmosCoin.fromJson(Map<String, dynamic> json) {
    lcdUrl = json['lcdUrl'];
    bech32Hrp = json['bech32Hrp'];
    blockExplorer = json['blockExplorer'];
    default_ = json['default'];
    symbol = json['symbol'];
    image = json['image'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['lcdUrl'] = lcdUrl;
    data['bech32Hrp'] = bech32Hrp;
    data['default'] = default_;
    data['symbol'] = symbol;
    data['name'] = name;
    data['blockExplorer'] = blockExplorer;

    data['image'] = image;

    return data;
  }

  @override
  Future<Map> fromMnemonic(String mnemonic) async {
    final keyName = sha3('cosmosDetails$bech32Hrp');
    List mmenomicMapping = [];
    if (pref.get(keyName) != null) {
      mmenomicMapping = jsonDecode(pref.get(keyName)) as List;
      for (int i = 0; i < mmenomicMapping.length; i++) {
        if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
          return mmenomicMapping[i]['key'];
        }
      }
    }
    final networkInfo = cosmos.NetworkInfo(
      bech32Hrp: bech32Hrp,
      lcdUrl: Uri.parse(lcdUrl),
    );

    final keys = await compute(
      calculateCosmosKey,
      {
        mnemonicKey: mnemonic,
        "networkInfo": networkInfo,
      },
    );
    mmenomicMapping.add({'key': keys, 'mmenomic': mnemonic});
    await pref.put(keyName, jsonEncode(mmenomicMapping));
    return keys;
  }

  calculateCosmosKey(Map config) {
    final wallet = cosmos.Wallet.derive(
      config[mnemonicKey].split(' '),
      config['networkInfo'],
    );

    return {'address': wallet.bech32Address};
  }

  @override
  Future<double> getBalance(bool skipNetworkRequest) async {
    final address = await address_();
    final key = 'cosmosAddressBalance$address$lcdUrl';

    final storedBalance = pref.get(key);

    double savedBalance = 0;

    if (storedBalance != null) {
      savedBalance = storedBalance;
    }

    if (skipNetworkRequest) return savedBalance;
    try {
      final response = await get(
        Uri.parse(
          '$lcdUrl/cosmos/bank/v1beta1/balances/$address',
        ),
      );
      final responseBody = response.body;
      if (response.statusCode ~/ 100 == 4 || response.statusCode ~/ 100 == 5) {
        throw Exception(responseBody);
      }

      List balances = jsonDecode(responseBody)['balances'];

      if (balances.isEmpty) {
        return 0;
      }

      final String balance = balances
          .where((element) => element['denom'] == 'uatom')
          .toList()[0]['amount'];

      double balanceInCosmos = double.parse(balance) / pow(10, cosmosDecimals);

      await pref.put(key, balanceInCosmos);

      return balanceInCosmos;
    } catch (e) {
      return savedBalance;
    }
  }

  @override
  Future<Map> getTransactions() async {
    final address = await address_();
    return {
      'trx': jsonDecode(pref.get('$default_ Details')),
      'currentUser': address
    };
  }

  @override
  Future<String> transferToken(String amount, String to) async {
    final networkInfo = cosmos.NetworkInfo(
      bech32Hrp: bech32Hrp,
      lcdUrl: Uri.parse(lcdUrl),
    );

    final uatomToSend = double.parse(amount) * pow(10, cosmosDecimals);

    final mnemonic = pref.get(currentMmenomicKey);

    final wallet = cosmos.Wallet.derive(mnemonic.split(' '), networkInfo);

    final message = cosmos.StdMsg(
      type: 'cosmos-sdk/MsgSend',
      value: {
        'from_address': wallet.bech32Address,
        'to_address': to,
        'amount': [
          {
            'denom': 'uatom',
            'amount': uatomToSend.toInt(),
          }
        ]
      },
    );

    final stdTx = cosmos.TxBuilder.buildStdTx(stdMsgs: [message]);

    final signedStdTx =
        await cosmos.TxSigner.signStdTx(wallet: wallet, stdTx: stdTx);

    final result = await cosmos.TxSender.broadcastStdTx(
      wallet: wallet,
      stdTx: signedStdTx,
    );

    if (result.success) {
      return result.hash;
    }

    throw Exception(result.error);
  }

  @override
  validateAddress(String address) {
    Bech32 sel = bech32.decode(address);
    if (sel.hrp != bech32Hrp) {
      throw Exception('not a valid cosmos address');
    }
  }

  @override
  int decimals() {
    return cosmosDecimals;
  }

  @override
  Future<double> getTransactionFee(String amount, String to) async {
    return 0.001;
  }
}

List<Map> getCosmosBlockChains() {
  // change lcdurl for cosmos to sdk 0.37.9 / cosmoshub-3
  List<Map> blockChains = [
    {
      'blockExplorer':
          'https://atomscan.com/transactions/$transactionhashTemplateKey',
      'symbol': 'ATOM',
      'name': 'Cosmos',
      'default': 'ATOM',
      'image': 'assets/cosmos.png',
      'bech32Hrp': 'cosmos',
      'lcdUrl': 'https://api.cosmos.network'
    }
  ];

  if (enableTestNet) {
    blockChains.add({
      'blockExplorer':
          'https://explorer.theta-testnet.polypore.xyz/transactions/$transactionhashTemplateKey',
      'symbol': 'ATOM',
      'name': 'Cosmos(Test)',
      'default': 'ATOM',
      'image': 'assets/cosmos.png',
      'bech32Hrp': 'cosmos',
      'lcdUrl': 'https://rest.state-sync-02.theta-testnet.polypore.xyz'
    });
  }
  return blockChains;
}
