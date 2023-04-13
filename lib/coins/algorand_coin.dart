// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:math';

import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart';
import 'package:hive/hive.dart';
import 'package:algorand_dart/algorand_dart.dart' as algo_rand;
import '../interface/coin.dart';
import '../main.dart';
import '../model/seed_phrase_root.dart';
import '../utils/app_config.dart';
import '../utils/rpc_urls.dart';

const algorandDecimals = 6;

class AlgorandCoin extends Coin {
  AlgorandTypes algoType;
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
    this.name,
    this.algoType,
  });

  factory AlgorandCoin.fromJson(Map<String, dynamic> json) {
    return AlgorandCoin(
      algoType: json['algoType'],
      blockExplorer: json['blockExplorer'],
      default_: json['default'],
      symbol: json['symbol'],
      image: json['image'],
      name: json['name'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['algoType'] = algoType;

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
      Map.from(toJson())
        ..addAll({
          mnemonicKey: mnemonic,
          seedRootKey: seedPhraseRoot,
        }),
    );

    mmenomicMapping.add({'key': keys, 'mmenomic': mnemonic});
    await pref.put(key, jsonEncode(mmenomicMapping));
    return keys;
  }

  @override
  Future<double> getBalance(bool skipNetworkRequest) async {
    final address = await address_();
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
  Future<String> transferToken(String amount, String to) async {
    final keyPair = await compute(calculateAlgorandKey, {
      mnemonicKey: pref.get(currentMmenomicKey),
      'getAlgorandKeys': true,
      seedRootKey: seedPhraseRoot,
    });
    String signature;
    try {
      signature = await getAlgorandClient(algoType).sendPayment(
        account: keyPair,
        recipient: algo_rand.Address.fromAlgorandAddress(
          address: to,
        ),
        amount: algo_rand.Algo.toMicroAlgos(
          double.parse(amount),
        ),
      );
    } on algo_rand.AlgorandException catch (e) {
      throw e.message;
    }

    return signature;
  }

  @override
  validateAddress(String address) {
    algo_rand.Address.fromAlgorandAddress(
      address: address,
    );
  }

  @override
  int decimals() {
    return algorandDecimals;
  }

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

  @override
  Future<double> getTransactionFee(String amount, String to) async {
    return 0.001;
  }
}

List<Map> getAlgorandBlockchains() {
  List<Map> blockChains = [
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

enum AlgorandTypes {
  mainNet,
  testNet,
}

algo_rand.Algorand getAlgorandClient(AlgorandTypes type) {
  final _algodClient = algo_rand.AlgodClient(
    apiUrl: type == AlgorandTypes.mainNet
        ? algo_rand.PureStake.MAINNET_ALGOD_API_URL
        : algo_rand.PureStake.TESTNET_ALGOD_API_URL,
    apiKey: pureStakeApiKey,
    tokenKey: algo_rand.PureStake.API_TOKEN_HEADER,
  );

  final _indexerClient = algo_rand.IndexerClient(
    apiUrl: type == AlgorandTypes.mainNet
        ? algo_rand.PureStake.MAINNET_INDEXER_API_URL
        : algo_rand.PureStake.TESTNET_INDEXER_API_URL,
    apiKey: pureStakeApiKey,
    tokenKey: algo_rand.PureStake.API_TOKEN_HEADER,
  );

  final _kmdClient = algo_rand.KmdClient(
    apiUrl: '127.0.0.1',
    apiKey: pureStakeApiKey,
  );

  return algo_rand.Algorand(
    algodClient: _algodClient,
    indexerClient: _indexerClient,
    kmdClient: _kmdClient,
  );
}

Future calculateAlgorandKey(Map config) async {
  SeedPhraseRoot seedRoot_ = config[seedRootKey];
  KeyData masterKey =
      await ED25519_HD_KEY.derivePath("m/44'/283'/0'/0'/0'", seedRoot_.seed);

  final account =
      await algo_rand.Account.fromPrivateKey(HEX.encode(masterKey.key));
  if (config['getAlgorandKeys'] != null && config['getAlgorandKeys'] == true) {
    return account;
  }

  return {
    'address': account.publicAddress,
  };
}
