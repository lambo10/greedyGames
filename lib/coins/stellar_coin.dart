// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:math';

import 'package:eth_sig_util/util/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart' as stellar
    hide Row;

import '../interface/coin.dart';
import '../utils/app_config.dart';

final pref = Hive.box(secureStorageKey);
const stellarDecimals = 6;

class StellarCoin extends Coin {
  stellar.Network cluster;
  stellar.StellarSDK sdk;
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

  StellarCoin({
    this.blockExplorer,
    this.symbol,
    this.default_,
    this.image,
    this.name,
    this.sdk,
    this.cluster,
  });

  StellarCoin.fromJson(Map<String, dynamic> json) {
    sdk = json['sdk'];
    cluster = json['cluster'];
    blockExplorer = json['blockExplorer'];
    default_ = json['default'];
    symbol = json['symbol'];
    image = json['image'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cluster'] = cluster;
    data['sdk'] = sdk;
    data['default'] = default_;
    data['symbol'] = symbol;
    data['name'] = name;
    data['blockExplorer'] = blockExplorer;
    data['image'] = image;

    return data;
  }

  @override
  Future<Map> fromMnemonic(String mnemonic) async {
    const keyName = 'stellarDetail';
    List mmenomicMapping = [];

    if (pref.get(keyName) != null) {
      mmenomicMapping = jsonDecode(pref.get(keyName)) as List;
      for (int i = 0; i < mmenomicMapping.length; i++) {
        if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
          return mmenomicMapping[i]['key'];
        }
      }
    }
    final keys = await compute(calculateStellarKey, {mnemonicKey: mnemonic});
    mmenomicMapping.add({'key': keys, 'mmenomic': mnemonic});
    await pref.put(keyName, jsonEncode(mmenomicMapping));
    return keys;
  }

  Future<Map> calculateStellarKey(Map config) async {
    final wallet = await stellar.Wallet.from(config[mnemonicKey]);
    final userWalletAddress = await wallet.getKeyPair(index: 0);
    return {
      'address': userWalletAddress.accountId,
      'private_key': userWalletAddress.secretSeed,
    };
  }

  @override
  Future<double> getBalance(bool skipNetworkRequest) async {
    final address = await address_();
    final key = 'stellarAddressBalance$address${bytesToHex(cluster.networkId)}';

    final storedBalance = pref.get(key);

    double savedBalance = 0;

    if (storedBalance != null) {
      savedBalance = storedBalance;
    }

    if (skipNetworkRequest) return savedBalance;

    try {
      stellar.AccountResponse account = await sdk.accounts.account(address);

      for (stellar.Balance balance in account.balances) {
        if (balance.assetType == stellar.Asset.TYPE_NATIVE) {
          double balanceInStellar = double.parse(balance.balance);
          await pref.put(key, balanceInStellar);
          return balanceInStellar;
        }
      }
      return 0;
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
    String mnemonic = pref.get(currentMmenomicKey);
    Map stellarDetails = await fromMnemonic(mnemonic);
    stellar.KeyPair senderKeyPair =
        stellar.KeyPair.fromSecretSeed(stellarDetails['private_key']);

    stellar.AccountResponse sender =
        await sdk.accounts.account(senderKeyPair.accountId);
    stellar.Operation operation;
    if (await isActiveStellarAccount(to, sdk)) {
      operation = stellar.PaymentOperationBuilder(
        to,
        stellar.Asset.NATIVE,
        amount,
      ).build();
    } else {
      operation = stellar.CreateAccountOperationBuilder(
        to,
        amount,
      ).build();
    }

    stellar.Transaction transaction =
        stellar.TransactionBuilder(sender).addOperation(operation).build();

    transaction.sign(
      senderKeyPair,
      cluster,
    );

    stellar.SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);

    if (response.success) {
      return response.hash;
    }
    throw Exception('could not send coin');
  }

  @override
  validateAddress(String address) {
    stellar.KeyPair.fromAccountId(address);
  }

  Future<double> getStellarGas(
    String destinationAddress,
    String stellarToSend,
    stellar.StellarSDK sdk,
  ) async {
    try {
      String mnemonic = pref.get(currentMmenomicKey);
      Map getStellarDetails = await fromMnemonic(mnemonic);

      stellar.KeyPair senderKeyPair =
          stellar.KeyPair.fromSecretSeed(getStellarDetails['private_key']);
      stellar.AccountResponse sender =
          await sdk.accounts.account(senderKeyPair.accountId);
      stellar.Operation operation;
      if (await isActiveStellarAccount(destinationAddress, sdk)) {
        operation = stellar.PaymentOperationBuilder(
          destinationAddress,
          stellar.Asset.NATIVE,
          stellarToSend,
        ).build();
      } else {
        operation = stellar.CreateAccountOperationBuilder(
          destinationAddress,
          stellarToSend,
        ).build();
      }

      stellar.Transaction transaction =
          stellar.TransactionBuilder(sender).addOperation(operation).build();

      return transaction.fee / pow(10, stellarDecimals);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(stackTrace);
      }
      return 0;
    }
  }

  @override
  int decimals() {
    return stellarDecimals;
  }

  @override
  Future<double> getTransactionFee(String amount, String to) async {
    return await getStellarGas(to, amount, sdk);
  }
}

List getStellarBlockChains() {
  List blockChains = [
    {
      'name': 'Stellar',
      'symbol': 'XLM',
      'default': 'XLM',
      'blockExplorer':
          'https://stellarchain.io/transactions/$transactionhashTemplateKey',
      'image': 'assets/stellar.png', // sdk stellar
      'sdk': stellar.StellarSDK.PUBLIC,
      'cluster': stellar.Network.PUBLIC
    }
  ];
  if (enableTestNet) {
    blockChains.add({
      'name': 'Stellar(Testnet)',
      'symbol': 'XLM',
      'default': 'XLM',
      'blockExplorer':
          'https://testnet.stellarchain.io/transactions/$transactionhashTemplateKey',
      'image': 'assets/stellar.png',
      'sdk': stellar.StellarSDK.TESTNET,
      'cluster': stellar.Network.TESTNET
    });
  }
  return blockChains;
}

Future<bool> isActiveStellarAccount(
  String address,
  stellar.StellarSDK sdk,
) async {
  try {
    stellar.KeyPair senderKeyPair = stellar.KeyPair.fromAccountId(address);
    await sdk.accounts.account(senderKeyPair.accountId);
    return true;
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print(stackTrace);
    }
    return false;
  }
}
