import 'package:bitbox/bitbox.dart';
import 'package:cryptowallet/coins/ethereum_coin.dart';

import '../utils/app_config.dart';

class RoninCoin extends EthereumCoin {
  RoninCoin({
    String blockExplorer,
    int chainId,
    String symbol,
    String default_,
    String image,
    int coinType,
    String rpc,
    String name,
  }) : super(
          blockExplorer: blockExplorer,
          chainId: chainId,
          symbol: symbol,
          default_: default_,
          image: image,
          coinType: coinType,
          rpc: rpc,
          name: name,
        );

  factory RoninCoin.fromJson(Map<String, dynamic> json) {
    return RoninCoin(
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
  Future<Map> fromMnemonic(String mnemonic) async {
    final mnemonicDetails = await super.fromMnemonic(mnemonic);
    final String address = mnemonicDetails['address'];
    return {
      ...mnemonicDetails,
      'address': address.replaceFirst('0x', 'ronin:')
    };
  }

  @override
  void validateAddress(String address) {
    final address_ = address.replaceFirst('ronin:', '0x');
    super.validateAddress(address_);
  }
}

List<Map> getRoninBlockchains() {
  List<Map> blockChains = [
    {
      "rpc": 'https://api.roninchain.com/rpc',
      'chainId': 2020,
      'blockExplorer':
          'https://explorer.roninchain.com/tx/$transactionhashTemplateKey',
      'symbol': 'RON',
      'default': 'RON',
      'name': 'Ronin',
      'image': 'assets/ronin.jpeg',
      'coinType': 60
    }
  ];

  if (enableTestNet) {
    blockChains.addAll([
      {
        "rpc": ' https://saigon-testnet.roninchain.com/rpc',
        'chainId': 2021,
        'blockExplorer':
            'https://saigon-explorer.roninchain.com/tx/$transactionhashTemplateKey',
        'symbol': 'RON',
        'default': 'RON',
        'name': 'Ronin(Testnet)',
        'image': 'assets/ronin.jpeg',
        'coinType': 60
      },
    ]);
  }

  return blockChains;
}
