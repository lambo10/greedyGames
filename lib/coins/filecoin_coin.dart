// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:math';

import 'package:algorand_dart/algorand_dart.dart';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart' hide Coin;
import 'package:elliptic/elliptic.dart';
import 'package:flutter/foundation.dart';
// ignore_for_file: constant_identifier_names

import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:hex/hex.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:leb128/leb128.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'package:cbor/cbor.dart' as cbor;
import 'package:cryptowallet/utils/addressToBytes.dart';
import 'package:cryptowallet/utils/app_config.dart';
import 'package:web3dart/crypto.dart';

import '../interface/coin.dart';
import '../model/seed_phrase_root.dart';

final pref = Hive.box(secureStorageKey);
const filecoinfaucet = 'https://faucet.calibration.fildev.network/';
const fileCoinDecimals = 18;

class FilecoinCoin implements Coin {
  String prefix;
  String baseUrl;
  String address;
  String blockExplorer;
  String symbol;
  String default_;
  String image;
  String name;

  FilecoinCoin({
    this.blockExplorer,
    this.symbol,
    this.default_,
    this.image,
    this.address,
    this.baseUrl,
    this.prefix,
    this.name,
  });

  FilecoinCoin.fromJson(Map<String, dynamic> json) {
    prefix = json['prefix'];
    baseUrl = json['baseUrl'];
    blockExplorer = json['blockExplorer'];
    default_ = json['default'];
    symbol = json['symbol'];
    image = json['image'];
    address = json['address'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['prefix'] = prefix;
    data['baseUrl'] = baseUrl;
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
    final keyName = 'fileCoinDetail$prefix';
    List mmenomicMapping = [];
    if (pref.get(keyName) != null) {
      mmenomicMapping = jsonDecode(pref.get(keyName)) as List;
      for (int i = 0; i < mmenomicMapping.length; i++) {
        if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
          return mmenomicMapping[i]['key'];
        }
      }
    }
    final keys = await compute(calculateFileCoinKey, {
      mnemonicKey: mnemonic,
      seedRootKey: seedPhraseRoot,
      'addressPrefix': prefix,
    });
    mmenomicMapping.add({'key': keys, 'mmenomic': mnemonic});
    await pref.put(keyName, jsonEncode(mmenomicMapping));
    return keys;
  }

  Uint8List _hexToU8a(String hex) {
    RegExp hexRegex = RegExp(r'^(0x)?[a-fA-F0-9]+$');
    if (!hexRegex.hasMatch(hex)) {
      throw ArgumentError('Provided string is not valid hex value');
    }
    final value = hex.startsWith('0x') ? hex.substring(2) : hex;
    final valLength = value.length ~/ 2;

    final bufLength = (valLength).ceil();

    final result = Uint8List(bufLength);
    final offset = (bufLength - valLength).clamp(0, bufLength);
    for (var index = 0; index < bufLength; index++) {
      result[index + offset] =
          int.parse(value.substring(index * 2, index * 2 + 2), radix: 16);
    }
    return result;
  }

  Map calculateFileCoinKey(Map config) {
    SeedPhraseRoot seedRoot_ = config[seedRootKey];
    final node = seedRoot_.root.derivePath("m/44'/461'/0'/0");
    final rs0 = node.derive(0);

    final pk = _hexToU8a(HEX.encode(rs0.privateKey));
    final e = getSecp256k1();

    final publickEy =
        e.privateToPublicKey(PrivateKey.fromBytes(getSecp256k1(), pk));

    final protocolByte = Leb128.encodeUnsigned(1);
    final payload = blake2bHash(HEX.decode(publickEy.toHex()), digestSize: 20);

    final addressBytes = [...protocolByte, ...payload];
    final checksum = blake2bHash(addressBytes, digestSize: 4);
    Uint8List bytes = Uint8List.fromList([...payload, ...checksum]);
    final address = '${config['addressPrefix']}1${Base32.encode(bytes)}';

    return {
      "address": address.toLowerCase(),
      'privateKey': HEX.encode(rs0.privateKey),
    };
  }

  @override
  Future<double> getBalance(bool skipNetworkRequest) async {
    final key = 'fileCoinAddressBalance$address$baseUrl';

    final storedBalance = pref.get(key);

    double savedBalance = 0;

    if (storedBalance != null) {
      savedBalance = storedBalance;
    }

    if (skipNetworkRequest) return savedBalance;

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "jsonrpc": "2.0",
          "id": 1,
          "method": "Filecoin.WalletBalance",
          "params": [address]
        }),
      );
      final responseBody = response.body;
      if (response.statusCode ~/ 100 == 4 || response.statusCode ~/ 100 == 5) {
        throw Exception(responseBody);
      }

      double balanceInFileCoin = double.parse(
            jsonDecode(responseBody)['result'].toString(),
          ) /
          pow(10, fileCoinDecimals);

      await pref.put(key, balanceInFileCoin);

      return balanceInFileCoin;
    } catch (e) {
      return savedBalance;
    }
  }

  @override
  Map getTransactions() {
    return {
      'trx': jsonDecode(pref.get('$default_ Details')),
      'currentUser': address
    };
  }

  @override
  validateAddress(String address) {
    if (!validateFilecoinAddress(address)) {
      throw Exception('not a valid filecoin address');
    }
  }

  Future<int> getFileCoinNonce(
    String addressPrefix,
    String baseUrl,
  ) async {
    try {
      final pref = Hive.box(secureStorageKey);
      String mnemonic = pref.get(currentMmenomicKey);
      final fileCoinDetails = await fromMnemonic(mnemonic);

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "id": 1,
          "jsonrpc": "2.0",
          "method": "Filecoin.MpoolGetNonce",
          "params": [fileCoinDetails['address']]
        }),
      );
      final responseBody = response.body;
      if (response.statusCode ~/ 100 == 4 || response.statusCode ~/ 100 == 5) {
        throw Exception(responseBody);
      }

      return jsonDecode(responseBody)['result'];
    } catch (e) {
      return 0;
    }
  }

  Future<Map<String, dynamic>> fileCoinEstimateGas(
    String baseUrl,
    Map msg,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "id": 1,
          "jsonrpc": "2.0",
          "method": "Filecoin.GasEstimateMessageGas",
          "params": [
            msg,
            {"MaxFee": "30000000000000"},
            []
          ]
        }),
      );
      final responseBody = response.body;

      if (response.statusCode ~/ 100 == 4 || response.statusCode ~/ 100 == 5) {
        throw Exception(responseBody);
      }

      Map jsonDecodedBody = jsonDecode(responseBody)['result'];

      if (jsonDecodedBody == null) {
        throw Exception('no response for gas fee available');
      }

      return jsonDecodedBody;
    } catch (e) {
      return {
        "GasLimit": 0,
        "GasFeeCap": "0",
        "GasPremium": "0",
      };
    }
  }

  bool validateFilecoinAddress(String address) {
    try {
      const checksumHashLength = 4;
      const fileCoinPrefixs = ['f', 't'];
      if (!fileCoinPrefixs.contains(address.substring(0, 1))) {
        return false;
      }
      final protocol = address[1];
      final protocolByte = Leb128.encodeUnsigned(int.parse(protocol));
      final raw = address.substring(2);
      if (protocol == '1' || protocol == '2' || protocol == '3') {
        List<int> payloadCksm = Base32.decode(raw);

        if (payloadCksm.length < checksumHashLength) {
          throw Exception('Invalid address length');
        }

        Uint8List payload = payloadCksm.sublist(0, payloadCksm.length - 4);

        Uint8List checksum = payloadCksm.sublist(payload.length);

        List<int> byteList = List.from(protocolByte)..addAll(payload);
        Uint8List bytes = Uint8List.fromList(byteList);

        if (!_validateChecksum(bytes, checksum)) {
          throw Exception('Invalid address checksum');
        }

        return true;
      } else if (protocol == '0') {
        const maxInt64StringLength = 19;
        if (raw.length > maxInt64StringLength) {
          throw Exception('Invalid ID address length');
        }
        final payload = Leb128.encodeUnsigned(int.parse(raw));
        final bytes = [...protocolByte, ...payload];
        if (kDebugMode) {
          print(bytes);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  _validateChecksum(Uint8List bytes, Uint8List checksum) {
    return seqEqual(_getChecksum(bytes), checksum);
  }

  Uint8List _getChecksum(Uint8List data) {
    return blake2bHash(data, digestSize: 4);
  }

  String transactionSignLotus(Map msg, String privateKeyHex) {
    final to = addressAsBytes(msg['To']);
    final from = addressAsBytes(msg['From']);
    final value = serializeBigNum(msg['Value']);
    final gasfeecap = serializeBigNum(msg['GasFeeCap']);
    final gaspremium = serializeBigNum(msg['GasPremium']);
    final gaslimit = msg['GasLimit'];
    int method = msg['Method'];
    final params = msg['Params'];
    int nonce = msg['Nonce'];
    int version = msg['Version'];

    final messageToEncode = [
      version ?? 0,
      to,
      from,
      nonce ?? 0,
      value,
      gaslimit,
      gasfeecap,
      gaspremium,
      method ?? 0,
      base64.decode(params ?? '')
    ];
    cbor.init();
    final output = cbor.OutputStandard();
    final encoder = cbor.Encoder(output);
    output.clear();
    encoder.writeArray(messageToEncode);
    final unsignedMessage = output.getDataAsList();
    Uint8List privateKey = HEX.decode(privateKeyHex);

    final messageDigest = getDigest(Uint8List.fromList(unsignedMessage));

    final signatureEC = sign(messageDigest, privateKey);
    final recid = signatureEC.v - 27;

    final cid = base64.encode([
      ...signatureEC.r.toUint8List(),
      ...signatureEC.s.toUint8List(),
      recid,
    ]);
    return cid;
  }

  Map constructFilecoinMsg(
    String destinationAddress,
    String from,
    int nonce,
    BigInt filecoinToSend,
  ) {
    final msg = {
      "Version": 0,
      "To": destinationAddress,
      "From": from,
      "Nonce": nonce,
      "Value": '$filecoinToSend',
      "GasLimit": 0,
      "GasFeeCap": "0",
      "GasPremium": "0",
      "Method": 0,
      "Params": ""
    };
    return msg;
  }

  @override
  Future<String> transferToken(String amount, String to) async {
    final attoFil = double.parse(amount) * pow(10, fileCoinDecimals);

    BigInt amounToSend = BigInt.from(attoFil);
    String mnemonic = pref.get(currentMmenomicKey);
    final fileCoinDetails = await fromMnemonic(mnemonic);
    final nonce = await getFileCoinNonce(
      prefix,
      baseUrl,
    );

    final msg = constructFilecoinMsg(
      to,
      fileCoinDetails['address'],
      nonce,
      amounToSend,
    );

    final gasFromNetwork = await fileCoinEstimateGas(baseUrl, msg);
    if (gasFromNetwork.isNotEmpty) {
      msg['GasLimit'] = gasFromNetwork['GasLimit'];
      msg['GasFeeCap'] = gasFromNetwork['GasFeeCap'];
      msg['GasPremium'] = gasFromNetwork['GasPremium'];
    }

    final signature = transactionSignLotus(msg, fileCoinDetails['privateKey']);
    const signTypeSecp = 1;

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "id": 1,
        "jsonrpc": "2.0",
        "method": "Filecoin.MpoolPush",
        "params": [
          {
            "Message": msg,
            "Signature": {
              "Type": signTypeSecp,
              "Data": signature,
            },
          }
        ]
      }),
    );

    final responseBody = response.body;
    if (response.statusCode ~/ 100 == 4 || response.statusCode ~/ 100 == 5) {
      throw Exception(responseBody);
    }

    Map jsonDecodedBody = json.decode(responseBody) as Map;

    return jsonDecodedBody['result']['/'];
  }

  @override
  int decimals() {
    return fileCoinDecimals;
  }
}

List getFilecoinBlockChains() {
  List blockChains = [
    {
      'name': 'Filecoin',
      'symbol': 'FIL',
      'default': 'FIL',
      'blockExplorer':
          'https://filscan.io/tipset/message-detail?cid=$transactionhashTemplateKey',
      'image': 'assets/filecoin.png',
      'baseUrl': 'https://api.node.glif.io/rpc/v0',
      'prefix': 'f'
    }
  ];
  if (enableTestNet) {
    blockChains.add({
      'name': 'Filecoin(Testnet)',
      'symbol': 'FIL',
      'default': 'FIL',
      'blockExplorer':
          'https://calibration.filscan.io/tipset/message-detail?cid=$transactionhashTemplateKey',
      'image': 'assets/filecoin.png',
      'baseUrl': 'https://api.calibration.node.glif.io/rpc/v0',
      'prefix': 't'
    });
  }
  return blockChains;
}
