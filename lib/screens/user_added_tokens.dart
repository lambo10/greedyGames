import 'dart:async';
import 'dart:convert';

import 'package:cryptowallet/coins/eth_contract_coin.dart';
import 'package:cryptowallet/components/user_balance.dart';
import 'package:cryptowallet/screens/token.dart';
import 'package:cryptowallet/utils/app_config.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../utils/get_blockchain_widget.dart';
import '../utils/rpc_urls.dart';

class UserAddedTokens extends StatefulWidget {
  const UserAddedTokens({Key key}) : super(key: key);

  @override
  State<UserAddedTokens> createState() => _UserAddedTokensState();
}

class _UserAddedTokensState extends State<UserAddedTokens> {
  List<ValueNotifier<double>> addedTokensNotifiers = <ValueNotifier<double>>[];
  List<Timer> addedTokensTimer = <Timer>[];
  double tokenBalance;
  int addedTokensCounter = 0;

  @override
  void initState() {
    super.initState();
    getUserAddedToken();
  }

  @override
  void dispose() {
    for (Timer cryptoTimer in addedTokensTimer) {
      cryptoTimer?.cancel();
    }
    for (ValueNotifier cryptoNotifier in addedTokensNotifiers) {
      cryptoNotifier?.dispose();
    }
    super.dispose();
  }

  final List<EthContractCoin> tokenList = [];
  Future getUserAddedToken() async {
    final pref = Hive.box(secureStorageKey);
    final userTokenListKey = getAddTokenKey();
    final prefToken = pref.get(userTokenListKey);

    List userTokenList = [];

    if (prefToken != null) {
      userTokenList = jsonDecode(prefToken);
    }

    for (final token in userTokenList) {
      tokenList.add(EthContractCoin.fromJson({
        'name': token['name'],
        'symbol': token['symbol'],
        'decimals': token['decimals'],
        'contractAddress': token['contractAddress'],
        'network': token['network'],
        'chainId': token['chainId'],
        'blockExplorer': token['blockExplorer'],
        'rpc': token['rpc'],
        'coinType': token['coinType'],
        'noPrice': true,
        'isNFT': false,
        'isContract': true,
        'tokenType': EthTokenType.ERC20,
      }));
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> addedTokens = <Widget>[];
    if (tokenList != null) {
      for (int i = 0; i < tokenList.length; i++) {
        final notifier = ValueNotifier<double>(null);
        addedTokensNotifiers.add(notifier);
        addedTokens.addAll([
          Dismissible(
            background: Container(),
            key: UniqueKey(),
            direction: DismissDirection.endToStart,
            secondaryBackground: Container(
              color: Colors.red,
              margin: const EdgeInsets.symmetric(horizontal: 15),
              alignment: Alignment.centerRight,
              child: const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
            ),
            onDismissed: (DismissDirection direction) {
              setState(() {});
            },
            confirmDismiss: (DismissDirection direction) async {
              final pref = Hive.box(secureStorageKey);

              final userTokenListKey = getAddTokenKey();

              if (tokenList.isEmpty) return false;
              String customTokenDetailsKey = await contractDetailsKey(
                tokenList[i].rpcUrl,
                tokenList[i].contractAddress_,
              );

              if (pref.get(customTokenDetailsKey) != null) {
                await pref.delete(customTokenDetailsKey);
              }
              tokenList.removeAt(i);

              await pref.put(
                userTokenListKey,
                jsonEncode(tokenList),
              );
              return true;
            },
            child: InkWell(
              child: Column(
                children: [
                  GetBlockChainWidget(
                    name_: ellipsify(str: tokenList[i].name_()),
                    image_: tokenList[i].image_() != null
                        ? AssetImage(tokenList[i].image_())
                        : null,
                    priceWithCurrency_: '0',
                    hasPrice_: false,
                    cryptoChange_: 0,
                    symbol_: tokenList[i].symbol_(),
                    cryptoAmount_: ValueListenableBuilder(
                      valueListenable: notifier,
                      builder: ((_, double value, Widget __) {
                        if (value == null) {
                          () async {
                            try {
                              notifier.value = await tokenList[i]
                                  .getBalance(notifier.value == null);
                            } catch (_) {}
                            addedTokensTimer.add(
                              Timer.periodic(httpPollingDelay, (timer) async {
                                try {
                                  notifier.value = await tokenList[i]
                                      .getBalance(notifier.value == null);
                                } catch (_) {}
                              }),
                            );
                          }();

                          return Container();
                        }
                        return UserBalance(
                          symbol: ellipsify(
                            str: tokenList[i].symbol_(),
                          ),
                          balance: value,
                        );
                      }),
                    ),
                  ),
                  const Divider()
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => Token(
                      tokenData: tokenList[i],
                    ),
                  ),
                );
              },
            ),
          ),
        ]);
      }
    }

    return Column(
      children: addedTokens,
    );
  }
}
