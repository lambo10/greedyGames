// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:math';

import 'package:bech32/bech32.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart';
import 'package:sacco/sacco.dart' as cosmos;
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:algorand_dart/algorand_dart.dart' as algo_rand;
import '../interface/coin.dart';
import '../model/seed_phrase_root.dart';
import '../utils/alt_ens.dart';
import '../utils/app_config.dart';
import '../utils/rpc_urls.dart';

final pref = Hive.box(secureStorageKey);

class AlgorandCoin implements Coin {
  AlgorandTypes algoType;
  String address;
  String blockExplorer;
  String symbol;
  String default_;
  String image;
  String name;

  AlgorandCoin({
    this.blockExplorer,
    this.symbol,
    this.default_,
    this.image,
    this.address,
    this.name,
    this.algoType,
  });

  AlgorandCoin.fromJson(Map<String, dynamic> json) {
    algoType = json['algoType'];
    blockExplorer = json['blockExplorer'];
    default_ = json['default'];
    symbol = json['symbol'];
    image = json['image'];
    address = json['address'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['algoType'] = algoType;
    data['address'] = address;
    data['default'] = default_;
    data['symbol'] = symbol;
    data['name'] = name;
    data['blockExplorer'] = blockExplorer;

    data['image'] = image;

    return data;
  }

  @override
  Future<Map> fromMnemonic(String mnemonic) async {
    String key = 'algorandDetails$mnemonic';

    List mmenomicMapping = [];
    if (pref.get(key) != null) {
      mmenomicMapping = jsonDecode(pref.get(key)) as List;
      for (int i = 0; i < mmenomicMapping.length; i++) {
        if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
          return mmenomicMapping[i]['key'];
        }
      }
    }

    final keys = await compute(
      calculateAlgorandKey,
      {
        mnemonicKey: mnemonic,
        seedRootKey: seedPhraseRoot,
      },
    );

    mmenomicMapping.add({'key': keys, 'mmenomic': mnemonic});
    await pref.put(key, jsonEncode(mmenomicMapping));
    return keys;
  }

  Future calculateAlgorandKey(Map config) async {
    SeedPhraseRoot seedRoot_ = config[seedRootKey];
    KeyData masterKey =
        await ED25519_HD_KEY.derivePath("m/44'/283'/0'/0'/0'", seedRoot_.seed);

    final account =
        await algo_rand.Account.fromPrivateKey(HEX.encode(masterKey.key));
    if (config['getAlgorandKeys'] != null &&
        config['getAlgorandKeys'] == true) {
      return account;
    }

    return {
      'address': account.publicAddress,
    };
  }

  @override
  Future<double> getBalance(bool skipNetworkRequest) async {
    final key = 'algorandAddressBalance$address${algoType.index}';

    final storedBalance = pref.get(key);

    double savedBalance = 0;

    if (storedBalance != null) {
      savedBalance = storedBalance;
    }

    if (skipNetworkRequest) return savedBalance;

    try {
      final userBalanceMicro =
          await getAlgorandClient(algoType).getBalance(address);
      final userBalance = userBalanceMicro / pow(10, algorandDecimals);
      await pref.put(key, userBalance);

      return userBalance;
    } catch (e) {
      return savedBalance;
    }
  }

  @override
  getTransactions() {
    return {
      'trx': jsonDecode(pref.get('$default_ Details')),
      'currentUser': address
    };
  }

  @override
  Future<String> transferToken(String amount, String to) async {
    final keyPair = await compute(calculateAlgorandKey, {
      mnemonicKey: pref.get(currentMmenomicKey),
      'getAlgorandKeys': true,
      seedRootKey: seedPhraseRoot,
    });

    String signature = await getAlgorandClient(algoType).sendPayment(
      account: keyPair,
      recipient: algo_rand.Address.fromAlgorandAddress(
        address: to,
      ),
      amount: algo_rand.Algo.toMicroAlgos(
        double.parse(amount),
      ),
    );

    return signature;
  }

  @override
  validateAddress(String address) {
    algo_rand.Address.fromAlgorandAddress(
      address: address,
    );
  }
}

List getAlgorandBlockchains() {
  List blockChains = [
    {
      'blockExplorer': 'https://algoexplorer.io/tx/$transactionhashTemplateKey',
      'symbol': 'ALGO',
      'name': 'Algorand',
      'default': 'ALGO',
      'image': 'assets/algorand.png',
      'algoType': AlgorandTypes.mainNet,
    }
  ];

  if (enableTestNet) {
    blockChains.add({
      'blockExplorer':
          'https://testnet.algoexplorer.io/tx/$transactionhashTemplateKey',
      'symbol': 'ALGO',
      'name': 'Algorand(Testnet)',
      'default': 'ALGO',
      'image': 'assets/algorand.png',
      'algoType': AlgorandTypes.testNet,
    });
  }
  return blockChains;
}
