import 'dart:async';
import 'dart:convert';

import 'package:cryptowallet/utils/app_config.dart';
import 'package:cryptowallet/utils/format_money.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import '../config/colors.dart';

class GetBlockChainWidget extends StatefulWidget {
  final AssetImage image;
  final String name;
  final String priceWithCurrency;
  final double cryptoChange;
  final Widget cryptoAmount;
  final bool hasPrice;
  final String symbol;

  const GetBlockChainWidget({
    Key key,
    AssetImage image_,
    String name_,
    String priceWithCurrency_,
    double cryptoChange_,
    Widget cryptoAmount_,
    String symbol_,
    bool hasPrice_,
  })  : hasPrice = hasPrice_,
        image = image_,
        symbol = symbol_,
        name = name_,
        priceWithCurrency = priceWithCurrency_,
        cryptoChange = cryptoChange_,
        cryptoAmount = cryptoAmount_,
        super(key: key);

  @override
  State<GetBlockChainWidget> createState() => _GetBlockChainWidgetState();
}

class _GetBlockChainWidgetState extends State<GetBlockChainWidget> {
  Timer timer;
  Map blockchainPrice;
  bool skipNetworkRequest = true;

  @override
  void initState() {
    super.initState();
    if (widget.hasPrice != null && widget.hasPrice) {
      getBlockchainPrice();
      timer = Timer.periodic(
        httpPollingDelay,
        (Timer t) async {
          try {
            await getBlockchainPrice();
          } catch (_) {}
        },
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future getBlockchainPrice() async {
    try {
      Map allCryptoPrice = jsonDecode(
        await getCryptoPrice(
          skipNetworkRequest: skipNetworkRequest,
        ),
      ) as Map;

      if (skipNetworkRequest) skipNetworkRequest = false;

      final currencyWithSymbol = jsonDecode(
        await rootBundle.loadString('json/currency_symbol.json'),
      );

      final defaultCurrency =
          Hive.box(secureStorageKey).get('defaultCurrency') ?? "USD";
      final symbol = currencyWithSymbol[defaultCurrency]['symbol'];

      final Map cryptoMarket =
          allCryptoPrice[coinGeckCryptoSymbolToID[widget.symbol]];

      final double cryptoWidgetPrice =
          (cryptoMarket[defaultCurrency.toLowerCase()] as num).toDouble();

      blockchainPrice = {
        'price': symbol + formatMoney(cryptoWidgetPrice),
        'change':
            (cryptoMarket[defaultCurrency.toLowerCase() + '_24h_change'] as num)
                .toDouble()
      };
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            spreadRadius: 16,
            color: Colors.black.withOpacity(0.2),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        //child:
        // BackdropFilter(
        //   filter: ImageFilter.blur(
        //     sigmaX: 40.0,
        //     sigmaY: 40.0,
        //   ),
        child: Container(
          height: 65,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8.0),
            // border: Border.all(
            //   width: 1.5,
            //   color: Colors.white.withOpacity(0.2),
            // ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        widget.image != null
                            ? CircleAvatar(
                                backgroundImage: widget.image,
                                backgroundColor:
                                    Theme.of(context).colorScheme.background,
                              )
                            : CircleAvatar(
                                child: Text(
                                  ellipsify(str: widget.symbol, maxLength: 3),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                        const SizedBox(
                          width: 10,
                        ),
                        Flexible(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      widget.name,
                                      style: const TextStyle(
                                          color: black,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.fade,
                                    ),
                                    widget.cryptoAmount
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                        child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (blockchainPrice != null)
                                          Row(
                                            children: [
                                              Text(
                                                blockchainPrice['price'],
                                                style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w800,
                                                    color: widget.hasPrice
                                                        ? null
                                                        : black),
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              widget.hasPrice
                                                  ? Text(
                                                      (blockchainPrice[
                                                                      'change'] >
                                                                  0
                                                              ? '+'
                                                              : '') +
                                                          formatMoney(
                                                              blockchainPrice[
                                                                  'change']) +
                                                          '%',
                                                      style: widget.hasPrice
                                                          ? TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 12,
                                                              color: (blockchainPrice[
                                                                          'change'] <
                                                                      0)
                                                                  ? red
                                                                  : green,
                                                            )
                                                          : const TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: black),
                                                    )
                                                  : Container()
                                            ],
                                          )
                                      ],
                                    )),
                                  ],
                                ),
                              ]),
                        )
                      ],
                    ),
                  ),
                ]),
          ),
        ),

        //),
      ),
    );
  }
}
