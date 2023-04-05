import 'dart:async';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart' as cardano;
import 'dart:math';
import 'package:algorand_dart/algorand_dart.dart' as algoRan;
import 'package:cryptowallet/api/notification_api.dart';
import 'package:cryptowallet/components/loader.dart';
import 'package:cryptowallet/config/colors.dart';
import 'package:cryptowallet/utils/app_config.dart';
import 'package:cryptowallet/utils/bitcoin_util.dart';
import 'package:cryptowallet/utils/format_money.dart';
import 'package:cryptowallet/utils/stellar_utils.dart';
import 'package:dartez/dartez.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:web3dart/web3dart.dart' as web3;
import 'package:web3dart/web3dart.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import '../utils/filecoin_util.dart';

class TransferToken extends StatefulWidget {
  final Map data;
  final String cryptoDomain;
  const TransferToken({Key key, this.data, this.cryptoDomain})
      : super(key: key);

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
  ContractAbi contrAbi;
  List _parameters;
  String mnemonic;

  @override
  void initState() {
    super.initState();
    mnemonic = Hive.box(secureStorageKey).get(currentMmenomicKey);
    isContract = widget.data['contractAddress'] != null;
    isBitcoinType = widget.data['POSNetwork'] != null;
    isSolana = widget.data['default'] == 'SOL';
    isCardano = widget.data['default'] == 'ADA';
    isFilecoin = widget.data['default'] == 'FIL';
    isStellar = widget.data['default'] == 'XLM';
    isCosmos = widget.data['default'] == 'ATOM';
    isAlgorand = widget.data['default'] == 'ALGO';
    isTron = widget.data['default'] == 'TRX';
    isTezor = widget.data['default'] == 'XTZ';
    isXRP = widget.data['default'] == 'XRP';
    isNFTTransfer = widget.data['isNFT'] != null;
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
          widget.data['rpc'],
          Client(),
        );

        Map response = await getEthereumFromMemnomic(
          mnemonic,
          widget.data['coinType'],
        );

        final sendingAddress = web3.EthereumAddress.fromHex(
          response['eth_wallet_address'],
        );

        if (!isNFTTransfer) {
          contrAbi = web3.ContractAbi.fromJson(
            erc20Abi,
            '',
          );
        } else if (widget.data['tokenType'] == 'ERC721') {
          contrAbi = web3.ContractAbi.fromJson(
            erc721Abi,
            '',
          );
        } else if (widget.data['tokenType'] == 'ERC1155') {
          contrAbi = web3.ContractAbi.fromJson(
            erc1155Abi,
            '',
          );
        }

        final contract = web3.DeployedContract(
          contrAbi,
          web3.EthereumAddress.fromHex(widget.data['contractAddress']),
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
            web3.EthereumAddress.fromHex(widget.data['recipient']),
            BigInt.parse(widget.data['amount']) *
                BigInt.from(pow(10, decimals.toInt()))
          ];
        } else if (widget.data['tokenType'] == 'ERC721') {
          _parameters = [
            sendingAddress,
            web3.EthereumAddress.fromHex(widget.data['recipient']),
            widget.data['tokenId']
          ];
        } else if (widget.data['tokenType'] == 'ERC1155') {
          _parameters = [
            sendingAddress,
            web3.EthereumAddress.fromHex(widget.data['recipient']),
            widget.data['tokenId'],
            BigInt.parse(widget.data['amount']),
            Uint8List(1)
          ];
        }

        Uint8List contractData = transfer.encodeCall(_parameters);

        final transactionFee = await getEtherTransactionFee(
          widget.data['rpc'],
          contractData,
          sendingAddress,
          web3.EthereumAddress.fromHex(
            widget.data['contractAddress'],
          ),
        );
        final userBalance =
            (await client.getBalance(sendingAddress)).getInWei.toDouble() /
                pow(10, etherDecimals);

        final blockChainCost = transactionFee / pow(10, etherDecimals);

        transactionFeeMap = {
          'transactionFee': blockChainCost,
          'userBalance': userBalance,
        };
      } else if (isBitcoinType) {
        final getBitcoinDetails = await getBitcoinFromMemnomic(
          mnemonic,
          widget.data,
        );
        final bitCoinBalance = await getBitcoinAddressBalance(
          getBitcoinDetails['address'],
          widget.data['POSNetwork'],
        );

        List getUnspentOutput;
        int fee = 0;
        int satoshiToSend =
            (double.parse(widget.data['amount']) * pow(10, 8)).toInt();

        if (widget.data['default'] == 'BCH') {
          fee = await getBCHNetworkFee(
            getBitcoinDetails['address'],
            widget.data,
            satoshiToSend,
          );
        } else {
          getUnspentOutput =
              await getUnspentTransactionBitcoinType(widget.data);
          fee = await getBitcoinTypeNetworkFee(satoshiToSend, getUnspentOutput);
        }

        double feeInBitcoin = fee / pow(10, bitCoinDecimals);

        transactionFeeMap = {
          'transactionFee': feeInBitcoin,
          'userBalance': bitCoinBalance,
        };
      } else if (isTron) {
        //FIXME:
        transactionFeeMap = {
          'transactionFee': 0,
          'userBalance': 0,
        };
      } else if (isTezor) {
        final getTrezorDetails =
            await getTezorFromMemnomic(mnemonic, widget.data);
        final tezorBalance = await getTezorAddressBalance(
          getTrezorDetails['address'],
          widget.data,
        );
        transactionFeeMap = {
          'transactionFee': 0,
          'userBalance': tezorBalance,
        };
      } else if (isXRP) {
        final getXRPDetails = await getXRPFromMemnomic(mnemonic);
        final xrpBalance = await getXRPAddressBalance(
          getXRPDetails['address'],
          widget.data['ws'],
        );
        transactionFeeMap = {
          'transactionFee': 0,
          'userBalance': xrpBalance,
        };
      } else if (isAlgorand) {
        final getAlgorandDetials = await getAlgorandFromMemnomic(
          mnemonic,
        );
        final algorandBalance = await getAlgorandAddressBalance(
          getAlgorandDetials['address'],
          widget.data['algoType'],
        );

        transactionFeeMap = {
          'transactionFee': 0.001,
          'userBalance': algorandBalance,
        };
      } else if (isSolana) {
        final getSolanaDetails = await getSolanaFromMemnomic(mnemonic);
        final solanaCoinBalance = await getSolanaAddressBalance(
          getSolanaDetails['address'],
          widget.data['solanaCluster'],
        );

        final fees = await getSolanaClient(widget.data['solanaCluster'])
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
          widget.data['cardano_network'],
        );
        final cardanoCoinBalance = await getCardanoAddressBalance(
          getCardanoDetails['address'],
          widget.data['cardano_network'],
          widget.data['blockFrostKey'],
        );

        final fees = maxFeeGuessForCardano / pow(10, cardanoDecimals);

        transactionFeeMap = {
          'transactionFee': fees,
          'userBalance': cardanoCoinBalance,
        };
      } else if (isFilecoin) {
        final getFileCoinDetails = await getFileCoinFromMemnomic(
          mnemonic,
          widget.data['prefix'],
        );
        print(getFileCoinDetails);
        final fileCoinBalance = await getFileCoinAddressBalance(
          getFileCoinDetails['address'],
          baseUrl: widget.data['baseUrl'],
        );

        final nonce = await getFileCoinNonce(
          widget.data['prefix'],
          widget.data['baseUrl'],
        );

        BigInt amounToSend = BigInt.parse(
              widget.data['amount'],
            ) *
            BigInt.from(pow(10, fileCoinDecimals));

        final msg = constructFilecoinMsg(
          widget.data['recipient'],
          getFileCoinDetails['address'],
          nonce,
          amounToSend,
        );
        print('msg gotten');
        final gasFromNetwork = await fileCoinEstimateMessageGas(
          widget.data['prefix'],
          widget.data['baseUrl'],
          msg,
        );

        print(gasFromNetwork);

        final feePlusPremium = double.parse(gasFromNetwork['GasPremium']) +
            double.parse(gasFromNetwork['GasFeeCap']);
        final fees = (feePlusPremium * gasFromNetwork['GasLimit']) /
            pow(10, fileCoinDecimals);

        transactionFeeMap = {
          'transactionFee': fees,
          'userBalance': fileCoinBalance,
        };
      } else if (isStellar) {
        final getStellarDetails = await getStellarFromMemnomic(mnemonic);

        final stellarBalance = await getStellarAddressBalance(
          getStellarDetails['address'],
          widget.data['sdk'],
          widget.data['cluster'],
        );

        final fees = await getStellarGas(
          widget.data['recipient'],
          widget.data['amount'],
          widget.data['sdk'],
        );

        transactionFeeMap = {
          'transactionFee': fees,
          'userBalance': stellarBalance,
        };
      } else if (isCosmos) {
        final getCosmosDetails = await getCosmosFromMemnomic(
          mnemonic,
          widget.data['bech32Hrp'],
          widget.data['lcdUrl'],
        );

        final cosmosBalance = await getCosmosAddressBalance(
          getCosmosDetails['address'],
          widget.data['lcdUrl'],
        );
        transactionFeeMap = {
          'transactionFee': 0.001,
          'userBalance': cosmosBalance,
        };
      } else {
        final response = await getEthereumFromMemnomic(
          mnemonic,
          widget.data['coinType'],
        );
        final client = web3.Web3Client(
          widget.data['rpc'],
          Client(),
        );

        final transactionFee = await getEtherTransactionFee(
          widget.data['rpc'],
          null,
          web3.EthereumAddress.fromHex(
            response['eth_wallet_address'],
          ),
          web3.EthereumAddress.fromHex(
            widget.data['recipient'],
          ),
        );

        final userBalance = (await client.getBalance(
                    EthereumAddress.fromHex(response['eth_wallet_address'])))
                .getInWei
                .toDouble() /
            pow(10, etherDecimals);

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
                    '-${formatMoney(widget.data['amount'] ?? '1')} ${isContract ? ellipsify(str: widget.data['symbol']) : widget.data['symbol']}',
                    style: const TextStyle(
                        fontSize: 25, fontWeight: FontWeight.bold),
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
                    '${isContract ? ellipsify(str: widget.data['name']) : widget.data['name']} (${isContract ? ellipsify(str: widget.data['symbol']) : widget.data['symbol']})',
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
                        widget.data,
                      );
                      return {'address': getPOSblockchainDetails['address']};
                    } else if (isSolana) {
                      final getSolanaDetails =
                          await getSolanaFromMemnomic(mnemonic);
                      return {'address': getSolanaDetails['address']};
                    } else if (isCardano) {
                      final getCardanoDetails = await getCardanoFromMemnomic(
                        mnemonic,
                        widget.data['cardano_network'],
                      );
                      return {'address': getCardanoDetails['address']};
                    } else if (isTezor) {
                      final getTezorDetails = await getTezorFromMemnomic(
                        mnemonic,
                        widget.data,
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
                        widget.data['prefix'],
                      );
                      return {'address': getFileCoinDetails['address']};
                    } else if (isStellar) {
                      final getStellarDetails =
                          await getStellarFromMemnomic(mnemonic);
                      return {'address': getStellarDetails['address']};
                    } else if (isCosmos) {
                      final getCosmosDetails = await getCosmosFromMemnomic(
                        mnemonic,
                        widget.data['bech32Hrp'],
                        widget.data['lcdUrl'],
                      );
                      return {'address': getCosmosDetails['address']};
                    } else {
                      return {
                        'address': (await getEthereumFromMemnomic(
                          mnemonic,
                          widget.data['coinType'],
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
                        ? '${widget.cryptoDomain} (${widget.data['recipient']})'
                        : widget.data['recipient'],
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
                      widget.data['tokenId'].toString(),
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
                  widget.data['default'] != null
                      ? Text(
                          '${transactionFeeMap != null ? transactionFeeMap['transactionFee'] : '0'}  ${widget.data['default']}',
                          style: const TextStyle(fontSize: 16),
                        )
                      : Container(),
                  widget.data['network'] != null
                      ? Text(
                          '${transactionFeeMap != null ? transactionFeeMap['transactionFee'] : '0'}  ${getEVMBlockchains()[widget.data['network']]['symbol']}',
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
                                      setState(() {
                                        isSending = true;
                                      });
                                      try {
                                        final pref = Hive.box(secureStorageKey);

                                        String userAddress;
                                        String transactionHash;
                                        int coinDecimals;
                                        String userTransactionsKey;
                                        if (isContract) {
                                          final client = web3.Web3Client(
                                            widget.data['rpc'],
                                            Client(),
                                          );

                                          Map response =
                                              await getEthereumFromMemnomic(
                                            mnemonic,
                                            widget.data['coinType'],
                                          );
                                          final credentials =
                                              EthPrivateKey.fromHex(
                                            response['eth_wallet_privateKey'],
                                          );

                                          final contract =
                                              web3.DeployedContract(
                                            contrAbi,
                                            web3.EthereumAddress.fromHex(
                                              widget.data['contractAddress'],
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
                                            chainId: widget.data['chainId'],
                                          );

                                          transactionHash = await client
                                              .sendRawTransaction(trans);

                                          userAddress =
                                              response['eth_wallet_address'];

                                          userTransactionsKey =
                                              '${widget.data['contractAddress']}${widget.data['rpc']} Details';

                                          await client.dispose();
                                        } else if (isBitcoinType) {
                                          final getBitCoinDetails =
                                              await getBitcoinFromMemnomic(
                                            mnemonic,
                                            widget.data,
                                          );

                                          double amount = double.parse(
                                            widget.data['amount'],
                                          );
                                          int amountToSend = (amount *
                                                  pow(10, bitCoinDecimals))
                                              .toInt();

                                          final transaction = await sendBTCType(
                                            widget.data['recipient'],
                                            amountToSend,
                                            widget.data,
                                          );
                                          transactionHash = transaction['txid'];

                                          coinDecimals = bitCoinDecimals;
                                          userAddress =
                                              getBitCoinDetails['address'];

                                          userTransactionsKey =
                                              '${widget.data['default']} Details';
                                        } else if (isTezor) {
                                          final getTezorDetails =
                                              await getTezorFromMemnomic(
                                            mnemonic,
                                            widget.data,
                                          );

                                          final keyStore = KeyStoreModel(
                                            publicKey:
                                                getTezorDetails['public_key'],
                                            secretKey:
                                                getTezorDetails['private_key'],
                                            publicKeyHash:
                                                getTezorDetails['address'],
                                          );

                                          final signer = Dartez.createSigner(
                                            Dartez.writeKeyWithHint(
                                                keyStore.secretKey, 'edsk'),
                                          );

                                          final result = await Dartez
                                              .sendTransactionOperation(
                                            widget.data['server'],
                                            signer,
                                            keyStore,
                                            widget.data['recipient'],
                                            (double.parse(
                                                        widget.data['amount']) *
                                                    pow(10, tezorDecimals))
                                                .toInt(),
                                            1500,
                                          );
                                          transactionHash = Map.from(
                                              result)['operationGroupID'];

                                          transactionHash = transactionHash
                                              .replaceAll('\n', '');

                                          coinDecimals = tezorDecimals;
                                          userAddress =
                                              getTezorDetails['address'];

                                          userTransactionsKey =
                                              '${widget.data['default']} Details';
                                        } else if (isXRP) {
                                          final getXRPDetails =
                                              await getXRPFromMemnomic(
                                            mnemonic,
                                          );
                                          Map transaction = await sendXRP(
                                            ws: widget.data['ws'],
                                            recipient: widget.data['recipient'],
                                            amount: widget.data['amount'],
                                            mnemonic: mnemonic,
                                          );
                                          transactionHash = transaction['txid'];

                                          coinDecimals = xrpDecimals;
                                          userAddress =
                                              getXRPDetails['address'];
                                          userTransactionsKey =
                                              '${widget.data['default']} Details';
                                        } else if (isAlgorand) {
                                          final getAlgorandDetails =
                                              await getAlgorandFromMemnomic(
                                                  mnemonic);

                                          Map transaction = await sendAlgorand(
                                            widget.data['recipient'],
                                            widget.data['algoType'],
                                            algoRan.Algo.toMicroAlgos(
                                              double.parse(
                                                widget.data['amount'],
                                              ),
                                            ),
                                          );
                                          transactionHash = transaction['txid'];

                                          coinDecimals = algorandDecimals;
                                          userAddress =
                                              getAlgorandDetails['address'];
                                          userTransactionsKey =
                                              '${widget.data['default']} Details';
                                        } else if (isSolana) {
                                          final getSolanaDetails =
                                              await getSolanaFromMemnomic(
                                                  mnemonic);

                                          final transaction = await sendSolana(
                                            widget.data['recipient'],
                                            (double.parse(
                                                        widget.data['amount']) *
                                                    pow(10, solanaDecimals))
                                                .toInt(),
                                            widget.data['solanaCluster'],
                                          );
                                          transactionHash = transaction['txid'];

                                          coinDecimals = solanaDecimals;
                                          userAddress =
                                              getSolanaDetails['address'];
                                          userTransactionsKey =
                                              '${widget.data['default']} Details';
                                        } else if (isCardano) {
                                          final getCardanoDetails =
                                              await getCardanoFromMemnomic(
                                            mnemonic,
                                            widget.data['cardano_network'],
                                          );

                                          double amount = double.parse(
                                            widget.data['amount'],
                                          );

                                          int amountToSend = (amount *
                                                  pow(10, cardanoDecimals))
                                              .toInt();
                                          final transaction = await compute(
                                            sendCardano,
                                            {
                                              'cardanoNetwork': widget
                                                  .data['cardano_network'],
                                              'blockfrostForCardanoApiKey':
                                                  widget.data['blockFrostKey'],
                                              'mnemonic': mnemonic,
                                              'lovelaceToSend': amountToSend,
                                              'senderAddress': cardano
                                                  .ShelleyAddress.fromBech32(
                                                getCardanoDetails['address'],
                                              ),
                                              'recipientAddress': cardano
                                                  .ShelleyAddress.fromBech32(
                                                widget.data['recipient'],
                                              )
                                            },
                                          );
                                          transactionHash = transaction['txid'];

                                          coinDecimals = cardanoDecimals;
                                          userAddress =
                                              getCardanoDetails['address'];
                                          userTransactionsKey =
                                              '${widget.data['default']} Details';
                                        } else if (isFilecoin) {
                                          final getFileCoinDetails =
                                              await getFileCoinFromMemnomic(
                                            mnemonic,
                                            widget.data['prefix'],
                                          );

                                          double amount = double.parse(
                                            widget.data['amount'],
                                          );

                                          BigInt amounToSend = BigInt.from(
                                                amount,
                                              ) *
                                              BigInt.from(
                                                  pow(10, fileCoinDecimals));

                                          final transaction =
                                              await sendFilecoin(
                                            widget.data['recipient'],
                                            amounToSend,
                                            baseUrl: widget.data['baseUrl'],
                                            addressPrefix:
                                                widget.data['prefix'],
                                          );
                                          transactionHash = transaction['txid'];

                                          coinDecimals = fileCoinDecimals;
                                          userAddress =
                                              getFileCoinDetails['address'];
                                          userTransactionsKey =
                                              '${widget.data['default']} Details';
                                        } else if (isStellar) {
                                          Map getStellarDetails =
                                              await getStellarFromMemnomic(
                                            mnemonic,
                                          );

                                          final transaction = await sendStellar(
                                            widget.data['recipient'],
                                            widget.data['amount'],
                                            widget.data['sdk'],
                                            widget.data['cluster'],
                                          );
                                          transactionHash = transaction['txid'];

                                          coinDecimals = stellarDecimals;
                                          userAddress =
                                              getStellarDetails['address'];
                                          userTransactionsKey =
                                              '${widget.data['default']} Details';
                                        } else if (isCosmos) {
                                          Map getCosmosDetails =
                                              await getCosmosFromMemnomic(
                                            mnemonic,
                                            widget.data['bech32Hrp'],
                                            widget.data['lcdUrl'],
                                          );

                                          final uatomToSend = double.parse(
                                                  widget.data['amount']) *
                                              pow(10, cosmosDecimals);

                                          final transaction =
                                              await compute(sendCosmos, {
                                            'bech32Hrp':
                                                widget.data['bech32Hrp'],
                                            'lcdUrl': widget.data['lcdUrl'],
                                            'mnemonic': mnemonic,
                                            'recipientAddress':
                                                widget.data['recipient'],
                                            'uatomToSend':
                                                uatomToSend.toInt().toString()
                                          });
                                          transactionHash = transaction['txid'];

                                          coinDecimals = cosmosDecimals;
                                          userAddress =
                                              getCosmosDetails['address'];
                                          userTransactionsKey =
                                              '${widget.data['default']} Details';
                                        } else {
                                          final client = web3.Web3Client(
                                            widget.data['rpc'],
                                            Client(),
                                          );

                                          final response =
                                              await getEthereumFromMemnomic(
                                            mnemonic,
                                            widget.data['coinType'],
                                          );

                                          final credentials =
                                              EthPrivateKey.fromHex(
                                            response['eth_wallet_privateKey'],
                                          );
                                          final gasPrice =
                                              await client.getGasPrice();

                                          final trans =
                                              await client.signTransaction(
                                            credentials,
                                            web3.Transaction(
                                              from: web3.EthereumAddress
                                                  .fromHex(response[
                                                      'eth_wallet_address']),
                                              to: web3.EthereumAddress.fromHex(
                                                  widget.data['recipient']),
                                              value: web3.EtherAmount.inWei(
                                                  BigInt.from(double.parse(
                                                          widget.data[
                                                              'amount'])) *
                                                      BigInt.from(pow(
                                                          10, etherDecimals))),
                                              gasPrice: gasPrice,
                                            ),
                                            chainId: widget.data['chainId'],
                                          );

                                          transactionHash = await client
                                              .sendRawTransaction(trans);

                                          coinDecimals = etherDecimals;
                                          userAddress =
                                              response['eth_wallet_address'];
                                          userTransactionsKey =
                                              '${widget.data['default']}${widget.data['rpc']} Details';

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
                                            ? widget.data['tokenId'].toString()
                                            : widget.data['amount'];

                                        NotificationApi.showNotification(
                                          title:
                                              '${widget.data['symbol']} Sent',
                                          body:
                                              '$tokenSent ${widget.data['symbol']} sent to ${widget.data['recipient']}',
                                        );

                                        if (isNFTTransfer) {
                                          setState(() {
                                            isSending = false;
                                          });
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
                                          'to': widget.data['recipient'],
                                          'value': double.parse(
                                                widget.data['amount'],
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
                                        setState(() {
                                          isSending = false;
                                        });
                                        if (Navigator.canPop(context)) {
                                          int count = 0;
                                          Navigator.popUntil(context, (route) {
                                            return count++ == 3;
                                          });
                                        }
                                      } catch (e) {
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
