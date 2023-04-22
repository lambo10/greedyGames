// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:algorand_dart/algorand_dart.dart';
import 'package:bip39/bip39.dart';
import 'package:bs58check/bs58check.dart';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart' hide Coin;
import 'package:cryptowallet/utils/alt_ens.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart';
import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart';
import 'package:polkadart_scale_codec/polkadart_scale_codec.dart';
import 'package:xxh64/xxh64.dart';
import '../interface/coin.dart';
import '../main.dart';
import '../model/seed_phrase_root.dart';
import '../utils/app_config.dart';
import '../utils/rpc_urls.dart';

const polkadotDecimals = 10;
const westendDecimals = 12;
final systemAccount = '0x${xxhashAsHex('System')}${xxhashAsHex('Account')}';

class PolkadotCoin extends Coin {
  String blockExplorer;
  String symbol;
  String default_;
  String image;
  String name;
  String api;
  static List rpcMethods;
  Map runTimeResult;
  String genesisHash;

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
  int decimals() {
    return polkadotDecimals;
  }

  @override
  Future<Map> fromMnemonic(String mnemonic) async {
    final keyName = 'polkadotDetails$mnemonic';
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
      calculatePolkadotKey,
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
  String savedTransKey() {
    return '$default_$api Details';
  }

  Future<int> _getNonce() async {
    const nonce = 0;
    try {
      if (rpcMethods == null) {
        final result = await _queryRpc('rpc_methods', []);
        rpcMethods = result['result']['methods'];
      }
      String getHead =
          rpcMethods.firstWhere((element) => element == 'chain_getHead');

      getHead ??=
          rpcMethods.firstWhere((element) => element == 'chain_getBlockHash');
      final blockHashRes = await _queryRpc(getHead, []);
      final String address = await address_();
      final decodedAddr = decodeDOTAddress(address);
      final storageName = blake2_128_concat(decodedAddr);
      final storageKey = '$systemAccount${HEX.encode(storageName)}';

      String getStorageAt =
          rpcMethods.firstWhere((element) => element == 'state_getStorageAt');

      getStorageAt ??=
          rpcMethods.firstWhere((element) => element == 'state_getStorage');

      final storageResult =
          await _queryRpc(getStorageAt, [storageKey, blockHashRes['result']]);
      String storageData = storageResult['result'];
      if (storageData != null) {
        storageData = storageData.replaceFirst('0x', '');

        final input = Input.fromHex(storageData.substring(0, 0 + 4));

        return U16Codec.codec.decode(input);
      }
      return nonce;
    } catch (_) {
      return nonce;
    }
  }

  @override
  Future<double> getBalance(bool skipNetworkRequest) async {
    final address = await address_();
    final key = 'polkadotAddressBalance$address$api';

    final storedBalance = pref.get(key);

    double savedBalance = 0;

    if (storedBalance != null) {
      savedBalance = storedBalance;
    }

    if (skipNetworkRequest) return savedBalance;

    try {
      double balanceInFileCoin = 0;
      if (rpcMethods == null) {
        final result = await _queryRpc('rpc_methods', []);
        rpcMethods = result['result']['methods'];
      }
      String getHead =
          rpcMethods.firstWhere((element) => element == 'chain_getHead');

      getHead ??=
          rpcMethods.firstWhere((element) => element == 'chain_getBlockHash');
      final blockHashRes = await _queryRpc(getHead, []);
      final String address = await address_();
      final decodedAddr = decodeDOTAddress(address);
      final storageName = blake2_128_concat(decodedAddr);
      final storageKey = '$systemAccount${HEX.encode(storageName)}';

      String getStorageAt =
          rpcMethods.firstWhere((element) => element == 'state_getStorageAt');

      getStorageAt ??=
          rpcMethods.firstWhere((element) => element == 'state_getStorage');

      final storageResult =
          await _queryRpc(getStorageAt, [storageKey, blockHashRes['result']]);
      String storageData = storageResult['result'];
      if (storageData != null) {
        storageData = storageData.replaceFirst('0x', '');

        final input = Input.fromHex(storageData.substring(32, 32 + 48));

        final BigInt balanceBigInt = U128Codec.codec.decode(input);
        balanceInFileCoin =
            (balanceBigInt / BigInt.from(10).pow(_getDecimals())).toDouble();
      }
      await pref.put(key, balanceInFileCoin);
      return balanceInFileCoin;
    } catch (_) {
      return savedBalance;
    }
  }

  @override
  Future<double> getTransactionFee(String amount, String to) async {
    return 0;
  }

  PolkadotCoin({
    this.blockExplorer,
    this.symbol,
    this.default_,
    this.image,
    this.name,
    this.api,
  });

  factory PolkadotCoin.fromJson(Map<String, dynamic> json) {
    return PolkadotCoin(
      blockExplorer: json['blockExplorer'],
      default_: json['default'],
      symbol: json['symbol'],
      image: json['image'],
      name: json['name'],
      api: json['api'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['default'] = default_;
    data['symbol'] = symbol;
    data['name'] = name;
    data['blockExplorer'] = blockExplorer;
    data['image'] = image;
    data['api'] = api;

    return data;
  }

  Future<Map> _queryRpc(String rpcMethod, List params) async {
    try {
      final response = await post(
        Uri.parse(api),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "jsonrpc": "2.0",
          "id": "1",
          "method": rpcMethod,
          "params": params
        }),
      );
      final responseBody = response.body;
      if (response.statusCode ~/ 100 == 4 || response.statusCode ~/ 100 == 5) {
        throw Exception(responseBody);
      }
      return jsonDecode(responseBody);
    } catch (e) {
      return null;
    }
  }

  int _getDecimals() {
    return name == 'Polkadot' ? polkadotDecimals : westendDecimals;
  }

  @override
  Future<String> transferToken(String amount, String to) async {
    double planck = double.parse(amount) * pow(10, _getDecimals());
    int planckInt = planck.toInt();
    final hexDecAddr = HEX.encode(decodeDOTAddress(to));
    String hexDecAddr0x =
        hexDecAddr.startsWith('0x') ? hexDecAddr : '0x$hexDecAddr';
    final compactPrice = HEX.encode(CompactCodec.codec.encode(planckInt));
    final nonce = await _getNonce();

    final encodedData = '040000$hexDecAddr$compactPrice';

    final response = await fromMnemonic(pref.get(currentMmenomicKey));
    final privatekey = HEX.decode(response['privateKey']);
    final signaturePayload = await _signaturePayload(encodedData, nonce);

    final transferReq = {
      'account_id': hexDecAddr0x,
      'signature': {
        'Ed25519':
            '0x00419e81980c632ae1d2239c18d1721ecb2707457a9af3f08812ea8c40cebc457e63e994419ecd08bc95f94ec497508de601237b4a9250ffb9db09e3d0713889'
      },
      'call_function': 'transfer',
      'call_module': 'Balances',
      'call_args': {'dest': to, 'value': planckInt},
      'nonce': nonce,
      'era': '00',
      'tip': 0,
      'asset_id': {'tip': 0, 'asset_id': None},
      'signature_version': 0,
      'address': hexDecAddr0x,
      'call': {
        'call_function': 'transfer',
        'call_module': 'Balances',
        'call_args': {'dest': to, 'value': planckInt}
      }
    };

    final submitResult = await _queryRpc('author_submitExtrinsic', [
      '0x41028400d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d01740941d2a43cbfe0827780cb7d8904c8d97e073f756dec043ba18461916c4f1d770b0db317a5a26de83d58f9028994e954b76ea19d1a495a3dca01788f0fdb820000000$encodedData'
    ]);
    // print(submitResult);
    // print(encodedData);
    throw Exception('sending failed');
  }

  Future _signaturePayload(String call, int nonce) async {
    if (runTimeResult == null) {
      final runTimeVersion = await _queryRpc('chain_getRuntimeVersion', []);
      runTimeResult = runTimeVersion['result'];
    }

    if (genesisHash == null) {
      final genesisHashRes = await _queryRpc('chain_getBlockHash', [0]);
      genesisHash = genesisHashRes['result'];
    }

    const era = '00';
    final payload = {
      'call': call,
      'era': era,
      'nonce': nonce,
      'tip': 0,
      'spec_version': runTimeResult['specVersion'],
      'genesis_hash': genesisHash,
      'block_hash': genesisHash,
      'transaction_version': runTimeResult['transactionVersion'],
      'asset_id': {'tip': 0, 'asset_id': null}
    };
    print(genesisHash);
    print(call);
    print(nonce);
    print(json.encode(payload));
  }

  @override
  validateAddress(String address) {
    decodeDOTAddress(address);
  }
}

List _polkaChecksum(Uint8List decoded) {
  final ss58Length = (decoded[0] & 64) != 0 ? 2 : 1;
  final ss58Decoded = ss58Length == 1
      ? decoded[0]
      : ((decoded[0] & 63) << 2) | (decoded[1] >> 6) | ((decoded[1] & 63) << 8);
  final isPublicKey =
      [34 + ss58Length, 35 + ss58Length].contains(decoded.length);
  final length = decoded.length - (isPublicKey ? 2 : 1);
  final hash = sshash(Uint8List.fromList(decoded.sublist(0, length)));
  final isValid = (decoded[0] & 128) == 0 &&
      ![46, 47].contains(decoded[0]) &&
      (isPublicKey
          ? decoded[decoded.length - 2] == hash[0] &&
              decoded[decoded.length - 1] == hash[1]
          : decoded[decoded.length - 1] == hash[0]);
  return [isValid, length, ss58Length, ss58Decoded];
}

List<Map> getPolkadoBlockChains() {
  List<Map> blockChains = [
    {
      'blockExplorer':
          'https://polkadot.subscan.io/extrinsic/$transactionhashTemplateKey',
      'symbol': 'DOT',
      'name': 'Polkadot',
      'default': 'DOT',
      'image': 'assets/polkadot.png',
      'api': 'https://rpc.polkadot.io/'
    }
  ];

  if (enableTestNet) {
    blockChains.addAll([
      {
        'blockExplorer':
            'https://westend.subscan.io/extrinsic/$transactionhashTemplateKey',
        'symbol': 'DOT',
        'name': 'Polkadot(Westend)',
        'default': 'DOT',
        'image': 'assets/polkadot.png',
        'api': 'https://westend-rpc.polkadot.io'
      },
    ]);
  }

  return blockChains;
}

Uint8List decodeDOTAddress(String address) {
  final decoded = base58.decode(address);
  final checksum = _polkaChecksum(decoded);
  final bool isValid = checksum[0];
  final int endPos = checksum[1];
  final int ss58Length = checksum[2];

  if (!isValid) {
    throw Exception('Invalid decoded address checksum');
  }
  return decoded.sublist(ss58Length, endPos);
}

Future<List<int>> bip39ToMiniSeed(mnemonic) async {
  final entropy = HEX.decode(mnemonicToEntropy(mnemonic));
  final salt = StrCodec.codec.encode('mnemonic').sublist(1);
  final pdkd = Pbkdf2(
    macAlgorithm: Hmac.sha512(),
    iterations: 2048,
    bits: 256,
  );

  final keys = await pdkd.deriveKey(secretKey: SecretKey(entropy), nonce: salt);
  return await keys.extractBytes();
}

List<int> sshash(Uint8List bytes) {
  const SS58_PREFIX = [83, 83, 53, 56, 80, 82, 69];
  return blake2bHash(
    Uint8List.fromList([...SS58_PREFIX, ...bytes]),
    digestSize: 64,
  );
}

String xxhashAsHex(String data) {
  return HEX.encode(xxh128(data).toList());
}

calculatePolkadotKey(Map config) async {
  SeedPhraseRoot seedRoot_ = config[seedRootKey];
  final derivedKey =
      await ED25519_HD_KEY.derivePath("m/44'/354'/0'/0'/0'", seedRoot_.seed);

  final publicKey = await ED25519_HD_KEY.getPublicKey(derivedKey.key);

  final address = base58.encode(Uint8List.fromList([
    ...publicKey,
    ...sshash(Uint8List.fromList(publicKey))
        .sublist(0, [32, 33].contains(publicKey.length) ? 2 : 1)
  ]));
  return {
    'address': address,
    'privateKey': HEX.encode(derivedKey.key),
  };
}

List<int> blake2_128_concat(List data) {
  return blake2bHash(data, digestSize: 16) + data;
}

Uint8List xxh128(String data) {
  List storage_key1 = XXH64
      .digest(data: data, seed: BigInt.from(0))
      .toUint8List()
      .reversed
      .toList();

  List storage_key2 = XXH64
      .digest(data: data, seed: BigInt.from(1))
      .toUint8List()
      .reversed
      .toList();

  return Uint8List.fromList(storage_key1 + storage_key2);
}


// extending ScaleDecoder
// removing the 0x
// 'f9170000000000000100000000000000503b9566ad6d01000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'.substr(32,48)
// balance is a U128 // gotten from 32 -> 48
// nonce is a U32 // gotten from 0 -> 4


// [203, 56, 67, 63, 165, 89, 107, 182, 49, 254, 58, 83, 33, 38, 191, 171, 57, 7, 56, 162, 44, 169, 222, 185, 46, 128, 101, 69, 33, 50, 7, 217]