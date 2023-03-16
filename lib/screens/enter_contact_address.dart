import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

import '../utils/app_config.dart';
import '../utils/coin_pay.dart';
import '../utils/qr_scan_view.dart';

class EnterContactAddress extends StatefulWidget {
  final Map blockchainData;
  const EnterContactAddress({Key key, this.blockchainData}) : super(key: key);

  @override
  State<EnterContactAddress> createState() => _EnterContactAddressState();
}

class _EnterContactAddressState extends State<EnterContactAddress> {
  List languages;
  String languageCode;
  final recipientAddressController = TextEditingController();

  final nameController = TextEditingController();

  @override
  initState() {
    super.initState();

    languages = context
        .findAncestorWidgetOfExactType<MaterialApp>()
        ?.supportedLocales
        ?.toList();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.blockchainData['symbol']} ${AppLocalizations.of(context).address}',
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 2));
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    autocorrect: false,
                    keyboardType: TextInputType.visiblePassword,
                    validator: (value) {
                      if (value?.trim() == '') {
                        return AppLocalizations.of(context)
                            .receipientAddressIsRequired;
                      } else {
                        return null;
                      }
                    },
                    controller: recipientAddressController
                      ..text = widget.blockchainData['address'],
                    decoration: InputDecoration(
                      suffixIcon: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.qr_code_scanner,
                            ),
                            onPressed: () async {
                              String recipientAddr = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => const QRScanView(),
                                ),
                              );

                              if (recipientAddr == null) return;

                              if (!recipientAddr.contains(':')) {
                                recipientAddressController.text = recipientAddr;
                              }

                              // try {
                              //   if (widget.data['contractAddress'] != null) {
                              //     Map data = EIP681.parse(recipientAddr);

                              //     recipientAddressController.text =
                              //         data['parameters']['address'];
                              //     return;
                              //   }
                              // } catch (_) {}

                              try {
                                CoinPay data = CoinPay.parseUri(recipientAddr);
                                recipientAddressController.text =
                                    data.recipient;
                              } catch (_) {}
                            },
                          ),
                          InkWell(
                            onTap: () async {
                              ClipboardData cdata =
                                  await Clipboard.getData(Clipboard.kTextPlain);
                              if (cdata == null) return;
                              if (cdata.text == null) return;
                              recipientAddressController.text = cdata.text;
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                AppLocalizations.of(context).paste,
                              ),
                            ),
                          ),
                        ],
                      ),
                      hintText:
                          '${widget.blockchainData['symbol']} ${AppLocalizations.of(context).address}',

                      focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          borderSide: BorderSide.none),
                      border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          borderSide: BorderSide.none),
                      enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          borderSide: BorderSide.none), // you
                      filled: true,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    color: Colors.transparent,
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith(
                            (states) => appBackgroundblue),
                        shape: MaterialStateProperty.resolveWith(
                          (states) => RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        textStyle: MaterialStateProperty.resolveWith(
                          (states) => const TextStyle(color: Colors.white),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context).done,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      onPressed: () async {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        String recipient =
                            recipientAddressController.text.trim();
                        try {
                          validateAddress(
                            widget.blockchainData,
                            recipient,
                          );
                          Navigator.pop(context, {
                            ...widget.blockchainData,
                            'address': recipient,
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              content: Text(
                                AppLocalizations.of(context).invalidAddress,
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                          return;
                        }
                      },
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
