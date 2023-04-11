// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';

import '../interface/coin.dart';
import '../utils/app_config.dart';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart' as cardano;
import '../utils/rpc_urls.dart';

final pref = Hive.box(secureStorageKey);
const cardanoDecimals = 6;

class CardanoCoin extends Coin {
  String blockFrostKey;
  cardano.NetworkId cardano_network;
  String address;
  String blockExplorer;
  String symbol;
  String default_;
  String image;
  String name;

  CardanoCoin({
    this.blockExplorer,
    this.symbol,
    this.default_,
    this.image,
    this.address,
    this.name,
    this.blockFrostKey,
    this.cardano_network,
  });

  CardanoCoin.fromJson(Map<String, dynamic> json) {
    blockFrostKey = json['blockFrostKey'];
    cardano_network = json['cardano_network'];
    blockExplorer = json['blockExplorer'];
    default_ = json['default'];
    symbol = json['symbol'];
    image = json['image'];
    address = json['address'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cardano_network'] = cardano_network;
    data['blockFrostKey'] = blockFrostKey;
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
    final keyName = 'cardanoDetail${cardano_network.name}';
    List mmenomicMapping = [];
    if (pref.get(keyName) != null) {
      mmenomicMapping = jsonDecode(pref.get(keyName)) as List;

      for (int i = 0; i < mmenomicMapping.length; i++) {
        if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
          return mmenomicMapping[i]['key'];
        }
      }
    }
    final keys = await compute(calculateCardanoKey, {
      mnemonicKey: mnemonic,
      'network': cardano_network,
    });

    mmenomicMapping.add({'key': keys, 'mmenomic': mnemonic});

    await pref.put(keyName, jsonEncode(mmenomicMapping));
    return keys;
  }

  Map calculateCardanoKey(Map config) {
    final wallet = cardano.HdWallet.fromMnemonic(config[mnemonicKey]);
    const cardanoAccountHardOffsetKey = 0x80000000;

    String userWalletAddress = wallet
        .deriveUnusedBaseAddressKit(
            networkId: config['network'],
            index: 0,
            account: cardanoAccountHardOffsetKey,
            role: 0,
            unusedCallback: (cardano.ShelleyAddress address) => true)
        .address
        .toString();

    return {
      'address': userWalletAddress,
    };
  }

  @override
  Future<double> getBalance(bool skipNetworkRequest) async {
    final key = 'cardanoAddressBalance$address';

    final storedBalance = pref.get(key);

    double savedBalance = 0;

    if (storedBalance != null) {
      savedBalance = storedBalance;
    }

    if (skipNetworkRequest) return savedBalance;

    try {
      final cardanoBlockfrostBaseUrl =
          'https://cardano-${cardano_network == cardano.NetworkId.mainnet ? 'mainnet' : 'preprod'}.blockfrost.io/api/v0/addresses/';
      final request = await get(
        Uri.parse('$cardanoBlockfrostBaseUrl$address'),
        headers: {'project_id': blockFrostKey},
      );

      if (request.statusCode ~/ 100 == 4 || request.statusCode ~/ 100 == 5) {
        throw Exception('Request failed');
      }
      Map decodedData = jsonDecode(request.body);
      final String balance = (decodedData['amount'] as List)
          .where((element) => element['unit'] == 'lovelace')
          .toList()[0]['quantity'];

      final balanceFromAdaToLoveLace =
          (BigInt.parse(balance) / BigInt.from(pow(10, cardanoDecimals)))
              .toDouble();
      await pref.put(key, balanceFromAdaToLoveLace);

      return balanceFromAdaToLoveLace;
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

  @override
  Future<String> transferToken(String amount, String to) async {
    final walletBuilder = cardano.WalletBuilder()
      ..networkId = cardano_network
      ..mnemonic = pref.get(currentMmenomicKey).split(' ');

    final cardanoDetails = await fromMnemonic(pref.get(currentMmenomicKey));

    if (cardano_network == cardano.NetworkId.mainnet) {
      walletBuilder.mainnetAdapterKey = blockFrostKey;
    } else if (cardano_network == cardano.NetworkId.testnet) {
      walletBuilder.testnetAdapterKey = blockFrostKey;
    }
    final result = await walletBuilder.buildAndSync();
    if (result.isErr()) {
      if (kDebugMode) {
        print(result.err());
      }
      throw Exception(result.err());
    }

    final lovelace = double.parse(amount) * pow(10, cardanoDecimals);
    cardano.Wallet userWallet = result.unwrap();

    final coinSelection = await cardano.largestFirst(
      unspentInputsAvailable: userWallet.unspentTransactions,
      outputsRequested: [
        cardano.MultiAssetRequest.lovelace(
          lovelace.toInt() + maxFeeGuessForCardano,
        )
      ],
      ownedAddresses: userWallet.addresses.toSet(),
    );

    final builder = cardano.TransactionBuilder()
      ..wallet(userWallet)
      ..blockchainAdapter(userWallet.blockchainAdapter)
      ..toAddress(cardano.ShelleyAddress.fromBech32(to))
      ..inputs(coinSelection.unwrap().inputs)
      ..value(
        cardano.ShelleyValue(
          coin: lovelace.toInt(),
          multiAssets: [],
        ),
      )
      ..changeAddress(cardanoDetails['address']);

    final txResult = await builder.buildAndSign();

    if (txResult.isErr()) {
      if (kDebugMode) {
        print(txResult.err());
      }
      throw Exception(txResult.err());
    }

    final submitTrx = await userWallet.blockchainAdapter.submitTransaction(
      txResult.unwrap().serialize,
    );

    if (submitTrx.isErr()) {
      if (kDebugMode) {
        print(submitTrx.err());
      }
      throw Exception(submitTrx.err());
    }

    final txHash = submitTrx.unwrap();
    return txHash.replaceAll('"', '');
  }

  @override
  validateAddress(String address) {
    cardano.ShelleyAddress.fromBech32(address);
  }

  @override
  int decimals() {
    return cardanoDecimals;
  }
}

List getCardanoBlockChains() {
  List blockChains = [
    {
      'name': 'Cardano',
      'symbol': 'ADA',
      'default': 'ADA',
      'blockExplorer':
          'https://cardanoscan.io/transaction/$transactionhashTemplateKey',
      'image': 'assets/cardano.png',
      'cardano_network': cardano.NetworkId.mainnet,
      'blockFrostKey': 'mainnetpgkQqXqQ4HjK6gzUKaHW6VU9jcmcKEbd'
    }
  ];
  if (enableTestNet) {
    blockChains.add({
      'name': 'Cardano(Prepod)',
      'symbol': 'ADA',
      'default': 'ADA',
      'blockExplorer':
          'https://preprod.cardanoscan.io/transaction/$transactionhashTemplateKey',
      'image': 'assets/cardano.png',
      'cardano_network': cardano.NetworkId.testnet,
      'blockFrostKey': 'preprodmpCaCFGCxLihVPPxXxqEvEnp7dyFmG6J'
    });
  }
  return blockChains;
}
