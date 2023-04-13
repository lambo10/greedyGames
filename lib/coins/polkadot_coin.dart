import '../interface/coin.dart';

class PolkadotCoin extends Coin {
  @override
  Future<String> address_() {
    // TODO: implement address_
    throw UnimplementedError();
  }

  @override
  String blockExplorer_() {
    // TODO: implement blockExplorer_
    throw UnimplementedError();
  }

  @override
  int decimals() {
    // TODO: implement decimals
    throw UnimplementedError();
  }

  @override
  String default__() {
    // TODO: implement default__
    throw UnimplementedError();
  }

  @override
  Future<Map> fromMnemonic(String mnemonic) {
    // TODO: implement fromMnemonic
    throw UnimplementedError();
  }

  @override
  Future<double> getBalance(bool skipNetworkRequest) {
    // TODO: implement getBalance
    throw UnimplementedError();
  }

  @override
  Future<double> getTransactionFee(String amount, String to) {
    // TODO: implement getTransactionFee
    throw UnimplementedError();
  }

  @override
  String image_() {
    // TODO: implement image_
    throw UnimplementedError();
  }

  @override
  String name_() {
    // TODO: implement name_
    throw UnimplementedError();
  }

  @override
  String symbol_() {
    // TODO: implement symbol_
    throw UnimplementedError();
  }

  @override
  Map toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  @override
  Future<String> transferToken(String amount, String to) {
    // TODO: implement transferToken
    throw UnimplementedError();
  }

  @override
  validateAddress(String address) {
    // TODO: implement validateAddress
    throw UnimplementedError();
  }
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
