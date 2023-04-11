// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hash/hash.dart';
import 'package:hex/hex.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:crypto/crypto.dart';

import '../interface/coin.dart';
import '../model/seed_phrase_root.dart';
import '../utils/app_config.dart';
import '../utils/rpc_urls.dart';
import '../xrp_transaction/xrp_transaction.dart';

final pref = Hive.box(secureStorageKey);
const xrpDecimals = 6;

class XRPCoin implements Coin {
  String api;
  String address;
  String blockExplorer;
  String symbol;
  String default_;
  String image;
  String name;

  XRPCoin({
    this.blockExplorer,
    this.symbol,
    this.default_,
    this.image,
    this.address,
    this.name,
    this.api,
  });
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

  XRPCoin.fromJson(Map<String, dynamic> json) {
    api = json['api'];
    blockExplorer = json['blockExplorer'];
    default_ = json['default'];
    symbol = json['symbol'];
    image = json['image'];
    address = json['address'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['api'] = api;

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
    String key = 'xrpDetails$mnemonic';

    List mmenomicMapping = [];

    if (pref.get(key) != null) {
      mmenomicMapping = jsonDecode(pref.get(key)) as List;
      for (int i = 0; i < mmenomicMapping.length; i++) {
        if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
          return mmenomicMapping[i]['key'];
        }
      }
    }

    final keys = await compute(calculateRippleKey, {
      mnemonicKey: mnemonic,
      seedRootKey: seedPhraseRoot,
    });

    mmenomicMapping.add({'key': keys, 'mmenomic': mnemonic});
    await pref.put(key, jsonEncode(mmenomicMapping));
    return keys;
  }

  Map<String, String> calculateRippleKey(Map config) {
    SeedPhraseRoot seedRoot_ = config[seedRootKey];
    final node = seedRoot_.root.derivePath("m/44'/144'/0'/0/0");

    final pubKeyHash = computePublicKeyHash(node.publicKey);

    final t = sha256
        .convert(sha256.convert([0, ...pubKeyHash]).bytes)
        .bytes
        .sublist(0, 4);

    String address =
        xrpBaseCodec.encode(Uint8List.fromList([0, ...pubKeyHash, ...t]));
    return {
      'address': address,
      'publicKey': HEX.encode(node.publicKey),
      'privateKey': HEX.encode(node.privateKey),
    };
  }

  Uint8List computePublicKeyHash(Uint8List publicKeyBytes) {
    final hash256 = sha256.convert(publicKeyBytes).bytes;
    final hash160 = RIPEMD160().update(hash256).digest();

    return Uint8List.fromList(hash160);
  }

  @override
  Future<double> getBalance(bool skipNetworkRequest) async {
    final key = 'xrpAddressBalance$address$api';

    final storedBalance = pref.get(key);

    double savedBalance = 0;

    if (storedBalance != null) {
      savedBalance = storedBalance;
    }

    if (skipNetworkRequest) return savedBalance;
    try {
      final httpFromWs = Uri.parse(api);
      final request = await post(
        httpFromWs,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "method": "account_info",
          "params": [
            {"account": address}
          ]
        }),
      );

      if (request.statusCode ~/ 100 == 4 || request.statusCode ~/ 100 == 5) {
        throw Exception(request.body);
      }

      Map accountInfo = json.decode(request.body);

      if (accountInfo['result']['account_data'] == null) {
        throw Exception('Account not found');
      }

      final balance = accountInfo['result']['account_data']['Balance'];
      final userBalance = double.parse(balance) / pow(10, xrpDecimals);
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
    final getXRPDetails = await fromMnemonic(pref.get(currentMmenomicKey));

    final amountInDrop =
        BigInt.from(double.parse(amount) * pow(10, xrpDecimals));

    Map xrpJson = {
      "Account": getXRPDetails['address'],
      "Fee": "10",
      "Sequence": 0,
      "TransactionType": "Payment",
      "SigningPubKey": getXRPDetails['publicKey'],
      "Amount": "$amountInDrop",
      "Destination": to
    };

    if (getXRPDetails['address'] == to) {
      throw Exception(
        'An XRP payment transaction cannot have the same sender and destination',
      );
    }

    Map ledgers = await getXrpLedgerSequence(getXRPDetails['address'], api);

    Map fee = await getXrpFee(api);

    if (ledgers != null) {
      xrpJson = {...xrpJson, ...ledgers};
    }
    if (fee != null) {
      xrpJson = {...xrpJson, ...fee};
    }

    Map xrpTransaction =
        signXrpTransaction(getXRPDetails['privateKey'], xrpJson);

    final httpFromWs = Uri.parse(api);
    final request = await post(
      httpFromWs,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "method": "submit",
        "params": [
          {
            "tx_blob": encodeXrpJson(xrpTransaction).substring(8),
          }
        ]
      }),
    );

    if (request.statusCode ~/ 100 == 4 || request.statusCode ~/ 100 == 5) {
      throw Exception(request.body);
    }

    Map txInfo = json.decode(request.body);

    final hash = txInfo['result']["tx_json"]['hash'];

    return hash;
  }

  @override
  validateAddress(String address) {
    final bytes = xrpBaseCodec.decode(address);

    final computedCheckSum = sha256
        .convert(sha256.convert(bytes.sublist(0, bytes.length - 4)).bytes)
        .bytes
        .sublist(0, 4);
    final expectedCheckSum = bytes.sublist(bytes.length - 4);

    if (!seqEqual(computedCheckSum, expectedCheckSum)) {
      throw Exception('Invalid XRP address');
    }
  }

  @override
  int decimals() {
    return xrpDecimals;
  }
}

List getXRPBlockChains() {
  List blockChains = [
    {
      'name': 'XRP',
      'symbol': 'XRP',
      'default': 'XRP',
      'blockExplorer':
          'https://livenet.xrpl.org/transactions/$transactionhashTemplateKey',
      'image': 'assets/ripple.png',
      'api': 'https://s1.ripple.com:51234/'
    }
  ];
  if (enableTestNet) {
    blockChains.add({
      'name': 'XRP(Testnet)',
      'symbol': 'XRP',
      'default': 'XRP',
      'blockExplorer':
          'https://testnet.xrpl.org/transactions/$transactionhashTemplateKey',
      'image': 'assets/ripple.png',
      'api': 'https://s.altnet.rippletest.net:51234/',
    });
  }
  return blockChains;
}

Future<Map> getXrpLedgerSequence(
  String address,
  String ws,
) async {
  try {
    final httpFromWs = Uri.parse(ws);
    final request = await post(
      httpFromWs,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "method": "account_info",
        "params": [
          {
            "account": address,
            "ledger_index": "current",
          }
        ]
      }),
    );

    if (request.statusCode ~/ 100 == 4 || request.statusCode ~/ 100 == 5) {
      throw Exception(request.body);
    }

    Map accountInfo = json.decode(request.body);

    final accountData = accountInfo['result']['account_data'];
    if (accountData == null) {
      throw Exception('Account not found');
    }

    return {
      'Sequence': accountData['Sequence'],
      'Flags': accountData['Flags'],
    };
  } catch (e) {
    return null;
  }
}

Future<Map> getXrpFee(String ws) async {
  try {
    final httpFromWs = Uri.parse(ws);
    final request = await post(
      httpFromWs,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'method': 'fee',
        'params': [{}]
      }),
    );

    if (request.statusCode ~/ 100 == 4 || request.statusCode ~/ 100 == 5) {
      throw Exception(request.body);
    }

    Map feeInfo = json.decode(request.body);

    return {
      'Fee': feeInfo['result']['drops']['base_fee'],
    };
  } catch (e) {
    return null;
  }
}

Future<bool> fundRippleTestnet(String address) async {
  try {
    const ws = 'https://faucet.altnet.rippletest.net/accounts';
    final httpFromWs = Uri.parse(ws);
    final request = await post(
      httpFromWs,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({"destination": address}),
    );

    if (request.statusCode ~/ 100 == 4 || request.statusCode ~/ 100 == 5) {
      throw Exception(request.body);
    }
    return true;
  } catch (e) {
    return false;
  }
}
