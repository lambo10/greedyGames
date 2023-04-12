// ignore_for_file: constant_identifier_names

import 'dart:math';
import 'dart:typed_data';

import 'package:cryptowallet/coins/ethereum_coin.dart';
import 'package:cryptowallet/utils/app_config.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

import '../utils/rpc_urls.dart';

enum EthTokenType {
  ERC1155,
  ERC721,
  ERC20,
}

class EthContractCoin extends EthereumCoin {
  EthTokenType tokenType;
  String tokenId;
  bool isNFT;
  bool isContract = true;
  String contractAddress_;
  String network;

  @override
  bool noPrice() {
    return true;
  }

  @override
  String contractAddress() {
    return contractAddress_;
  }

  EthContractCoin({
    String blockExplorer,
    int chainId,
    String symbol,
    String default_,
    String image,
    int coinType,
    String rpcUrl,
    String name,
    this.tokenType,
    this.tokenId,
    this.isNFT,
    this.isContract,
    this.contractAddress_,
    this.network,
  }) : super(
          blockExplorer: blockExplorer,
          chainId: chainId,
          symbol: symbol,
          default_: default_,
          image: image,
          coinType: coinType,
          rpcUrl: rpcUrl,
          name: name,
        );

  factory EthContractCoin.fromJson(Map<String, dynamic> json) {
    return EthContractCoin(
      chainId: json['chainId'],
      rpcUrl: json['rpcUrl'],
      coinType: json['coinType'],
      blockExplorer: json['blockExplorer'],
      default_: json['default'],
      symbol: json['symbol'],
      image: json['image'],
      name: json['name'],
      tokenType: json['tokenType'],
      tokenId: json['tokenId'],
      isNFT: json['isNFT'],
      isContract: json['isContract'],
      contractAddress_: json['contractAddress'],
      network: json['network'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['chainId'] = chainId;
    data['rpcUrl'] = rpcUrl;
    data['default'] = default_;
    data['symbol'] = symbol;
    data['name'] = name;
    data['blockExplorer'] = blockExplorer;
    data['coinType'] = coinType;
    data['image'] = image;
    data['tokenType'] = tokenType;
    data['tokenId'] = tokenId;
    data['isNFT'] = isNFT;
    data['isContract'] = isContract;
    data['contractAddress'] = contractAddress;
    data['network'] = network;

    return data;
  }

  @override
  Future<double> getTransactionFee(String amount, String to) async {
    final client = Web3Client(
      rpcUrl,
      Client(),
    );

    final response = await fromMnemonic(pref.get(currentMmenomicKey));

    final sendingAddress = EthereumAddress.fromHex(
      response['address'],
    );

    ContractAbi contrAbi;
    if (!isNFT) {
      contrAbi = ContractAbi.fromJson(
        erc20Abi,
        '',
      );
    } else if (tokenType == EthTokenType.ERC721) {
      contrAbi = ContractAbi.fromJson(
        erc721Abi,
        '',
      );
    } else if (tokenType == EthTokenType.ERC1155) {
      contrAbi = ContractAbi.fromJson(
        erc1155Abi,
        '',
      );
    }

    final contract = DeployedContract(
      contrAbi,
      EthereumAddress.fromHex(contractAddress()),
    );

    ContractFunction decimalsFunction;

    BigInt decimals;

    if (!isNFT) {
      decimalsFunction = contract.function('decimals');
      decimals = (await client
              .call(contract: contract, function: decimalsFunction, params: []))
          .first;
    }

    final transfer = isNFT
        ? contract.findFunctionsByName('safeTransferFrom').toList()[0]
        : contract.function('transfer');
    List _parameters;
    if (!isNFT) {
      _parameters = [
        EthereumAddress.fromHex(to),
        BigInt.from(
          double.parse(amount) * pow(10, decimals.toInt()),
        )
      ];
    } else if (tokenType == EthTokenType.ERC721) {
      _parameters = [sendingAddress, EthereumAddress.fromHex(to), tokenId];
    } else if (tokenType == EthTokenType.ERC1155) {
      _parameters = [
        sendingAddress,
        EthereumAddress.fromHex(to),
        tokenId,
        BigInt.from(
          double.parse(amount),
        ),
        Uint8List(1)
      ];
    }

    Uint8List contractData = transfer.encodeCall(_parameters);

    final transactionFee = await getEtherTransactionFee(
      rpcUrl,
      contractData,
      sendingAddress,
      EthereumAddress.fromHex(
        contractAddress(),
      ),
    );

    return transactionFee / pow(10, etherDecimals);
  }
}
