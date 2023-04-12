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
}

class EthContractCoin extends EthereumCoin {
  EthTokenType tokenType;
  String tokenId;
  bool isNFT;
  EthContractCoin({
    this.tokenType,
    this.tokenId,
    this.isNFT,
  });

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
