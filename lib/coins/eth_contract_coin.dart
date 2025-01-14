// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptowallet/coins/ethereum_coin.dart';
import 'package:cryptowallet/utils/app_config.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

import '../main.dart';
import '../utils/alt_ens.dart';
import '../utils/rpc_urls.dart';

enum EthTokenType {
  ERC1155,
  ERC721,
  ERC20,
}

class EthContractCoin extends EthereumCoin {
  EthTokenType tokenType;
  BigInt tokenId;
  String contractAddress_;
  String network;
  List parameters_;
  ContractAbi contrAbi;
  int decimals_;

  @override
  bool noPrice() {
    return true;
  }

  @override
  String contractAddress() {
    return contractAddress_;
  }

  @override
  int decimals() {
    return decimals_;
  }

  EthContractCoin({
    String blockExplorer,
    int chainId,
    String symbol,
    String default_,
    String image,
    int coinType,
    String rpc,
    String name,
    this.decimals_,
    this.tokenType,
    this.tokenId,
    this.contractAddress_,
    this.network,
  }) : super(
          blockExplorer: blockExplorer,
          chainId: chainId,
          symbol: symbol,
          default_: default_,
          image: image,
          coinType: coinType,
          rpc: rpc,
          name: name,
        ) {
    if (tokenType == EthTokenType.ERC20) {
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
  }

  factory EthContractCoin.fromJson(Map<String, dynamic> json) {
    if (json['tokenType'].runtimeType == String) {
      json['tokenType'] = EthTokenType.values.byName(json['tokenType']);
    }

    return EthContractCoin(
      chainId: json['chainId'],
      rpc: json['rpc'],
      coinType: json['coinType'],
      blockExplorer: json['blockExplorer'],
      default_: json['default'],
      symbol: json['symbol'],
      image: json['image'],
      name: json['name'],
      tokenType: json['tokenType'] ?? EthTokenType.ERC20,
      tokenId: json['tokenId'],
      contractAddress_: json['contractAddress'],
      network: json['network'],
      decimals_: json['decimals'].runtimeType == String
          ? int.parse(json['decimals'])
          : json['decimals'],
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
    data['tokenType'] = tokenType.name;
    data['tokenId'] = tokenId;
    data['contractAddress'] = contractAddress_;
    data['network'] = network;
    data['decimals'] = decimals_;

    return data;
  }

  fillParameter(String amount, String to) async {
    final address = await address_();

    if (tokenType == EthTokenType.ERC20) {
      parameters_ = [
        EthereumAddress.fromHex(to),
        BigInt.from(
          double.parse(amount) * pow(10, decimals()),
        )
      ];
    } else if (tokenType == EthTokenType.ERC721) {
      parameters_ = [
        EthereumAddress.fromHex(address),
        EthereumAddress.fromHex(to),
        tokenId,
      ];
    } else if (tokenType == EthTokenType.ERC1155) {
      parameters_ = [
        EthereumAddress.fromHex(address),
        EthereumAddress.fromHex(to),
        tokenId,
        BigInt.from(
          double.parse(amount),
        ),
        Uint8List(1)
      ];
    }
  }

  @override
  String savedTransKey() {
    return '$contractAddress_$rpc Details';
  }

  final roninChainIds = [2020, 2021];
  @override
  void validateAddress(String address) {
    if (_isRonin()) {
      super.validateAddress(roninAddrToEth(address));
      return;
    }
    super.validateAddress(address);
  }

  bool _isRonin() {
    return roninChainIds.contains(chainId);
  }

  @override
  Future<Map> fromMnemonic(String mnemonic) async {
    if (_isRonin()) {
      final mnemonicDetails = await super.fromMnemonic(mnemonic);
      return {
        ...mnemonicDetails,
        'address': ethAddrToRonin(mnemonicDetails['address']),
      };
    }

    return await super.fromMnemonic(mnemonic);
  }

  @override
  Future<String> transferToken(String amount, String to) async {
    await fillParameter(amount, to);

    final client = Web3Client(
      rpc,
      Client(),
    );

    Map response = await fromMnemonic(pref.get(currentMmenomicKey));
    final credentials = EthPrivateKey.fromHex(response['privateKey']);

    final contract = DeployedContract(
      contrAbi,
      EthereumAddress.fromHex(
        contractAddress_,
      ),
    );

    ContractFunction transfer;

    if (tokenType == EthTokenType.ERC20) {
      transfer = contract.function('transfer');
    } else {
      transfer = contract.findFunctionsByName('safeTransferFrom').toList()[0];
    }

    final trans = await client.signTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: transfer,
        parameters: parameters_,
      ),
      chainId: chainId,
    );

    final transactionHash = await client.sendRawTransaction(trans);

    await client.dispose();
    return transactionHash;
  }

  @override
  Future<double> getBalance(bool skipNetworkRequest) async {
    if (tokenType != EthTokenType.ERC20) {
      return 1;
    }
    return await getERC20TokenBalance(
      toJson(),
      skipNetworkRequest: skipNetworkRequest,
    );
  }

  @override
  Future<double> getTransactionFee(String amount, String to) async {
    await fillParameter(amount, to);

    final response = await fromMnemonic(pref.get(currentMmenomicKey));

    final sendingAddress = EthereumAddress.fromHex(
      response['address'],
    );

    final contract = DeployedContract(
      contrAbi,
      EthereumAddress.fromHex(contractAddress()),
    );

    final transfer = tokenType == EthTokenType.ERC20
        ? contract.function('transfer')
        : contract.findFunctionsByName('safeTransferFrom').toList()[0];

    Uint8List contractData = transfer.encodeCall(parameters_);

    final transactionFee = await getEtherTransactionFee(
      rpc,
      contractData,
      sendingAddress,
      EthereumAddress.fromHex(
        contractAddress(),
      ),
    );

    return transactionFee / pow(10, etherDecimals);
  }
}

Future<double> getERC20TokenBalance(
  Map tokenDetails, {
  bool skipNetworkRequest = false,
}) async {
  Web3Client client = Web3Client(
    tokenDetails['rpc'],
    Client(),
  );

  String mnemonic = pref.get(currentMmenomicKey);

  Map response =
      await EthereumCoin.fromJson(tokenDetails).fromMnemonic(mnemonic);

  final sendingAddress = EthereumAddress.fromHex(
    response['address'],
  );
  String elementDetailsKey = contractDetailsKey(
    tokenDetails['rpc'],
    tokenDetails['contractAddress'],
  );

  String balanceKey = sha3('${elementDetailsKey}balance');

  final storedBalance = pref.get(balanceKey);

  double savedBalance = 0;

  if (storedBalance != null) {
    final crytoBalance = jsonDecode(pref.get(balanceKey));
    savedBalance = double.parse(crytoBalance['balance']) /
        pow(10, double.parse(crytoBalance['decimals']));
  }

  if (skipNetworkRequest) return savedBalance;

  try {
    final contract = DeployedContract(
      ContractAbi.fromJson(erc20Abi, ''),
      EthereumAddress.fromHex(
        tokenDetails['contractAddress'],
      ),
    );

    final balanceFunction = contract.function('balanceOf');

    final decimalsFunction = contract.function('decimals');

    final decimals = (await client
            .call(contract: contract, function: decimalsFunction, params: []))
        .first
        .toString();

    final balance = (await client.call(
      contract: contract,
      function: balanceFunction,
      params: [sendingAddress],
    ))
        .first
        .toString();
    await pref.put(
      balanceKey,
      jsonEncode({
        'balance': balance,
        'decimals': decimals,
      }),
    );
    await client.dispose();

    return double.parse(balance) / pow(10, double.parse(decimals));
  } catch (e, sk) {
    return savedBalance;
  }
}

Future getErc20Allowance({
  String owner,
  String spender,
  String rpc,
  String contractAddress,
}) async {
  Web3Client client = Web3Client(
    rpc,
    Client(),
  );

  final contract = DeployedContract(
    ContractAbi.fromJson(erc20Abi, ''),
    EthereumAddress.fromHex(contractAddress),
  );

  final allowanceFunction = contract.function('allowance');

  final allowance = (await client.call(
    contract: contract,
    function: allowanceFunction,
    params: [
      EthereumAddress.fromHex(owner),
      EthereumAddress.fromHex(spender),
    ],
  ))
      .first;

  return allowance;
}

Future<Map> getERC20TokenDetails({
  String contractAddress,
  String rpc,
}) async {
  final client = Web3Client(
    rpc,
    Client(),
  );

  final contract = DeployedContract(
    ContractAbi.fromJson(erc20Abi, ''),
    EthereumAddress.fromHex(contractAddress),
  );

  final nameFunction = contract.function('name');
  final symbolFunction = contract.function('symbol');
  final decimalsFunction = contract.function('decimals');

  final name =
      await client.call(contract: contract, function: nameFunction, params: []);

  final symbol = await client
      .call(contract: contract, function: symbolFunction, params: []);
  final decimals = await client
      .call(contract: contract, function: decimalsFunction, params: []);

  return {
    'name': name.first,
    'symbol': symbol.first,
    'decimals': decimals.first.toString()
  };
}

Future<Map> savedERC20Details({
  String contractAddress,
  String rpc,
  int chainId,
}) async {
  String tokenDetailsKey = contractDetailsKey(rpc, contractAddress);

  String tokenDetailsSaved = pref.get(tokenDetailsKey);
  Map erc20TokenDetails = {};
  try {
    erc20TokenDetails = await getERC20TokenDetails(
      contractAddress: contractAddress,
      rpc: rpc,
    );
  } catch (e) {
    if (tokenDetailsSaved != null) {
      erc20TokenDetails = json.decode(tokenDetailsSaved);
    }
  }

  await pref.put(tokenDetailsKey, json.encode(erc20TokenDetails));
  return erc20TokenDetails;
}
