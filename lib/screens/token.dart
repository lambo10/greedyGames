import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cryptowallet/components/user_balance.dart';
import 'package:cryptowallet/crypto_charts/crypto_chart.dart';
import 'package:cryptowallet/interface/coin.dart';
import 'package:cryptowallet/screens/receive_token.dart';
import 'package:cryptowallet/screens/send_token.dart';
import 'package:cryptowallet/screens/token_contract_info.dart';
import 'package:cryptowallet/utils/app_config.dart';
import 'package:cryptowallet/utils/bitcoin_util.dart';
import 'package:cryptowallet/utils/format_money.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:intl/intl.dart';

class Token extends StatefulWidget {
  final Coin tokenData;
  const Token({this.tokenData, Key key}) : super(key: key);

  @override
  _TokenState createState() => _TokenState();
}

class _TokenState extends State<Token> {
  Map tokenTransaction;
  double cryptoBalance;
  Map blockchainPrice;
  bool skipNetworkRequest = true;
  Timer timer;
  ValueNotifier trxOpen = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    callTokenApi();
    timer = Timer.periodic(
      httpPollingDelay,
      (Timer t) async => await callTokenApi(),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future callTokenApi() async {
    await getTokenTransactions();
    await getBlockchainPrice();
    await getBlockchainBalance();
    if (skipNetworkRequest) skipNetworkRequest = false;
  }

  Future getBlockchainPrice() async {
    try {
      final bool priceNotavailble = widget.tokenData['noPrice'] != null &&
          widget.tokenData['noPrice'] == true;
      if (priceNotavailble) return;

      final currencyWithSymbol =
          jsonDecode(await rootBundle.loadString('json/currency_symbol.json'))
              as Map;
      final defaultCurrency =
          Hive.box(secureStorageKey).get('defaultCurrency') ?? "USD";

      final symbol = (currencyWithSymbol[defaultCurrency]['symbol']);

      Map allCryptoPrice = jsonDecode(
        await getCryptoPrice(
          skipNetworkRequest: skipNetworkRequest,
        ),
      ) as Map;

      final Map cryptoMarket =
          allCryptoPrice[coinGeckoID[widget.tokenData['symbol']]];

      final double price =
          (cryptoMarket[defaultCurrency.toLowerCase()] as num).toDouble();

      final change =
          (cryptoMarket[defaultCurrency.toLowerCase() + '_24h_change'] as num)
              .toDouble();

      blockchainPrice = {'price': price, 'change': change, 'symbol': symbol};
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future getBlockchainBalance() async {
    try {
      final mnemonic = Hive.box(secureStorageKey).get(currentMmenomicKey);
      if (widget.tokenData['contractAddress'] != null) {
        cryptoBalance = await getERC20TokenBalance(
          widget.tokenData,
          skipNetworkRequest: skipNetworkRequest,
        );
      } else if (widget.tokenData['POSNetwork'] != null) {
        final getBitcoinDetails = await getBitcoinFromMemnomic(
          mnemonic,
          widget.tokenData,
        );
        cryptoBalance = await getBitcoinAddressBalance(
          getBitcoinDetails['address'],
          widget.tokenData['POSNetwork'],
          skipNetworkRequest: skipNetworkRequest,
        );
      } else if (widget.tokenData['default'] == 'XRP') {
        final getXrpDetails = await getXRPFromMemnomic(mnemonic);
        cryptoBalance = await getXRPAddressBalance(
          getXrpDetails['address'],
          widget.tokenData['ws'],
          skipNetworkRequest: skipNetworkRequest,
        );
      } else if (widget.tokenData['default'] == 'SOL') {
        final getSolanaDetails = await getSolanaFromMemnomic(mnemonic);
        cryptoBalance = await getSolanaAddressBalance(
          getSolanaDetails['address'],
          widget.tokenData['solanaCluster'],
          skipNetworkRequest: skipNetworkRequest,
        );
      } else if (widget.tokenData['default'] == 'XTZ') {
        final getTezorDetails =
            await getTezorFromMemnomic(mnemonic, widget.tokenData);
        cryptoBalance = await getTezorAddressBalance(
          getTezorDetails['address'],
          widget.tokenData,
          skipNetworkRequest: skipNetworkRequest,
        );
      } else if (widget.tokenData['default'] == 'ALGO') {
        final getAlgorandDetails = await getAlgorandFromMemnomic(mnemonic);
        cryptoBalance = await getAlgorandAddressBalance(
          getAlgorandDetails['address'],
          widget.tokenData['algoType'],
          skipNetworkRequest: skipNetworkRequest,
        );
      } else if (widget.tokenData['default'] == 'TRX') {
        final getTronDetails = await getTronFromMemnomic(mnemonic);
        cryptoBalance = await getTronAddressBalance(
          getTronDetails['address'],
          widget.tokenData['api'],
          skipNetworkRequest: skipNetworkRequest,
        );
      } else if (widget.tokenData['default'] == 'ADA') {
        final getCardanoDetails = await getCardanoFromMemnomic(
          mnemonic,
          widget.tokenData['cardano_network'],
        );
        cryptoBalance = await getCardanoAddressBalance(
          getCardanoDetails['address'],
          widget.tokenData['cardano_network'],
          widget.tokenData['blockFrostKey'],
          skipNetworkRequest: skipNetworkRequest,
        );
      } else if (widget.tokenData['default'] == 'NEAR') {
        final getNearDetails = await getNearFromMemnomic(mnemonic);
        cryptoBalance = await getNearAddressBalance(
          getNearDetails['address'],
          widget.tokenData['api'],
          skipNetworkRequest: skipNetworkRequest,
        );
      } else if (widget.tokenData['default'] == 'FIL') {
        final getFileCoinDetails = await getFileCoinFromMemnomic(
          mnemonic,
          widget.tokenData['prefix'],
        );
        cryptoBalance = await getFileCoinAddressBalance(
          getFileCoinDetails['address'],
          baseUrl: widget.tokenData['baseUrl'],
          skipNetworkRequest: skipNetworkRequest,
        );
      } else if (widget.tokenData['default'] == 'XLM') {
        final getStellarDetails = await getStellarFromMemnomic(
          mnemonic,
        );

        cryptoBalance = await getStellarAddressBalance(
          getStellarDetails['address'],
          widget.tokenData['sdk'],
          widget.tokenData['cluster'],
          skipNetworkRequest: skipNetworkRequest,
        );
      } else if (widget.tokenData['default'] == 'ATOM') {
        final getCosmosDetails = await getCosmosFromMemnomic(
          mnemonic,
          widget.tokenData['bech32Hrp'],
          widget.tokenData['lcdUrl'],
        );

        cryptoBalance = await getCosmosAddressBalance(
          getCosmosDetails['address'],
          widget.tokenData['lcdUrl'],
          skipNetworkRequest: skipNetworkRequest,
        );
      } else {
        final getEthereumDetails = await getEthereumFromMemnomic(
          mnemonic,
          widget.tokenData['coinType'],
        );
        final ethBalance = await getEthereumAddressBalance(
          getEthereumDetails['address'],
          widget.tokenData['rpc'],
          coinType: widget.tokenData['coinType'],
          skipNetworkRequest: skipNetworkRequest,
        );
        cryptoBalance = ethBalance;
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  String rampName;
  String currentAddress;
  String rampCurrentAddress;
  Future getTokenTransactions() async {
    try {
      final pref = Hive.box(secureStorageKey);

      String mnemonic = pref.get(currentMmenomicKey);

      if (widget.tokenData['POSNetwork'] != null) {
        currentAddress = (await getBitcoinFromMemnomic(
          mnemonic,
          widget.tokenData,
        ))['address'];
      } else if (widget.tokenData['default'] == 'SOL') {
        currentAddress =
            (await getSolanaFromMemnomic(mnemonic))['address'].toString();
      } else if (widget.tokenData['default'] == 'XRP') {
        currentAddress = (await getXRPFromMemnomic(
          mnemonic,
        ))['address']
            .toString();
      } else if (widget.tokenData['default'] == 'NEAR') {
        currentAddress = (await getNearFromMemnomic(
          mnemonic,
        ))['address']
            .toString();
      } else if (widget.tokenData['default'] == 'ADA') {
        currentAddress = (await getCardanoFromMemnomic(
          mnemonic,
          widget.tokenData['cardano_network'],
        ))['address']
            .toString();
      } else if (widget.tokenData['default'] == 'ALGO') {
        currentAddress = (await getAlgorandFromMemnomic(
          mnemonic,
        ))['address']
            .toString();
      } else if (widget.tokenData['default'] == 'TRX') {
        currentAddress = (await getTronFromMemnomic(
          mnemonic,
        ))['address']
            .toString();
      } else if (widget.tokenData['default'] == 'XTZ') {
        currentAddress = (await getTezorFromMemnomic(
          mnemonic,
          widget.tokenData,
        ))['address']
            .toString();
      } else if (widget.tokenData['default'] == 'FIL') {
        currentAddress = (await getFileCoinFromMemnomic(
          mnemonic,
          widget.tokenData['prefix'],
        ))['address']
            .toString();
      } else if (widget.tokenData['default'] == 'XLM') {
        currentAddress =
            (await getStellarFromMemnomic(mnemonic))['address'].toString();
      } else if (widget.tokenData['default'] == 'ATOM') {
        final getCosmosDetails = await getCosmosFromMemnomic(
          mnemonic,
          widget.tokenData['bech32Hrp'],
          widget.tokenData['lcdUrl'],
        );
        currentAddress = getCosmosDetails['address'].toString();
      } else {
        final response = await getEthereumFromMemnomic(
          mnemonic,
          widget.tokenData['coinType'],
        );
        currentAddress = response['address'].toString();
      }

      rampName = rampSwap[widget.tokenData['symbol']];
      rampCurrentAddress = currentAddress;
      currentAddress = currentAddress.toLowerCase();
      String contractAddrLookUpkey;
      String evmAddrLookUpkey;

      if (widget.tokenData['rpc'] != null) {
        contractAddrLookUpkey =
            '${widget.tokenData['contractAddress']}${widget.tokenData['rpc']} Details';
        evmAddrLookUpkey =
            '${widget.tokenData['default']}${widget.tokenData['rpc']} Details';
      }

      final isContractAddress = widget.tokenData['contractAddress'] != null;
      final isEvmAddress = widget.tokenData['rpc'] != null;
      if (widget.tokenData['default'] == 'ALGO') {
        AlgorandTypes type = widget.tokenData['algoType'];
        final userTransactionsKey =
            pref.get('${widget.tokenData['default']}${type.index} Details');
        if (userTransactionsKey != null) {
          tokenTransaction = {
            'trx': jsonDecode(userTransactionsKey),
            'currentUser': currentAddress
          };
        }
      } else if (isContractAddress && pref.get(contractAddrLookUpkey) != null) {
        tokenTransaction = {
          'trx': jsonDecode(pref.get(contractAddrLookUpkey)),
          'currentUser': currentAddress
        };
      } else if (widget.tokenData['default'] != null &&
          isEvmAddress &&
          pref.get(evmAddrLookUpkey) != null) {
        tokenTransaction = {
          'trx': jsonDecode(pref.get(evmAddrLookUpkey)),
          'currentUser': currentAddress
        };
      } else if (widget.tokenData['default'] != null &&
          !isEvmAddress &&
          pref.get('${widget.tokenData['default']} Details') != null) {
        tokenTransaction = {
          'trx': jsonDecode(pref.get('${widget.tokenData['default']} Details')),
          'currentUser': currentAddress
        };
      } else {
        tokenTransaction = {
          'trx': [],
          'currentUser': currentAddress,
        };
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final listTransactions = <Widget>[];
    if (tokenTransaction != null) {
      List data = tokenTransaction['trx'] as List;

      int count = 1;

      for (final datum in data) {
        if (datum == null) continue;
        if (count > maximumTransactionToSave) break;
        if (datum['from'].toString().toLowerCase() !=
            tokenTransaction['currentUser'].toString().toLowerCase()) continue;
        final tokenSent = datum['value'] / pow(10, datum['decimal']);
        DateTime trnDate =
            DateFormat("yyyy-MM-dd hh:mm:ss").parse(datum['time']);

        listTransactions.addAll([
          GestureDetector(
            onTap: () async {
              await navigateToDappBrowser(
                context,
                widget.tokenData['blockExplorer'].toString().replaceFirst(
                      transactionhashTemplateKey,
                      datum['transactionHash'],
                    ),
              );
            },
            child: Container(
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            SvgPicture.asset('assets/sent-trans.svg'),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  UserBalance(
                                    balance: tokenSent,
                                    symbol: '-',
                                    reversed: true,
                                    textStyle: const TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${trnDate.day} ${months[trnDate.month - 1]} ${trnDate.year}',
                                    style: const TextStyle(color: Colors.grey),
                                  )
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Sent'),
                                  const SizedBox(height: 10),
                                  Text(
                                    ellipsify(
                                      str: datum['to'],
                                    ),
                                    overflow: TextOverflow.fade,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const Divider()
        ]);
        count++;
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tokenData['contractAddress'] != null
              ? ellipsify(str: widget.tokenData['name'])
              : widget.tokenData['name'],
        ),
        actions: [
          IconButton(
            onPressed: widget.tokenData['default'] != null
                ? () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => CryptoChart(
                          name: widget.tokenData['name'],
                          symbol: widget.tokenData['default'],
                        ),
                      ),
                    );
                  }
                : null,
            icon: SvgPicture.asset(
              'assets/chart-mixed.svg',
              color: widget.tokenData['default'] != null
                  ? Colors.white
                  : const Color(0x00aaaaaa),
            ),
          ),
          if (rampName != null)
            IconButton(
              onPressed: widget.tokenData['default'] != null
                  ? () async {
                      final buyLink = getRampLink(rampName, rampCurrentAddress);
                      await navigateToDappBrowser(context, buyLink);
                    }
                  : null,
              icon: Icon(
                Icons.shopping_bag,
                color: widget.tokenData['default'] != null
                    ? Colors.white
                    : const Color(0x00aaaaaa),
              ),
            ),
          if (widget.tokenData['contractAddress'] != null)
            IconButton(
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TokenContractInfo(
                      tokenData: widget.tokenData,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.info,
                color: Colors.white,
              ),
            ),
        ],
      ),
      body: SizedBox(
        height: double.infinity,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 300,
                          child: Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 10, right: 10, top: 20),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        widget.tokenData['contractAddress'] !=
                                                null
                                            ? widget.tokenData['network']
                                            : AppLocalizations.of(context).coin,
                                        style: const TextStyle(
                                            fontSize: 16, color: Colors.grey),
                                      ),
                                      widget.tokenData['noPrice'] != null
                                          ? Text(
                                              '\$0',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  color: widget.tokenData[
                                                              'contractAddress'] !=
                                                          null
                                                      ? const Color(0x00ffffff)
                                                      : null),
                                            )
                                          : Container(),
                                      blockchainPrice != null
                                          ? Row(
                                              children: [
                                                Text(
                                                  '${widget.tokenData['contractAddress'] != null ? ellipsify(str: blockchainPrice['symbol']) : (blockchainPrice)['symbol']}${formatMoney((blockchainPrice)['price'])}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 5,
                                                ),
                                                Text(
                                                  ((blockchainPrice)['change'] >
                                                              0
                                                          ? '+'
                                                          : '') +
                                                      formatMoney(
                                                          (blockchainPrice)[
                                                              'change']) +
                                                      '%',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: ((blockchainPrice)[
                                                                'change'] <
                                                            0)
                                                        ? red
                                                        : green,
                                                  ),
                                                )
                                              ],
                                            )
                                          : const Text(
                                              '',
                                              style: TextStyle(fontSize: 18),
                                            )
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  widget.tokenData['image'] != null
                                      ? CircleAvatar(
                                          radius: 30,
                                          backgroundImage: AssetImage(
                                            widget.tokenData['image'],
                                          ),
                                          backgroundColor:
                                              Theme.of(context).backgroundColor,
                                        )
                                      : CircleAvatar(
                                          radius: 30,
                                          child: Text(
                                            ellipsify(
                                                str: widget.tokenData['symbol'],
                                                maxLength: 3),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  if (cryptoBalance != null)
                                    UserBalance(
                                      iconSize: 20,
                                      textStyle: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                      balance: cryptoBalance,
                                      symbol:
                                          widget.tokenData['contractAddress'] !=
                                                  null
                                              ? ellipsify(
                                                  str: widget
                                                      .tokenData['symbol'])
                                              : widget.tokenData['symbol'],
                                    )
                                  else
                                    const Text(
                                      '',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  const Divider(),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Column(
                                          children: [
                                            GestureDetector(
                                              onTap: () async {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (ctx) =>
                                                          SendToken(
                                                        tokenData:
                                                            widget.tokenData,
                                                      ),
                                                    ));
                                              },
                                              child: Container(
                                                width: 40,
                                                height: 40,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: appBackgroundblue,
                                                ),
                                                child: const Icon(
                                                    Icons.arrow_upward,
                                                    color: Colors.black),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 5,
                                            ),
                                            Text(AppLocalizations.of(context)
                                                .send),
                                          ],
                                        ),
                                        const SizedBox(
                                          width: 40,
                                        ),
                                        Column(
                                          children: [
                                            GestureDetector(
                                              onTap: () async {
                                                final mnemonic =
                                                    Hive.box(secureStorageKey)
                                                        .get('mmemonic');

                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (ctx) =>
                                                        ReceiveToken(
                                                      tokenData:
                                                          widget.tokenData,
                                                      mnemonic: mnemonic,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                width: 40,
                                                height: 40,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: appBackgroundblue,
                                                ),
                                                child: const Icon(
                                                    Icons.arrow_downward,
                                                    color: Colors.black),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 5,
                                            ),
                                            Text(AppLocalizations.of(context)
                                                .receive),
                                          ],
                                        ),
                                      ]),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        ValueListenableBuilder(
                            valueListenable: trxOpen,
                            builder: (_, trxOpen_, __) {
                              return Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      trxOpen.value = !trxOpen.value;
                                    },
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(15.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              "Transactions",
                                              style: TextStyle(
                                                fontSize: 18,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 5,
                                            ),
                                            Transform.rotate(
                                              child: const Icon(
                                                Icons.arrow_back_ios_new,
                                                size: 15,
                                              ),
                                              angle: trxOpen_
                                                  ? 90 * pi / 180
                                                  : 270 * pi / 180,
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (listTransactions.isNotEmpty && trxOpen_)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: listTransactions,
                                    ),
                                ],
                              );
                            }),
                      ],
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
