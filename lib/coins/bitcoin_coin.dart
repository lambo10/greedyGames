// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:math';

import 'package:bech32/bech32.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart';
import 'package:hive/hive.dart';
import 'package:bs58check/bs58check.dart' as bs58check;
import 'package:http/http.dart';
import 'package:web3dart/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bitbox/bitbox.dart' as bitbox;

import 'package:http/http.dart';
import 'package:cryptowallet/utils/pos_networks.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:http/http.dart' as http;

import '../interface/coin.dart';
import '../model/seed_phrase_root.dart';
import '../utils/alt_ens.dart';
import '../utils/app_config.dart';

final pref = Hive.box(secureStorageKey);
const sochainApi = 'https://sochain.com/api/v2/';
const bitCoinDecimals = 8;

class BitcoinCoin extends Coin {
  NetworkType POSNetwork;
  bool P2WPKHType;
  String derivationPath;
  String blockExplorer;
  String symbol;
  String default_;
  String image;
  String name;

  BitcoinCoin({
    this.blockExplorer,
    this.symbol,
    this.default_,
    this.image,
    this.P2WPKHType,
    this.derivationPath,
    this.POSNetwork,
    this.name,
  });

  factory BitcoinCoin.fromJson(Map<String, dynamic> json) {
    return BitcoinCoin(
      POSNetwork: json['POSNetwork'],
      derivationPath: json['derivationPath'],
      P2WPKHType: json['P2WPKH'],
      blockExplorer: json['blockExplorer'],
      default_: json['default'],
      symbol: json['symbol'],
      image: json['image'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['POSNetwork'] = POSNetwork;
    data['P2WPKH'] = P2WPKHType;
    data['default'] = default_;
    data['symbol'] = symbol;
    data['name'] = name;
    data['blockExplorer'] = blockExplorer;
    data['derivationPath'] = derivationPath;
    data['image'] = image;

    return data;
  }

  @override
  fromMnemonic(String mnemonic) async {
    final keyName = sha3('bitcoinDetail$POSNetwork$default_');
    List mmenomicMapping = [];
    if (pref.get(keyName) != null) {
      mmenomicMapping = jsonDecode(pref.get(keyName)) as List;
      for (int i = 0; i < mmenomicMapping.length; i++) {
        if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
          return mmenomicMapping[i]['key'];
        }
      }
    }
    final keys = await compute(
      calculateBitCoinKey,
      Map.from(toJson())
        ..addAll({
          mnemonicKey: mnemonic,
          seedRootKey: seedPhraseRoot,
        }),
    );
    mmenomicMapping.add({'key': keys, 'mmenomic': mnemonic});
    await pref.put(keyName, jsonEncode(mmenomicMapping));
    return keys;
  }

  @override
  Future<double> getBalance(bool skipNetworkRequest) async {
    final sochainType = _abrFromNetwork(POSNetwork);
    final address = await address_();

    final key = '${sochainType}AddressBalance$address';
    final storedBalance = pref.get(key);

    double savedBalance = 0;

    if (storedBalance != null) {
      savedBalance = storedBalance;
    }

    if (skipNetworkRequest) return savedBalance;

    try {
      double balance = 0.0;
      if (sochainType == 'BCH') {
        final addressDetails = await bitbox.Address.details(address);
        balance = addressDetails['balance'];
      } else {
        final url = '${sochainApi}get_address_balance/$sochainType/$address';
        final response = await get(Uri.parse(url));
        final data = response.body;
        balance = double.parse(jsonDecode(data)['data']['confirmed_balance']);
      }

      await pref.put(key, balance);

      return balance;
    } catch (e) {
      return savedBalance;
    }
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
  Future<String> transferToken(String amount, String to) async {
    double satoshi = double.parse(
          amount,
        ) *
        pow(10, bitCoinDecimals);

    int amountToSend = satoshi.toInt();

    return await _sendBTCType(
      to,
      amountToSend,
      toJson(),
    );
  }

  @override
  validateAddress(String address) {
    if (default_ == 'BCH') {
      bitbox.Address.detectFormat(address);
      return;
    }

    if (Address.validateAddress(address, POSNetwork)) {
      return;
    }

    bool canReceivePayment = false;

    try {
      final base58DecodeRecipient = bs58check.decode(address);

      final pubHashString = base58DecodeRecipient[0].toRadixString(16) +
          base58DecodeRecipient[1].toRadixString(16);

      canReceivePayment =
          hexToInt(pubHashString).toInt() == POSNetwork.pubKeyHash;
    } catch (_) {}

    if (!canReceivePayment) {
      Bech32 sel = bech32.decode(address);
      canReceivePayment = POSNetwork.bech32 == sel.hrp;
    }

    if (!canReceivePayment) {
      throw Exception('Invalid $symbol address');
    }
  }

  Future<int> _getNetworkFee(int satoshiToSend, List userUnspentInput) async {
    int inputCount = 0;
    int outputCount = 2;
    int transactionSize = 0;
    int totalAmountAvailable = 0;
    int fee = 0;

    for (int i = 0; i < userUnspentInput.length; i++) {
      transactionSize = inputCount * 146 + outputCount * 34 + 10 - inputCount;
      fee = transactionSize * 20;
      int utxAvailable = (double.parse(userUnspentInput[i]['value']) *
              pow(10, bitCoinDecimals))
          .toInt();
      totalAmountAvailable += utxAvailable;
      inputCount += 1;
      if (totalAmountAvailable - satoshiToSend - fee >= 0) break;
    }
    return fee;
  }

  Future<List> _getUnspentTXs(Map posDetails) async {
    final bitcoinDetails = await fromMnemonic(pref.get(currentMmenomicKey));
    NetworkType bitcoinNetworkType = posDetails['POSNetwork'];
    final url =
        "${sochainApi}get_tx_unspent/${_abrFromNetwork(bitcoinNetworkType)}/${bitcoinDetails['address']}";
    final request = await http.get(Uri.parse(url));

    if (request.statusCode ~/ 100 == 4 || request.statusCode ~/ 100 == 5) {
      throw Exception('Request failed');
    }

    return jsonDecode(request.body)['data']['txs'];
  }

  String _abrFromNetwork(NetworkType bitcoinNetworkType) {
    return symbol;
  }

  Future<String> _sendBTCType(
    String destinationAddress,
    int satoshiToSend,
    Map posDetails,
  ) async {
    if (satoshiToSend < satoshiDustAmount) {
      throw Exception('dust amount given, bitcoin too small to send');
    }
    int totalAmountAvailable = 0;
    int inputCount = 0;
    int fee = 0;
    List<int> utxInputsValues = [];

    NetworkType bitcoinNetworkType = posDetails['POSNetwork'];
    String sochainNetwork = _abrFromNetwork(bitcoinNetworkType);

    List userUnspentInput = await _getUnspentTXs(posDetails);
    final mmemomic = pref.get(currentMmenomicKey);
    final bitcoinDetails = await fromMnemonic(mmemomic);
    final sender = ECPair.fromPrivateKey(
      txDataToUintList(bitcoinDetails['privateKey']),
      network: bitcoinNetworkType,
    );

    final txb = TransactionBuilder();
    txb.setVersion(1);
    txb.network = bitcoinNetworkType;

    for (int i = 0; i < userUnspentInput.length; i++) {
      txb.addInput(
        userUnspentInput[i]['txid'],
        userUnspentInput[i]['output_no'],
        null,
        txDataToUintList('0x${userUnspentInput[i]['script_hex']}'),
      );

      int utxAvailable = (double.parse(userUnspentInput[i]['value']) *
              pow(10, bitCoinDecimals))
          .toInt();
      utxInputsValues.add(utxAvailable);
      totalAmountAvailable += utxAvailable;

      inputCount += 1;
      fee = await _getNetworkFee(satoshiToSend, userUnspentInput);
      if (totalAmountAvailable - satoshiToSend - fee >= 0) break;
    }

    if (totalAmountAvailable - satoshiToSend - fee < 0) {
      throw Exception('not enough fee for transfer');
    }
    final address = await address_();
    txb.addOutput(destinationAddress, satoshiToSend);
    txb.addOutput(address, totalAmountAvailable - satoshiToSend - fee);

    for (int i = 0; i < inputCount; i++) {
      txb.sign(
        vin: i,
        keyPair: sender,
        witnessValue: utxInputsValues[i],
      );
    }

    String hexBuilt = txb.build().toHex();

    final sendTransaction = await http.post(
      Uri.parse("${sochainApi}send_tx/$sochainNetwork"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'tx_hex': hexBuilt}),
    );

    if (sendTransaction.statusCode ~/ 100 == 4 ||
        sendTransaction.statusCode ~/ 100 == 5) {
      if (kDebugMode) {
        print(sendTransaction.body);
      }
      throw Exception('Request failed');
    }

    if (kDebugMode) {
      print(sendTransaction.body);
    }

    return json.decode(sendTransaction.body)['data']['txid'];
  }

  @override
  int decimals() {
    return bitCoinDecimals;
  }

  @override
  Future<double> getTransactionFee(String amount, String to) async {
    List getUnspentOutput;
    int fee = 0;
    num satoshi = double.parse(amount) * pow(10, 8);
    int satoshiToSend = satoshi.toInt();

    getUnspentOutput = await _getUnspentTXs(toJson());
    fee = await _getNetworkFee(satoshiToSend, getUnspentOutput);

    double feeInBitcoin = fee / pow(10, bitCoinDecimals);

    return feeInBitcoin;
  }
}

List<Map> getBitCoinPOSBlockchains() {
  List<Map> blockChains = [
    {
      'name': 'Bitcoin',
      'symbol': 'BTC',
      'default': 'BTC',
      'blockExplorer':
          'https://live.blockcypher.com/btc/tx/$transactionhashTemplateKey',
      'image': 'assets/bitcoin.jpg',
      'POSNetwork': bitcoin,
      'P2WPKH': true,
      'derivationPath': "m/84'/0'/0'/0/0"
    },
    {
      'symbol': 'BCH',
      'name': 'BitcoinCash',
      'default': 'BCH',
      'blockExplorer':
          'https://www.blockchain.com/explorer/transactions/bch/$transactionhashTemplateKey',
      'image': 'assets/bitcoin_cash.png',
      'POSNetwork': bitcoincash,
      'P2WPKH': false,
      'derivationPath': "m/44'/145'/0'/0/0"
    },
    {
      'name': 'Litecoin',
      'symbol': 'LTC',
      'default': 'LTC',
      'blockExplorer':
          'https://live.blockcypher.com/ltc/tx/$transactionhashTemplateKey',
      'image': 'assets/litecoin.png',
      'POSNetwork': litecoin,
      'P2WPKH': true,
      'derivationPath': "m/84'/2'/0'/0/0"
    },
    {
      'name': 'Dash',
      'symbol': 'DASH',
      'default': 'DASH',
      'blockExplorer':
          'https://live.blockcypher.com/dash/tx/$transactionhashTemplateKey',
      'image': 'assets/dash.png',
      'POSNetwork': dash,
      'P2WPKH': false,
      'derivationPath': "m/44'/5'/0'/0/0"
    },
    {
      'name': 'ZCash',
      'symbol': 'ZEC',
      'default': 'ZEC',
      'blockExplorer':
          'https://zcashblockexplorer.com/transactions/$transactionhashTemplateKey',
      'image': 'assets/zcash.png',
      'POSNetwork': zcash,
      'P2WPKH': false,
      'derivationPath': "m/44'/133'/0'/0/0"
    },
    {
      'name': 'Dogecoin',
      'symbol': 'DOGE',
      'default': 'DOGE',
      'blockExplorer':
          'https://live.blockcypher.com/doge/tx/$transactionhashTemplateKey',
      'image': 'assets/dogecoin.png',
      'POSNetwork': dogecoin,
      'P2WPKH': false,
      'derivationPath': "m/44'/3'/0'/0/0"
    }
  ];

  if (enableTestNet) {
    blockChains.add({
      'name': 'Bitcoin(Test)',
      'symbol': 'BTC',
      'default': 'BTC',
      'blockExplorer':
          'https://www.blockchain.com/btc-testnet/tx/$transactionhashTemplateKey',
      'image': 'assets/bitcoin.jpg',
      'POSNetwork': testnet,
      'P2WPKH': false,
      'derivationPath': "m/44'/0'/0'/0/0"
    });
  }

  return blockChains;
}

Map calculateBitCoinKey(Map config) {
  SeedPhraseRoot seedRoot_ = config[seedRootKey];
  final node = seedRoot_.root.derivePath(config['derivationPath']);

  String address;
  if (config['P2WPKH']) {
    address = P2WPKH(
      data: PaymentData(
        pubkey: node.publicKey,
      ),
      network: config['POSNetwork'],
    ).data.address;
  } else {
    address = P2PKH(
      data: PaymentData(
        pubkey: node.publicKey,
      ),
      network: config['POSNetwork'],
    ).data.address;
  }
  if (config['default'] == 'BCH') {
    if (bitbox.Address.detectFormat(address) == bitbox.Address.formatLegacy) {
      address = bitbox.Address.toCashAddress(address).split(':')[1];
    }
  }

  if (config['default'] == 'ZEC') {
    final baddr = [...bs58check.decode(address)];
    baddr.removeAt(0);

    final taddr = Uint8List(22);

    taddr.setAll(2, baddr);
    taddr.setAll(0, [0x1c, 0xb8]);

    address = bs58check.encode(taddr);
  }

  return {'address': address, 'privateKey': "0x${HEX.encode(node.privateKey)}"};
}
