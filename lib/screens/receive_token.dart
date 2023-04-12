import 'dart:math';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cryptowallet/coins/ethereum_coin.dart';
import 'package:cryptowallet/eip/eip681.dart';
import 'package:cryptowallet/utils/app_config.dart';
import 'package:cryptowallet/utils/coin_pay.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share/share.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

import '../components/loader.dart';
import '../interface/coin.dart';

class ReceiveToken extends StatefulWidget {
  final Coin tokenData;
  final String mnemonic;
  const ReceiveToken({Key key, this.tokenData, this.mnemonic})
      : super(key: key);

  @override
  _ReceiveTokenState createState() => _ReceiveTokenState();
}

class _ReceiveTokenState extends State<ReceiveToken> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String userAddress = "";

  bool isRequestingPayment = false;
  String amountRequested;
  TextEditingController amountField = TextEditingController();

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    amountField.dispose();
    super.dispose();
  }

  Future _getDetails() async {
    return {'address': await widget.tokenData.address_()};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${AppLocalizations.of(context).receive} ${widget.tokenData.contractAddress() != null ? ellipsify(str: widget.tokenData.symbol_()) : widget.tokenData.symbol_()}'),
      ),
      key: scaffoldKey,
      body: FutureBuilder(
        future: _getDetails(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            if (kDebugMode) {
              print(snapshot.error.toString() + 'error here');
            }
          }
          if (snapshot.hasData) {
            if (!isRequestingPayment) userAddress = snapshot.data['address'];
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 300,
                        height: 300,
                        child: Card(
                          color: const Color(0xffF1F1F1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 10, bottom: 10),
                              child: QrImage(
                                data: userAddress,
                                version: QrVersions.auto,
                                size: 250,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 40,
                      ),
                      GestureDetector(
                        onTap: () async {
                          // copy to clipboard
                          await Clipboard.setData(ClipboardData(
                            text: (snapshot.data as Map)['address'],
                          ));

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)
                                  .copiedToClipboard),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          color: colorForAddress,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (snapshot.data as Map)['address'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      amountRequested != null
                          ? Text(amountRequested)
                          : Container(),
                      const SizedBox(
                        height: 40,
                      ),
                      Text.rich(
                          TextSpan(children: [
                            TextSpan(
                              text: AppLocalizations.of(context).sendOnly(
                                '${widget.tokenData.contractAddress() != null ? ellipsify(str: widget.tokenData.name_()) : widget.tokenData.name_()} (${widget.tokenData.contractAddress() != null ? ellipsify(str: widget.tokenData.symbol_()) : widget.tokenData.symbol_()})',
                              ),
                            ),
                          ]),
                          textAlign: TextAlign.center),
                      const SizedBox(
                        height: 40,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              GestureDetector(
                                  onTap: () async {
                                    // copy to clipboard
                                    await Clipboard.setData(ClipboardData(
                                      text: (snapshot.data as Map)['address'],
                                    ));

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            AppLocalizations.of(context)
                                                .copiedToClipboard),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xff0C66F1),
                                      ),
                                      child: const Icon(Icons.copy,
                                          color: Colors.white))),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(AppLocalizations.of(context).copy),
                            ],
                          ),
                          Column(
                            children: [
                              GestureDetector(
                                  onTap: () async {
                                    await Share.share(
                                        '${AppLocalizations.of(context).publicAddressToReceive} ${widget.tokenData.symbol_()} ${(snapshot.data as Map)['address']}');
                                  },
                                  child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xff0C66F1),
                                      ),
                                      child: const Icon(Icons.share,
                                          color: Colors.white))),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(AppLocalizations.of(context).share),
                            ],
                          ),
                          Column(
                            children: [
                              GestureDetector(
                                  onTap: () {
                                    AwesomeDialog(
                                      showCloseIcon: true,
                                      context: context,
                                      closeIcon: const Icon(
                                        Icons.close,
                                      ),
                                      animType: AnimType.SCALE,
                                      dialogType: DialogType.INFO,
                                      keyboardAware: true,
                                      body: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          children: <Widget>[
                                            Text(
                                              AppLocalizations.of(context)
                                                  .requestPayment,
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            Material(
                                              elevation: 0,
                                              color:
                                                  Colors.blueGrey.withAlpha(40),
                                              child: TextFormField(
                                                keyboardType:
                                                    TextInputType.number,
                                                controller: amountField,
                                                autofocus: true,
                                                minLines: 1,
                                                decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  labelText:
                                                      AppLocalizations.of(
                                                              context)
                                                          .amount,
                                                  prefixIcon: const Icon(
                                                      Icons.text_fields),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            AnimatedButton(
                                              isFixedHeight: false,
                                              text: AppLocalizations.of(context)
                                                  .ok,
                                              pressEvent: () {
                                                if (Navigator.canPop(context)) {
                                                  Navigator.pop(context);
                                                }
                                                Map blockchainData =
                                                    snapshot.data as Map;
                                                FocusManager
                                                    .instance.primaryFocus
                                                    ?.unfocus();
                                                String requestUrl;

                                                if (amountField.text != null &&
                                                    double.tryParse(amountField
                                                            .text
                                                            .trim()) !=
                                                        null) {
                                                  Decimal amountEntered =
                                                      Decimal.parse(amountField
                                                          .text
                                                          .trim());
                                                  try {
                                                    if (widget.tokenData
                                                            .default__() !=
                                                        null) {
                                                      requestUrl = CoinPay(
                                                        coinScheme:
                                                            requestPaymentScheme[
                                                                widget.tokenData
                                                                    .symbol_()],
                                                        amount: amountEntered
                                                            .toDouble(),
                                                        recipient:
                                                            blockchainData[
                                                                'address'],
                                                      ).toUri();
                                                    } else {
                                                      requestUrl = EIP681.build(
                                                          targetAddress: widget
                                                              .tokenData
                                                              .contractAddress(),
                                                          chainId: (widget
                                                                      .tokenData
                                                                  as EthereumCoin)
                                                              .chainId
                                                              .toString(),
                                                          functionName:
                                                              'transfer',
                                                          parameters: {
                                                            'uint256':
                                                                (amountEntered *
                                                                        Decimal.parse(
                                                                            pow(
                                                                          10,
                                                                          widget
                                                                              .tokenData
                                                                              .decimals(),
                                                                        ).toString()))
                                                                    .toString(),
                                                            'address':
                                                                (snapshot.data
                                                                        as Map)[
                                                                    'address']
                                                          });
                                                    }
                                                  } catch (e) {
                                                    if (kDebugMode) {
                                                      print(e);
                                                    }
                                                  }

                                                  if (kDebugMode) {
                                                    print(requestUrl);
                                                  }
                                                }

                                                setState(() {
                                                  isRequestingPayment = true;
                                                  amountRequested = requestUrl !=
                                                          null
                                                      ? "+${amountField.text.trim()} ${widget.tokenData.symbol_()}"
                                                      : null;
                                                  amountField.text = '';
                                                  userAddress = requestUrl ??
                                                      (snapshot.data
                                                          as Map)['address'];
                                                });
                                              },
                                            )
                                          ],
                                        ),
                                      ),
                                    ).show();
                                  },
                                  child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black,
                                      ),
                                      child: const Icon(Icons.add,
                                          color: Colors.white))),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(AppLocalizations.of(context).request),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return const Center(child: Loader());
        },
      ),
    );
  }
}
