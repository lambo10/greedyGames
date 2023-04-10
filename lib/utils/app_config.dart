import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const walletAbbr = 'GVERSE';

const walletName = 'GreedyVerse';
const walletURL = "https://greedyverse.co/";
const walletIconURL = "https://greedyverse.co/api/GV.png";
const walletDexProviderUrl = 'https://pancakeswap.finance/swap';
const stakeDexProviderUrl = 'https://pancakeswap.finance/pools';
const fiatDexProviderUrl = 'https://paxful.com/';
const browserDexProviderUrl = 'https://duckduckgo.com/';
// addresses
const tokenContractAddress = '0x6F155F1cB165635e189062a3e6e3617184E52672';
const tokenSaleContractAddress = "0x8ad2B931A9aB12caA19DdBe9b4cdF69a9f261374";
const tokenStakingContractAddress =
    '0xa85037b56Dc212eEa0DFBd76aFDfF47EB33650F9';
const busdAddress = '0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56';

const mnemonicKey = 'mnemonic';

// token sale
const minimumNetworkTokenForSwap = 1;

// networks -> check rpcurl.dart for more info
const tokenContractNetwork = 'Smart Chain';
const tokenSaleContractNetwork = "Smart Chain";
const tokenStakingContractNetwork = 'Polygon (Mumbai)';

// dapp links
const blogUrl = 'https://greedyverse.co/';
const vrUrl = 'https://opensea.io/category/virtual-worlds';
const marketPlaceUrl = 'https://refinable.com/';
const ecommerceUrl = 'https://opensea.com';

// social media links
const telegramLink = 'https://t.me/GreedyVerse_Portal';
const twitterLink = 'https://www.twitter.com/GreedyVerse';
const mediumLink = 'https://medium.com/@greedyverseproject';
// const linkedInLink = 'https://www.linkedin.com/in/';
// const redditLink = 'https://reddit.com/r/';
// const discordLink = 'https://discord.gg/';
// const facebookLink = 'https://facebook.com/';
// const instagramLink = 'https://instagram.com/';

// color
const settingIconColor = Colors.white;
const dividerColor = Color(0xffE6E6E3);
const appPrimaryColor = Color.fromARGB(255, 233, 183, 9);
const red = Color(0xffeb6a61);
const green = Color(0xff01aa78);
const grey = Colors.grey;
const colorForAddress = Color(0xffEBF3FF);
const appBackgroundblue = Color.fromARGB(255, 233, 183, 9);
const appBackgroundblueDim = Color.fromARGB(140, 233, 185, 9);
const portfolioCardColor = Color.fromARGB(255, 75, 75, 75);
const portfolioCardColorLowerSection = Color.fromARGB(255, 39, 39, 39);
const orangTxt = Colors.orange;
const primaryMaterialColor = MaterialColor(
  0xff2469E9,
  <int, Color>{
    50: appPrimaryColor,
    100: appPrimaryColor,
    200: appPrimaryColor,
    300: appPrimaryColor,
    400: appPrimaryColor,
    500: appPrimaryColor,
    600: appPrimaryColor,
    700: appPrimaryColor,
    800: appPrimaryColor,
    900: appPrimaryColor,
  },
);

// security
const secureStorageKey = 'box28aldk3qka';
const alchemyEthMainnetApiKey = 'DyEtOvLwpEw43cr-lTgQWre7HfjPeUlq';
const alchemyEthGoerliApiKey = 's00aWtjDOmCnUYS7cFBFIL3fbVCzsc8Z';
const alchemyMumbaiApiKey = 'gpR0c9Le2dR45Fqit9OXTz6dtpf1HPfa';
const alchemyPolygonApiKey = 'DtU0__wTk6KUpZElU8pYQRpaHK0b8mip';
const rampApiKey = '9842oj9c45xuzc93bm7zd7z4rn8cub3fs45decqh';
const bscApiKey = '2WQ9Q2TTNSMD5DJ7GJR8F7TAEMZUCNCI5B';
const tronGridApiKey = 'e09b6df9-0abc-4463-a623-43eaf291ef22';

List getAlchemyNFTs() {
  List allowedNFTNames = [
    'Ethereum',
    'Polygon Matic',
  ];

  if (enableTestNet) {
    allowedNFTNames.addAll([
      'Polygon (Mumbai)',
      'Ethereum(Goerli)',
    ]);
  }
  return allowedNFTNames;
}

const infuraApiKey = '53163c736f1d4ba78f0a39ffda8d87b4';
const pureStakeApiKey = 'G322hXkYM4749xUANJXm02d6M98WvYjtaWeAgJ4m';
const seedRootKey = 'seedRoot';

// settings key...not to be edited
const addcontactKey = 'addContactdk383laskdnco3';
const biometricsKey = 's3ialdkal3aksleidla83aidildilsiei83019';
const userUnlockPasscodeKey = 'userUnlockPasscode';
const languageKey = 'languageksks38q830qialdkjd';
const darkModekey = 'userTheme';
const hideBalanceKey = 'hideUserBalance';
const wcSessionKey = 'slswalletcondkdkaleiealdidkeianekdkk22a';
const dappChainIdKey = 'dappBrowserChainIdKey';
const eIP681ProcessingErrorMsg =
    'Ethereum request format not supported or Network Time Out';
const personalSignKey = 'Personal';
const normalSignKey = 'Normal Sign';
const typedMessageSignKey = "Typed Message";
const userSignInDataKey = 'user-sign-in-data';
const mnemonicListKey = 'mnemonics_List';
const currentMmenomicKey = 'mmemomic_mnemonic';
const currentUserWalletNameKey = 'current__walletNameKey';
const coinGeckoCryptoPriceKey = 'cryptoPricesKey';
const bookMarkKey = 'bookMarks';
const historyKey = 'broswer_kehsi_history';
const coinMarketCapApiKey = 'a4e88d80-acc3-4bb5-a8a6-151a2ddb5f32';
const newEVMChainKey = 'skskalskslskssaieii3ladkaldkadieiaa;ss';
const appUnlockTime = 'applockksksietimeal382';
// template tags
const transactionhashTemplateKey = '{{TransactionHash}}';

// enable
const enableTestNet = kDebugMode;

// app theme
final darkTheme = ThemeData(
  dialogBackgroundColor: const Color.fromARGB(255, 26, 26, 26),
  fontFamily: 'Roboto',
  primaryColor: const Color.fromARGB(255, 233, 183, 9),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    unselectedItemColor: Colors.white,
    backgroundColor: Color.fromARGB(255, 47, 47, 47),
    selectedItemColor: Color.fromARGB(255, 233, 183, 9),
  ),
  backgroundColor: const Color.fromARGB(255, 26, 26, 26),
  scaffoldBackgroundColor: const Color.fromARGB(255, 26, 26, 26),
  cardColor: const Color.fromARGB(255, 47, 47, 47),
  dividerColor: const Color.fromARGB(255, 57, 57, 57),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Color.fromARGB(255, 26, 26, 26),
  ),
  colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.grey).copyWith(
    secondary: Colors.white,
    brightness: Brightness.dark,
    surface: const Color.fromARGB(255, 47, 47, 47),
    onSurface: Colors.white,
  ),
);

final lightTheme = ThemeData(
  appBarTheme: const AppBarTheme(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
    ),
  ),
  fontFamily: 'Roboto',
  primaryColor: Colors.white,
  backgroundColor: const Color(0xFFE5E5E5),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    type: BottomNavigationBarType.fixed,
    backgroundColor: Color(0xffEBF3FF),
    unselectedItemColor: Colors.grey,
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: MaterialStateProperty.all(appPrimaryColor),
    checkColor: MaterialStateProperty.all(appPrimaryColor),
    overlayColor: MaterialStateProperty.all(appPrimaryColor),
  ),
  dividerColor: dividerColor,
  colorScheme:
      ColorScheme.fromSwatch(primarySwatch: primaryMaterialColor).copyWith(
    secondary: Colors.black,
    brightness: Brightness.light,
  ),
);

// preferences keys and app data
const userPinTrials = 3;
const pinLength = 6;
const maximumTransactionToSave = 30;
const maximumBrowserHistoryToSave = 20;
