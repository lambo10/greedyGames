// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';
import 'dart:math';

import 'package:algorand_dart/algorand_dart.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:bs58check/bs58check.dart' as bs58check;
import 'package:wallet/wallet.dart' as wallet;
import 'package:web3dart/crypto.dart';
import '../interface/coin.dart';
import '../model/seed_phrase_root.dart';
import '../utils/app_config.dart';
import '../utils/rpc_urls.dart';

final pref = Hive.box(secureStorageKey);
const TRX_FEE_LIMIT = 150000000;
const TRX_ADDRESS_PREFIX = '41';
const TRX_MESSAGE_HEADER = '\x19TRON Signed Message:\n32';

const tronDecimals = 6;

class TronCoin extends Coin {
  String api;
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

  TronCoin({
    this.blockExplorer,
    this.symbol,
    this.default_,
    this.image,
    this.name,
    this.api,
  });

  TronCoin.fromJson(Map<String, dynamic> json) {
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
  Future<Map> fromMnemonic(String mnemonic) async {
    String key = 'tronDetails$mnemonic';

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
      calculateTronKey,
      {
        mnemonicKey: mnemonic,
        seedRootKey: seedPhraseRoot,
      },
    );

    mmenomicMapping.add({'key': keys, 'mmenomic': mnemonic});
    await pref.put(key, jsonEncode(mmenomicMapping));
    return keys;
  }

  calculateTronKey(Map config) {
    SeedPhraseRoot seedRoot_ = config[seedRootKey];
    final master =
        wallet.ExtendedPrivateKey.master(seedRoot_.seed, wallet.xprv);
    final root = master.forPath("m/44'/195'/0'/0/0");

    final privateKey =
        wallet.PrivateKey((root as wallet.ExtendedPrivateKey).key);
    final publicKey = wallet.tron.createPublicKey(privateKey);
    final address = wallet.tron.createAddress(publicKey);

    return {
      'privateKey': HEX.encode(privateKey.value.toUint8List()),
      'address': address,
    };
  }

  @override
  Future<double> getBalance(bool skipNetworkRequest) async {
    final address = await address_();
    final key = 'tronAddressBalance$address$api';

    final storedBalance = pref.get(key);

    double savedBalance = 0;

    if (storedBalance != null) {
      savedBalance = storedBalance;
    }

    if (skipNetworkRequest) return savedBalance;

    try {
      final request = await get(
        Uri.parse('$api/v1/accounts/$address'),
        headers: {
          'TRON-PRO-API-KEY': tronGridApiKey,
          'Content-Type': 'application/json'
        },
      );

      if (request.statusCode ~/ 100 == 4 || request.statusCode ~/ 100 == 5) {
        throw Exception('Request failed');
      }
      Map decodedData = jsonDecode(request.body);

      final int balance = decodedData['data'][0]['balance'];

      final balanceInTron =
          (BigInt.from(balance) / BigInt.from(pow(10, tronDecimals)))
              .toDouble();
      await pref.put(key, balanceInTron);

      return balanceInTron;
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
    final mnemonic = pref.get(currentMmenomicKey);
    final tronDetails = await fromMnemonic(mnemonic);

    final microTron = double.parse(amount) * pow(10, tronDecimals);
    final txInfo = await tronTrxInfo(
      api,
      microTron.toInt(),
      tronDetails['address'],
      to,
    );
    Uint8List privateKey = HEX.decode(tronDetails['privateKey']);
    Uint8List txID = HEX.decode(txInfo['txID']);
    final signatureEC = sign(txID, privateKey);
    final recid = signatureEC.v - 27;
    final signature = '${HEX.encode([
          ...signatureEC.r.toUint8List(),
          ...signatureEC.s.toUint8List(),
        ])}0$recid';
    txInfo['signature'] = [signature];
    final txSent = await sendRawTransaction(api, txInfo);

    if (txSent['result'] ?? false) {
      return txSent['txid'];
    }
    throw Exception('sending failed');
  }

  @override
  validateAddress(String address) {
    if (!wallet.isValidTronAddress(address)) {
      throw Exception('Invalid $default_ address');
    }
  }

  @override
  int decimals() {
    return tronDecimals;
  }
}

List getTronBlockchains() {
  List blockChains = [
    {
      'blockExplorer':
          'https://tronscan.org/#/transaction/$transactionhashTemplateKey',
      'symbol': 'TRX',
      'name': 'Tron',
      'default': 'TRX',
      'image': 'assets/tron.png',
      'api': 'https://api.trongrid.io',
    }
  ];

  if (enableTestNet) {
    blockChains.add({
      'blockExplorer':
          'https://shasta.tronscan.org/#/transaction/$transactionhashTemplateKey',
      'symbol': 'TRX',
      'default': 'TRX',
      'name': 'Tron(Testnet)',
      'image': 'assets/tron.png',
      'api': 'https://api.shasta.trongrid.io',
    });
  }

  return blockChains;
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

String tronAddressToHex(String address) {
  if (isHexString(address)) {
    return address.replaceFirst('0x', TRX_ADDRESS_PREFIX).toUpperCase();
  }
  return HEX.encode(bs58check.decode(address)).toUpperCase();
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
