// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';
import 'dart:math';

import 'package:dartez/dartez.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../interface/coin.dart';
import '../utils/app_config.dart';
import '../utils/rpc_urls.dart';
import 'package:bs58check/bs58check.dart' as bs58check;

final pref = Hive.box(secureStorageKey);
const tezorDecimals = 6;

class TezosCoin extends Coin {
  TezosTypes tezorType;
  String server;
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

  TezosCoin({
    this.blockExplorer,
    this.symbol,
    this.default_,
    this.image,
    this.name,
    this.tezorType,
    this.server,
  });

  factory TezosCoin.fromJson(Map<String, dynamic> json) {
    return TezosCoin(
      tezorType: json['tezorType'],
      server: json['server'],
      blockExplorer: json['blockExplorer'],
      default_: json['default'],
      symbol: json['symbol'],
      image: json['image'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['server'] = server;
    data['tezorType'] = tezorType;
    data['default'] = default_;
    data['symbol'] = symbol;
    data['name'] = name;
    data['blockExplorer'] = blockExplorer;

    data['image'] = image;

    return data;
  }

  @override
  Future<Map> fromMnemonic(String mnemonic) async {
    final keyName = 'tezorDetails${tezorType.index}';
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
      calculateTezorKey,
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

  Future<Map> calculateTezorKey(Map config) async {
    List<String> keys = await Dartez.restoreIdentityFromDerivationPath(
      "m/44'/1729'/0'/0'",
      config[mnemonicKey],
    );

    return {
      'address': keys[2],
      'private_key': keys[0],
      'public_key': keys[1],
    };
  }

  @override
  Future<double> getBalance(bool skipNetworkRequest) async {
    final address = await address_();
    final key = '${tezorType.index}AddressBalance$address';
    final storedBalance = pref.get(key);

    double savedBalance = 0;

    if (storedBalance != null) {
      savedBalance = storedBalance;
    }

    if (skipNetworkRequest) return savedBalance;

    try {
      double balance = 0.0;

      final res = await Dartez.getBalance(address, server);
      balance = double.parse(res) / pow(10, tezorDecimals);

      await pref.put(key, balance);

      return balance;
    } catch (e) {
      return savedBalance;
    }
  }

  @override
  Future<String> transferToken(String amount, String to) async {
    final getTezorDetails = await fromMnemonic(pref.get(currentMmenomicKey));

    final keyStore = KeyStoreModel(
      publicKey: getTezorDetails['public_key'],
      secretKey: getTezorDetails['private_key'],
      publicKeyHash: getTezorDetails['address'],
    );

    final signer = Dartez.createSigner(
      Dartez.writeKeyWithHint(keyStore.secretKey, 'edsk'),
    );
    final microTez = double.parse(amount) * pow(10, tezorDecimals);

    final result = await Dartez.sendTransactionOperation(
      server,
      signer,
      keyStore,
      to,
      microTez.toInt(),
      1500,
    );
    String transactionHash = Map.from(result)['operationGroupID'];
    return transactionHash.replaceAll('\n', '');
  }

  @override
  validateAddress(String address) {
    if (!validateTezosAddress(address)) {
      throw Exception('Invalid $default_ address');
    }
  }

  @override
  int decimals() {
    return tezorDecimals;
  }

  @override
  Future<double> getTransactionFee(String amount, String to) async {
    return 0;
  }
}

List<Map> getTezosBlockchains() {
  List<Map> blockChains = [
    {
      'blockExplorer': 'https://tzkt.io/$transactionhashTemplateKey',
      'symbol': 'XTZ',
      'name': 'Tezos',
      'default': 'XTZ',
      'image': 'assets/tezos.png',
      'tezorType': TezosTypes.mainNet,
      'server': 'https://rpc.tzkt.io/mainnet'
    }
  ];

  if (enableTestNet) {
    blockChains.add({
      'blockExplorer': 'https://ghostnet.tzkt.io/$transactionhashTemplateKey',
      'symbol': 'XTZ',
      'default': 'XTZ',
      'name': 'Tezos(Testnet)',
      'image': 'assets/tezos.png',
      'tezorType': TezosTypes.ghostNet,
      'server': 'https://rpc.tzkt.io/ghostnet'
    });
  }
  return blockChains;
}

final List<String> implicitPrefix = ['tz1', 'tz2', 'tz3', 'tz4'];
final List<String> contractPrefix = ['KT1', 'txr1'];

class Prefix {
  static const TZ1 = 'tz1';
  static const TZ2 = 'tz2';
  static const TZ3 = 'tz3';
  static const TZ4 = 'tz4';
  static const KT = 'KT';
  static const KT1 = 'KT1';

  static const EDSK2 = 'edsk2';
  static const SPSK = 'spsk';
  static const P2SK = 'p2sk';

  static const EDPK = 'edpk';
  static const SPPK = 'sppk';
  static const P2PK = 'p2pk';
  static const BLPK = 'BLpk';

  static const EDESK = 'edesk';
  static const SPESK = 'spesk';
  static const P2ESK = 'p2esk';

  static const EDSK = 'edsk';
  static const EDSIG = 'edsig';
  static const SPSIG = 'spsig';
  static const P2SIG = 'p2sig';
  static const SIG = 'sig';

  static const NET = 'Net';
  static const NCE = 'nce';
  static const B = 'B';
  static const O = 'o';
  static const LO = 'Lo';
  static const LLO = 'LLo';
  static const P = 'P';
  static const CO = 'Co';
  static const ID = 'id';

  static const EXPR = 'expr';
  static const TZ = 'TZ';

  static const VH = 'vh'; // block_payload_hash

  static const SASK = 'sask'; // sapling_spending_key
  static const ZET1 = 'zet1'; // sapling_address

  //rollups
  static const TXR1 = 'txr1';
  static const TXI = 'txi';
  static const TXM = 'txm';
  static const TXC = 'txc';
  static const TXMR = 'txmr';
  static const TXRL = 'txM';
  static const TXW = 'txw';
}

class PrefixByte {
  static const Map<String, List<int>> prefix = {
    Prefix.TZ1: [6, 161, 159],
    Prefix.TZ2: [6, 161, 161],
    Prefix.TZ3: [6, 161, 164],
    Prefix.TZ4: [6, 161, 166],
    Prefix.KT: [2, 90, 121],
    Prefix.KT1: [2, 90, 121],
    Prefix.EDSK: [43, 246, 78, 7],
    Prefix.EDSK2: [13, 15, 58, 7],
    Prefix.SPSK: [17, 162, 224, 201],
    Prefix.P2SK: [16, 81, 238, 189],
    Prefix.EDPK: [13, 15, 37, 217],
    Prefix.SPPK: [3, 254, 226, 86],
    Prefix.P2PK: [3, 178, 139, 127],
    Prefix.BLPK: [6, 149, 135, 204],
    Prefix.EDESK: [7, 90, 60, 179, 41],
    Prefix.SPESK: [0x09, 0xed, 0xf1, 0xae, 0x96],
    Prefix.P2ESK: [0x09, 0x30, 0x39, 0x73, 0xab],
    Prefix.EDSIG: [9, 245, 205, 134, 18],
    Prefix.SPSIG: [13, 115, 101, 19, 63],
    Prefix.P2SIG: [54, 240, 44, 52],
    Prefix.SIG: [4, 130, 43],

    Prefix.NET: [87, 82, 0],
    Prefix.NCE: [69, 220, 169],
    Prefix.B: [1, 52],
    Prefix.O: [5, 116],
    Prefix.LO: [133, 233],
    Prefix.LLO: [29, 159, 109],
    Prefix.P: [2, 170],
    Prefix.CO: [79, 179],
    Prefix.ID: [153, 103],

    Prefix.EXPR: [13, 44, 64, 27],
    // Legacy prefix
    Prefix.TZ: [2, 90, 121],

    Prefix.VH: [1, 106, 242],
    Prefix.SASK: [11, 237, 20, 92],
    Prefix.ZET1: [18, 71, 40, 223],

    Prefix.TXR1: [1, 128, 120, 31],
    Prefix.TXI: [79, 148, 196],
    Prefix.TXM: [79, 149, 30],
    Prefix.TXC: [79, 148, 17],
    Prefix.TXMR: [18, 7, 206, 87],
    Prefix.TXRL: [79, 146, 82],
    Prefix.TXW: [79, 150, 72],
  };
}

enum ValidationResult { noPrefixMatched, invalidChecksum, invalidLength, valid }

bool validateTezosAddress(String value) {
  try {
    ValidationResult result =
        validatePrefixedValue(value, [...implicitPrefix, ...contractPrefix]);
    return result == ValidationResult.valid;
  } catch (e) {
    return false;
  }
}

ValidationResult validatePrefixedValue(String value, List<String> prefixes) {
  final RegExp regExp = RegExp('^(${prefixes.join('|')})');
  final Match match = regExp.firstMatch(value);

  if (match == null || match.group(0).isEmpty) {
    return ValidationResult.noPrefixMatched;
  }

  final String prefixKey = match.group(0);

  if (!isValidPrefix(prefixKey)) {
    return ValidationResult.noPrefixMatched;
  }

  String decodedValue = value;
  final RegExp contractAddressRegExp = RegExp(r'^(KT1\w{33})(%(.*))?$');
  final Match contractAddress = contractAddressRegExp.firstMatch(value);

  if (contractAddress != null) {
    decodedValue = contractAddress.group(1);
  }

  List<int> decoded;
  try {
    decoded = bs58check.decode(decodedValue);
  } catch (_) {}

  if (decoded == null) {
    return ValidationResult.invalidChecksum;
  }

  decoded = decoded.sublist(PrefixByte.prefix[prefixKey].length);

  if (decoded.length != prefixLength[prefixKey]) {
    return ValidationResult.invalidLength;
  }

  return ValidationResult.valid;
}

bool isValidPrefix(String prefixKey) {
  return PrefixByte.prefix.containsKey(prefixKey) &&
      prefixLength.containsKey(prefixKey);
}

final Map<String, int> prefixLength = {
  Prefix.TZ1: 20,
  Prefix.TZ2: 20,
  Prefix.TZ3: 20,
  Prefix.TZ4: 20,
  Prefix.KT: 20,
  Prefix.KT1: 20,
  Prefix.EDPK: 32,
  Prefix.SPPK: 33,
  Prefix.P2PK: 33,
  Prefix.BLPK: 48,
  Prefix.EDSIG: 64,
  Prefix.SPSIG: 64,
  Prefix.P2SIG: 64,
  Prefix.SIG: 64,
  Prefix.NET: 4,
  Prefix.B: 32,
  Prefix.P: 32,
  Prefix.O: 32,
  Prefix.VH: 32,
  Prefix.SASK: 169,
  Prefix.ZET1: 43,
  Prefix.TXR1: 20,
  Prefix.TXI: 32,
  Prefix.TXM: 32,
  Prefix.TXC: 32,
  Prefix.TXMR: 32,
  Prefix.TXRL: 32,
  Prefix.TXW: 32,
};

enum TezosTypes {
  mainNet,
  ghostNet,
}
