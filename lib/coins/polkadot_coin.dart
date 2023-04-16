// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';
import 'dart:typed_data';

import 'package:algorand_dart/algorand_dart.dart';
import 'package:bs58check/bs58check.dart';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart' hide Coin;
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart';
import 'package:http/http.dart';
import 'package:xxh64/xxh64.dart';
import '../interface/coin.dart';
import '../main.dart';
import '../model/seed_phrase_root.dart';
import '../utils/app_config.dart';
import '../utils/rpc_urls.dart';

const polkadotDecimals = 10;
final systemAccount = '0x${xxhashAsHex('System')}${xxhashAsHex('Account')}';

class PolkadotCoin extends Coin {
  String blockExplorer;
  String symbol;
  String default_;
  String image;
  String name;
  String api;
  static List rpcMethods;

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
  Future<double> getBalance(bool skipNetworkRequest) async {
    print(systemAccount);
    if (rpcMethods == null) {
      final result = await _queryRpc('rpc_methods', []);
      rpcMethods = result['result']['methods'];
    } else {
      String getHead =
          rpcMethods.firstWhere((element) => element == 'chain_getHead');

      getHead ??=
          rpcMethods.firstWhere((element) => element == 'chain_getBlockHash');
      final result = await _queryRpc(getHead, []);
      print(result);
    }
    return 0;
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

  @override
  Future<String> transferToken(String amount, String to) async {
    return '';
  }

  @override
  validateAddress(String address) {
    final decoded = base58.decode(address);
    final checksum = _polkaChecksum(decoded);
    final bool isValid = checksum[0];
    final int endPos = checksum[1];
    final int ss58Length = checksum[2];

    if (!isValid) {
      throw Exception('Invalid decoded address checksum');
    }
    decoded.sublist(ss58Length, endPos);
  }

  List _polkaChecksum(Uint8List decoded) {
    final ss58Length = (decoded[0] & 64) != 0 ? 2 : 1;
    final ss58Decoded = ss58Length == 1
        ? decoded[0]
        : ((decoded[0] & 63) << 2) |
            (decoded[1] >> 6) |
            ((decoded[1] & 63) << 8);
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

  return blockChains;
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

final methods = {
  "jsonrpc": "2.0",
  "result": {
    "methods": [
      "account_nextIndex",
      "author_hasKey",
      "author_hasSessionKeys",
      "author_insertKey",
      "author_pendingExtrinsics",
      "author_removeExtrinsic",
      "author_rotateKeys",
      "author_submitAndWatchExtrinsic",
      "author_submitExtrinsic",
      "author_unwatchExtrinsic",
      "babe_epochAuthorship",
      "beefy_getFinalizedHead",
      "beefy_subscribeJustifications",
      "beefy_unsubscribeJustifications",
      "chainHead_unstable_body",
      "chainHead_unstable_call",
      "chainHead_unstable_follow",
      "chainHead_unstable_genesisHash",
      "chainHead_unstable_header",
      "chainHead_unstable_stopBody",
      "chainHead_unstable_stopCall",
      "chainHead_unstable_stopStorage",
      "chainHead_unstable_storage",
      "chainHead_unstable_unfollow",
      "chainHead_unstable_unpin",
      "chain_getBlock",
      "chain_getBlockHash",
      "chain_getFinalisedHead",
      "chain_getFinalizedHead",
      "chain_getHead",
      "chain_getHeader",
      "chain_getRuntimeVersion",
      "chain_subscribeAllHeads",
      "chain_subscribeFinalisedHeads",
      "chain_subscribeFinalizedHeads",
      "chain_subscribeNewHead",
      "chain_subscribeNewHeads",
      "chain_subscribeRuntimeVersion",
      "chain_unsubscribeAllHeads",
      "chain_unsubscribeFinalisedHeads",
      "chain_unsubscribeFinalizedHeads",
      "chain_unsubscribeNewHead",
      "chain_unsubscribeNewHeads",
      "chain_unsubscribeRuntimeVersion",
      "childstate_getKeys",
      "childstate_getKeysPaged",
      "childstate_getKeysPagedAt",
      "childstate_getStorage",
      "childstate_getStorageEntries",
      "childstate_getStorageHash",
      "childstate_getStorageSize",
      "grandpa_proveFinality",
      "grandpa_roundState",
      "grandpa_subscribeJustifications",
      "grandpa_unsubscribeJustifications",
      "mmr_generateProof",
      "mmr_root",
      "mmr_verifyProof",
      "mmr_verifyProofStateless",
      "offchain_localStorageGet",
      "offchain_localStorageSet",
      "payment_queryFeeDetails",
      "payment_queryInfo",
      "state_call",
      "state_callAt",
      "state_getChildReadProof",
      "state_getKeys",
      "state_getKeysPaged",
      "state_getKeysPagedAt",
      "state_getMetadata",
      "state_getPairs",
      "state_getReadProof",
      "state_getRuntimeVersion",
      "state_getStorage",
      "state_getStorageAt",
      "state_getStorageHash",
      "state_getStorageHashAt",
      "state_getStorageSize",
      "state_getStorageSizeAt",
      "state_queryStorage",
      "state_queryStorageAt",
      "state_subscribeRuntimeVersion",
      "state_subscribeStorage",
      "state_traceBlock",
      "state_trieMigrationStatus",
      "state_unsubscribeRuntimeVersion",
      "state_unsubscribeStorage",
      "subscribe_newHead",
      "sync_state_genSyncSpec",
      "system_accountNextIndex",
      "system_addLogFilter",
      "system_addReservedPeer",
      "system_chain",
      "system_chainType",
      "system_dryRun",
      "system_dryRunAt",
      "system_health",
      "system_localListenAddresses",
      "system_localPeerId",
      "system_name",
      "system_nodeRoles",
      "system_peers",
      "system_properties",
      "system_removeReservedPeer",
      "system_reservedPeers",
      "system_resetLogFilter",
      "system_syncState",
      "system_unstable_networkState",
      "system_version",
      "transaction_unstable_submitAndWatch",
      "transaction_unstable_unwatch",
      "unsubscribe_newHead"
    ]
  },
  "id": "1"
};

final ass = {
  "jsonrpc": "2.0",
  "id": "1",
  "method": "state_queryStorageAt",
  "params": [
    [
      "0x26aa394eea5630e07c48ae0c9558cef7b99d880ec681799c0cf30e8886371da9cfc61ff47f1f55dd7e8dbb229c0bf362b1fdf42c5bfbeb6450a71bb937110d5da6f167fc569cd25d73fc445c9ea9bf8f"
    ]
  ]
};

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


//  const nameB = `${nameA}Api`;
//             console.log(nameA);
//             console.log(blake2AsHex(nameA, 64));
//             console.log(nameB);
//             console.log(blake2AsHex(nameB, 64));
//             console.log('------------------')
//             this._runtimeMap[blake2AsHex(nameA, 64)] = nameA;
//             this._runtimeMap[blake2AsHex(nameB, 64)] = nameB;
//         }

// 1583kEDq2YqxMNBXpJHWKZXydTLRmjNcYVPf7a2Pf3LGFYdW
// {"id":1,"jsonrpc":"2.0","method":"chain_getBlockHash","params":[0]}
// {"id":2,"jsonrpc":"2.0","method":"state_getRuntimeVersion","params":[]}
// {"id":3,"jsonrpc":"2.0","method":"system_chain","params":[]}
// {"id":4,"jsonrpc":"2.0","method":"system_properties","params":[]}
// {"id":5,"jsonrpc":"2.0","method":"rpc_methods","params":[]}
// {"id":6,"jsonrpc":"2.0","method":"state_getMetadata","params":[]}
// {"id":7,"jsonrpc":"2.0","method":"state_queryStorageAt","params":[["0x26aa394eea5630e07c48ae0c9558cef7b99d880ec681799c0cf30e8886371da901fb316253adf0c91272dcc3040df8edb650e4a750edfdf7e797855afaef2b5ed4c9c8ccec117f40b951d50842da5627"]]}