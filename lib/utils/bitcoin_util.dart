import 'dart:convert';
import 'dart:math';
import 'package:bitbox/bitbox.dart' as Bitbox;
import 'package:cryptowallet/utils/pos_networks.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bitbox/bitbox.dart' as bitbox;

import 'app_config.dart';

const sochainApi = 'https://sochain.com/api/v2/';
Future<int> getBCHNetworkFee(
    String address, Map posDetails, int satoshiToSend) async {
  final utxos = await Bitbox.Address.utxo(address) as List<Bitbox.Utxo>;

  final signatures = <Map>[];

  int totalBalance = 0;
  int fee = 0;
  for (var utxo in utxos) {
    totalBalance += utxo.satoshis;
    fee = Bitbox.BitcoinCash.getByteCount(signatures.length, 1);
    if (totalBalance - satoshiToSend - fee >= 0) break;
  }
  return fee;
}

Future<int> getBitcoinTypeNetworkFee(
    int satoshiToSend, List userUnspentInput) async {
  int inputCount = 0;
  int outputCount = 2;
  int transactionSize = 0;
  int totalAmountAvailable = 0;
  int fee = 0;

  for (int i = 0; i < userUnspentInput.length; i++) {
    transactionSize = inputCount * 146 + outputCount * 34 + 10 - inputCount;
    fee = transactionSize * 20;
    int utxAvailable =
        (double.parse(userUnspentInput[i]['value']) * pow(10, bitCoinDecimals))
            .toInt();
    totalAmountAvailable += utxAvailable;
    inputCount += 1;
    if (totalAmountAvailable - satoshiToSend - fee >= 0) break;
  }
  return fee;
}

Future<List> getUnspentTransactionBitcoinType(Map posDetails) async {
  final pref = Hive.box(secureStorageKey);

  final bitcoinTypeDetails = await getBitcoinFromMemnomic(
    pref.get(currentMmenomicKey),
    posDetails,
  );
  NetworkType bitcoinNetworkType = posDetails['POSNetwork'];
  final request = await http.get(Uri.parse(
      "${sochainApi}get_tx_unspent/${getSoChainTypeFromNetwork(bitcoinNetworkType)}/${bitcoinTypeDetails['address']}"));

  if (request.statusCode ~/ 100 == 4 || request.statusCode ~/ 100 == 5) {
    throw Exception('Request failed');
  }

  return jsonDecode(request.body)['data']['txs'];
}

String getSoChainTypeFromNetwork(bitcoin.NetworkType bitcoinNetworkType) {
  if (bitcoinNetworkType == bitcoin.bitcoin) {
    return "BTC";
  } else if (bitcoinNetworkType == bitcoin.testnet) {
    return "BTCTEST";
  } else if (bitcoinNetworkType == litecoin) {
    return "LTC";
  } else if (bitcoinNetworkType == dogecoin) {
    return "DOGE";
  } else if (bitcoinNetworkType == zcash) {
    return "ZEC";
  } else if (bitcoinNetworkType == dash) {
    return "DASH";
  } else if (bitcoinNetworkType == bitcoincash) {
    return "BCH";
  } else {
    throw Exception('Not supported network');
  }
}

Future<Map> sendBCHType(
  String destinationAddress,
  int satoshiToSend,
  Map posDetails,
  Map bitCoinDetails,
) async {
  final builder = Bitbox.Bitbox.transactionBuilder();

  final utxos =
      await Bitbox.Address.utxo(bitCoinDetails['address']) as List<Bitbox.Utxo>;

  final signatures = <Map>[];

  int totalBalance = 0;

  for (var utxo in utxos) {
    builder.addInput(utxo.txid, utxo.vout);

    final sender = ECPair.fromPrivateKey(
      txDataToUintList(bitCoinDetails['private_key']),
      network: posDetails['POSNetwork'],
    );
    signatures.add({
      "vin": signatures.length,
      "key_pair": sender,
      "original_amount": utxo.satoshis
    });

    totalBalance += utxo.satoshis;
    final fee = Bitbox.BitcoinCash.getByteCount(signatures.length, 1);
    if (totalBalance - satoshiToSend - fee >= 0) break;
  }

  final outputAddress = bitCoinDetails['address'];

  if (totalBalance > 0 && outputAddress != "") {
    final fee = Bitbox.BitcoinCash.getByteCount(signatures.length, 1);

    builder.addOutput(outputAddress, totalBalance - satoshiToSend - fee);
    builder.addOutput(destinationAddress, satoshiToSend);

    for (var signature in signatures) {
      builder.sign(
        signature["vin"],
        signature["key_pair"],
        signature["original_amount"],
      );
    }

    final tx = builder.build();

    final txid = await Bitbox.RawTransactions.sendRawTransaction([tx.toHex()]);

    return {'txid': txid[0]};
  }
  return {};
}

Future<Map> sendBTCType(
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
  String sochainNetwork = getSoChainTypeFromNetwork(bitcoinNetworkType);

  final pref = Hive.box(secureStorageKey);

  final bitcoinTypeDetails = await getBitcoinFromMemnomic(
    pref.get(currentMmenomicKey),
    posDetails,
  );
  if (sochainNetwork == 'BCH') {
    return await sendBCHType(
      destinationAddress,
      satoshiToSend,
      posDetails,
      bitcoinTypeDetails,
    );
  }
  List userUnspentInput = await getUnspentTransactionBitcoinType(posDetails);

  final sender = ECPair.fromPrivateKey(
    txDataToUintList(bitcoinTypeDetails['private_key']),
    network: bitcoinNetworkType,
  );

  final txb = bitcoin.TransactionBuilder();
  txb.setVersion(1);
  txb.network = bitcoinNetworkType;

  for (int i = 0; i < userUnspentInput.length; i++) {
    txb.addInput(
      userUnspentInput[i]['txid'],
      userUnspentInput[i]['output_no'],
      null,
      txDataToUintList('0x${userUnspentInput[i]['script_hex']}'),
    );

    int utxAvailable =
        (double.parse(userUnspentInput[i]['value']) * pow(10, bitCoinDecimals))
            .toInt();
    utxInputsValues.add(utxAvailable);
    totalAmountAvailable += utxAvailable;

    inputCount += 1;
    fee = await getBitcoinTypeNetworkFee(satoshiToSend, userUnspentInput);
    if (totalAmountAvailable - satoshiToSend - fee >= 0) break;
  }

  if (totalAmountAvailable - satoshiToSend - fee < 0) {
    throw Exception('not enough fee for transfer');
  }

  txb.addOutput(destinationAddress, satoshiToSend);
  txb.addOutput(bitcoinTypeDetails['address'],
      totalAmountAvailable - satoshiToSend - fee);

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

  return json.decode(sendTransaction.body)['data'];
}

Future<double> getBitcoinAddressBalance(
  String address,
  bitcoin.NetworkType bitcoinNetworkType, {
  bool skipNetworkRequest = false,
}) async {
  final pref = Hive.box(secureStorageKey);
  final sochainType = getSoChainTypeFromNetwork(bitcoinNetworkType);

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
      final data = (await http.get(Uri.parse(
              '${sochainApi}get_address_balance/$sochainType/$address')))
          .body;
      balance = double.parse(jsonDecode(data)['data']['confirmed_balance']);
    }

    await pref.put(key, balance);

    return balance;
  } catch (e) {
    return savedBalance;
  }
}
