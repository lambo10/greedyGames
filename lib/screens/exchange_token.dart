import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cryptowallet/components/user_balance.dart';
import 'package:cryptowallet/utils/format_money.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import '../coins/eth_contract_coin.dart';
import '../coins/ethereum_coin.dart';
import '../components/loader.dart';
import '../config/colors.dart';
import '../config/styles.dart';
import '../utils/app_config.dart';
import 'package:web3dart/web3dart.dart' as web3;
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class ExchangeToken extends StatefulWidget {
  const ExchangeToken({Key key}) : super(key: key);
  @override
  _ExchangeTokenState createState() => _ExchangeTokenState();
}

class _ExchangeTokenState extends State<ExchangeToken>
    with AutomaticKeepAliveClientMixin {
  bool isLoading = false;
  bool tokenPayLoading = false;
  bool tokenGetLoading = false;
  String error = '';
  final amountPay = TextEditingController()..text = '1';
  final networks = getEVMBlockchains();
  String network;
  String currentSelectedTokenPay = 'ETH';
  String currentSelectedTokenGet = 'ETH';
  String payAddress = nativeTokenAddress;
  String getAddress = nativeTokenAddress;
  Map tokenList;
  final mnemonic = Hive.box(secureStorageKey).get(currentMmenomicKey);
  Map selectedItemPay = {};
  Map selectedItemGet = {};
  String networkImage;
  Map networkBalanceInfo;
  double tokenToGet_;
  final nativeTokenLCase = nativeTokenAddress.toLowerCase();
  Map payDetails;
  Map getDetails;

  bool dataLoading = false;
  Timer timer;

  @override
  void dispose() {
    timer?.cancel();
    amountPay.dispose();
    super.dispose();
  }

  Future getAllExchangeToken() async {
    if (mounted) {
      setState(() {
        dataLoading = true;
      });
    }

    await userPayDetails();
    await userGetDetails();
    await evmBalance();
    await tokenToGet();
    if (mounted) {
      setState(() {
        dataLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    network = networks[0]['Ethereum']['name'];
    getAllExchangeToken();
    timer = Timer.periodic(
      httpPollingDelay,
      (Timer t) async => await getAllExchangeToken(),
    );
    networkImage = getEVMBlockchains()[0]['image'];
  }

  Future userGetDetails() async {
    try {
      double cryptoBalance = 0;

      if (selectedItemGet.values.isEmpty) {
        tokenList = await get1InchUrlList(1);
        selectedItemGet = tokenList[nativeTokenLCase];
      }

      final Map evmNetwork = getEVMBlockchains().firstWhere(
        (e) => e['name'] == network,
      );
      if (selectedItemGet['address'].toString().toLowerCase() ==
          nativeTokenLCase) {
        final EthereumCoin coin = EthereumCoin.fromJson(evmNetwork);
        cryptoBalance = await coin.getBalance(false);
      } else {
        cryptoBalance = await getERC20TokenBalance({
          'contractAddress': selectedItemGet['address'],
          'rpc': evmNetwork['rpc'],
          'chainId': evmNetwork['chainId'],
          'coinType': evmNetwork['coinType'],
        });
      }

      getDetails = {
        'balance': cryptoBalance,
        'symbol': selectedItemGet['symbol']
      };
      setState(() {});
    } catch (_) {}
  }

  Future userPayDetails() async {
    try {
      double cryptoBalance = 0;
      final Map networkDetails = getEVMBlockchains().firstWhere(
        (e) => e['name'] == network,
      );
      final EthereumCoin coin = EthereumCoin.fromJson(networkDetails);
      if (selectedItemPay.values.isEmpty) {
        tokenList = await get1InchUrlList(1);
        selectedItemPay = tokenList[nativeTokenLCase];
      }

      if (selectedItemPay['address'].toString().toLowerCase() ==
          nativeTokenLCase) {
        cryptoBalance = await coin.getBalance(false);
      } else {
        cryptoBalance = await getERC20TokenBalance({
          'contractAddress': selectedItemPay['address'],
          'rpc': networkDetails['rpc'],
          'chainId': networkDetails['chainId'],
          'coinType': networkDetails['coinType']
        });
      }
      payDetails = {
        'balance': cryptoBalance,
        'symbol': selectedItemPay['symbol']
      };
      setState(() {});
    } catch (_) {}
  }

  Future tokenToGet() async {
    final Map networkDetails = getEVMBlockchains().firstWhere(
      (e) => e['name'] == network,
    );
    final EthereumCoin coin = EthereumCoin.fromJson(networkDetails);
    try {
      if (selectedItemPay.values.isEmpty) {
        tokenList = await get1InchUrlList(1);
        selectedItemPay = selectedItemGet = tokenList[nativeTokenLCase];
      }
      if (selectedItemGet.values.isEmpty) {
        tokenList = await get1InchUrlList(1);
        selectedItemGet = selectedItemGet = tokenList[nativeTokenLCase];
      }

      final response = await coin.fromMnemonic(mnemonic);

      double amountPaying = double.tryParse(amountPay.text);

      if (amountPaying != null) {
        amountPaying *= pow(10, selectedItemPay['decimals']);

        Map transactionData = await oneInchSwapUrlResponse(
          fromTokenAddress: selectedItemPay['address'],
          toTokenAddress: selectedItemGet['address'],
          amountInWei: amountPaying,
          fromAddress: response['address'],
          slippage: 0.1,
          chainId: networkDetails['chainId'],
        );

        if (transactionData != null) {
          final tokenToGet = double.parse(transactionData['toTokenAmount']) /
              pow(10, transactionData['toToken']['decimals']);

          tokenToGet_ = tokenToGet;
        } else {
          tokenToGet_ = 0;
        }
      }
      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future evmBalance() async {
    final Map networkDetails = getEVMBlockchains().firstWhere(
      (e) => e['name'] == network,
    );
    final EthereumCoin coin = EthereumCoin.fromJson(networkDetails);
    try {
      final cryptoBalance = await coin.getBalance(false);

      networkBalanceInfo = {
        'balance': cryptoBalance,
        'symbol': networkDetails['symbol']
      };
      setState(() {});
    } catch (_) {}
  }

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
          child: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 2));
          setState(() {});
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 20,
                ),
                Text(
                  AppLocalizations.of(context).swap,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 24),
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context).network,
                      style: const TextStyle(
                        fontSize: 20,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        final Map networkDetails =
                            getEVMBlockchains().firstWhere(
                          (e) => e['name'] == network,
                        );
                        showBlockChainDialog(
                          context: context,
                          onTap: (blockChainData) async {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();

                            try {
                              tokenList = await get1InchUrlList(
                                blockChainData['chainId'],
                              );

                              if (tokenList[nativeTokenLCase] == null) return;

                              network = blockChainData['name'];
                              networkImage = blockChainData['image'];
                              selectedItemPay =
                                  selectedItemGet = tokenList[nativeTokenLCase];
                              final Map networkDetails =
                                  getEVMBlockchains().firstWhere(
                                (e) => e['name'] == network,
                              );
                              currentSelectedTokenPay =
                                  currentSelectedTokenGet =
                                      networkDetails['symbol'];
                              amountPay.text = '0';

                              try {
                                await getAllExchangeToken();
                              } catch (_) {}
                              setState(() {});
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text(
                                    AppLocalizations.of(context)
                                        .networkNotSupported,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            }
                          },
                          selectedChainId: networkDetails['chainId'],
                        );
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundImage: AssetImage(
                          networkImage ?? '',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Column(
                  children: [
                    SizedBox(
                      height: 300,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Positioned(
                            top: 0,
                            left: 0,
                            child: SizedBox(
                              height: 150,
                              width: MediaQuery.of(context).size.width * .9,
                              child: Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 15, bottom: 20),
                                      child: Column(
                                        children: [
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 10),
                                                child: Text(
                                                    AppLocalizations.of(context)
                                                        .from,
                                                    style:
                                                        s12_18_agSemiboldGrey),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 10),
                                                      child: SizedBox(
                                                        width: double.infinity,
                                                        child: TextFormField(
                                                          onChanged:
                                                              (value) async {
                                                            await getAllExchangeToken();
                                                            setState(() {});
                                                          },
                                                          keyboardType:
                                                              const TextInputType
                                                                  .numberWithOptions(
                                                            decimal: true,
                                                          ),
                                                          style: h5,
                                                          decoration:
                                                              const InputDecoration(
                                                            isDense: true,
                                                            isCollapsed: true,
                                                            border: InputBorder
                                                                .none,
                                                          ),
                                                          controller: amountPay,
                                                        ),
                                                      )),
                                                ),
                                                GestureDetector(
                                                  onTap: () async {
                                                    FocusManager
                                                        .instance.primaryFocus
                                                        ?.unfocus();

                                                    if (tokenPayLoading) return;
                                                    tokenPayLoading = true;
                                                    try {
                                                      tokenList ??=
                                                          await get1InchUrlList(
                                                              1);

                                                      buildSwapUi(
                                                        tokenList: tokenList
                                                            .values
                                                            .toList(),
                                                        context: context,
                                                        onSelect:
                                                            (value) async {
                                                          setState(() {
                                                            selectedItemPay =
                                                                value;
                                                          });
                                                          await getAllExchangeToken();
                                                        },
                                                      );
                                                    } catch (_) {}
                                                    tokenPayLoading = false;
                                                  },
                                                  child: Container(
                                                    color: Colors.transparent,
                                                    child: Row(
                                                      children: [
                                                        CachedNetworkImage(
                                                          imageUrl: ipfsTohttp(
                                                            selectedItemPay[
                                                                    'logoURI'] ??
                                                                'https://tokens.1inch.io/$nativeTokenLCase.png',
                                                          ),
                                                          width: 30,
                                                          height: 30,
                                                          placeholder:
                                                              (context, url) =>
                                                                  Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: const [
                                                              SizedBox(
                                                                width: 20,
                                                                height: 20,
                                                                child: Loader(
                                                                  color:
                                                                      appPrimaryColor,
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              const Icon(
                                                            Icons.error,
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 5,
                                                        ),
                                                        Text(
                                                          ellipsify(
                                                            str: selectedItemPay[
                                                                    'symbol'] ??
                                                                'ETH',
                                                          ),
                                                          style: m_agRegular,
                                                        ),
                                                        const SizedBox(
                                                          width: 5,
                                                        ),
                                                        const Icon(
                                                          Icons
                                                              .arrow_forward_ios,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                              ]),
                                          Row(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 10),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      '${AppLocalizations.of(context).balance}: ',
                                                      style: m_agRegular_grey,
                                                    ),
                                                    if (payDetails != null)
                                                      UserBalance(
                                                        symbol: payDetails[
                                                            'symbol'],
                                                        balance: payDetails[
                                                            'balance'],
                                                        textStyle:
                                                            m_agRegular_grey,
                                                      )
                                                    else
                                                      Container()
                                                  ],
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  )),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: SizedBox(
                              height: 150,
                              width: MediaQuery.of(context).size.width * .9,
                              child: Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 20, bottom: 20),
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 10),
                                              child: Text(
                                                  AppLocalizations.of(context)
                                                      .to,
                                                  style: s12_18_agSemiboldGrey),
                                            ),
                                            const Padding(
                                              padding:
                                                  EdgeInsets.only(right: 10),
                                              child: Text('', style: s_normal),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 10),
                                                  child: tokenToGet_ != null
                                                      ? Text(
                                                          '${formatMoney(tokenToGet_)}',
                                                          style: h5,
                                                        )
                                                      : const SizedBox(
                                                          width: 25,
                                                          height: 25,
                                                          child: Loader(
                                                            color:
                                                                appPrimaryColor,
                                                          ),
                                                        ),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () async {
                                                  FocusManager
                                                      .instance.primaryFocus
                                                      ?.unfocus();
                                                  if (tokenGetLoading) return;
                                                  tokenGetLoading = true;
                                                  try {
                                                    tokenList ??=
                                                        await get1InchUrlList(
                                                            1);

                                                    buildSwapUi(
                                                      tokenList: tokenList
                                                          .values
                                                          .toList(),
                                                      context: context,
                                                      onSelect: (value) async {
                                                        setState(() {
                                                          selectedItemGet =
                                                              value;
                                                        });
                                                        await getAllExchangeToken();
                                                      },
                                                    );
                                                  } catch (_) {}
                                                  tokenGetLoading = false;
                                                },
                                                child: Container(
                                                  color: Colors.transparent,
                                                  child: Row(
                                                    children: [
                                                      CachedNetworkImage(
                                                        imageUrl: ipfsTohttp(
                                                          selectedItemGet[
                                                                  'logoURI'] ??
                                                              'https://tokens.1inch.io/$nativeTokenLCase.png',
                                                        ),
                                                        placeholder:
                                                            (context, url) =>
                                                                Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: const [
                                                            SizedBox(
                                                              width: 20,
                                                              height: 20,
                                                              child: Loader(
                                                                color:
                                                                    appPrimaryColor,
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                        errorWidget: (context,
                                                                url, error) =>
                                                            const Icon(
                                                          Icons.error,
                                                          color: Colors.red,
                                                        ),
                                                        width: 30,
                                                        height: 30,
                                                      ),
                                                      const SizedBox(
                                                        width: 5,
                                                      ),
                                                      Text(
                                                        ellipsify(
                                                          str: selectedItemGet[
                                                                  'symbol'] ??
                                                              'ETH',
                                                        ),
                                                        style: m_agRegular,
                                                      ),
                                                      const SizedBox(
                                                        width: 5,
                                                      ),
                                                      const Icon(
                                                        Icons.arrow_forward_ios,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            ]),
                                        Row(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 10),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    '${AppLocalizations.of(context).balance}: ',
                                                    style: m_agRegular_grey,
                                                  ),
                                                  if (getDetails != null)
                                                    UserBalance(
                                                      symbol:
                                                          getDetails['symbol'],
                                                      balance:
                                                          getDetails['balance'],
                                                      textStyle:
                                                          m_agRegular_grey,
                                                    )
                                                  else
                                                    Container()
                                                ],
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            top: 0,
                            right: 30,
                            child: SizedBox(
                              width: 35,
                              height: 35,
                              child: GestureDetector(
                                onTap: () async {
                                  if (selectedItemGet.isNotEmpty &&
                                      selectedItemPay.isNotEmpty) {
                                    setState(() {
                                      final selectedToGet_ = selectedItemGet;
                                      selectedItemGet = selectedItemPay;
                                      selectedItemPay = selectedToGet_;
                                    });
                                  }
                                  await getAllExchangeToken();
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: appPrimaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Transform.rotate(
                                    angle: 90 / (180 / pi),
                                    child: const Icon(
                                      FontAwesomeIcons.exchangeAlt,
                                      color: Colors.white,
                                      size: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    if (networkBalanceInfo != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Loader(
                            size: 15,
                            color: dataLoading ? null : Colors.transparent,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(
                            '${AppLocalizations.of(context).networkBalance}: ',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          UserBalance(
                            balance: networkBalanceInfo['balance'],
                            symbol: networkBalanceInfo['symbol'],
                            textStyle: const TextStyle(color: Colors.grey),
                          ),
                          const Loader(
                            size: 15,
                            color: Colors.transparent,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                        ],
                      )
                    else
                      Container(),
                    const SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith(
                              (states) => appBackgroundblue),
                          shape: MaterialStateProperty.resolveWith(
                            (states) => RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        onPressed: () async {
                          if (isLoading) return;
                          FocusManager.instance.primaryFocus?.unfocus();
                          final Map evmDetails = getEVMBlockchains().firstWhere(
                            (e) => e['name'] == network,
                          );
                          final EthereumCoin coin =
                              EthereumCoin.fromJson(evmDetails);
                          try {
                            setState(() {
                              isLoading = true;
                            });

                            ScaffoldMessenger.of(context).hideCurrentSnackBar();

                            final response = await coin.fromMnemonic(mnemonic);

                            if (selectedItemPay.values.isEmpty) {
                              tokenList = await get1InchUrlList(1);
                              selectedItemPay =
                                  selectedItemGet = tokenList[nativeTokenLCase];
                            }
                            if (selectedItemGet.values.isEmpty) {
                              tokenList = await get1InchUrlList(1);
                              selectedItemGet =
                                  selectedItemGet = tokenList[nativeTokenLCase];
                            }

                            double amountToPay =
                                double.tryParse(amountPay.text);

                            if (amountToPay == null || amountToPay == 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text(
                                    AppLocalizations.of(context)
                                        .pleaseEnterAmount,
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                              setState(() {
                                isLoading = false;
                              });
                              return;
                            }

                            String payingContract = selectedItemPay['address'];
                            payingContract = payingContract.toLowerCase();

                            String getContract = selectedItemGet['address'];
                            getContract = getContract.toLowerCase();

                            if (payingContract == getContract) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text(
                                    AppLocalizations.of(context)
                                        .pleaseSelectDifferentTokens,
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                              setState(() {
                                isLoading = false;
                              });
                              return;
                            }

                            double amountInWei_ = amountToPay *
                                pow(10, selectedItemPay['decimals']);

                            Map swapOneInch = await oneInchSwapUrlResponse(
                              fromTokenAddress: payingContract,
                              toTokenAddress: getContract,
                              amountInWei: amountInWei_,
                              fromAddress: response['address'],
                              slippage: 0.1,
                              chainId: evmDetails['chainId'],
                            );

                            if (swapOneInch == null) {
                              throw Exception(
                                AppLocalizations.of(context)
                                    .insufficientLiquidity,
                              );
                            }

                            if (payingContract != nativeTokenLCase) {
                              BigInt allowance = await getErc20Allowance(
                                owner: response['address'],
                                rpc: evmDetails['rpc'],
                                contractAddress: payingContract,
                                spender: swapOneInch['tx']['to'],
                              );

                              if (allowance < BigInt.from(amountInWei_)) {
                                Map approve1inch = await approveTokenFor1inch(
                                  evmDetails['chainId'],
                                  amountInWei_,
                                  payingContract,
                                );

                                await signTransaction(
                                  gasPriceInWei_: approve1inch['gasPrice'],
                                  to: approve1inch['to'],
                                  from: response['address'],
                                  txData: approve1inch['data'],
                                  valueInWei_: approve1inch['value'],
                                  gasInWei_: null,
                                  networkIcon: null,
                                  context: context,
                                  blockChainCurrencySymbol:
                                      evmDetails['symbol'],
                                  name: '',
                                  onConfirm: () async {
                                    try {
                                      final client = web3.Web3Client(
                                        evmDetails['rpc'],
                                        Client(),
                                      );

                                      final credentials =
                                          web3.EthPrivateKey.fromHex(
                                        response['privateKey'],
                                      );
                                      final approveTrx =
                                          await client.signTransaction(
                                        credentials,
                                        web3.Transaction(
                                          from: web3.EthereumAddress.fromHex(
                                            response['address'],
                                          ),
                                          to: web3.EthereumAddress.fromHex(
                                            approve1inch['to'],
                                          ),
                                          value: web3.EtherAmount.inWei(
                                            BigInt.parse(
                                              approve1inch['value'],
                                            ),
                                          ),
                                          gasPrice: web3.EtherAmount.inWei(
                                            BigInt.parse(
                                              approve1inch['gasPrice'],
                                            ),
                                          ),
                                          data: txDataToUintList(
                                            approve1inch['data'],
                                          ),
                                        ),
                                        chainId: evmDetails['chainId'],
                                      );

                                      await client
                                          .sendRawTransaction(approveTrx);

                                      await client.dispose();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(context)
                                                .trxSent,
                                          ),
                                        ),
                                      );
                                    } catch (e) {
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
                                    } finally {
                                      if (Navigator.canPop(context)) {
                                        Navigator.pop(context);
                                      }
                                    }
                                  },
                                  onReject: () async {
                                    if (Navigator.canPop(context)) {
                                      Navigator.pop(context);
                                    }
                                  },
                                  title: 'Sign Transaction',
                                  chainId: evmDetails['chainId'],
                                );

                                setState(() {
                                  isLoading = false;
                                });
                                return;
                              }
                            }

                            await signTransaction(
                              gasPriceInWei_: swapOneInch['tx']['gasPrice'],
                              to: swapOneInch['tx']['to'],
                              from: swapOneInch['tx']['from'],
                              txData: swapOneInch['tx']['data'],
                              valueInWei_: swapOneInch['tx']['value'],
                              gasInWei_: null,
                              networkIcon: null,
                              context: context,
                              blockChainCurrencySymbol: evmDetails['symbol'],
                              name: '',
                              onConfirm: () async {
                                try {
                                  final client = web3.Web3Client(
                                    evmDetails['rpc'],
                                    Client(),
                                  );

                                  final credentials =
                                      web3.EthPrivateKey.fromHex(
                                    response['privateKey'],
                                  );
                                  final swapTrx = await client.signTransaction(
                                    credentials,
                                    web3.Transaction(
                                      from: web3.EthereumAddress.fromHex(
                                        swapOneInch['tx']['from'],
                                      ),
                                      to: web3.EthereumAddress.fromHex(
                                          swapOneInch['tx']['to']),
                                      value: web3.EtherAmount.inWei(
                                        BigInt.parse(
                                            swapOneInch['tx']['value']),
                                      ),
                                      gasPrice: web3.EtherAmount.inWei(
                                        BigInt.parse(
                                          swapOneInch['tx']['gasPrice'],
                                        ),
                                      ),
                                      data: txDataToUintList(
                                        swapOneInch['tx']['data'],
                                      ),
                                    ),
                                    chainId: evmDetails['chainId'],
                                  );

                                  await client.sendRawTransaction(swapTrx);

                                  await client.dispose();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(context).trxSent,
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.red,
                                      content: Text(
                                        e.toString(),
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                  );
                                } finally {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                }
                              },
                              onReject: () async {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }
                              },
                              title: 'Sign Transaction',
                              chainId: evmDetails['chainId'],
                            );

                            setState(() {
                              isLoading = false;
                            });
                          } catch (e) {
                            if (kDebugMode) {
                              print(e);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red,
                                content: Text(
                                  e.toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            );

                            setState(() {
                              isLoading = false;
                            });
                          }
                        },
                        child: isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Loader(color: white),
                              )
                            : Padding(
                                padding: const EdgeInsets.all(15),
                                child: Text(
                                  AppLocalizations.of(context).swap,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      )),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
