import 'dart:convert';
import 'dart:math';
import 'dart:ffi';

import 'package:algorand_dart/algorand_dart.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' hide Wallet;
import 'package:cryptowallet/screens/navigator_service.dart';
import 'package:cryptowallet/screens/open_app_pin_failed.dart';
import 'package:cryptowallet/screens/security.dart';
import 'package:cryptowallet/screens/wallet.dart';
import 'package:cryptowallet/utils/app_config.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:cryptowallet/utils/wc_connector.dart';
import 'package:cryptowallet/utils/web_notifications.dart';
import 'package:cryptowallet/xrp_transaction/xrp_transaction.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:elliptic/elliptic.dart';
import 'package:secp256k1/secp256k1.dart' as secp256k1;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hash/hash.dart';
// import 'package:pointycastle/pointycastle.dart';
import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';
import 'package:secp256k1/secp256k1.dart' as secp256k1;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:web3dart/crypto.dart';

import 'screens/main_screen.dart';

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
  final transactionJson = {
    "Account": "rUGmHgeFC6bRRG8r6gqP9FkZUtfRqGsH4x",
    "Fee": "485600",
    "Sequence": 3882,
    "LastLedgerSequence": 789282,
    "TransactionType": "Payment",
    "SigningPubKey": "abc38383833def",
    "Amount": "1388920",
    "Destination": "rPRiXRLGkw5hVwP5NePE2tXTQPi684bzrz"
  };
  const FlutterSecureStorage secureStorage = FlutterSecureStorage();
  var containsEncryptionKey =
      await secureStorage.containsKey(key: secureEncryptionKey);
  if (!containsEncryptionKey) {
    var key = Hive.generateSecureKey();
    await secureStorage.write(
      key: secureEncryptionKey,
      value: base64UrlEncode(key),
    );
  }

  var encryptionKey =
      base64Url.decode(await secureStorage.read(key: secureEncryptionKey));
  final pref = await Hive.openBox(secureStorageKey,
      encryptionCipher: HiveAesCipher(encryptionKey));

  await reInstianteSeedRoot();
  await WebNotificationPermissionDb.loadSavedPermissions();
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
        disableNavigation: true,
        splashIconSize: 100,
        backgroundColor: Theme.of(context).backgroundColor,
        splash: 'assets/logo.png',
        screenFunction: () async {
          final pref = Hive.box(secureStorageKey);
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
        splashTransition: SplashTransition.slideTransition,
        pageTransitionType: PageTransitionType.rightToLeft,
      ),
    );
  }
}
