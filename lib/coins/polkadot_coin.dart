// ignore_for_file: non_constant_identifier_names

import '../interface/coin.dart';
import '../main.dart';
import '../utils/app_config.dart';

const polkadotDecimals = 10;

class PolkadotCoin extends Coin {
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

  @override
  int decimals() {
    return polkadotDecimals;
  }

  @override
  Future<Map> fromMnemonic(String mnemonic) async {
    return {
      'address': '',
      'privateKey': '',
    };
  }

  @override
  Future<double> getBalance(bool skipNetworkRequest) async {
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
  });

  factory PolkadotCoin.fromJson(Map<String, dynamic> json) {
    return PolkadotCoin(
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

    data['default'] = default_;
    data['symbol'] = symbol;
    data['name'] = name;
    data['blockExplorer'] = blockExplorer;

    data['image'] = image;

    return data;
  }

  @override
  Future<String> transferToken(String amount, String to) async {
    return '';
  }

  @override
  validateAddress(String address) async {
    throw UnimplementedError();
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
    }
  ];

  return blockChains;
}

final polkadot = {
  "id": "polkadot",
  "name": "Polkadot",
  "coinId": 354,
  "symbol": "DOT",
  "decimals": 10,
  "blockchain": "Polkadot",
  "derivation": [
    {"path": "m/44'/354'/0'/0'/0'"}
  ],
  "curve": "ed25519",
  "publicKeyType": "ed25519",
  "addressHasher": "keccak256",
  "ss58Prefix": 0,
  "explorer": {
    "url": "https://polkadot.subscan.io",
    "txPath": "/extrinsic/",
    "accountPath": "/account/"
  },
  "info": {
    "url": "https://polkadot.network/",
    "source": "https://github.com/paritytech/polkadot",
    "rpc": "",
    "documentation": "https://polkadot.js.org/api/substrate/rpc.html"
  }
};
