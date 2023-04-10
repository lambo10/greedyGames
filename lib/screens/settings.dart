// ignore_for_file: prefer_const_constructors

import 'dart:convert';

import 'package:cryptowallet/components/user_details_placeholder.dart';
import 'package:cryptowallet/screens/contact.dart';
import 'package:cryptowallet/screens/dark_mode_toggler.dart';
import 'package:cryptowallet/screens/language.dart';
import 'package:cryptowallet/screens/saved_urls.dart';
import 'package:cryptowallet/screens/security.dart';
import 'package:cryptowallet/screens/main_screen.dart';
import 'package:cryptowallet/screens/recovery_pharse.dart';
import 'package:cryptowallet/screens/send_token.dart';
import 'package:cryptowallet/screens/set_currency.dart';
import 'package:cryptowallet/screens/unlock_with_biometrics.dart';
import 'package:cryptowallet/screens/view_wallets.dart';
import 'package:cryptowallet/screens/wallet_connect.dart';
import 'package:cryptowallet/utils/coin_pay.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import '../components/loader.dart';
import '../utils/app_config.dart';
import '../utils/qr_scan_view.dart';

class Settings extends StatefulWidget {
  final bool isDarkMode;
  const Settings({this.isDarkMode, Key key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final darkModeKey = 'useDark';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        actions: const [DarkModeToggler()],
        title: Text(AppLocalizations.of(context).settings),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppLocalizations.of(context).account,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Card(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(15),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: UserDetailsPlaceHolder(
                      size: .5,
                      showHi: false,
                      textSize: 18,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppLocalizations.of(context).wallet,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Card(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(15),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () async {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => const SetCurrency(),
                              ),
                            );
                          },
                          child: SizedBox(
                            height: 35,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Image(
                                        image: AssetImage(
                                            'assets/currency_new.png'),
                                        width: 25),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      AppLocalizations.of(context).currency,
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(),
                        InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (ctx) {
                                return const Language();
                              }),
                            );
                          },
                          child: SizedBox(
                            height: 35,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(13),
                                        color: Color.fromARGB(255, 255, 95, 82),
                                      ),
                                      child: Icon(
                                        Icons.language,
                                        size: 22,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      AppLocalizations.of(context).language,
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(),
                        InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (ctx) {
                                return Contact();
                              }),
                            );
                          },
                          child: SizedBox(
                            height: 35,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(13),
                                        color:
                                            Color.fromARGB(255, 50, 117, 186),
                                      ),
                                      child: Icon(
                                        FontAwesomeIcons.user,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      AppLocalizations.of(context).contact,
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(),
                        InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (ctx) {
                                return const WalletConnect();
                              }),
                            );
                          },
                          child: Container(
                            color: Colors.transparent,
                            height: 35,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Image(
                                        image: AssetImage(
                                            'assets/wallet_connect_new.png'),
                                        width: 25),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      'Wallet Connect',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(),
                        InkWell(
                          onTap: () async {
                            final pref = Hive.box(secureStorageKey);
                            final mnemonics = pref.get(mnemonicListKey);

                            final currentPhrase = pref.get(currentMmenomicKey);

                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => ViewWallets(
                                  data: (jsonDecode(mnemonics) as List),
                                  currentPhrase: currentPhrase,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            color: Colors.transparent,
                            height: 35,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(13),
                                        color: Color.fromARGB(255, 50, 185, 55),
                                      ),
                                      child: Icon(
                                        FontAwesomeIcons.wallet,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      AppLocalizations.of(context).viewWallets,
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(),
                        InkWell(
                          onTap: () async {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => const MainScreen(),
                              ),
                            );
                          },
                          child: Container(
                            color: Colors.transparent,
                            height: 35,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(13),
                                        color:
                                            Color.fromARGB(255, 233, 68, 123),
                                      ),
                                      child: Icon(
                                        FontAwesomeIcons.fileImport,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      AppLocalizations.of(context).importWallet,
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(),
                        InkWell(
                          onTap: () async {
                            String data = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => const QRScanView(),
                              ),
                            );
                            if (data == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text(
                                    eIP681ProcessingErrorMsg,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }
                            showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    backgroundColor: Colors.white,
                                    content: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        SizedBox(
                                          width: 35,
                                          height: 35,
                                          child: Loader(),
                                        ),
                                      ],
                                    ),
                                  );
                                });
                            Map scannedData;
                            try {
                              CoinPay cpData = CoinPay.parseUri(data);

                              if (cpData.amount == null) {
                                throw Exception("invalid request payment");
                              }

                              Map getInfo = getInfoScheme(cpData.coinScheme);

                              if (getInfo == null) {
                                throw Exception("coin data not available");
                              }
                              scannedData = {
                                'msg': {
                                  'recipient': cpData.recipient,
                                  'amount': cpData.amount.toString(),
                                  ...getInfo
                                },
                                'success': true,
                              };
                            } catch (e) {
                              scannedData = await processEIP681(data);
                            }

                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }

                            if (scannedData['success']) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => SendToken(
                                    data: scannedData['msg'],
                                  ),
                                ),
                              );
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red,
                                content: Text(
                                  scannedData['msg'],
                                  style: TextStyle(color: Colors.white),
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: SizedBox(
                            height: 35,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(13),
                                        color: Color.fromARGB(255, 255, 147, 5),
                                      ),
                                      child: Icon(
                                        FontAwesomeIcons.qrcode,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)
                                          .scanPaymentRequest,
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppLocalizations.of(context).security,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Card(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(15),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 35,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(13),
                                        color:
                                            Color.fromARGB(255, 238, 20, 139),
                                      ),
                                      child: Icon(
                                        FontAwesomeIcons.fingerprint,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)
                                          .useBiometrics,
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                                UnlockWithBiometrics(),
                              ],
                            ),
                          ),
                          const Divider(),
                          InkWell(
                            onTap: () async {
                              String mnemonic = (Hive.box(secureStorageKey))
                                  .get(currentMmenomicKey);
                              if (await authenticate(context)) {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (ctx) => RecoveryPhrase(
                                        data: mnemonic, verify: false),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.red,
                                    content: Text(
                                      AppLocalizations.of(context).authFailed,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: SizedBox(
                              height: 35,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(13),
                                          color: Color.fromARGB(
                                              255, 142, 141, 148),
                                        ),
                                        child: Icon(
                                          FontAwesomeIcons.key,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        AppLocalizations.of(context)
                                            .showmnemonic,
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(),
                          InkWell(
                            onTap: () async {
                              if (await authenticate(
                                context,
                                useLocalAuth: false,
                              )) {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (ctx) => const Security(
                                      isChangingPin: true,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.red,
                                    content: Text(
                                      AppLocalizations.of(context).authFailed,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              color: Colors.transparent,
                              height: 35,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(13),
                                          color:
                                              Color.fromARGB(255, 255, 61, 46),
                                        ),
                                        child: Icon(
                                          FontAwesomeIcons.shieldAlt,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        AppLocalizations.of(context).changePin,
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ]),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppLocalizations.of(context).web,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Card(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(15),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () async {
                              final pref = Hive.box(secureStorageKey);
                              List data = [];
                              if (pref.get(bookMarkKey) != null) {
                                data =
                                    jsonDecode(pref.get(bookMarkKey)) as List;
                              }
                              final localize = AppLocalizations.of(context);

                              final bookmarkTitle = localize.bookMark;
                              final bookmarkEmpty = localize.noBookMark;
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => SavedUrls(
                                    bookmarkTitle,
                                    bookmarkEmpty,
                                    bookMarkKey,
                                    data: data,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              color: Colors.transparent,
                              height: 35,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(13),
                                          color:
                                              Color.fromARGB(255, 28, 119, 255),
                                        ),
                                        child: Icon(
                                          FontAwesomeIcons.bookmark,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        AppLocalizations.of(context).bookMark,
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ]),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Card(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(15),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            AppLocalizations.of(context).joinOurCommunities,
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                await launchUrl(Uri.parse(telegramLink));
                              },
                              child: const Icon(
                                FontAwesomeIcons.telegram,
                              ),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            GestureDetector(
                              onTap: () async {
                                await launchUrl(Uri.parse(twitterLink));
                              },
                              child: const Icon(
                                FontAwesomeIcons.twitter,
                              ),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            GestureDetector(
                              onTap: () async {
                                await launchUrl(Uri.parse(mediumLink));
                              },
                              child: const Icon(
                                FontAwesomeIcons.medium,
                              ),
                            ),
                            // const SizedBox(
                            //   width: 20,
                            // ),
                            // GestureDetector(
                            //   onTap: () async {
                            // await launchUrl(Uri.parse(linkedInLink));
                            //   },
                            //   child: const Icon(
                            //     FontAwesomeIcons.linkedin,
                            //   ),
                            // ),
                            // const SizedBox(
                            //   width: 20,
                            // ),
                            // GestureDetector(
                            //   onTap: () async {
                            //  await launchUrl(Uri.parse(redditLink));
                            //   },
                            //   child: const Icon(
                            //     FontAwesomeIcons.reddit,
                            //   ),
                            // ),
                            const SizedBox(
                              width: 20,
                            ),
                            GestureDetector(
                              onTap: () async {
                                await launchUrl(Uri.parse(discordLink));
                              },
                              child: const Icon(
                                FontAwesomeIcons.discord,
                              ),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            GestureDetector(
                              onTap: () async {
                                await launchUrl(Uri.parse(instagramLink));
                              },
                              child: const Icon(
                                FontAwesomeIcons.instagram,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                FutureBuilder<Object>(future: () async {
                  PackageInfo packageInfo = await PackageInfo.fromPlatform();

                  return {
                    'appName': packageInfo.appName,
                    'version': packageInfo.version,
                    'buildNumber': packageInfo.buildNumber
                  };
                }(), builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    Map data = snapshot.data;
                    return Align(
                      alignment: Alignment.center,
                      child: Text.rich(
                        TextSpan(
                            text: data['appName'],
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                            children: [
                              TextSpan(
                                text:
                                    ' v${data['version']} (${data['buildNumber']})',
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                              )
                            ]),
                      ),
                    );
                  }
                  return Text('');
                })
              ],
            ),
          ),
        ),
      ),
    );
  }
}
