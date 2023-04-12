// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart';
import 'package:near_api_flutter/near_api_flutter.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';

import '../interface/coin.dart';
import '../model/seed_phrase_root.dart';
import '../utils/app_config.dart';
import '../utils/rpc_urls.dart';

final pref = Hive.box(secureStorageKey);
const nearDecimals = 24;

class NearCoin extends Coin {
  String api;
  String blockExplorer;
  String symbol;
  String default_;
  String image;
  String name;

  NearCoin({
    this.blockExplorer,
    this.symbol,
    this.default_,
    this.image,
    this.name,
    this.api,
  });

  NearCoin.fromJson(Map<String, dynamic> json) {
    api = json['api'];
    blockExplorer = json['blockExplorer'];
    default_ = json['default'];
    symbol = json['symbol'];
    image = json['image'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['api'] = api;
    data['default'] = default_;
    data['symbol'] = symbol;
    data['name'] = name;
    data['blockExplorer'] = blockExplorer;
    data['image'] = image;

    return data;
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
  Future<Map> fromMnemonic(String mnemonic) async {
    String key = 'nearDetails$mnemonic';

    final pref = Hive.box(secureStorageKey);
    List mmenomicMapping = [];

    if (pref.get(key) != null) {
      mmenomicMapping = jsonDecode(pref.get(key)) as List;
      for (int i = 0; i < mmenomicMapping.length; i++) {
        if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
          return mmenomicMapping[i]['key'];
        }
      }
    }

    final keys = await compute(calculateNearKey, {
      mnemonicKey: mnemonic,
      seedRootKey: seedPhraseRoot,
    });

    mmenomicMapping.add({'key': keys, 'mmenomic': mnemonic});
    await pref.put(key, jsonEncode(mmenomicMapping));
    return keys;
  }

  Future calculateNearKey(Map config) async {
    SeedPhraseRoot seedRoot_ = config[seedRootKey];
    KeyData masterKey =
        await ED25519_HD_KEY.derivePath("m/44'/397'/0'", seedRoot_.seed);
    final publicKey = await ED25519_HD_KEY.getPublicKey(masterKey.key);

    final address = HEX.encode(publicKey).substring(2);

    return {
      'privateKey': HEX.encode(masterKey.key),
      'address': address,
    };
  }

  @override
  Future<double> getBalance(bool skipNetworkRequest) async {
    final address = await address_();
    final key = 'nearAddressBalance$address$api';

    final storedBalance = pref.get(key);

    double savedBalance = 0;

    if (storedBalance != null) {
      savedBalance = storedBalance;
    }

    if (skipNetworkRequest) return savedBalance;

    try {
      final request = await post(
        Uri.parse(api),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(
          {
            "jsonrpc": "2.0",
            "id": "dontcare",
            "method": "query",
            "params": {
              "request_type": "view_account",
              "finality": "final",
              "account_id": address
            },
          },
        ),
      );

      if (request.statusCode ~/ 100 == 4 || request.statusCode ~/ 100 == 5) {
        throw Exception('Request failed');
      }
      Map decodedData = jsonDecode(request.body);

      final BigInt balance = BigInt.parse(decodedData['result']['amount']);
      final base = BigInt.from(10);

      final balanceInNear = (balance / base.pow(nearDecimals)).toDouble();
      await pref.put(key, balanceInNear);

      return balanceInNear;
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
    final getNearDetails = await fromMnemonic(pref.get(currentMmenomicKey));
    final privateKeyPublic = [
      ...HEX.decode(getNearDetails['privateKey']),
      ...HEX.decode(getNearDetails['address'])
    ];
    final publicKey = PublicKey(
      HEX.decode(
        getNearDetails['address'],
      ),
    );
    Account account = Account(
      accountId: getNearDetails['address'],
      keyPair: KeyPair(
        PrivateKey(privateKeyPublic),
        publicKey,
      ),
      provider: NearRpcProvider(api),
    );

    final trans = await account.sendTokens(
      double.parse(amount),
      to,
    );

    String transactionHash = trans['result']['transaction']['hash'];

    return transactionHash.replaceAll('\n', '');
  }

  @override
  validateAddress(String address) {
    final bytes = HEX.decode(address);
    const exceptedLength = 64;
    const exceptedBytesLength = 32;
    if (address.length != exceptedLength) {
      throw Exception("Near address must have a length of 64");
    }
    if (bytes.length != exceptedBytesLength) {
      throw Exception("Near address must have a decoded byte length of 32");
    }
  }

  @override
  int decimals() {
    return nearDecimals;
  }

  @override
  Future<double> getTransactionFee(String amount, String to) async {
    return 0;
  }
}

List getNearBlockChains() {
  List blockChains = [
    {
      'name': 'NEAR',
      'symbol': 'NEAR',
      'default': 'NEAR',
      'blockExplorer':
          'https://explorer.near.org/transactions/$transactionhashTemplateKey',
      'image': 'assets/near.png',
      'api': 'https://rpc.mainnet.near.org'
    }
  ];
  if (enableTestNet) {
    blockChains.add({
      'name': 'NEAR(Testnet)',
      'symbol': 'NEAR',
      'default': 'NEAR',
      'blockExplorer':
          'https://explorer.testnet.near.org/transactions/$transactionhashTemplateKey',
      'image': 'assets/near.png',
      'api': 'https://rpc.testnet.near.org'
    });
  }
  return blockChains;
}

class NearRpcProvider extends RPCProvider {
  final String endpoint;

  NearRpcProvider(this.endpoint) : super(endpoint);
}
