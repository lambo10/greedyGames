import 'dart:async';
import 'dart:convert';

import 'package:cryptowallet/components/user_balance.dart';
import 'package:cryptowallet/config/colors.dart';
import 'package:cryptowallet/screens/claim_airdrop.dart';
import 'package:cryptowallet/screens/private_sale.dart';
import 'package:cryptowallet/screens/private_sale_busd.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:page_transition/page_transition.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import '../screens/build_row.dart';
import '../utils/app_config.dart';
import '../utils/slide_up_panel.dart';

class Portfolio extends StatefulWidget {
  const Portfolio({Key key}) : super(key: key);

  @override
  State<Portfolio> createState() => _PortfolioState();
}

class _PortfolioState extends State<Portfolio> {
  Map userBalance;
  Timer timer;
  final bool skipNetworkRequest = true;

  @override
  void initState() {
    super.initState();
    getUserBalance();
    timer = Timer.periodic(
      httpPollingDelay,
      (Timer t) async => await getUserBalance(),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future getUserBalance() async {
    try {
      final allCryptoPrice = jsonDecode(
        await getCryptoPrice(
          skipNetworkRequest: skipNetworkRequest,
        ),
      ) as Map;

      final pref = Hive.box(secureStorageKey);

      final mnemonic = pref.get(currentMmenomicKey);

      final currencyWithSymbol =
          jsonDecode(await rootBundle.loadString('json/currency_symbol.json'));

      final defaultCurrency = pref.get('defaultCurrency') ?? "USD";

      final symbol = currencyWithSymbol[defaultCurrency]['symbol'];

      double balance = await totalCryptoBalance(
        mnemonic: mnemonic,
        defaultCurrency: defaultCurrency,
        allCryptoPrice: allCryptoPrice,
        skipNetworkRequest: skipNetworkRequest,
      );
      if (mounted) {
        setState(() {
          userBalance = {
            'balance': balance,
            'symbol': symbol,
          };
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: const BoxDecoration(
                // color: portfolioCardColor,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [portfolioCardColor, portfolioCardColorLowerSection],
                ),
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              width: double.infinity,
              height: 200,
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      AppLocalizations.of(context).portfolio,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color.fromRGBO(255, 255, 255, .6),
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    if (userBalance != null)
                      GestureDetector(
                        onTap: () async {
                          final pref = Hive.box(secureStorageKey);
                          final userPreviousHidingBalance =
                              pref.get(hideBalanceKey, defaultValue: false);

                          await pref.put(
                              hideBalanceKey, !userPreviousHidingBalance);
                        },
                        child: SizedBox(
                          height: 35,
                          child: UserBalance(
                            symbol: userBalance['symbol'],
                            balance: userBalance['balance'],
                            reversed: true,
                            iconSize: 29,
                            iconDivider: const SizedBox(
                              width: 5,
                            ),
                            iconSuffix: const Icon(
                              FontAwesomeIcons.eyeSlash,
                              color: Colors.white,
                              size: 29,
                            ),
                            iconColor: Colors.white,
                            textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 35),
                    const SizedBox(
                      height: 40,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 45,
                            child: ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.resolveWith(
                                  (states) => const Color.fromRGBO(
                                    255,
                                    255,
                                    255,
                                    .38,
                                  ),
                                ),
                                shape: MaterialStateProperty.resolveWith(
                                  (states) => RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              onPressed: () async {
                                final blockchains = <Widget>[];
                                final acceptedCurrencies = [
                                  {
                                    'name': 'BNB',
                                    'asset': 'assets/smartchain.png'
                                  },
                                  {'name': 'BUSD', 'asset': 'assets/busd.png'},
                                ];

                                for (int i = 0;
                                    i < acceptedCurrencies.length;
                                    i++) {
                                  blockchains.add(
                                    InkWell(
                                      onTap: () async {
                                        if (acceptedCurrencies[i]['name'] ==
                                            'BUSD') {
                                          await Navigator.push(
                                            context,
                                            PageTransition(
                                              type: PageTransitionType
                                                  .rightToLeft,
                                              child: const PrivateSaleBusd(),
                                            ),
                                          );
                                        } else {
                                          await Navigator.push(
                                            context,
                                            PageTransition(
                                              type: PageTransitionType
                                                  .rightToLeft,
                                              child: const PrivateSale(),
                                            ),
                                          );
                                        }
                                        Navigator.pop(context);
                                      },
                                      child: buildRow(
                                        acceptedCurrencies[i]['asset'],
                                        acceptedCurrencies[i]['name'],
                                        isSelected: false,
                                      ),
                                    ),
                                  );
                                }

                                slideUpPanel(
                                  context,
                                  Container(
                                    color: Colors.transparent,
                                    child: ListView(
                                      shrinkWrap: true,
                                      children: <Widget>[
                                        const SizedBox(height: 20),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Align(
                                              alignment: Alignment.centerRight,
                                              child: IconButton(
                                                onPressed: null,
                                                icon: Icon(
                                                  Icons.close,
                                                  color: Colors.transparent,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              AppLocalizations.of(context)
                                                  .currency,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20.0,
                                              ),
                                            ),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: IconButton(
                                                onPressed: () {
                                                  if (Navigator.canPop(
                                                      context)) {
                                                    Navigator.pop(context);
                                                  }
                                                },
                                                icon: const Icon(Icons.close),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        ...blockchains,
                                        const SizedBox(height: 20),
                                      ],
                                    ),
                                  ),
                                  canDismiss: false,
                                );
                              },
                              child: Text(
                                AppLocalizations.of(context).exchange,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 45,
                            child: ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.resolveWith(
                                        (states) => const Color.fromRGBO(
                                            255, 255, 255, .38)),
                                shape: MaterialStateProperty.resolveWith(
                                  (states) => RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  PageTransition(
                                    type: PageTransitionType.rightToLeft,
                                    child: const ClaimAirdrop(),
                                  ),
                                );
                              },
                              child: Text(
                                AppLocalizations.of(context).airDrop,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
