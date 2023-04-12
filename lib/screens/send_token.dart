import 'package:cryptowallet/coins/eth_contract_coin.dart';
import 'package:cryptowallet/coins/ethereum_coin.dart';
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
  final String amount;
  final String recipient;
  const SendToken({
    this.tokenData,
    Key key,
    this.amount,
    this.recipient,
  }) : super(key: key);

  @override
  _SendTokenState createState() => _SendTokenState();
}

class _SendTokenState extends State<SendToken> {
  final recipientContrl = TextEditingController();
  final amountContrl = TextEditingController();
  final tokenIdContrl = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLoading = false;
  EthTokenType tokenType;
  String rpc;
  String tokenId;
  bool isNFT;
  Box pref;

  @override
  void initState() {
    super.initState();
    if (widget.tokenData is EthContractCoin) {
      tokenType = (widget.tokenData as EthContractCoin).tokenType;
      rpc = (widget.tokenData as EthContractCoin).rpcUrl;
      tokenId = (widget.tokenData as EthContractCoin).tokenId;
    }
    pref = Hive.box(secureStorageKey);
  }

  @override
  void dispose() {
    amountContrl.dispose();
    recipientContrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
            '${AppLocalizations.of(context).send} ${widget.tokenData.contractAddress() != null ? ellipsify(str: widget.tokenData.symbol_()) : widget.tokenData.symbol_()}'),
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
                  controller: recipientContrl..text = widget.recipient,
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
                              recipientContrl.text = recipientAddr;
                            }

                            try {
                              if (widget.tokenData.contractAddress() != null) {
                                Map data = EIP681.parse(recipientAddr);

                                recipientContrl.text =
                                    data['parameters']['address'];
                                return;
                              }
                            } catch (_) {}

                            try {
                              CoinPay data = CoinPay.parseUri(recipientAddr);
                              recipientContrl.text = data.recipient;
                              amountContrl.text = data?.amount?.toString();
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
                                    sendName: widget.tokenData.name_(),
                                  ),
                                ),
                              );

                              if (userAddr == null) return;
                              recipientContrl.text = userAddr;
                            },
                          ),
                        InkWell(
                          onTap: () async {
                            ClipboardData cdata =
                                await Clipboard.getData(Clipboard.kTextPlain);
                            if (cdata == null) return;
                            if (cdata.text == null) return;
                            recipientContrl.text = cdata.text;
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
                if (isNFT == null || tokenType == EthTokenType.ERC1155) ...[
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
                    controller: amountContrl..text = widget.amount,
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
                    controller: tokenIdContrl..text = tokenId,
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
                      if (tokenType == EthTokenType.ERC721) {
                        amountContrl.text = '1';
                      }
                      if (tokenType == EthTokenType.ERC1155) {
                        if (int.tryParse(amountContrl.text.trim()) == null) {
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

                      if (double.tryParse(amountContrl.text.trim()) == null) {
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

                      String recipient = recipientContrl.text.trim();
                      String cryptoDomain;
                      bool iscryptoDomain = recipient.contains('.');

                      try {
                        setState(() {
                          isLoading = true;
                        });
                        if (widget.tokenData.default__() == 'XLM' &&
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
                            String currency;
                            if (widget.tokenData is EthereumCoin) {
                              currency = null;
                            } else {
                              currency = widget.tokenData.default__();
                            }
                            Map unstoppableDomainAddr =
                                await unstoppableDomainENS(
                              cryptoDomainName: recipient,
                              currency: currency,
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

                        widget.tokenData.validateAddress(recipient);
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
                      if (amountContrl.text.trim() == "" || recipient == "") {
                        return;
                      }

                      ScaffoldMessenger.of(context).clearSnackBars();
                      await reInstianteSeedRoot();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => TransferToken(
                            amount: Decimal.parse(amountContrl.text).toString(),
                            recipient: recipient,
                            tokenData: widget.tokenData,
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
