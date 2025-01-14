// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';
import 'dart:math';

import 'package:algorand_dart/algorand_dart.dart';
import 'package:bip39/bip39.dart';
import 'package:bs58check/bs58check.dart';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart' hide Coin;
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

final systemAccount = '0x${xxhashAsHex('System')}${xxhashAsHex('Account')}';

class PolkadotCoin extends Coin {
  String blockExplorer;
  String symbol;
  String default_;
  String image;
  String name;
  String api;
  int decimals_;
  List rpcMethods;
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
    return decimals_;
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
            (balanceBigInt / BigInt.from(10).pow(decimals())).toDouble();
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
    this.decimals_,
  });

  factory PolkadotCoin.fromJson(Map<String, dynamic> json) {
    return PolkadotCoin(
      blockExplorer: json['blockExplorer'],
      default_: json['default'],
      symbol: json['symbol'],
      image: json['image'],
      name: json['name'],
      api: json['api'],
      decimals_: json['decimals'],
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
    data['decimals'] = decimals_;

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

  Uint8List _signEd25519(EDSignature signature) {
    return signEd25519(
      message: HEX.decode(signature.signaturePayload.replaceFirst('0x', '')),
      privateKey: signature.privatekey,
    );
  }

  @override
  Future<String> transferToken(String amount, String to) async {
    double planck = double.parse(amount) * pow(10, decimals());
    int planckInt = planck.toInt();
    final hexDecAddr = HEX.encode(decodeDOTAddress(to));

    final compactAmount = HEX.encode(CompactCodec.codec.encode(planckInt));
    final nonce = await _getNonce();

    final encodedData = '040000$hexDecAddr$compactAmount';

    final response = await fromMnemonic(pref.get(currentMmenomicKey));
    final privatekey = HEX.decode(response['privateKey']);
    final signaturePayload = await _signaturePayload(encodedData, nonce);

    final publicKey = HEX.decode(response['publicKey']);
    final signature = await compute(
      _signEd25519,
      EDSignature(
        privatekey: privatekey,
        signaturePayload: signaturePayload,
      ),
    );

    String txSubmission = '84';
    txSubmission += HEX.encode(publicKey);
    txSubmission += '00';
    txSubmission += HEX.encode(signature);
    txSubmission += '00';
    txSubmission += HEX.encode(CompactCodec.codec.encode(nonce));
    txSubmission += '00';
    txSubmission += encodedData;

    int txLength = HEX.decode(txSubmission).length;

    txSubmission =
        HEX.encode(CompactCodec.codec.encode(txLength)) + txSubmission;

    final submitResult =
        await _queryRpc('author_submitExtrinsic', ['0x$txSubmission']);
    return submitResult['result'];
  }

  Future<String> _signaturePayload(String call, int nonce) async {
    if (runTimeResult == null) {
      final runTimeVersion = await _queryRpc('chain_getRuntimeVersion', []);
      runTimeResult = runTimeVersion['result'];
    }

    if (genesisHash == null) {
      final genesisHashRes = await _queryRpc('chain_getBlockHash', [0]);
      genesisHash = genesisHashRes['result'];
    }

    String payload = '0x$call';

    payload += '00';
    payload += HEX.encode(CompactCodec.codec.encode(nonce));
    payload += '00';
    payload += HEX.encode(U32Codec.codec.encode(runTimeResult['specVersion']));
    payload +=
        HEX.encode(U32Codec.codec.encode(runTimeResult['transactionVersion']));
    payload += genesisHash.replaceFirst('0x', '');
    payload += genesisHash.replaceFirst('0x', '');

    return payload;
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
      'api': 'https://rpc.polkadot.io/',
      'decimals': 10,
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
        'api': 'https://westend-rpc.polkadot.io',
        'decimals': 12,
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
    'publicKey': HEX.encode(publicKey),
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

class EDSignature {
  final String signaturePayload;
  final Uint8List privatekey;
  const EDSignature({this.privatekey, this.signaturePayload});
}
