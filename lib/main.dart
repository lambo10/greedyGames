// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:cryptowallet/coins/polkadot_coin.dart';
import 'package:cryptowallet/screens/navigator_service.dart';
import 'package:cryptowallet/screens/open_app_pin_failed.dart';
import 'package:cryptowallet/screens/security.dart';
import 'package:cryptowallet/screens/wallet.dart';
import 'package:cryptowallet/utils/app_config.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:cryptowallet/utils/wc_connector.dart';
import 'package:cryptowallet/utils/web_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:pointycastle/pointycastle.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'coins/ronin_coin.dart';
import 'interface/coin.dart';
import 'screens/main_screen.dart';
import '../coins/algorand_coin.dart';
import '../coins/bitcoin_coin.dart';
import '../coins/cardano_coin.dart';
import '../coins/cosmos_coin.dart';
import '../coins/ethereum_coin.dart';
import '../coins/filecoin_coin.dart';
import '../coins/near_coin.dart';
import '../coins/solana_coin.dart';
import '../coins/stellar_coin.dart';
import '../coins/tezos_coin.dart';
import '../coins/tron_coin.dart';
import '../coins/xrp_coin.dart';

List<Coin> getAllBlockchains = [];
Future<List<Coin>> getAllBlockchains_fun() async {
  return [
    ...getEVMBlockchains().map((e) => EthereumCoin.fromJson(Map.from(e))),
    ...getBitCoinPOSBlockchains().map((e) => BitcoinCoin.fromJson(Map.from(e))),
    ...getFilecoinBlockChains().map((e) => FilecoinCoin.fromJson(Map.from(e))),
    ...getCardanoBlockChains().map((e) => CardanoCoin.fromJson(Map.from(e))),
    ...getTezosBlockchains().map((e) => TezosCoin.fromJson(Map.from(e))),
    ...getXRPBlockChains().map((e) => XRPCoin.fromJson(Map.from(e))),
    ...getNearBlockChains().map((e) => NearCoin.fromJson(Map.from(e))),
    ...getCosmosBlockChains().map((e) => CosmosCoin.fromJson(Map.from(e))),
    ...getStellarBlockChains().map((e) => StellarCoin.fromJson(Map.from(e))),
    ...getSolanaBlockChains().map((e) => SolanaCoin.fromJson(Map.from(e))),
    ...getAlgorandBlockchains().map((e) => AlgorandCoin.fromJson(Map.from(e))),
    ...getTronBlockchains().map((e) => TronCoin.fromJson(Map.from(e))),
    ...getPolkadoBlockChains().map((e) => PolkadotCoin.fromJson(Map.from(e))),
    ...getRoninBlockchains().map((e) => RoninCoin.fromJson(Map.from(e))),
  ]..sort((a, b) => a.name_().compareTo(b.name_()));
}

Box pref;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize();
  await Hive.initFlutter();

  FocusManager.instance.primaryFocus?.unfocus();
  // make app always in portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kReleaseMode) {
      return Container();
    }
    return Container(
      color: Colors.red,
      child: Center(
        child: Text(
          details.exceptionAsString(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  };
  const _secureEncryptionKey = 'encryptionKeyekalslslaidkeiaoa';
  const FlutterSecureStorage secureStorage = FlutterSecureStorage();
  var containsEncryptionKey =
      await secureStorage.containsKey(key: _secureEncryptionKey);
  if (!containsEncryptionKey) {
    var key = Hive.generateSecureKey();
    await secureStorage.write(
      key: _secureEncryptionKey,
      value: base64UrlEncode(key),
    );
  }

  var encryptionKey =
      base64Url.decode(await secureStorage.read(key: _secureEncryptionKey));
  pref = await Hive.openBox(
    secureStorageKey,
    encryptionCipher: HiveAesCipher(encryptionKey),
  );

  await reInstianteSeedRoot();
  await WebNotificationPermissionDb.loadSavedPermissions();
  getAllBlockchains = await getAllBlockchains_fun();
  runApp(
    MyApp(
      userDarkMode: pref.get(darkModekey, defaultValue: true),
      locale: Locale.fromSubtags(
        languageCode: pref.get(languageKey, defaultValue: 'en'),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  static ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

  static bool getCoinGeckoData = true;
  static DateTime lastcoinGeckoData = DateTime.now();

  final bool userDarkMode;
  final Locale locale;

  const MyApp({Key key, this.userDarkMode, this.locale}) : super(key: key);
  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale;

  @override
  initState() {
    super.initState();
    _locale = widget.locale;
  }

  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    MyApp.themeNotifier.value =
        widget.userDarkMode ? ThemeMode.dark : ThemeMode.light;

    return ValueListenableBuilder(
      valueListenable: MyApp.themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarBrightness: currentMode == ThemeMode.light
                ? Brightness.light
                : Brightness.dark,
            statusBarColor: Colors.black,
          ),
        );
        return MaterialApp(
          navigatorKey: NavigationService.navigatorKey, // set property
          debugShowCheckedModeBanner: false,
          locale: _locale,
          theme: lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          darkTheme: darkTheme,
          themeMode: currentMode,
          home: const MyHomePage(),
          scrollBehavior: const CupertinoScrollBehavior(),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  BuildContext context;

  @override
  initState() {
    super.initState();
    WcConnector();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSplashScreen.withScreenFunction(
        curve: Curves.linear,
        splashIconSize: 100,
        backgroundColor: Theme.of(context).backgroundColor,
        disableNavigation: true,
        splash: 'assets/logo.png',
        screenFunction: () async {
          final bool hasWallet = pref.get(currentMmenomicKey) != null;

          final bool hasPasscode = pref.get(userUnlockPasscodeKey) != null;
          final int hasUnlockTime = pref.get(appUnlockTime, defaultValue: 1);
          bool isAuthenticated = false;

          if (hasUnlockTime > 1) {
            return OpenAppPinFailed(remainSec: hasUnlockTime);
          }

          if (hasWallet) {
            isAuthenticated = await authenticate(
              context,
              disableGoBack_: true,
            );
          }

          if (hasWallet && !isAuthenticated) return const OpenAppPinFailed();

          if (hasWallet) return const Wallet();

          if (hasPasscode) return const MainScreen();

          return const Security();
        },
        pageTransitionType: PageTransitionType.rightToLeft,
      ),
    );
  }
}
