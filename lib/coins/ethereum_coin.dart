// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

import '../interface/coin.dart';
import '../main.dart';
import '../model/seed_phrase_root.dart';
import '../utils/app_config.dart';
import '../utils/rpc_urls.dart';

const etherDecimals = 18;

class EthereumCoin extends Coin {
  int coinType;
  int chainId;
  String rpc;
  String blockExplorer;
  String symbol;
  String default_;
  String image;
  String name;

  EthereumCoin({
    this.blockExplorer,
    this.symbol,
    this.default_,
    this.image,
    this.coinType,
    this.rpc,
    this.chainId,
    this.name,
  });
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

  factory EthereumCoin.fromJson(Map<String, dynamic> json) {
    return EthereumCoin(
      chainId: json['chainId'],
      rpc: json['rpc'],
      coinType: json['coinType'],
      blockExplorer: json['blockExplorer'],
      default_: json['default'],
      symbol: json['symbol'],
      image: json['image'],
      name: json['name'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['chainId'] = chainId;
    data['rpc'] = rpc;
    data['default'] = default_;
    data['symbol'] = symbol;
    data['name'] = name;
    data['blockExplorer'] = blockExplorer;
    data['coinType'] = coinType;
    data['image'] = image;

    return data;
  }

  @override
  Future<Map> fromMnemonic(String mnemonic) async {
    String key = 'ethereumDetails$coinType';
    List mmenomicMapping = [];
    if (pref.get(key) != null) {
      mmenomicMapping = jsonDecode(pref.get(key)) as List;
      for (int i = 0; i < mmenomicMapping.length; i++) {
        if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
          return mmenomicMapping[i]['key'];
        }
      }
    }

    final privatekeyStr = await compute(
      calculateEthereumKey,
      Map.from(toJson())
        ..addAll({
          mnemonicKey: mnemonic,
          'coinType': coinType,
          seedRootKey: seedPhraseRoot,
        }),
    );

    final address = await etherPrivateKeyToAddress(privatekeyStr);

    final keys = {
      'address': address,
      'privateKey': privatekeyStr,
      mnemonicKey: mnemonic
    };
    mmenomicMapping.add({'key': keys, 'mmenomic': mnemonic});
    await pref.put(key, jsonEncode(mmenomicMapping));
    return keys;
  }

  @override
  Future<double> getBalance(bool skipNetworkRequest) async {
    final address = await address_();
    final tokenKey = '$rpc$address/balance';
    final storedBalance = pref.get(tokenKey);

    double savedBalance = 0;

    if (storedBalance != null) savedBalance = storedBalance;

    if (skipNetworkRequest) return savedBalance;

    try {
      final ethClient = Web3Client(rpc, Client());

      final userAddress = EthereumAddress.fromHex(address);

      final etherAmount = await ethClient.getBalance(userAddress);

      double ethBalance =
          etherAmount.getInWei.toDouble() / pow(10, etherDecimals);

      await pref.put(tokenKey, ethBalance);
      await ethClient.dispose();
      return ethBalance;
    } catch (e) {
      return savedBalance;
    }
  }

  @override
  String savedTransKey() {
    return '$default_$rpc Details';
  }

  @override
  Future<String> transferToken(String amount, String to) async {
    final client = Web3Client(
      rpc,
      Client(),
    );

    final response = await fromMnemonic(pref.get(currentMmenomicKey));

    final credentials = EthPrivateKey.fromHex(
      response['privateKey'],
    );
    final gasPrice = await client.getGasPrice();

    final wei = double.parse(amount) * pow(10, etherDecimals);

    final trans = await client.signTransaction(
      credentials,
      Transaction(
        from: EthereumAddress.fromHex(response['address']),
        to: EthereumAddress.fromHex(to),
        value: EtherAmount.inWei(
          BigInt.from(wei),
        ),
        gasPrice: gasPrice,
      ),
      chainId: chainId,
    );

    return await client.sendRawTransaction(trans);
  }

  @override
  validateAddress(String address) {
    EthereumAddress.fromHex(address);
  }

  @override
  int decimals() {
    return etherDecimals;
  }

  @override
  Future<double> getTransactionFee(String amount, String to) async {
    final response = await fromMnemonic(pref.get(currentMmenomicKey));
    final transactionFee = await getEtherTransactionFee(
      rpc,
      null,
      EthereumAddress.fromHex(response['address']),
      EthereumAddress.fromHex(to),
    );

    return transactionFee / pow(10, etherDecimals);
  }
}

List<Map> getEVMBlockchains() {
  Map userAddedEVM = {};

  if (pref.get(newEVMChainKey) != null) {
    userAddedEVM = Map.from(jsonDecode(pref.get(newEVMChainKey)));
  }

  List<Map> blockChains = [
    {
      "rpc": 'https://mainnet.infura.io/v3/$infuraApiKey',
      'chainId': 1,
      'blockExplorer': 'https://etherscan.io/tx/$transactionhashTemplateKey',
      'symbol': 'ETH',
      'default': 'ETH',
      'name': 'Ethereum',
      'image': 'assets/ethereum_logo.png',
      'coinType': 60
    },
    {
      'name': 'Smart Chain',
      "rpc": 'https://bsc-dataseed.binance.org/',
      'chainId': 56,
      'blockExplorer': 'https://bscscan.com/tx/$transactionhashTemplateKey',
      'symbol': 'BNB',
      'default': 'BNB',
      'image': 'assets/smartchain.png',
      'coinType': 60
    },
    {
      'name': 'Polygon Matic',
      "rpc": 'https://polygon-rpc.com',
      'chainId': 137,
      'blockExplorer': 'https://polygonscan.com/tx/$transactionhashTemplateKey',
      'symbol': 'MATIC',
      'default': 'MATIC',
      'image': 'assets/polygon.png',
      'coinType': 60
    },
    {
      'name': 'Avalanche',
      "rpc": 'https://api.avax.network/ext/bc/C/rpc',
      'chainId': 43114,
      'blockExplorer': 'https://snowtrace.io/tx/$transactionhashTemplateKey',
      'symbol': 'AVAX',
      'default': 'AVAX',
      'image': 'assets/avalanche.png',
      'coinType': 60
    },
    {
      'name': 'Fantom',
      "rpc": 'https://rpc.ftm.tools/',
      'chainId': 250,
      'blockExplorer': 'https://ftmscan.com/tx/$transactionhashTemplateKey',
      'symbol': 'FTM',
      'default': 'FTM',
      'image': 'assets/fantom.png',
      'coinType': 60
    },
    {
      'name': 'Arbitrum',
      "rpc": 'https://arb1.arbitrum.io/rpc',
      'chainId': 42161,
      'blockExplorer': 'https://arbiscan.io/tx/$transactionhashTemplateKey',
      'symbol': 'ETH',
      'default': 'ETH',
      'image': 'assets/arbitrum.jpg',
      'coinType': 60
    },
    {
      'name': 'Optimism',
      "rpc": 'https://mainnet.optimism.io',
      'chainId': 10,
      'blockExplorer':
          'https://optimistic.etherscan.io/tx/$transactionhashTemplateKey',
      'symbol': 'ETH',
      'default': 'ETH',
      'image': 'assets/optimism.png',
      'coinType': 60
    },
    {
      'name': 'Ethereum Classic',
      'symbol': 'ETC',
      'default': 'ETC',
      'blockExplorer':
          'https://blockscout.com/etc/mainnet/tx/$transactionhashTemplateKey',
      'rpc': 'https://www.ethercluster.com/etc',
      'chainId': 61,
      'image': 'assets/ethereum-classic.png',
      'coinType': 61
    },
    {
      'name': 'Cronos',
      "rpc": 'https://evm.cronos.org',
      'chainId': 25,
      'blockExplorer': 'https://cronoscan.com/tx/$transactionhashTemplateKey',
      'symbol': 'CRO',
      'default': 'CRO',
      'image': 'assets/cronos.png',
      'coinType': 60
    },
    {
      'name': 'Milkomeda Cardano',
      "rpc": ' https://rpc-mainnet-cardano-evm.c1.milkomeda.com',
      'chainId': 2001,
      'blockExplorer':
          'https://explorer-mainnet-cardano-evm.c1.milkomeda.com/tx/$transactionhashTemplateKey',
      'symbol': 'MilkADA',
      'default': 'MilkADA',
      'image': 'assets/milko-cardano.jpeg',
      'coinType': 60
    },
    {
      'name': 'Huobi Chain',
      "rpc": 'https://http-mainnet-node.huobichain.com/',
      'chainId': 128,
      'blockExplorer': 'https://hecoinfo.com/tx/$transactionhashTemplateKey',
      'symbol': 'HT',
      'default': 'HT',
      'image': 'assets/huobi.png',
      'coinType': 60
    },
    {
      'name': 'Kucoin Chain',
      "rpc": 'https://rpc-mainnet.kcc.network',
      'chainId': 321,
      'blockExplorer': 'https://explorer.kcc.io/tx/$transactionhashTemplateKey',
      'symbol': 'KCS',
      'default': 'KCS',
      'image': 'assets/kucoin.jpeg',
      'coinType': 60
    },
    {
      'name': 'Elastos',
      "rpc": 'https://api.elastos.io/eth',
      'chainId': 20,
      'blockExplorer':
          'https://explorer.elaeth.io/tx/$transactionhashTemplateKey',
      'symbol': 'ELA',
      'default': 'ELA',
      'image': 'assets/elastos.png',
      'coinType': 60
    },
    {
      'name': 'XDAI',
      "rpc": 'https://rpc.xdaichain.com/',
      'chainId': 100,
      'blockExplorer':
          'https://blockscout.com/xdai/mainnet/tx/$transactionhashTemplateKey',
      'symbol': 'XDAI',
      'default': 'XDAI',
      'image': 'assets/xdai.jpg',
      'coinType': 60
    },
    {
      'name': 'Ubiq',
      "rpc": 'https://rpc.octano.dev/',
      'chainId': 8,
      'blockExplorer': 'https://ubiqscan.io/tx/$transactionhashTemplateKey',
      'symbol': 'UBQ',
      'default': 'UBQ',
      'image': 'assets/ubiq.png',
      'coinType': 60
    },
    {
      'name': 'Celo',
      "rpc": 'https://rpc.ankr.com/celo',
      'chainId': 42220,
      'blockExplorer':
          'https://explorer.celo.org/tx/$transactionhashTemplateKey',
      'symbol': 'CELO',
      'default': 'CELO',
      'image': 'assets/celo.png',
      'coinType': 60
    },
    {
      'name': 'Fuse',
      "rpc": 'https://rpc.fuse.io',
      'chainId': 122,
      'blockExplorer':
          'https://explorer.fuse.io/tx/$transactionhashTemplateKey',
      'symbol': 'FUSE',
      'default': 'FUSE',
      'image': 'assets/fuse.png',
      'coinType': 60
    },
    {
      'name': 'Aurora',
      "rpc": 'https://mainnet.aurora.dev',
      'chainId': 1313161554,
      'blockExplorer': 'https://aurorascan.dev/tx/$transactionhashTemplateKey',
      'symbol': 'ETH',
      'default': 'ETH',
      'image': 'assets/aurora.png',
      'coinType': 60
    },
    {
      'name': 'Thunder Token',
      "rpc": 'https://mainnet-rpc.thundercore.com',
      'chainId': 108,
      'blockExplorer':
          'https://viewblock.io/thundercore/tx/$transactionhashTemplateKey',
      'symbol': 'TT',
      'default': 'TT',
      'image': 'assets/thunder-token.jpeg',
      'coinType': 1001
    },
    {
      'name': 'GoChain',
      "rpc": 'https://rpc.gochain.io',
      'chainId': 60,
      'blockExplorer':
          'https://explorer.gochain.io/tx/$transactionhashTemplateKey',
      'symbol': 'GO',
      'default': 'GO',
      'image': 'assets/go-chain.png',
      'coinType': 6060
    },
  ];

  if (enableTestNet) {
    blockChains.addAll([
      {
        'name': 'Smart Chain(Testnet)',
        "rpc": 'https://data-seed-prebsc-2-s3.binance.org:8545/',
        'chainId': 97,
        'blockExplorer':
            'https://testnet.bscscan.com/tx/$transactionhashTemplateKey',
        'symbol': 'BNB',
        'default': 'BNB',
        'image': 'assets/smartchain.png',
        'coinType': 60
      },
      {
        'name': 'Ethereum(Goerli)',
        "rpc": 'https://goerli.infura.io/v3/$infuraApiKey',
        'chainId': 5,
        'blockExplorer':
            'https://goerli.etherscan.io/tx/$transactionhashTemplateKey',
        'symbol': 'ETH',
        'default': 'ETH',
        'image': 'assets/ethereum_logo.png',
        'coinType': 60
      },
      {
        'name': 'Polygon (Mumbai)',
        "rpc": "https://rpc-mumbai.maticvigil.com",
        "chainId": 80001,
        "blockExplorer":
            "https://mumbai.polygonscan.com/tx/$transactionhashTemplateKey",
        "symbol": "MATIC",
        "default": "MATIC",
        "image": "assets/polygon.png",
        'coinType': 60
      }
    ]);
  }

  if (userAddedEVM.isNotEmpty) blockChains.addAll([userAddedEVM]);

  return blockChains;
}

Future<double> getEtherTransactionFee(
  String rpc,
  Uint8List data,
  EthereumAddress sender,
  EthereumAddress to, {
  double value,
  EtherAmount gasPrice,
}) async {
  final client = Web3Client(
    rpc,
    Client(),
  );

  final etherValue = value != null
      ? EtherAmount.inWei(
          BigInt.from(value),
        )
      : null;

  if (gasPrice == null || gasPrice.getInWei == BigInt.from(0)) {
    gasPrice = await client.getGasPrice();
  }

  BigInt gasUnit;

  try {
    gasUnit = await client.estimateGas(
      sender: sender,
      to: to,
      data: data,
      value: etherValue,
    );
  } catch (_) {}

  if (gasUnit == null) {
    try {
      gasUnit = await client.estimateGas(
        sender: EthereumAddress.fromHex(zeroAddress),
        to: to,
        data: data,
        value: etherValue,
      );
    } catch (_) {}
  }

  if (gasUnit == null) {
    try {
      gasUnit = await client.estimateGas(
        sender: EthereumAddress.fromHex(deadAddress),
        to: to,
        data: data,
        value: etherValue,
      );
    } catch (e) {
      gasUnit = BigInt.from(0);
    }
  }

  return gasPrice.getInWei.toDouble() * gasUnit.toDouble();
}

String calculateEthereumKey(Map config) {
  SeedPhraseRoot seedRoot_ = config[seedRootKey];
  return "0x${HEX.encode(seedRoot_.root.derivePath("m/44'/${config['coinType']}'/0'/0/0").privateKey)}";
}

Future<String> etherPrivateKeyToAddress(String privateKey) async {
  EthPrivateKey ethereumPrivateKey = EthPrivateKey.fromHex(privateKey);
  final uncheckedSumAddress = await ethereumPrivateKey.extractAddress();
  return EthereumAddress.fromHex(uncheckedSumAddress.toString()).hexEip55;
}
