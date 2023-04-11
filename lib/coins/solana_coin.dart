// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../interface/coin.dart';
import '../model/seed_phrase_root.dart';
import 'package:solana/solana.dart' as solana;
import '../utils/app_config.dart';
import '../utils/rpc_urls.dart';

final pref = Hive.box(secureStorageKey);
const solanaDecimals = 9;

class Solana implements Coin {
  SolanaClusters solanaCluster;
  String address;
  String blockExplorer;
  String symbol;
  String default_;
  String image;
  String name;
 @override
  String address_() {
    return address;
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
  Solana({
    this.blockExplorer,
    this.symbol,
    this.default_,
    this.image,
    this.address,
    this.name,
    this.solanaCluster,
  });

  Solana.fromJson(Map<String, dynamic> json) {
    solanaCluster = json['solanaCluster'];
    blockExplorer = json['blockExplorer'];
    default_ = json['default'];
    symbol = json['symbol'];
    image = json['image'];
    address = json['address'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['solanaCluster'] = solanaCluster;
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
    const keyName = 'solanaDetail';
    List mmenomicMapping = [];
    if (pref.get(keyName) != null) {
      mmenomicMapping = jsonDecode(pref.get(keyName)) as List;
      for (int i = 0; i < mmenomicMapping.length; i++) {
        if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
          return mmenomicMapping[i]['key'];
        }
      }
    }

    final keys = await compute(calculateSolanaKey, {
      mnemonicKey: mnemonic,
      seedRootKey: seedPhraseRoot,
    });
    mmenomicMapping.add({'key': keys, 'mmenomic': mnemonic});
    await pref.put(keyName, jsonEncode(mmenomicMapping));
    return keys;
  }

  Future calculateSolanaKey(Map config) async {
    SeedPhraseRoot seedRoot_ = config[seedRootKey];

    final solana.Ed25519HDKeyPair keyPair =
        await solana.Ed25519HDKeyPair.fromSeedWithHdPath(
      seed: seedRoot_.seed,
      hdPath: "m/44'/501'/0'",
    );

    if (config['getSolanaKeys'] != null && config['getSolanaKeys'] == true) {
      return keyPair;
    }

    return {
      'address': keyPair.address,
    };
  }

  @override
  Future<double> getBalance(bool skipNetworkRequest) async {
    final key = 'solanaAddressBalance$address${solanaCluster.index}';

    final storedBalance = pref.get(key);

    double savedBalance = 0;

    if (storedBalance != null) {
      savedBalance = storedBalance;
    }

    if (skipNetworkRequest) return savedBalance;

    try {
      final balanceInLamport =
          await getSolanaClient(solanaCluster).rpcClient.getBalance(address);
      double balanceInSol = balanceInLamport / solana.lamportsPerSol;

      await pref.put(key, balanceInSol);

      return balanceInSol;
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
    final lamportToSend = double.parse(amount) * pow(10, solanaDecimals);
    final keyPair = await compute(calculateSolanaKey, {
      mnemonicKey: pref.get(currentMmenomicKey),
      'getSolanaKeys': true,
      seedRootKey: seedPhraseRoot,
    });

    final signature = await getSolanaClient(solanaCluster).transferLamports(
      source: keyPair,
      destination: solana.Ed25519HDPublicKey.fromBase58(to),
      lamports: lamportToSend.toInt(),
    );
    return signature;
  }

  @override
  validateAddress(String address) {
    solana.Ed25519HDPublicKey.fromBase58(address);
  }

  @override
  int decimals() {
    return solanaDecimals;
  }
}

List getSolanaBlockChains() {
  List blockChains = [
    {
      'name': 'Solana',
      'symbol': 'SOL',
      'default': 'SOL',
      'blockExplorer':
          'https://explorer.solana.com/tx/$transactionhashTemplateKey',
      'image': 'assets/solana.webp',
      'solanaCluster': SolanaClusters.mainNet,
    }
  ];
  if (enableTestNet) {
    blockChains.add({
      {
        'nae': 'Solana(Devnet)',
        'symbol': 'SOL',
        'default': 'SOL',
        'blockExplorer':
            'https://explorer.solana.com/tx/$transactionhashTemplateKey?cluster=devnet',
        'image': 'assets/solana.webp',
        'solanaCluster': SolanaClusters.devNet,
      }
    });
  }
  return blockChains;
}
