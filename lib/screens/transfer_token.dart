import 'dart:async';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart' as cardano;
import 'dart:math';
import 'package:algorand_dart/algorand_dart.dart' as algoRan;
import 'package:cryptowallet/api/notification_api.dart';
import 'package:cryptowallet/components/loader.dart';
import 'package:cryptowallet/config/colors.dart';
import 'package:cryptowallet/interface/coin.dart';
import 'package:cryptowallet/utils/app_config.dart';
import 'package:cryptowallet/utils/bitcoin_util.dart';
import 'package:cryptowallet/utils/format_money.dart';
import 'package:cryptowallet/utils/stellar_utils.dart';
import 'package:cryptowallet/coins/tron_utils.dart';
import 'package:dartez/dartez.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:hex/hex.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:near_api_flutter/near_api_flutter.dart';
import 'package:web3dart/web3dart.dart' as web3;
import 'package:web3dart/web3dart.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import '../utils/filecoin_util.dart';

class TransferToken extends StatefulWidget {
  final Coin tokenData;
  final String cryptoDomain;
  const TransferToken({
    Key key,
    this.tokenData,
    this.cryptoDomain,
  }) : super(key: key);

  @override
  _TransferTokenState createState() => _TransferTokenState();
}

class _TransferTokenState extends State<TransferToken> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isSending = false;

  bool get kDebugMode => null;
  Timer timer;
  Map transactionFeeMap;
  bool isContract;
  bool isBitcoinType;
  bool isSolana;
  bool isAlgorand;
  bool isCardano;
  bool isFilecoin;
  bool isStellar;
  bool isNFTTransfer;
  bool isCosmos;
  bool isTron;
  bool isTezor;
  bool isXRP;
  bool isNear;
  ContractAbi contrAbi;
  List _parameters;
  String mnemonic;

  @override
  void initState() {
    super.initState();
    mnemonic = Hive.box(secureStorageKey).get(currentMmenomicKey);
    isContract = widget.tokenData['contractAddress'] != null;
    isBitcoinType = widget.tokenData['POSNetwork'] != null;
    isSolana = widget.tokenData['default'] == 'SOL';
    isCardano = widget.tokenData['default'] == 'ADA';
    isFilecoin = widget.tokenData['default'] == 'FIL';
    isStellar = widget.tokenData['default'] == 'XLM';
    isCosmos = widget.tokenData['default'] == 'ATOM';
    isAlgorand = widget.tokenData['default'] == 'ALGO';
    isTron = widget.tokenData['default'] == 'TRX';
    isTezor = widget.tokenData['default'] == 'XTZ';
    isXRP = widget.tokenData['default'] == 'XRP';
    isNear = widget.tokenData['default'] == 'NEAR';
    isNFTTransfer = widget.tokenData['isNFT'] != null;

    getTransactionFee();
    timer = Timer.periodic(
      httpPollingDelay,
      (Timer t) async => await getTransactionFee(),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Map transactionFee;

  Future getTransactionFee() async {
    try {
      if (isContract) {
        final client = web3.Web3Client(
          widget.tokenData['rpc'],
          Client(),
        );

        Map response = await getEthereumFromMemnomic(
          mnemonic,
          widget.tokenData['coinType'],
        );

        final sendingAddress = web3.EthereumAddress.fromHex(
          response['eth_wallet_address'],
        );

        if (!isNFTTransfer) {
          contrAbi = web3.ContractAbi.fromJson(
            erc20Abi,
            '',
          );
        } else if (widget.tokenData['tokenType'] == 'ERC721') {
          contrAbi = web3.ContractAbi.fromJson(
            erc721Abi,
            '',
          );
        } else if (widget.tokenData['tokenType'] == 'ERC1155') {
          contrAbi = web3.ContractAbi.fromJson(
            erc1155Abi,
            '',
          );
        }

        final contract = web3.DeployedContract(
          contrAbi,
          web3.EthereumAddress.fromHex(widget.tokenData['contractAddress']),
        );

        web3.ContractFunction decimalsFunction;

        BigInt decimals;

        if (!isNFTTransfer) {
          decimalsFunction = contract.function('decimals');
          decimals = (await client.call(
                  contract: contract, function: decimalsFunction, params: []))
              .first;
        }

        final transfer = isNFTTransfer
            ? contract.findFunctionsByName('safeTransferFrom').toList()[0]
            : contract.function('transfer');

        if (!isNFTTransfer) {
          _parameters = [
            web3.EthereumAddress.fromHex(widget.tokenData['recipient']),
            BigInt.from(
              double.parse(widget.tokenData['amount']) *
                  pow(10, decimals.toInt()),
            )
          ];
        } else if (widget.tokenData['tokenType'] == 'ERC721') {
          _parameters = [
            sendingAddress,
            web3.EthereumAddress.fromHex(widget.tokenData['recipient']),
            widget.tokenData['tokenId']
          ];
        } else if (widget.tokenData['tokenType'] == 'ERC1155') {
          _parameters = [
            sendingAddress,
            web3.EthereumAddress.fromHex(widget.tokenData['recipient']),
            widget.tokenData['tokenId'],
            BigInt.from(
              double.parse(widget.tokenData['amount']),
            ),
            Uint8List(1)
          ];
        }

        Uint8List contractData = transfer.encodeCall(_parameters);

        final transactionFee = await getEtherTransactionFee(
          widget.tokenData['rpc'],
          contractData,
          sendingAddress,
          web3.EthereumAddress.fromHex(
            widget.tokenData['contractAddress'],
          ),
        );
        final etherAmountBalance = await client.getBalance(sendingAddress);
        final userBalance =
            etherAmountBalance.getInWei.toDouble() / pow(10, etherDecimals);

        final blockChainCost = transactionFee / pow(10, etherDecimals);

        transactionFeeMap = {
          'transactionFee': blockChainCost,
          'userBalance': userBalance,
        };
      } else if (isBitcoinType) {
        final getBitcoinDetails = await getBitcoinFromMemnomic(
          mnemonic,
          widget.tokenData,
        );
        final bitCoinBalance = await getBitcoinAddressBalance(
          getBitcoinDetails['address'],
          widget.tokenData['POSNetwork'],
        );

        List getUnspentOutput;
        int fee = 0;
        num satoshi = double.parse(widget.tokenData['amount']) * pow(10, 8);
        int satoshiToSend = satoshi.toInt();

        if (widget.tokenData['default'] == 'BCH') {
          fee = await getBCHNetworkFee(
            getBitcoinDetails['address'],
            widget.tokenData,
            satoshiToSend,
          );
        } else {
          getUnspentOutput =
              await getUnspentTransactionBitcoinType(widget.tokenData);
          fee = await getBitcoinTypeNetworkFee(satoshiToSend, getUnspentOutput);
        }

        double feeInBitcoin = fee / pow(10, bitCoinDecimals);

        transactionFeeMap = {
          'transactionFee': feeInBitcoin,
          'userBalance': bitCoinBalance,
        };
      } else if (isTron) {
        final getTronDetails = await getTronFromMemnomic(mnemonic);
        final tronBalance = await getTronAddressBalance(
          getTronDetails['address'],
          widget.tokenData['api'],
        );
        transactionFeeMap = {
          'transactionFee': 0,
          'userBalance': tronBalance,
        };
      } else if (isNear) {
        final getNearDetails = await getNearFromMemnomic(mnemonic);
        final nearBalance = await getNearAddressBalance(
          getNearDetails['address'],
          widget.tokenData['api'],
        );
        transactionFeeMap = {
          'transactionFee': 0,
          'userBalance': nearBalance,
        };
      } else if (isTezor) {
        final getTrezorDetails =
            await getTezorFromMemnomic(mnemonic, widget.tokenData);
        final tezorBalance = await getTezorAddressBalance(
          getTrezorDetails['address'],
          widget.tokenData,
        );
        transactionFeeMap = {
          'transactionFee': 0,
          'userBalance': tezorBalance,
        };
      } else if (isXRP) {
        final getXRPDetails = await getXRPFromMemnomic(mnemonic);
        final xrpBalance = await getXRPAddressBalance(
          getXRPDetails['address'],
          widget.tokenData['ws'],
        );
        final fee = await getXrpFee(widget.tokenData['ws']);
        transactionFeeMap = {
          'transactionFee': double.parse(fee['Fee']) / pow(10, xrpDecimals),
          'userBalance': xrpBalance,
        };
      } else if (isAlgorand) {
        final getAlgorandDetials = await getAlgorandFromMemnomic(
          mnemonic,
        );
        final algorandBalance = await getAlgorandAddressBalance(
          getAlgorandDetials['address'],
          widget.tokenData['algoType'],
        );

        transactionFeeMap = {
          'transactionFee': 0.001,
          'userBalance': algorandBalance,
        };
      } else if (isSolana) {
        final getSolanaDetails = await getSolanaFromMemnomic(mnemonic);
        final solanaCoinBalance = await getSolanaAddressBalance(
          getSolanaDetails['address'],
          widget.tokenData['solanaCluster'],
        );

        final fees = await getSolanaClient(widget.tokenData['solanaCluster'])
            .rpcClient
            .getFees();

        transactionFeeMap = {
          'transactionFee':
              fees.feeCalculator.lamportsPerSignature / pow(10, solanaDecimals),
          'userBalance': solanaCoinBalance,
        };
      } else if (isCardano) {
        final getCardanoDetails = await getCardanoFromMemnomic(
          mnemonic,
          widget.tokenData['cardano_network'],
        );
        final cardanoCoinBalance = await getCardanoAddressBalance(
          getCardanoDetails['address'],
          widget.tokenData['cardano_network'],
          widget.tokenData['blockFrostKey'],
        );

        final fees = maxFeeGuessForCardano / pow(10, cardanoDecimals);

        transactionFeeMap = {
          'transactionFee': fees,
          'userBalance': cardanoCoinBalance,
        };
      } else if (isFilecoin) {
        final getFileCoinDetails = await getFileCoinFromMemnomic(
          mnemonic,
          widget.tokenData['prefix'],
        );
        final fileCoinBalance = await getFileCoinAddressBalance(
          getFileCoinDetails['address'],
          baseUrl: widget.tokenData['baseUrl'],
        );

        final nonce = await getFileCoinNonce(
          widget.tokenData['prefix'],
          widget.tokenData['baseUrl'],
        );
        final attoFIL = double.parse(widget.tokenData['amount']) *
            pow(10, fileCoinDecimals.toInt());

        BigInt amounToSend = BigInt.from(attoFIL);

        final msg = constructFilecoinMsg(
          widget.tokenData['recipient'],
          getFileCoinDetails['address'],
          nonce,
          amounToSend,
        );

        final gasFromNetwork = await fileCoinEstimateGas(
          widget.tokenData['baseUrl'],
          msg,
        );

        // Transaction Fee = GasLimit * GasFeeCap + GasPremium
        final gasLimit = gasFromNetwork['GasLimit'];
        final gasFeeCap = double.parse(gasFromNetwork['GasFeeCap']);
        final gasPremium = double.parse(gasFromNetwork['GasPremium']);
        final fees =
            ((gasLimit * gasFeeCap) + gasPremium) / pow(10, fileCoinDecimals);

        transactionFeeMap = {
          'transactionFee': fees,
          'userBalance': fileCoinBalance,
        };
      } else if (isStellar) {
        final getStellarDetails = await getStellarFromMemnomic(mnemonic);

        final stellarBalance = await getStellarAddressBalance(
          getStellarDetails['address'],
          widget.tokenData['sdk'],
          widget.tokenData['cluster'],
        );

        final fees = await getStellarGas(
          widget.tokenData['recipient'],
          widget.tokenData['amount'],
          widget.tokenData['sdk'],
        );

        transactionFeeMap = {
          'transactionFee': fees,
          'userBalance': stellarBalance,
        };
      } else if (isCosmos) {
        final getCosmosDetails = await getCosmosFromMemnomic(
          mnemonic,
          widget.tokenData['bech32Hrp'],
          widget.tokenData['lcdUrl'],
        );

        final cosmosBalance = await getCosmosAddressBalance(
          getCosmosDetails['address'],
          widget.tokenData['lcdUrl'],
        );
        transactionFeeMap = {
          'transactionFee': 0.001,
          'userBalance': cosmosBalance,
        };
      } else {
        final response = await getEthereumFromMemnomic(
          mnemonic,
          widget.tokenData['coinType'],
        );
        final client = web3.Web3Client(
          widget.tokenData['rpc'],
          Client(),
        );

        final transactionFee = await getEtherTransactionFee(
          widget.tokenData['rpc'],
          null,
          web3.EthereumAddress.fromHex(
            response['eth_wallet_address'],
          ),
          web3.EthereumAddress.fromHex(
            widget.tokenData['recipient'],
          ),
        );

        final senderAddress =
            EthereumAddress.fromHex(response['eth_wallet_address']);

        final getSenderBalance = await client.getBalance(senderAddress);

        final userBalance =
            getSenderBalance.getInWei.toDouble() / pow(10, etherDecimals);

        final blockChainCost = transactionFee / pow(10, etherDecimals);

        transactionFeeMap = {
          'transactionFee': blockChainCost,
          'userBalance': userBalance,
        };
      }
      if (mounted) {
        setState(() {});
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: Text(AppLocalizations.of(context).transfer)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 2));
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '-${widget.tokenData['amount'] ?? '1'} ${isContract ? ellipsify(str: widget.tokenData['symbol']) : widget.tokenData['symbol']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    AppLocalizations.of(context).asset,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    '${isContract ? ellipsify(str: widget.tokenData['name']) : widget.tokenData['name']} (${isContract ? ellipsify(str: widget.tokenData['symbol']) : widget.tokenData['symbol']})',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    AppLocalizations.of(context).from,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  FutureBuilder(future: () async {
                    if (isBitcoinType) {
                      final getPOSblockchainDetails =
                          await getBitcoinFromMemnomic(
                        mnemonic,
                        widget.tokenData,
                      );
                      return {'address': getPOSblockchainDetails['address']};
                    } else if (isSolana) {
                      final getSolanaDetails =
                          await getSolanaFromMemnomic(mnemonic);
                      return {'address': getSolanaDetails['address']};
                    } else if (isCardano) {
                      final getCardanoDetails = await getCardanoFromMemnomic(
                        mnemonic,
                        widget.tokenData['cardano_network'],
                      );
                      return {'address': getCardanoDetails['address']};
                    } else if (isNear) {
                      final getNearDetails =
                          await getNearFromMemnomic(mnemonic);
                      return {'address': getNearDetails['address']};
                    } else if (isTezor) {
                      final getTezorDetails = await getTezorFromMemnomic(
                        mnemonic,
                        widget.tokenData,
                      );
                      return {'address': getTezorDetails['address']};
                    } else if (isXRP) {
                      final getXRPDetails = await getXRPFromMemnomic(mnemonic);
                      return {'address': getXRPDetails['address']};
                    } else if (isTron) {
                      final getTronDetails = await getTronFromMemnomic(
                        mnemonic,
                      );
                      return {'address': getTronDetails['address']};
                    } else if (isAlgorand) {
                      final getAlgorandDetails = await getAlgorandFromMemnomic(
                        mnemonic,
                      );
                      return {'address': getAlgorandDetails['address']};
                    } else if (isFilecoin) {
                      final getFileCoinDetails = await getFileCoinFromMemnomic(
                        mnemonic,
                        widget.tokenData['prefix'],
                      );
                      return {'address': getFileCoinDetails['address']};
                    } else if (isStellar) {
                      final getStellarDetails =
                          await getStellarFromMemnomic(mnemonic);
                      return {'address': getStellarDetails['address']};
                    } else if (isCosmos) {
                      final getCosmosDetails = await getCosmosFromMemnomic(
                        mnemonic,
                        widget.tokenData['bech32Hrp'],
                        widget.tokenData['lcdUrl'],
                      );
                      return {'address': getCosmosDetails['address']};
                    } else {
                      return {
                        'address': (await getEthereumFromMemnomic(
                          mnemonic,
                          widget.tokenData['coinType'],
                        ))['eth_wallet_address']
                      };
                    }
                  }(), builder: (context, snapshot) {
                    return Text(
                      snapshot.hasData
                          ? (snapshot.data as Map)['address']
                          : 'Loading...',
                      style: const TextStyle(fontSize: 16),
                    );
                  }),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    AppLocalizations.of(context).to,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    widget.cryptoDomain != null
                        ? '${widget.cryptoDomain} (${widget.tokenData['recipient']})'
                        : widget.tokenData['recipient'],
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  if (isNFTTransfer) ...[
                    Text(
                      AppLocalizations.of(context).tokenId,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      widget.tokenData['tokenId'].toString(),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(
                      height: 20,
                    )
                  ],
                  Text(
                    AppLocalizations.of(context).transactionFee,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  widget.tokenData['default'] != null
                      ? Text(
                          '${transactionFeeMap != null ? Decimal.parse(transactionFeeMap['transactionFee'].toString()) : '--'}  ${widget.tokenData['default']}',
                          style: const TextStyle(fontSize: 16),
                        )
                      : Container(),
                  widget.tokenData['network'] != null
                      ? Text(
                          '${transactionFeeMap != null ? Decimal.parse(transactionFeeMap['transactionFee'].toString()) : '--'}  ${getEVMBlockchains()[widget.tokenData['network']]['symbol']}',
                          style: const TextStyle(fontSize: 16),
                        )
                      : Container(),
                  const SizedBox(
                    height: 20,
                  ),
                  transactionFeeMap != null
                      ? Container(
                          color: Colors.transparent,
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.resolveWith(
                                      (states) => appBackgroundblue),
                              shape: MaterialStateProperty.resolveWith(
                                (states) => RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            onPressed: transactionFeeMap['userBalance'] ==
                                        null ||
                                    transactionFeeMap['userBalance'] <= 0
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppLocalizations.of(context)
                                              .insufficientBalance,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                : () async {
                                    if (isSending) return;
                                    if (await authenticate(context)) {
                                      ScaffoldMessenger.of(context)
                                          .hideCurrentSnackBar();
                                      if (mounted) {
                                        setState(() {
                                          isSending = true;
                                        });
                                      }
                                      try {
                                        final pref = Hive.box(secureStorageKey);

                                        String userAddress;
                                        String transactionHash;
                                        int coinDecimals;
                                        String userTransactionsKey;
                                        if (isContract) {
                                          final client = web3.Web3Client(
                                            widget.tokenData['rpc'],
                                            Client(),
                                          );

                                          Map response =
                                              await getEthereumFromMemnomic(
                                            mnemonic,
                                            widget.tokenData['coinType'],
                                          );
                                          final credentials =
                                              EthPrivateKey.fromHex(
                                            response['eth_wallet_privateKey'],
                                          );

                                          final contract =
                                              web3.DeployedContract(
                                            contrAbi,
                                            web3.EthereumAddress.fromHex(
                                              widget
                                                  .tokenData['contractAddress'],
                                            ),
                                          );

                                          web3.ContractFunction
                                              decimalsFunction;

                                          BigInt decimals;

                                          ContractFunction transfer;

                                          if (isNFTTransfer) {
                                            transfer = contract
                                                .findFunctionsByName(
                                                    'safeTransferFrom')
                                                .toList()[0];
                                          } else {
                                            transfer =
                                                contract.function('transfer');

                                            decimalsFunction =
                                                contract.function('decimals');
                                            decimals = (await client.call(
                                                    contract: contract,
                                                    function: decimalsFunction,
                                                    params: []))
                                                .first;

                                            coinDecimals = decimals.toInt();
                                          }

                                          final trans =
                                              await client.signTransaction(
                                            credentials,
                                            Transaction.callContract(
                                              contract: contract,
                                              function: transfer,
                                              parameters: _parameters,
                                            ),
                                            chainId:
                                                widget.tokenData['chainId'],
                                          );

                                          transactionHash = await client
                                              .sendRawTransaction(trans);

                                          userAddress =
                                              response['eth_wallet_address'];

                                          userTransactionsKey =
                                              '${widget.tokenData['contractAddress']}${widget.tokenData['rpc']} Details';

                                          await client.dispose();
                                        } else if (isBitcoinType) {
                                          transactionHash = transaction['txid'];

                                          coinDecimals = bitCoinDecimals;
                                          userAddress =
                                              getBitCoinDetails['address'];

                                          userTransactionsKey =
                                              '${widget.tokenData['default']} Details';
                                        } else if (isTezor) {
                                          coinDecimals = tezorDecimals;
                                          userAddress =
                                              getTezorDetails['address'];

                                          userTransactionsKey =
                                              '${widget.tokenData['default']} Details';
                                        } else if (isNear) {
                                          coinDecimals = nearDecimals;
                                          userAddress =
                                              getNearDetails['address'];

                                          userTransactionsKey =
                                              '${widget.tokenData['default']} Details';
                                        } else if (isXRP) {
                                          final getXRPDetails =
                                              await getXRPFromMemnomic(
                                            mnemonic,
                                          );
                                          Map transaction = await sendXRP(
                                            ws: widget.tokenData['ws'],
                                            recipient:
                                                widget.tokenData['recipient'],
                                            amountInXrp:
                                                widget.tokenData['amount'],
                                            mnemonic: mnemonic,
                                          );
                                          transactionHash = transaction['txid'];

                                          coinDecimals = xrpDecimals;
                                          userAddress =
                                              getXRPDetails['address'];
                                          userTransactionsKey =
                                              '${widget.tokenData['default']} Details';
                                        } else if (isAlgorand) {
                                          final getAlgorandDetails =
                                              await getAlgorandFromMemnomic(
                                                  mnemonic);

                                          Map transaction = await sendAlgorand(
                                            widget.tokenData['recipient'],
                                            widget.tokenData['algoType'],
                                            algoRan.Algo.toMicroAlgos(
                                              double.parse(
                                                widget.tokenData['amount'],
                                              ),
                                            ),
                                          );
                                          transactionHash = transaction['txid'];

                                          coinDecimals = algorandDecimals;
                                          userAddress =
                                              getAlgorandDetails['address'];
                                          userTransactionsKey =
                                              '${widget.tokenData['default']} Details';
                                        } else if (isSolana) {
                                          final getSolanaDetails =
                                              await getSolanaFromMemnomic(
                                                  mnemonic);

                                          final transaction = await sendSolana(
                                            widget.tokenData['recipient'],
                                            lamport.toInt(),
                                            widget.tokenData['solanaCluster'],
                                          );
                                          transactionHash = transaction['txid'];

                                          coinDecimals = solanaDecimals;
                                          userAddress =
                                              getSolanaDetails['address'];
                                          userTransactionsKey =
                                              '${widget.tokenData['default']} Details';
                                        } else if (isCardano) {
                                          final getCardanoDetails =
                                              await getCardanoFromMemnomic(
                                            mnemonic,
                                            widget.tokenData['cardano_network'],
                                          );

                                          final lovelace = double.parse(
                                                widget.tokenData['amount'],
                                              ) *
                                              pow(10, cardanoDecimals);

                                          int amountToSend = lovelace.toInt();
                                          final transaction = await compute(
                                            sendCardano,
                                            {
                                              'cardanoNetwork': widget
                                                  .tokenData['cardano_network'],
                                              'blockfrostForCardanoApiKey':
                                                  widget.tokenData[
                                                      'blockFrostKey'],
                                              'mnemonic': mnemonic,
                                              'lovelaceToSend': amountToSend,
                                              'senderAddress': cardano
                                                  .ShelleyAddress.fromBech32(
                                                getCardanoDetails['address'],
                                              ),
                                              'recipientAddress': cardano
                                                  .ShelleyAddress.fromBech32(
                                                widget.tokenData['recipient'],
                                              )
                                            },
                                          );
                                          transactionHash = transaction['txid'];

                                          coinDecimals = cardanoDecimals;
                                          userAddress =
                                              getCardanoDetails['address'];
                                          userTransactionsKey =
                                              '${widget.tokenData['default']} Details';
                                        } else if (isTron) {
                                          final getTronDetails =
                                              await getTronFromMemnomic(
                                                  mnemonic);

                                          final transaction = await sendTron(
                                            widget.tokenData['api'],
                                            microTron.toInt(),
                                            getTronDetails['address'],
                                            widget.tokenData['recipient'],
                                          );
                                          transactionHash = transaction['txid'];

                                          coinDecimals = tronDecimals;
                                          userAddress =
                                              getTronDetails['address'];
                                          userTransactionsKey =
                                              '${widget.tokenData['default']} Details';
                                        } else if (isFilecoin) {
                                          final getFileCoinDetails =
                                              await getFileCoinFromMemnomic(
                                            mnemonic,
                                            widget.tokenData['prefix'],
                                          );

                                          final attoFil = double.parse(
                                                  widget.tokenData['amount']) *
                                              pow(10, fileCoinDecimals);

                                          BigInt amounToSend =
                                              BigInt.from(attoFil);

                                          final transaction =
                                              await sendFilecoin(
                                            widget.tokenData['recipient'],
                                            amounToSend,
                                            baseUrl:
                                                widget.tokenData['baseUrl'],
                                            addressPrefix:
                                                widget.tokenData['prefix'],
                                          );
                                          transactionHash = transaction['txid'];

                                          coinDecimals = fileCoinDecimals;
                                          userAddress =
                                              getFileCoinDetails['address'];
                                          userTransactionsKey =
                                              '${widget.tokenData['default']} Details';
                                        } else if (isStellar) {
                                          Map getStellarDetails =
                                              await getStellarFromMemnomic(
                                            mnemonic,
                                          );

                                          final transaction = await sendStellar(
                                            widget.tokenData['recipient'],
                                            widget.tokenData['amount'],
                                            widget.tokenData['sdk'],
                                            widget.tokenData['cluster'],
                                          );
                                          transactionHash = transaction['txid'];

                                          coinDecimals = stellarDecimals;
                                          userAddress =
                                              getStellarDetails['address'];
                                          userTransactionsKey =
                                              '${widget.tokenData['default']} Details';
                                        } else if (isCosmos) {
                                          Map getCosmosDetails =
                                              await getCosmosFromMemnomic(
                                            mnemonic,
                                            widget.tokenData['bech32Hrp'],
                                            widget.tokenData['lcdUrl'],
                                          );

                                          final uatomToSend = double.parse(
                                                  widget.tokenData['amount']) *
                                              pow(10, cosmosDecimals);

                                          final transaction =
                                              await compute(sendCosmos, {
                                            'bech32Hrp':
                                                widget.tokenData['bech32Hrp'],
                                            'lcdUrl':
                                                widget.tokenData['lcdUrl'],
                                            'mnemonic': mnemonic,
                                            'recipientAddress':
                                                widget.tokenData['recipient'],
                                            'uatomToSend':
                                                uatomToSend.toInt().toString()
                                          });
                                          transactionHash = transaction['txid'];

                                          coinDecimals = cosmosDecimals;
                                          userAddress =
                                              getCosmosDetails['address'];
                                          userTransactionsKey =
                                              '${widget.tokenData['default']} Details';
                                        } else {
                                          final client = web3.Web3Client(
                                            widget.tokenData['rpc'],
                                            Client(),
                                          );

                                          final response =
                                              await getEthereumFromMemnomic(
                                            mnemonic,
                                            widget.tokenData['coinType'],
                                          );

                                          final credentials =
                                              EthPrivateKey.fromHex(
                                            response['eth_wallet_privateKey'],
                                          );
                                          final gasPrice =
                                              await client.getGasPrice();

                                          final wei = double.parse(
                                                  widget.tokenData['amount']) *
                                              pow(10, etherDecimals);

                                          final trans =
                                              await client.signTransaction(
                                            credentials,
                                            web3.Transaction(
                                              from: web3.EthereumAddress
                                                  .fromHex(response[
                                                      'eth_wallet_address']),
                                              to: web3.EthereumAddress.fromHex(
                                                  widget
                                                      .tokenData['recipient']),
                                              value: web3.EtherAmount.inWei(
                                                BigInt.from(wei),
                                              ),
                                              gasPrice: gasPrice,
                                            ),
                                            chainId:
                                                widget.tokenData['chainId'],
                                          );

                                          transactionHash = await client
                                              .sendRawTransaction(trans);

                                          coinDecimals = etherDecimals;
                                          userAddress =
                                              response['eth_wallet_address'];
                                          userTransactionsKey =
                                              '${widget.tokenData['default']}${widget.tokenData['rpc']} Details';

                                          await client.dispose();
                                        }

                                        if (transactionHash == null) {
                                          throw Exception('Sending failed');
                                        }
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              AppLocalizations.of(context)
                                                  .trxSent,
                                            ),
                                          ),
                                        );

                                        String tokenSent = isNFTTransfer
                                            ? widget.tokenData['tokenId']
                                                .toString()
                                            : widget.tokenData['amount'];

                                        NotificationApi.showNotification(
                                          title:
                                              '${widget.tokenData['symbol']} Sent',
                                          body:
                                              '$tokenSent ${widget.tokenData['symbol']} sent to ${widget.tokenData['recipient']}',
                                        );

                                        if (isNFTTransfer) {
                                          if (mounted) {
                                            setState(() {
                                              isSending = false;
                                            });
                                          }
                                          if (Navigator.canPop(context)) {
                                            int count = 0;
                                            Navigator.popUntil(context,
                                                (route) {
                                              return count++ == 2;
                                            });
                                          }
                                          return;
                                        }

                                        String formattedDate =
                                            DateFormat("yyyy-MM-dd HH:mm:ss")
                                                .format(
                                          DateTime.now(),
                                        );

                                        final mapData = {
                                          'time': formattedDate,
                                          'from': userAddress,
                                          'to': widget.tokenData['recipient'],
                                          'value': double.parse(
                                                widget.tokenData['amount'],
                                              ) *
                                              pow(10, coinDecimals),
                                          'decimal': coinDecimals,
                                          'transactionHash': transactionHash
                                        };

                                        List userTransactions = [];
                                        String jsonEncodedUsrTrx =
                                            pref.get(userTransactionsKey);

                                        if (jsonEncodedUsrTrx != null) {
                                          userTransactions = json.decode(
                                            jsonEncodedUsrTrx,
                                          );
                                        }

                                        userTransactions.insert(0, mapData);
                                        userTransactions.length =
                                            maximumTransactionToSave;
                                        await pref.put(
                                          userTransactionsKey,
                                          jsonEncode(userTransactions),
                                        );
                                        if (mounted) {
                                          setState(() {
                                            isSending = false;
                                          });
                                        }
                                        if (Navigator.canPop(context)) {
                                          int count = 0;
                                          Navigator.popUntil(context, (route) {
                                            return count++ == 3;
                                          });
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          setState(() {
                                            isSending = false;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                backgroundColor: Colors.red,
                                                content: Text(
                                                  e.toString(),
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                            );
                                          });
                                        }
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          backgroundColor: Colors.red,
                                          content: Text(
                                            AppLocalizations.of(context)
                                                .authFailed,
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: isSending
                                  ? Container(
                                      color: Colors.transparent,
                                      width: 20,
                                      height: 20,
                                      child: const Loader(color: white),
                                    )
                                  : Text(
                                      AppLocalizations.of(context).send,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.resolveWith(
                                      (states) => appBackgroundblue),
                              shape: MaterialStateProperty.resolveWith(
                                (states) => RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            onPressed: null,
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Text(
                                AppLocalizations.of(context).loading,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
