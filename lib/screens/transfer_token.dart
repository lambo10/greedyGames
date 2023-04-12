import 'dart:async';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart' as cardano;
import 'dart:math';
import 'package:algorand_dart/algorand_dart.dart' as algoRan;
import 'package:cryptowallet/api/notification_api.dart';
import 'package:cryptowallet/coins/eth_contract_coin.dart';
import 'package:cryptowallet/coins/ethereum_coin.dart';
import 'package:cryptowallet/components/loader.dart';
import 'package:cryptowallet/config/colors.dart';
import 'package:cryptowallet/interface/coin.dart';
import 'package:cryptowallet/utils/app_config.dart';
import 'package:decimal/decimal.dart';
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

class TransferToken extends StatefulWidget {
  final Coin tokenData;
  final String cryptoDomain;
  final String recipient;
  final String amount;
  const TransferToken({
    Key key,
    this.tokenData,
    this.cryptoDomain,
    this.recipient,
    this.amount,
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

  ContractAbi contrAbi;
  bool isContract;
  bool isNFT;
  String tokenId;
  String mnemonic;

  @override
  void initState() {
    super.initState();
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
      transactionFeeMap = {
        'transactionFee': await widget.tokenData.getTransactionFee(
          widget.amount,
          widget.recipient,
        ),
        'userBalance': await widget.tokenData.getBalance(false),
      };
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
                    '-${widget.amount ?? '1'} ${isContract ? ellipsify(str: widget.tokenData.symbol_()) : widget.tokenData.symbol_()}',
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
                    '${isContract ? ellipsify(str: widget.tokenData.name_()) : widget.tokenData.name_()} (${isContract ? ellipsify(str: widget.tokenData.symbol_()) : widget.tokenData.symbol_()})',
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
                    return {
                      'address': await widget.tokenData.address_(),
                    };
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
                        ? '${widget.cryptoDomain} (${widget.recipient})'
                        : widget.recipient,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  if (isNFT) ...[
                    Text(
                      AppLocalizations.of(context).tokenId,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      tokenId,
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
                  widget.tokenData.default__() != null
                      ? Text(
                          '${transactionFeeMap != null ? Decimal.parse(transactionFeeMap['transactionFee'].toString()) : '--'}  ${widget.tokenData.default__()}',
                          style: const TextStyle(fontSize: 16),
                        )
                      : Container(),
                  widget.tokenData.contractAddress() != null
                      ? Text(
                          '${transactionFeeMap != null ? Decimal.parse(transactionFeeMap['transactionFee'].toString()) : '--'}  ${widget.tokenData.default__()}',
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
                                        transactionHash = await widget.tokenData
                                            .transferToken(widget.amount,
                                                widget.recipient);

                                        coinDecimals =
                                            widget.tokenData.decimals();
                                        userAddress =
                                            await widget.tokenData.address_();

                                        userTransactionsKey =
                                            '${widget.tokenData.default__()} Details';

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

                                        String tokenSent =
                                            isNFT ? tokenId : widget.amount;

                                        NotificationApi.showNotification(
                                          title:
                                              '${widget.tokenData.symbol_()} Sent',
                                          body:
                                              '$tokenSent ${widget.tokenData.symbol_()} sent to ${widget.recipient}',
                                        );

                                        if (isNFT) {
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
                                          'to': widget.recipient,
                                          'value': double.parse(
                                                widget.amount,
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
