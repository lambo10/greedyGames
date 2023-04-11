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
import 'package:cryptowallet/screens/wallet_connect.dart';
import 'package:cryptowallet/utils/bitcoin_util.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:cryptowallet/utils/wc_connector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_js/flutter_js.dart';

import 'package:flutter_svg/svg.dart';
import 'package:hive/hive.dart';
import 'package:page_transition/page_transition.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:upgrader/upgrader.dart';
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
    Map scannedData = await processEIP681(value);
    navigateWidget = scannedData['success']
        ? SendToken(
            data: scannedData['msg'],
          )
        : null;
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
  List<ValueNotifier<double>> cryptoBalanceListNotifiers =
      <ValueNotifier<double>>[];
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
    for (ValueNotifier cryptoNotifier in cryptoBalanceListNotifiers) {
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

    final mnemonic = Hive.box(secureStorageKey).get(currentMmenomicKey);

    for (String name in getBitCoinPOSBlockchains().keys) {
      Map bitcoinBlockchain = Map.from(getBitCoinPOSBlockchains()[name])
        ..addAll({'name': name});

      final notifier = ValueNotifier<double>(null);

      cryptoBalanceListNotifiers.add(notifier);

      blockChainsArray.addAll([
        InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => Token(data: bitcoinBlockchain),
                ),
              );
            },
            child: GetBlockChainWidget(
              name_: name,
              symbol_: bitcoinBlockchain['symbol'],
              hasPrice_: true,
              image_: AssetImage(bitcoinBlockchain['image']),
              cryptoAmount_: ValueListenableBuilder(
                valueListenable: notifier,
                builder: ((_, double value, Widget __) {
                  if (value == null) {
                    () async {
                      final getBitcoinDetails = await getBitcoinFromMemnomic(
                        mnemonic,
                        bitcoinBlockchain,
                      );
                      try {
                        notifier.value = await getBitcoinAddressBalance(
                          getBitcoinDetails['address'],
                          bitcoinBlockchain['POSNetwork'],
                          skipNetworkRequest: notifier.value == null,
                        );
                      } catch (_) {}

                      cryptoBalancesTimer.add(
                        Timer.periodic(httpPollingDelay, (timer) async {
                          try {
                            notifier.value = await getBitcoinAddressBalance(
                              getBitcoinDetails['address'],
                              bitcoinBlockchain['POSNetwork'],
                              skipNetworkRequest: notifier.value == null,
                            );
                          } catch (_) {}
                        }),
                      );
                    }();
                    return Container();
                  }

                  return UserBalance(
                    symbol: bitcoinBlockchain['symbol'],
                    balance: value,
                  );
                }),
              ),
            )),
      ]);
      blockChainsArray.add(const Divider());
    }

    for (String i in getEVMBlockchains().keys) {
      final Map evmBlockchain = Map.from(getEVMBlockchains()[i])
        ..addAll({'name': i});

      final notifier = ValueNotifier<double>(null);
      cryptoBalanceListNotifiers.add(notifier);

      blockChainsArray.add(
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => Token(
                  data: evmBlockchain,
                ),
              ),
            );
          },
          child: GetBlockChainWidget(
            name_: i,
            symbol_: evmBlockchain['symbol'],
            hasPrice_: true,
            image_: AssetImage(
              evmBlockchain['image'],
            ),
            cryptoAmount_: ValueListenableBuilder(
              valueListenable: notifier,
              builder: ((context, value, child) {
                if (value == null) {
                  () async {
                    final getEthereumDetails = await getEthereumFromMemnomic(
                      mnemonic,
                      evmBlockchain['coinType'],
                    );
                    try {
                      notifier.value = await getEthereumAddressBalance(
                        getEthereumDetails['eth_wallet_address'],
                        evmBlockchain['rpc'],
                        coinType: evmBlockchain['coinType'],
                        skipNetworkRequest: notifier.value == null,
                      );
                    } catch (_) {}

                    cryptoBalancesTimer.add(
                      Timer.periodic(httpPollingDelay, (timer) async {
                        try {
                          notifier.value = await getEthereumAddressBalance(
                            getEthereumDetails['eth_wallet_address'],
                            evmBlockchain['rpc'],
                            coinType: evmBlockchain['coinType'],
                            skipNetworkRequest: notifier.value == null,
                          );
                        } catch (_) {}
                      }),
                    );
                  }();
                  return Container();
                }
                return UserBalance(
                  symbol: evmBlockchain['symbol'],
                  balance: value,
                );
              }),
            ),
          ),
        ),
      );
      blockChainsArray.add(const Divider());
    }

    for (String i in getSolanaBlockChains().keys) {
      final Map solanaBlockchain = Map.from(getSolanaBlockChains()[i])
        ..addAll({'name': i});

      final notifier = ValueNotifier<double>(null);
      cryptoBalanceListNotifiers.add(notifier);

      blockChainsArray.addAll([
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => Token(
                  data: solanaBlockchain,
                ),
              ),
            );
          },
          child: GetBlockChainWidget(
            name_: i,
            symbol_: solanaBlockchain['symbol'],
            hasPrice_: true,
            image_: AssetImage(solanaBlockchain['image']),
            cryptoAmount_: ValueListenableBuilder(
              valueListenable: notifier,
              builder: ((context, value, child) {
                if (value == null) {
                  () async {
                    final getSolanaDetails =
                        await getSolanaFromMemnomic(mnemonic);
                    try {
                      notifier.value = await getSolanaAddressBalance(
                        getSolanaDetails['address'],
                        solanaBlockchain['solanaCluster'],
                        skipNetworkRequest: notifier.value == null,
                      );
                    } catch (_) {}

                    cryptoBalancesTimer.add(
                      Timer.periodic(httpPollingDelay, (timer) async {
                        try {
                          notifier.value = await getSolanaAddressBalance(
                            getSolanaDetails['address'],
                            solanaBlockchain['solanaCluster'],
                            skipNetworkRequest: notifier.value == null,
                          );
                        } catch (_) {}
                      }),
                    );
                  }();
                  return Container();
                }
                return UserBalance(
                  symbol: solanaBlockchain['symbol'],
                  balance: value,
                );
              }),
            ),
          ),
        ),
      ]);

      blockChainsArray.add(const Divider());
    }
    for (String i in getStellarBlockChains().keys) {
      final Map stellarBlockChain = Map.from(getStellarBlockChains()[i])
        ..addAll({'name': i});
      final notifier = ValueNotifier<double>(null);
      cryptoBalanceListNotifiers.add(notifier);

      blockChainsArray.addAll([
        InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => Token(
                    data: stellarBlockChain,
                  ),
                ),
              );
            },
            child: GetBlockChainWidget(
              name_: i,
              symbol_: stellarBlockChain['symbol'],
              hasPrice_: true,
              image_: AssetImage(
                stellarBlockChain['image'],
              ),
              cryptoAmount_: ValueListenableBuilder(
                valueListenable: notifier,
                builder: ((context, value, child) {
                  if (value == null) {
                    () async {
                      final getStellarDetails =
                          await getStellarFromMemnomic(mnemonic);
                      try {
                        notifier.value = await getStellarAddressBalance(
                          getStellarDetails['address'],
                          stellarBlockChain['sdk'],
                          stellarBlockChain['cluster'],
                          skipNetworkRequest: notifier.value == null,
                        );
                      } catch (_) {}

                      cryptoBalancesTimer.add(
                        Timer.periodic(httpPollingDelay, (timer) async {
                          try {
                            notifier.value = await getStellarAddressBalance(
                              getStellarDetails['address'],
                              stellarBlockChain['sdk'],
                              stellarBlockChain['cluster'],
                              skipNetworkRequest: notifier.value == null,
                            );
                          } catch (_) {}
                        }),
                      );
                    }();
                    return Container();
                  }
                  return UserBalance(
                    symbol: stellarBlockChain['symbol'],
                    balance: value,
                  );
                }),
              ),
            )),
      ]);

      blockChainsArray.add(const Divider());
    }

    for (String i in getFilecoinBlockChains().keys) {
      final Map filecoinBlockchain = Map.from(getFilecoinBlockChains()[i])
        ..addAll({'name': i});

      final notifier = ValueNotifier<double>(null);
      cryptoBalanceListNotifiers.add(notifier);

      blockChainsArray.addAll([
        InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => Token(
                    data: filecoinBlockchain,
                  ),
                ),
              );
            },
            child: GetBlockChainWidget(
              name_: i,
              symbol_: filecoinBlockchain['symbol'],
              hasPrice_: true,
              image_: AssetImage(
                filecoinBlockchain['image'],
              ),
              cryptoAmount_: ValueListenableBuilder(
                valueListenable: notifier,
                builder: ((context, value, child) {
                  if (value == null) {
                    () async {
                      final getFilecoinDetails = await getFileCoinFromMemnomic(
                        mnemonic,
                        filecoinBlockchain['prefix'],
                      );
                      try {
                        notifier.value = await getFileCoinAddressBalance(
                          getFilecoinDetails['address'],
                          baseUrl: filecoinBlockchain['baseUrl'],
                          skipNetworkRequest: notifier.value == null,
                        );
                      } catch (_) {}

                      cryptoBalancesTimer.add(
                        Timer.periodic(httpPollingDelay, (timer) async {
                          try {
                            notifier.value = await getFileCoinAddressBalance(
                              getFilecoinDetails['address'],
                              baseUrl: filecoinBlockchain['baseUrl'],
                              skipNetworkRequest: notifier.value == null,
                            );
                          } catch (_) {}
                        }),
                      );
                    }();
                    return Container();
                  }
                  return UserBalance(
                    symbol: filecoinBlockchain['symbol'],
                    balance: value,
                  );
                }),
              ),
            )),
      ]);

      blockChainsArray.add(const Divider());
    }
    for (String i in getCosmosBlockChains().keys) {
      final Map cosmosBlockchain = Map.from(getCosmosBlockChains()[i])
        ..addAll({'name': i});

      final notifier = ValueNotifier<double>(null);
      cryptoBalanceListNotifiers.add(notifier);

      blockChainsArray.addAll([
        InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => Token(
                    data: cosmosBlockchain,
                  ),
                ),
              );
            },
            child: GetBlockChainWidget(
              name_: i,
              symbol_: cosmosBlockchain['symbol'],
              hasPrice_: true,
              image_: AssetImage(
                cosmosBlockchain['image'],
              ),
              cryptoAmount_: ValueListenableBuilder(
                valueListenable: notifier,
                builder: ((context, value, child) {
                  if (value == null) {
                    () async {
                      final getCosmosDetails = await getCosmosFromMemnomic(
                        mnemonic,
                        cosmosBlockchain['bech32Hrp'],
                        cosmosBlockchain['lcdUrl'],
                      );

                      try {
                        notifier.value = await getCosmosAddressBalance(
                          getCosmosDetails['address'],
                          cosmosBlockchain['lcdUrl'],
                          skipNetworkRequest: notifier.value == null,
                        );
                      } catch (_) {}

                      cryptoBalancesTimer.add(
                        Timer.periodic(httpPollingDelay, (timer) async {
                          try {
                            notifier.value = await getCosmosAddressBalance(
                              getCosmosDetails['address'],
                              cosmosBlockchain['lcdUrl'],
                              skipNetworkRequest: notifier.value == null,
                            );
                          } catch (_) {}
                        }),
                      );
                    }();
                    return Container();
                  }
                  return UserBalance(
                    symbol: cosmosBlockchain['symbol'],
                    balance: value,
                  );
                }),
              ),
            )),
      ]);

      blockChainsArray.add(const Divider());
    }

    for (String i in getAlgorandBlockchains().keys) {
      final Map algorandBlockchain = Map.from(getAlgorandBlockchains()[i])
        ..addAll({'name': i});

      final notifier = ValueNotifier<double>(null);
      cryptoBalanceListNotifiers.add(notifier);

      blockChainsArray.addAll([
        InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => Token(
                    data: algorandBlockchain,
                  ),
                ),
              );
            },
            child: GetBlockChainWidget(
              name_: i,
              symbol_: algorandBlockchain['symbol'],
              hasPrice_: true,
              image_: AssetImage(
                algorandBlockchain['image'],
              ),
              cryptoAmount_: ValueListenableBuilder(
                valueListenable: notifier,
                builder: ((context, value, child) {
                  if (value == null) {
                    () async {
                      final getAlgorandDetails =
                          await getAlgorandFromMemnomic(mnemonic);
                      try {
                        notifier.value = await getAlgorandAddressBalance(
                          getAlgorandDetails['address'],
                          algorandBlockchain['algoType'],
                          skipNetworkRequest: notifier.value == null,
                        );
                      } catch (_) {}

                      cryptoBalancesTimer.add(
                        Timer.periodic(httpPollingDelay, (timer) async {
                          try {
                            notifier.value = await getAlgorandAddressBalance(
                              getAlgorandDetails['address'],
                              algorandBlockchain['algoType'],
                              skipNetworkRequest: notifier.value == null,
                            );
                          } catch (_) {}
                        }),
                      );
                    }();
                    return Container();
                  }
                  return UserBalance(
                    symbol: algorandBlockchain['symbol'],
                    balance: value,
                  );
                }),
              ),
            )),
      ]);
      blockChainsArray.add(const Divider());
    }

    for (String i in getNearBlockChains().keys) {
      final Map nearBlockchains = Map.from(getNearBlockChains()[i])
        ..addAll({'name': i});

      final notifier = ValueNotifier<double>(null);
      cryptoBalanceListNotifiers.add(notifier);

      blockChainsArray.addAll([
        InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => Token(
                    data: nearBlockchains,
                  ),
                ),
              );
            },
            child: GetBlockChainWidget(
              name_: i,
              symbol_: nearBlockchains['symbol'],
              hasPrice_: true,
              image_: AssetImage(
                nearBlockchains['image'],
              ),
              cryptoAmount_: ValueListenableBuilder(
                valueListenable: notifier,
                builder: ((context, value, child) {
                  if (value == null) {
                    () async {
                      final getNearDetails =
                          await getNearFromMemnomic(mnemonic);
                      try {
                        notifier.value = await getTronAddressBalance(
                          getNearDetails['address'],
                          nearBlockchains['api'],
                          skipNetworkRequest: notifier.value == null,
                        );
                      } catch (_) {}

                      cryptoBalancesTimer.add(
                        Timer.periodic(httpPollingDelay, (timer) async {
                          try {
                            notifier.value = await getTronAddressBalance(
                              getNearDetails['address'],
                              nearBlockchains['api'],
                              skipNetworkRequest: notifier.value == null,
                            );
                          } catch (_) {}
                        }),
                      );
                    }();
                    return Container();
                  }
                  return UserBalance(
                    symbol: nearBlockchains['symbol'],
                    balance: value,
                  );
                }),
              ),
            )),
      ]);
      blockChainsArray.add(const Divider());
    }

    for (String i in getTronBlockchains().keys) {
      final Map tronBlockchain = Map.from(getTronBlockchains()[i])
        ..addAll({'name': i});

      final notifier = ValueNotifier<double>(null);
      cryptoBalanceListNotifiers.add(notifier);

      blockChainsArray.addAll([
        InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => Token(
                    data: tronBlockchain,
                  ),
                ),
              );
            },
            child: GetBlockChainWidget(
              name_: i,
              symbol_: tronBlockchain['symbol'],
              hasPrice_: true,
              image_: AssetImage(
                tronBlockchain['image'],
              ),
              cryptoAmount_: ValueListenableBuilder(
                valueListenable: notifier,
                builder: ((context, value, child) {
                  if (value == null) {
                    () async {
                      final getTronDetails =
                          await getTronFromMemnomic(mnemonic);
                      try {
                        notifier.value = await getTronAddressBalance(
                          getTronDetails['address'],
                          tronBlockchain['api'],
                          skipNetworkRequest: notifier.value == null,
                        );
                      } catch (_) {}

                      cryptoBalancesTimer.add(
                        Timer.periodic(httpPollingDelay, (timer) async {
                          try {
                            notifier.value = await getTronAddressBalance(
                              getTronDetails['address'],
                              tronBlockchain['api'],
                              skipNetworkRequest: notifier.value == null,
                            );
                          } catch (_) {}
                        }),
                      );
                    }();
                    return Container();
                  }
                  return UserBalance(
                    symbol: tronBlockchain['symbol'],
                    balance: value,
                  );
                }),
              ),
            )),
      ]);
      blockChainsArray.add(const Divider());
    }

    for (String i in getCardanoBlockChains().keys) {
      final Map cardanoBlockchain = Map.from(getCardanoBlockChains()[i])
        ..addAll({'name': i});

      final notifier = ValueNotifier<double>(null);
      cryptoBalanceListNotifiers.add(notifier);

      blockChainsArray.addAll([
        InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => Token(
                    data: cardanoBlockchain,
                  ),
                ),
              );
            },
            child: GetBlockChainWidget(
              name_: i,
              symbol_: cardanoBlockchain['symbol'],
              hasPrice_: true,
              image_: AssetImage(
                cardanoBlockchain['image'],
              ),
              cryptoAmount_: ValueListenableBuilder(
                valueListenable: notifier,
                builder: ((context, value, child) {
                  if (value == null) {
                    () async {
                      final getCardanoDetails = await getCardanoFromMemnomic(
                        mnemonic,
                        cardanoBlockchain['cardano_network'],
                      );
                      try {
                        notifier.value = await getCardanoAddressBalance(
                          getCardanoDetails['address'],
                          cardanoBlockchain['cardano_network'],
                          cardanoBlockchain['blockFrostKey'],
                          skipNetworkRequest: notifier.value == null,
                        );
                      } catch (_) {}

                      cryptoBalancesTimer.add(
                        Timer.periodic(httpPollingDelay, (timer) async {
                          try {
                            notifier.value = await getCardanoAddressBalance(
                              getCardanoDetails['address'],
                              cardanoBlockchain['cardano_network'],
                              cardanoBlockchain['blockFrostKey'],
                              skipNetworkRequest: notifier.value == null,
                            );
                          } catch (_) {}
                        }),
                      );
                    }();
                    return Container();
                  }
                  return UserBalance(
                    symbol: cardanoBlockchain['symbol'],
                    balance: value,
                  );
                }),
              ),
            )),
      ]);
      blockChainsArray.add(const Divider());
    }

    for (String i in getXRPBlockChains().keys) {
      final Map xrpBlockchain = Map.from(getXRPBlockChains()[i])
        ..addAll({'name': i});

      final notifier = ValueNotifier<double>(null);
      cryptoBalanceListNotifiers.add(notifier);

      blockChainsArray.addAll([
        InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => Token(
                    data: xrpBlockchain,
                  ),
                ),
              );
            },
            child: GetBlockChainWidget(
              name_: i,
              symbol_: xrpBlockchain['symbol'],
              hasPrice_: true,
              image_: AssetImage(
                xrpBlockchain['image'],
              ),
              cryptoAmount_: ValueListenableBuilder(
                valueListenable: notifier,
                builder: ((context, value, child) {
                  if (value == null) {
                    () async {
                      final getXRPDetails = await getXRPFromMemnomic(mnemonic);

                      try {
                        notifier.value = await getXRPAddressBalance(
                          getXRPDetails['address'],
                          xrpBlockchain['ws'],
                          skipNetworkRequest: notifier.value == null,
                        );
                      } catch (_) {}

                      cryptoBalancesTimer.add(
                        Timer.periodic(httpPollingDelay, (timer) async {
                          try {
                            notifier.value = await getXRPAddressBalance(
                              getXRPDetails['address'],
                              xrpBlockchain['ws'],
                              skipNetworkRequest: notifier.value == null,
                            );
                          } catch (_) {}
                        }),
                      );
                    }();
                    return Container();
                  }
                  return UserBalance(
                    symbol: xrpBlockchain['symbol'],
                    balance: value,
                  );
                }),
              ),
            )),
      ]);
      blockChainsArray.add(const Divider());
    }

    for (String name in getTezosBlockchains().keys) {
      Map tezorBlockchain = Map.from(getTezosBlockchains()[name])
        ..addAll({'name': name});

      final notifier = ValueNotifier<double>(null);

      cryptoBalanceListNotifiers.add(notifier);

      blockChainsArray.addAll([
        InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => Token(data: tezorBlockchain),
                ),
              );
            },
            child: GetBlockChainWidget(
              name_: name,
              symbol_: tezorBlockchain['symbol'],
              hasPrice_: true,
              image_: AssetImage(tezorBlockchain['image']),
              cryptoAmount_: ValueListenableBuilder(
                valueListenable: notifier,
                builder: ((_, double value, Widget __) {
                  if (value == null) {
                    () async {
                      final getBitcoinDetails = await getTezorFromMemnomic(
                        mnemonic,
                        tezorBlockchain,
                      );
                      try {
                        notifier.value = await getTezorAddressBalance(
                          getBitcoinDetails['address'],
                          tezorBlockchain,
                          skipNetworkRequest: notifier.value == null,
                        );
                      } catch (_) {}

                      cryptoBalancesTimer.add(
                        Timer.periodic(httpPollingDelay, (timer) async {
                          try {
                            notifier.value = await getTezorAddressBalance(
                              getBitcoinDetails['address'],
                              tezorBlockchain,
                              skipNetworkRequest: notifier.value == null,
                            );
                          } catch (_) {}
                        }),
                      );
                    }();
                    return Container();
                  }

                  return UserBalance(
                    symbol: tezorBlockchain['symbol'],
                    balance: value,
                  );
                }),
              ),
            )),
      ]);
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

                              for (final appToken
                                  in (snapshot.data['elementList'] as List)) {
                                appTokenWidget.add(
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (ctx) =>
                                              Token(data: appToken),
                                        ),
                                      );
                                    },
                                    child: GetBlockChainWidget(
                                      name_: appToken['name'],
                                      image_: appToken['image'] != null
                                          ? AssetImage(appToken['image'])
                                          : null,
                                      priceWithCurrency_:
                                          snapshot.data['nativeCurrency'] + '0',
                                      hasPrice_: false,
                                      cryptoChange_: 0,
                                      symbol_: appToken['symbol'],
                                      cryptoAmount_: ValueListenableBuilder(
                                        valueListenable: walletNotifier,
                                        builder: ((_, double value, Widget __) {
                                          if (value == null) {
                                            () async {
                                              try {
                                                walletNotifier.value =
                                                    await getERC20TokenBalance(
                                                  appToken,
                                                  skipNetworkRequest:
                                                      walletNotifier.value ==
                                                          null,
                                                );
                                              } catch (_) {}

                                              cryptoBalancesTimer.add(
                                                Timer.periodic(httpPollingDelay,
                                                    (timer) async {
                                                  try {
                                                    walletNotifier.value =
                                                        await getERC20TokenBalance(
                                                      appToken,
                                                      skipNetworkRequest:
                                                          walletNotifier
                                                                  .value ==
                                                              null,
                                                    );
                                                  } catch (_) {}
                                                }),
                                              );
                                            }();
                                            return Container();
                                          }
                                          return UserBalance(
                                            symbol: appToken['symbol'],
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
                              }

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
    final pref = Hive.box(secureStorageKey);
    Map appTokenDetails = {};
    const appTokenKey = 'appTokenDetails';

    if (pref.get(appTokenKey) == null) {
      final Map evmBlockchain = getEVMBlockchains()[tokenContractNetwork];
      final Map erc20AppTokenDetails = await getERC20TokenNameSymbolDecimal(
        contractAddress: tokenContractAddress,
        rpc: evmBlockchain['rpc'],
      );

      if (erc20AppTokenDetails.isNotEmpty) {
        appTokenDetails = {
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
          'noPrice': true
        };
        await pref.put(
          appTokenKey,
          jsonEncode(appTokenDetails),
        );
      }
    } else {
      appTokenDetails = jsonDecode(pref.get(appTokenKey));
    }

    final currencyWithSymbol =
        jsonDecode(await rootBundle.loadString('json/currency_symbol.json'));

    final defaultCurrency = pref.get('defaultCurrency') ?? "USD";

    if (appTokenDetails.isNotEmpty) {
      return {
        'elementList': [appTokenDetails],
        'nativeCurrency': currencyWithSymbol[defaultCurrency]['symbol'],
      };
    }
  }
}
