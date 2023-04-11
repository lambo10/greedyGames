import 'package:cryptowallet/components/loader.dart';
import 'package:cryptowallet/eip/eip681.dart';
import 'package:cryptowallet/interface/coin.dart';
import 'package:cryptowallet/screens/contact.dart';
import 'package:cryptowallet/screens/transfer_token.dart';
import 'package:cryptowallet/utils/alt_ens.dart';
import 'package:cryptowallet/utils/app_config.dart';
import 'package:cryptowallet/utils/coin_pay.dart';
import 'package:cryptowallet/utils/qr_scan_view.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart' as stellar
    hide Row;

// import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart' as cardano;
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class SendToken extends StatefulWidget {
  final Coin tokenData;

  const SendToken({this.tokenData, Key key}) : super(key: key);

  @override
  _SendTokenState createState() => _SendTokenState();
}

class _SendTokenState extends State<SendToken> {
  final recipientAddressController = TextEditingController();
  final amount = TextEditingController();
  final tokenId = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLoading = false;
  Box pref;

  @override
  void initState() {
    super.initState();
    pref = Hive.box(secureStorageKey);
  }

  @override
  void dispose() {
    amount.dispose();
    recipientAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
            '${AppLocalizations.of(context).send} ${widget.tokenData['contractAddress'] != null ? ellipsify(str: symbol) : symbol}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
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
                  controller: recipientAddressController..text = recipient,
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

                            try {
                              if (widget.tokenData['contractAddress'] != null) {
                                Map data = EIP681.parse(recipientAddr);

                                recipientAddressController.text =
                                    data['parameters']['address'];
                                return;
                              }
                            } catch (_) {}

                            try {
                              CoinPay data = CoinPay.parseUri(recipientAddr);
                              recipientAddressController.text = data.recipient;
                              amount.text = data?.amount?.toString();
                            } catch (_) {}
                          },
                        ),
                        if (pref.get(addcontactKey) != null)
                          IconButton(
                            icon: const Icon(
                              FontAwesomeIcons.user,
                            ),
                            onPressed: () async {
                              String userAddr = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => Contact(
                                    showAdd: false,
                                    sendName: widget.tokenData['name'],
                                  ),
                                ),
                              );

                              if (userAddr == null) return;
                              recipientAddressController.text = userAddr;
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
                    hintText: AppLocalizations.of(context).receipientAddress +
                        (rpc == null
                            ? ''
                            : ' ${AppLocalizations.of(context).or} ENS'),

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
                if (isNFT == null || tokenType == 'ERC1155') ...[
                  const SizedBox(
                    height: 20,
                  ),
                  TextFormField(
                    enabled: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.trim() == '') {
                        return AppLocalizations.of(context).amountIsRequired;
                      } else {
                        return null;
                      }
                    },
                    inputFormatters: <TextInputFormatter>[
                      if (isNFT ?? false) FilteringTextInputFormatter.digitsOnly
                    ],
                    controller: amount..text = widget.tokenData['amount'],
                    decoration: InputDecoration(
                      suffixIconConstraints:
                          const BoxConstraints(minWidth: 100),
                      suffixIcon: isNFT ?? false
                          ? null
                          : IconButton(
                              alignment: Alignment.centerRight,
                              icon: Text(
                                AppLocalizations.of(context).max,
                                textAlign: TextAlign.end,
                              ),
                              onPressed: () async {},
                            ),
                      hintText: AppLocalizations.of(context).amount,

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
                ],
                if (isNFT != null) ...[
                  const SizedBox(
                    height: 20,
                  ),
                  TextFormField(
                    enabled: false,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.trim() == '') {
                        return AppLocalizations.of(context).amountIsRequired;
                      } else {
                        return null;
                      }
                    },
                    controller: tokenId
                      ..text = widget.tokenData['tokenId'].toString(),
                    decoration: const InputDecoration(
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          borderSide: BorderSide.none),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          borderSide: BorderSide.none), // you
                      filled: true,
                    ),
                  ),
                ],
                const SizedBox(
                  height: 30,
                ),
                SizedBox(
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
                    child: isLoading
                        ? const Loader()
                        : Text(
                            AppLocalizations.of(context).continue_,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                    onPressed: () async {
                      if (isLoading) return;
                      // hide snackbar if it is showing
                      ScaffoldMessenger.of(context).clearSnackBars();
                      FocusManager.instance.primaryFocus?.unfocus();
                      if (tokenType == 'ERC721') {
                        amount.text = '1';
                      }
                      if (tokenType == 'ERC1155') {
                        if (int.tryParse(amount.text.trim()) == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              content: Text(
                                AppLocalizations.of(context).pleaseEnterAmount,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                          return;
                        }
                      }

                      if (double.tryParse(amount.text.trim()) == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(
                              AppLocalizations.of(context).pleaseEnterAmount,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                        return;
                      }

                      String recipient = recipientAddressController.text.trim();
                      String cryptoDomain;
                      bool iscryptoDomain = recipient.contains('.');

                      try {
                        setState(() {
                          isLoading = true;
                        });
                        if (widget.tokenData['default'] == 'XLM' &&
                            iscryptoDomain) {
                          try {
                            stellar.FederationResponse response =
                                await stellar.Federation.resolveStellarAddress(
                              recipient,
                            );
                            cryptoDomain = recipient;
                            recipient = response.accountId;
                          } catch (_) {}
                        } else if (iscryptoDomain) {
                          Map ensAddress = await ensToAddress(
                            cryptoDomainName: recipient,
                          );

                          if (ensAddress['success']) {
                            cryptoDomain = recipient;
                            recipient = ensAddress['msg'];
                          } else {
                            Map unstoppableDomainAddr =
                                await unstoppableDomainENS(
                              cryptoDomainName: recipient,
                              currency: widget.tokenData['rpc'] == null
                                  ? widget.tokenData['default']
                                  : null,
                            );
                            cryptoDomain = unstoppableDomainAddr['success']
                                ? recipient
                                : null;
                            recipient = unstoppableDomainAddr['success']
                                ? unstoppableDomainAddr['msg']
                                : recipient;
                          }
                        }

                        setState(() {
                          isLoading = false;
                        });

                        validateAddress(widget.tokenData, recipient);
                      } catch (e) {
                        setState(() {
                          isLoading = false;
                        });
                        if (kDebugMode) {
                          print(e);
                        }
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
                      if (amount.text.trim() == "" || recipient == "") {
                        return;
                      }
                      final data = {
                        ...widget.tokenData,
                        'amount': Decimal.parse(amount.text).toString(),
                        'recipient': recipient
                      };

                      ScaffoldMessenger.of(context).clearSnackBars();
                      await reInstianteSeedRoot();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => TransferToken(
                            tokenData: data,
                            cryptoDomain: cryptoDomain,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
