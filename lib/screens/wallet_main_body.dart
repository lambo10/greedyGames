import 'dart:async';
import 'dart:convert';
import 'package:cryptowallet/components/portfolio.dart';
import 'package:cryptowallet/components/user_balance.dart';
import 'package:cryptowallet/components/user_details_placeholder.dart';
import 'package:cryptowallet/screens/send_token.dart';
import 'package:cryptowallet/screens/user_added_tokens.dart';
import 'package:cryptowallet/screens/add_custom_token.dart';
import 'package:cryptowallet/screens/settings.dart';
import 'package:cryptowallet/screens/token.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:cryptowallet/utils/wc_connector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'package:flutter_svg/svg.dart';
import 'package:hive/hive.dart';
import 'package:page_transition/page_transition.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:upgrader/upgrader.dart';
import '../coins/eth_contract_coin.dart';
import '../coins/ethereum_coin.dart';
import '../interface/coin.dart';
import '../main.dart';
import '../utils/app_config.dart';
import '../utils/get_blockchain_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class WalletMainBody extends StatefulWidget {
  const WalletMainBody({Key key}) : super(key: key);

  @override
  _WalletMainBodyState createState() => _WalletMainBodyState();
}

Future<void> handleAllIntent(String value, BuildContext context) async {
  if (value == null) return;
  bool isWalletConnect = value.trim().startsWith('wc:');

  Widget navigateWidget;

  if (isWalletConnect) {
    await WcConnector.qrScanHandler(value);
  } else {
    navigateWidget = SendToken(
      tokenData: await processEIP681(value),
    );
  }

  if (navigateWidget == null) return;

  SchedulerBinding.instance.addPostFrameCallback((_) {
    if (Navigator.canPop(context)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (ctx) => navigateWidget,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => navigateWidget,
      ),
    );
  });
}

class _WalletMainBodyState extends State<WalletMainBody>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  StreamSubscription _intentDataStreamSubscription;
  List<ValueNotifier<double>> cryptoNotifiers = <ValueNotifier<double>>[];
  ValueNotifier<double> walletNotifier = ValueNotifier(null);

  List<Widget> blockChainsArray = <Widget>[];
  List<Timer> cryptoBalancesTimer = <Timer>[];
  Future _getWalletToken;

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    for (Timer cryptoTimer in cryptoBalancesTimer) {
      cryptoTimer?.cancel();
    }
    for (ValueNotifier cryptoNotifier in cryptoNotifiers) {
      cryptoNotifier?.dispose();
    }
    walletNotifier?.dispose();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    _getWalletToken = getWalletToken();
    initializeBlockchains();

    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) async {
      await handleAllIntent(value, context);
    }, onError: (err) {
      if (kDebugMode) {
        print("getLinkStream error: $err");
      }
    });

    ReceiveSharingIntent.getInitialText().then((String value) async {
      await handleAllIntent(value, context);
    }).catchError((err) {
      if (kDebugMode) {
        print("getLinkStream error: $err");
      }
    });
  }

  void initializeBlockchains() {
    blockChainsArray = <Widget>[];

    for (int i = 0; i < getAllBlockchains.length; i++) {
      final notifier = ValueNotifier<double>(null);

      cryptoNotifiers.add(notifier);

      blockChainsArray.addAll(
        [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => Token(tokenData: getAllBlockchains[i]),
                ),
              );
            },
            child: GetBlockChainWidget(
              name_: getAllBlockchains[i].name_(),
              symbol_: getAllBlockchains[i].symbol_(),
              hasPrice_: true,
              image_: AssetImage(getAllBlockchains[i].image_()),
              cryptoAmount_: ValueListenableBuilder(
                valueListenable: notifier,
                builder: ((_, double value, Widget __) {
                  if (value == null) {
                    () async {
                      try {
                        notifier.value = await getAllBlockchains[i].getBalance(
                          notifier.value == null,
                        );
                      } catch (_) {}

                      cryptoBalancesTimer.add(
                        Timer.periodic(httpPollingDelay, (timer) async {
                          try {
                            notifier.value =
                                await getAllBlockchains[i].getBalance(
                              notifier.value == null,
                            );
                          } catch (_) {}
                        }),
                      );
                    }();
                    return Container();
                  }

                  return UserBalance(
                    symbol: getAllBlockchains[i].symbol_(),
                    balance: value,
                  );
                }),
              ),
            ),
          ),
        ],
      );
      blockChainsArray.add(const Divider());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 2));
          setState(() {});
        },
        child: UpgradeAlert(
          upgrader: Upgrader(
            dialogStyle: UpgradeDialogStyle.cupertino,
            showReleaseNotes: false,
          ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Theme.of(context)
                      .bottomNavigationBarTheme
                      .backgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            UserDetailsPlaceHolder(
                              size: .5,
                              showHi: true,
                            ),
                            SizedBox(
                              width: 20,
                            ),
                          ],
                        ),
                        GestureDetector(
                          child: Container(
                              width: 35,
                              height: 35,
                              decoration: const BoxDecoration(
                                  color: Color(0xff1F2051),
                                  shape: BoxShape.circle),
                              child: SvgPicture.asset(
                                'assets/settings_light_home.svg',
                              )),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              PageTransition(
                                type: PageTransitionType.rightToLeft,
                                child: const Settings(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                const Portfolio(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context).assets,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      //
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageTransition(
                              type: PageTransitionType.rightToLeft,
                              child: const AddCustomToken(),
                            ),
                          );
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Text(
                                    AppLocalizations.of(context).addToken,
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.add,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder(
                          future: _getWalletToken,
                          builder: (ctx, snapshot) {
                            if (snapshot.hasError) {
                              if (kDebugMode) {
                                print(snapshot.error.toString());
                              }
                              return Container();
                            }

                            if (snapshot.hasData) {
                              final appTokenWidget = <Widget>[];

                              final EthContractCoin appToken =
                                  snapshot.data['appTokenDetails'];
                              appToken.tokenType = EthTokenType.ERC20;

                              appTokenWidget.add(
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (ctx) => Token(
                                          tokenData: appToken,
                                        ),
                                      ),
                                    );
                                  },
                                  child: GetBlockChainWidget(
                                    name_: appToken.name_(),
                                    image_: appToken.image_() != null
                                        ? AssetImage(appToken.image_())
                                        : null,
                                    priceWithCurrency_:
                                        snapshot.data['nativeCurrency'] + '0',
                                    hasPrice_: false,
                                    cryptoChange_: 0,
                                    symbol_: appToken.symbol_(),
                                    cryptoAmount_: ValueListenableBuilder(
                                      valueListenable: walletNotifier,
                                      builder: ((_, double value, Widget __) {
                                        if (value == null) {
                                          () async {
                                            try {
                                              walletNotifier.value =
                                                  await appToken.getBalance(
                                                      walletNotifier.value ==
                                                          null);
                                            } catch (_) {}

                                            cryptoBalancesTimer.add(
                                              Timer.periodic(httpPollingDelay,
                                                  (timer) async {
                                                try {
                                                  walletNotifier.value =
                                                      await appToken.getBalance(
                                                          walletNotifier
                                                                  .value ==
                                                              null);
                                                } catch (_) {}
                                              }),
                                            );
                                          }();
                                          return Container();
                                        }
                                        return UserBalance(
                                          symbol: appToken.symbol_(),
                                          balance: value,
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                              );

                              appTokenWidget.add(
                                const Divider(),
                              );

                              return Column(
                                children: appTokenWidget,
                              );
                            } else {
                              return Container();
                            }
                          }),
                      ...blockChainsArray,
                      const UserAddedTokens(),
                      const SizedBox(
                        height: 20,
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future getWalletToken() async {
    EthContractCoin appCoinInfo;
    const appTokenKey = 'appTokenDetails';
    final evmBlockchain = getEVMBlockchains().firstWhere(
      (element) => element['name'] == tokenContractNetwork,
    );
    if (pref.get(appTokenKey) == null) {
      final Map erc20AppTokenDetails = await savedERC20Details(
        contractAddress: tokenContractAddress,
        rpc: evmBlockchain['rpc'],
      );

      if (erc20AppTokenDetails.isNotEmpty) {
        appCoinInfo = EthContractCoin.fromJson({
          'name': erc20AppTokenDetails['name'],
          'symbol': erc20AppTokenDetails['symbol'],
          'decimals': erc20AppTokenDetails['decimals'],
          'contractAddress': tokenContractAddress,
          'network': tokenContractNetwork,
          'rpc': evmBlockchain['rpc'],
          'chainId': evmBlockchain['chainId'],
          'coinType': evmBlockchain['coinType'],
          'blockExplorer': evmBlockchain['blockExplorer'],
          'image': 'assets/logo.png',
          'noPrice': true,
          'isNFT': false,
          'isContract': true,
        });
        await pref.put(
          appTokenKey,
          jsonEncode(appCoinInfo.toJson()),
        );
      }
    } else {
      appCoinInfo = EthContractCoin.fromJson(jsonDecode(pref.get(appTokenKey)));
    }

    final currencyWithSymbol =
        jsonDecode(await rootBundle.loadString('json/currency_symbol.json'));

    final defaultCurrency = pref.get('defaultCurrency') ?? "USD";

    if (appCoinInfo != null) {
      return {
        'appTokenDetails': appCoinInfo,
        'nativeCurrency': currencyWithSymbol[defaultCurrency]['symbol'],
      };
    }
  }
}
