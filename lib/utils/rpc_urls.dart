import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:base_x/base_x.dart';
import 'package:crypto/crypto.dart';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart' as cardano;
import 'package:algorand_dart/algorand_dart.dart' as algo_rand;
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:bech32/bech32.dart';
import 'package:cryptowallet/main.dart';
import 'package:cryptowallet/screens/security.dart';
import 'package:cryptowallet/utils/bitcoin_util.dart';
import 'package:cryptowallet/utils/json_viewer.dart';
import 'package:cryptowallet/validate_tezos.dart';
import 'package:dartez/dartez.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:eth_sig_util/util/utils.dart' hide hexToBytes, bytesToHex;
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:hash/hash.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sacco/sacco.dart' as cosmos;
import 'package:bs58check/bs58check.dart' as bs58check;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart' as stellar
    hide Row;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cryptowallet/utils/slide_up_panel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:validators/validators.dart';
import 'package:wallet/wallet.dart' as wallet;
import 'package:wallet_connect/wallet_connect.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart' as web3;
import 'package:web3dart/web3dart.dart';
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';
import 'package:local_auth/local_auth.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:http/http.dart' as http;
import 'package:solana/solana.dart' as solana;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bitbox/bitbox.dart' as bitbox;
import 'package:hex/hex.dart';

import '../components/loader.dart';
import '../eip/eip681.dart';
import '../model/seed_phrase_root.dart';
import '../screens/build_row.dart';
import '../screens/dapp.dart';
import 'alt_ens.dart';
import 'app_config.dart';
import 'pos_networks.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

// crypto decimals
const etherDecimals = 18;
const bitCoinDecimals = 8;
const cardanoDecimals = 6;
const cosmosDecimals = 6;
const xrpDecimals = 6;
const fileCoinDecimals = 18;
const solanaDecimals = 9;
const satoshiDustAmount = 546;
const stellarDecimals = 6;
const algorandDecimals = 6;
const tezorDecimals = 6;
const int maxFeeGuessForCardano = 200000;

// time
const Duration networkTimeOutDuration = Duration(seconds: 15);
const Duration httpPollingDelay = Duration(seconds: 15);

// extra seedValues.
SeedPhraseRoot seedPhraseRoot;

// useful ether addresses
const zeroAddress = '0x0000000000000000000000000000000000000000';
const deadAddress = '0x000000000000000000000000000000000000dEaD';
const nativeTokenAddress = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
const ensInterfaceAddress = '0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e';
const coinGeckoBaseurl = 'https://api.coingecko.com/api/v3';

// third party urls
const coinGeckoSupportedCurrencies =
    '$coinGeckoBaseurl/simple/supported_vs_currencies';

// abi's
const uniswapAbi2 =
    '''[{"inputs":[{"internalType":"address","name":"_factoryV2","type":"address"},{"internalType":"address","name":"factoryV3","type":"address"},{"internalType":"address","name":"_positionManager","type":"address"},{"internalType":"address","name":"_WETH9","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[],"name":"WETH9","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"}],"name":"approveMax","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"}],"name":"approveMaxMinusOne","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"}],"name":"approveZeroThenMax","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"}],"name":"approveZeroThenMaxMinusOne","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"bytes","name":"data","type":"bytes"}],"name":"callPositionManager","outputs":[{"internalType":"bytes","name":"result","type":"bytes"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"bytes[]","name":"paths","type":"bytes[]"},{"internalType":"uint128[]","name":"amounts","type":"uint128[]"},{"internalType":"uint24","name":"maximumTickDivergence","type":"uint24"},{"internalType":"uint32","name":"secondsAgo","type":"uint32"}],"name":"checkOracleSlippage","outputs":[],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes","name":"path","type":"bytes"},{"internalType":"uint24","name":"maximumTickDivergence","type":"uint24"},{"internalType":"uint32","name":"secondsAgo","type":"uint32"}],"name":"checkOracleSlippage","outputs":[],"stateMutability":"view","type":"function"},{"inputs":[{"components":[{"internalType":"bytes","name":"path","type":"bytes"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amountIn","type":"uint256"},{"internalType":"uint256","name":"amountOutMinimum","type":"uint256"}],"internalType":"struct IV3SwapRouter.ExactInputParams","name":"params","type":"tuple"}],"name":"exactInput","outputs":[{"internalType":"uint256","name":"amountOut","type":"uint256"}],"stateMutability":"payable","type":"function"},{"inputs":[{"components":[{"internalType":"address","name":"tokenIn","type":"address"},{"internalType":"address","name":"tokenOut","type":"address"},{"internalType":"uint24","name":"fee","type":"uint24"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amountIn","type":"uint256"},{"internalType":"uint256","name":"amountOutMinimum","type":"uint256"},{"internalType":"uint160","name":"sqrtPriceLimitX96","type":"uint160"}],"internalType":"struct IV3SwapRouter.ExactInputSingleParams","name":"params","type":"tuple"}],"name":"exactInputSingle","outputs":[{"internalType":"uint256","name":"amountOut","type":"uint256"}],"stateMutability":"payable","type":"function"},{"inputs":[{"components":[{"internalType":"bytes","name":"path","type":"bytes"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amountOut","type":"uint256"},{"internalType":"uint256","name":"amountInMaximum","type":"uint256"}],"internalType":"struct IV3SwapRouter.ExactOutputParams","name":"params","type":"tuple"}],"name":"exactOutput","outputs":[{"internalType":"uint256","name":"amountIn","type":"uint256"}],"stateMutability":"payable","type":"function"},{"inputs":[{"components":[{"internalType":"address","name":"tokenIn","type":"address"},{"internalType":"address","name":"tokenOut","type":"address"},{"internalType":"uint24","name":"fee","type":"uint24"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amountOut","type":"uint256"},{"internalType":"uint256","name":"amountInMaximum","type":"uint256"},{"internalType":"uint160","name":"sqrtPriceLimitX96","type":"uint160"}],"internalType":"struct IV3SwapRouter.ExactOutputSingleParams","name":"params","type":"tuple"}],"name":"exactOutputSingle","outputs":[{"internalType":"uint256","name":"amountIn","type":"uint256"}],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"factory","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"factoryV2","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"getApprovalType","outputs":[{"internalType":"enum IApproveAndCall.ApprovalType","name":"","type":"uint8"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"components":[{"internalType":"address","name":"token0","type":"address"},{"internalType":"address","name":"token1","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"uint256","name":"amount0Min","type":"uint256"},{"internalType":"uint256","name":"amount1Min","type":"uint256"}],"internalType":"struct IApproveAndCall.IncreaseLiquidityParams","name":"params","type":"tuple"}],"name":"increaseLiquidity","outputs":[{"internalType":"bytes","name":"result","type":"bytes"}],"stateMutability":"payable","type":"function"},{"inputs":[{"components":[{"internalType":"address","name":"token0","type":"address"},{"internalType":"address","name":"token1","type":"address"},{"internalType":"uint24","name":"fee","type":"uint24"},{"internalType":"int24","name":"tickLower","type":"int24"},{"internalType":"int24","name":"tickUpper","type":"int24"},{"internalType":"uint256","name":"amount0Min","type":"uint256"},{"internalType":"uint256","name":"amount1Min","type":"uint256"},{"internalType":"address","name":"recipient","type":"address"}],"internalType":"struct IApproveAndCall.MintParams","name":"params","type":"tuple"}],"name":"mint","outputs":[{"internalType":"bytes","name":"result","type":"bytes"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"previousBlockhash","type":"bytes32"},{"internalType":"bytes[]","name":"data","type":"bytes[]"}],"name":"multicall","outputs":[{"internalType":"bytes[]","name":"","type":"bytes[]"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"bytes[]","name":"data","type":"bytes[]"}],"name":"multicall","outputs":[{"internalType":"bytes[]","name":"","type":"bytes[]"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"bytes[]","name":"data","type":"bytes[]"}],"name":"multicall","outputs":[{"internalType":"bytes[]","name":"results","type":"bytes[]"}],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"positionManager","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"pull","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"refundETH","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"selfPermit","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"nonce","type":"uint256"},{"internalType":"uint256","name":"expiry","type":"uint256"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"selfPermitAllowed","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"nonce","type":"uint256"},{"internalType":"uint256","name":"expiry","type":"uint256"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"selfPermitAllowedIfNecessary","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"selfPermitIfNecessary","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountIn","type":"uint256"},{"internalType":"uint256","name":"amountOutMin","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"},{"internalType":"address","name":"to","type":"address"}],"name":"swapExactTokensForTokens","outputs":[{"internalType":"uint256","name":"amountOut","type":"uint256"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountOut","type":"uint256"},{"internalType":"uint256","name":"amountInMax","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"},{"internalType":"address","name":"to","type":"address"}],"name":"swapTokensForExactTokens","outputs":[{"internalType":"uint256","name":"amountIn","type":"uint256"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"amountMinimum","type":"uint256"},{"internalType":"address","name":"recipient","type":"address"}],"name":"sweepToken","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"amountMinimum","type":"uint256"}],"name":"sweepToken","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"amountMinimum","type":"uint256"},{"internalType":"uint256","name":"feeBips","type":"uint256"},{"internalType":"address","name":"feeRecipient","type":"address"}],"name":"sweepTokenWithFee","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"amountMinimum","type":"uint256"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"feeBips","type":"uint256"},{"internalType":"address","name":"feeRecipient","type":"address"}],"name":"sweepTokenWithFee","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"int256","name":"amount0Delta","type":"int256"},{"internalType":"int256","name":"amount1Delta","type":"int256"},{"internalType":"bytes","name":"_data","type":"bytes"}],"name":"uniswapV3SwapCallback","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountMinimum","type":"uint256"},{"internalType":"address","name":"recipient","type":"address"}],"name":"unwrapWETH9","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountMinimum","type":"uint256"}],"name":"unwrapWETH9","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountMinimum","type":"uint256"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"feeBips","type":"uint256"},{"internalType":"address","name":"feeRecipient","type":"address"}],"name":"unwrapWETH9WithFee","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountMinimum","type":"uint256"},{"internalType":"uint256","name":"feeBips","type":"uint256"},{"internalType":"address","name":"feeRecipient","type":"address"}],"name":"unwrapWETH9WithFee","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"value","type":"uint256"}],"name":"wrapETH","outputs":[],"stateMutability":"payable","type":"function"},{"stateMutability":"payable","type":"receive"}]''';
const wrappedEthAbi =
    '''[{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"guy","type":"address"},{"name":"wad","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"src","type":"address"},{"name":"dst","type":"address"},{"name":"wad","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"wad","type":"uint256"}],"name":"withdraw","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"dst","type":"address"},{"name":"wad","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[],"name":"deposit","outputs":[],"payable":true,"stateMutability":"payable","type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"},{"name":"","type":"address"}],"name":"allowance","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"payable":true,"stateMutability":"payable","type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"src","type":"address"},{"indexed":true,"name":"guy","type":"address"},{"indexed":false,"name":"wad","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"src","type":"address"},{"indexed":true,"name":"dst","type":"address"},{"indexed":false,"name":"wad","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"dst","type":"address"},{"indexed":false,"name":"wad","type":"uint256"}],"name":"Deposit","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"src","type":"address"},{"indexed":false,"name":"wad","type":"uint256"}],"name":"Withdrawal","type":"event"}]''';
const uniswapAbi =
    '''[{"inputs":[{"internalType":"address","name":"_factory","type":"address"},{"internalType":"address","name":"_WETH","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[],"name":"WETH","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"tokenA","type":"address"},{"internalType":"address","name":"tokenB","type":"address"},{"internalType":"uint256","name":"amountADesired","type":"uint256"},{"internalType":"uint256","name":"amountBDesired","type":"uint256"},{"internalType":"uint256","name":"amountAMin","type":"uint256"},{"internalType":"uint256","name":"amountBMin","type":"uint256"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"addLiquidity","outputs":[{"internalType":"uint256","name":"amountA","type":"uint256"},{"internalType":"uint256","name":"amountB","type":"uint256"},{"internalType":"uint256","name":"liquidity","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"amountTokenDesired","type":"uint256"},{"internalType":"uint256","name":"amountTokenMin","type":"uint256"},{"internalType":"uint256","name":"amountETHMin","type":"uint256"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"addLiquidityETH","outputs":[{"internalType":"uint256","name":"amountToken","type":"uint256"},{"internalType":"uint256","name":"amountETH","type":"uint256"},{"internalType":"uint256","name":"liquidity","type":"uint256"}],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"factory","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountOut","type":"uint256"},{"internalType":"uint256","name":"reserveIn","type":"uint256"},{"internalType":"uint256","name":"reserveOut","type":"uint256"}],"name":"getAmountIn","outputs":[{"internalType":"uint256","name":"amountIn","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountIn","type":"uint256"},{"internalType":"uint256","name":"reserveIn","type":"uint256"},{"internalType":"uint256","name":"reserveOut","type":"uint256"}],"name":"getAmountOut","outputs":[{"internalType":"uint256","name":"amountOut","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountOut","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"}],"name":"getAmountsIn","outputs":[{"internalType":"uint256[]","name":"amounts","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountIn","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"}],"name":"getAmountsOut","outputs":[{"internalType":"uint256[]","name":"amounts","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountA","type":"uint256"},{"internalType":"uint256","name":"reserveA","type":"uint256"},{"internalType":"uint256","name":"reserveB","type":"uint256"}],"name":"quote","outputs":[{"internalType":"uint256","name":"amountB","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"address","name":"tokenA","type":"address"},{"internalType":"address","name":"tokenB","type":"address"},{"internalType":"uint256","name":"liquidity","type":"uint256"},{"internalType":"uint256","name":"amountAMin","type":"uint256"},{"internalType":"uint256","name":"amountBMin","type":"uint256"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"removeLiquidity","outputs":[{"internalType":"uint256","name":"amountA","type":"uint256"},{"internalType":"uint256","name":"amountB","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"liquidity","type":"uint256"},{"internalType":"uint256","name":"amountTokenMin","type":"uint256"},{"internalType":"uint256","name":"amountETHMin","type":"uint256"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"removeLiquidityETH","outputs":[{"internalType":"uint256","name":"amountToken","type":"uint256"},{"internalType":"uint256","name":"amountETH","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"liquidity","type":"uint256"},{"internalType":"uint256","name":"amountTokenMin","type":"uint256"},{"internalType":"uint256","name":"amountETHMin","type":"uint256"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"removeLiquidityETHSupportingFeeOnTransferTokens","outputs":[{"internalType":"uint256","name":"amountETH","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"liquidity","type":"uint256"},{"internalType":"uint256","name":"amountTokenMin","type":"uint256"},{"internalType":"uint256","name":"amountETHMin","type":"uint256"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"bool","name":"approveMax","type":"bool"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"removeLiquidityETHWithPermit","outputs":[{"internalType":"uint256","name":"amountToken","type":"uint256"},{"internalType":"uint256","name":"amountETH","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"liquidity","type":"uint256"},{"internalType":"uint256","name":"amountTokenMin","type":"uint256"},{"internalType":"uint256","name":"amountETHMin","type":"uint256"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"bool","name":"approveMax","type":"bool"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"removeLiquidityETHWithPermitSupportingFeeOnTransferTokens","outputs":[{"internalType":"uint256","name":"amountETH","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"tokenA","type":"address"},{"internalType":"address","name":"tokenB","type":"address"},{"internalType":"uint256","name":"liquidity","type":"uint256"},{"internalType":"uint256","name":"amountAMin","type":"uint256"},{"internalType":"uint256","name":"amountBMin","type":"uint256"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"bool","name":"approveMax","type":"bool"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"removeLiquidityWithPermit","outputs":[{"internalType":"uint256","name":"amountA","type":"uint256"},{"internalType":"uint256","name":"amountB","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountOut","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"swapETHForExactTokens","outputs":[{"internalType":"uint256[]","name":"amounts","type":"uint256[]"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountOutMin","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"swapExactETHForTokens","outputs":[{"internalType":"uint256[]","name":"amounts","type":"uint256[]"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountOutMin","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"swapExactETHForTokensSupportingFeeOnTransferTokens","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountIn","type":"uint256"},{"internalType":"uint256","name":"amountOutMin","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"swapExactTokensForETH","outputs":[{"internalType":"uint256[]","name":"amounts","type":"uint256[]"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountIn","type":"uint256"},{"internalType":"uint256","name":"amountOutMin","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"swapExactTokensForETHSupportingFeeOnTransferTokens","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountIn","type":"uint256"},{"internalType":"uint256","name":"amountOutMin","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"swapExactTokensForTokens","outputs":[{"internalType":"uint256[]","name":"amounts","type":"uint256[]"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountIn","type":"uint256"},{"internalType":"uint256","name":"amountOutMin","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"swapExactTokensForTokensSupportingFeeOnTransferTokens","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountOut","type":"uint256"},{"internalType":"uint256","name":"amountInMax","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"swapTokensForExactETH","outputs":[{"internalType":"uint256[]","name":"amounts","type":"uint256[]"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountOut","type":"uint256"},{"internalType":"uint256","name":"amountInMax","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"swapTokensForExactTokens","outputs":[{"internalType":"uint256[]","name":"amounts","type":"uint256[]"}],"stateMutability":"nonpayable","type":"function"},{"stateMutability":"payable","type":"receive"}]''';
const oneInchAbi =
    '''[{"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"reason","type":"string"}],"name":"Error","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"sender","type":"address"},{"indexed":false,"internalType":"contract IERC20","name":"srcToken","type":"address"},{"indexed":false,"internalType":"contract IERC20","name":"dstToken","type":"address"},{"indexed":false,"internalType":"address","name":"dstReceiver","type":"address"},{"indexed":false,"internalType":"uint256","name":"spentAmount","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"returnAmount","type":"uint256"}],"name":"Swapped","type":"event"},{"inputs":[],"name":"destroy","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"contract IAggregationExecutor","name":"caller","type":"address"},{"components":[{"internalType":"contract IERC20","name":"srcToken","type":"address"},{"internalType":"contract IERC20","name":"dstToken","type":"address"},{"internalType":"address","name":"srcReceiver","type":"address"},{"internalType":"address","name":"dstReceiver","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"uint256","name":"minReturnAmount","type":"uint256"},{"internalType":"uint256","name":"flags","type":"uint256"},{"internalType":"bytes","name":"permit","type":"bytes"}],"internalType":"struct AggregationRouterV3.SwapDescription","name":"desc","type":"tuple"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"discountedSwap","outputs":[{"internalType":"uint256","name":"returnAmount","type":"uint256"},{"internalType":"uint256","name":"gasLeft","type":"uint256"},{"internalType":"uint256","name":"chiSpent","type":"uint256"}],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"contract IERC20","name":"token","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"rescueFunds","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"contract IAggregationExecutor","name":"caller","type":"address"},{"components":[{"internalType":"contract IERC20","name":"srcToken","type":"address"},{"internalType":"contract IERC20","name":"dstToken","type":"address"},{"internalType":"address","name":"srcReceiver","type":"address"},{"internalType":"address","name":"dstReceiver","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"uint256","name":"minReturnAmount","type":"uint256"},{"internalType":"uint256","name":"flags","type":"uint256"},{"internalType":"bytes","name":"permit","type":"bytes"}],"internalType":"struct AggregationRouterV3.SwapDescription","name":"desc","type":"tuple"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"swap","outputs":[{"internalType":"uint256","name":"returnAmount","type":"uint256"},{"internalType":"uint256","name":"gasLeft","type":"uint256"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"contract IERC20","name":"srcToken","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"uint256","name":"minReturn","type":"uint256"},{"internalType":"bytes32[]","name":"","type":"bytes32[]"}],"name":"unoswap","outputs":[{"internalType":"uint256","name":"returnAmount","type":"uint256"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"contract IERC20","name":"srcToken","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"uint256","name":"minReturn","type":"uint256"},{"internalType":"bytes32[]","name":"pools","type":"bytes32[]"},{"internalType":"bytes","name":"permit","type":"bytes"}],"name":"unoswapWithPermit","outputs":[{"internalType":"uint256","name":"returnAmount","type":"uint256"}],"stateMutability":"payable","type":"function"},{"stateMutability":"payable","type":"receive"}]''';
const erc1155Abi =
    '''[{"inputs":[{"internalType":"string","name":"uri_","type":"string"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":false,"internalType":"bool","name":"approved","type":"bool"}],"name":"ApprovalForAll","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256[]","name":"ids","type":"uint256[]"},{"indexed":false,"internalType":"uint256[]","name":"values","type":"uint256[]"}],"name":"TransferBatch","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"TransferSingle","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"value","type":"string"},{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"}],"name":"URI","type":"event"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"id","type":"uint256"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"accounts","type":"address[]"},{"internalType":"uint256[]","name":"ids","type":"uint256[]"}],"name":"balanceOfBatch","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"address","name":"operator","type":"address"}],"name":"isApprovedForAll","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256[]","name":"ids","type":"uint256[]"},{"internalType":"uint256[]","name":"amounts","type":"uint256[]"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"safeBatchTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"operator","type":"address"},{"internalType":"bool","name":"approved","type":"bool"}],"name":"setApprovalForAll","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes4","name":"interfaceId","type":"bytes4"}],"name":"supportsInterface","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"uri","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"}]''';
const erc721Abi =
    '''[{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"approved","type":"address"},{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":false,"internalType":"bool","name":"approved","type":"bool"}],"name":"ApprovalForAll","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Transfer","type":"event"},{"inputs":[],"name":"TOKEN_LIMIT","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"admin","outputs":[{"internalType":"address payable","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"uint256","name":"priceInWei","type":"uint256"}],"name":"allowBuy","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"approve","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"burn","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_tokenId","type":"uint256"}],"name":"buy","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"createTokenId","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_tokenId","type":"uint256"}],"name":"disallowBuy","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"getApproved","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getMintingPrice","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"operator","type":"address"}],"name":"isApprovedForAll","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"mint","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"mintedNFTPrices","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"mintingPrice","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"ownerOf","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"bytes","name":"_data","type":"bytes"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"operator","type":"address"},{"internalType":"bool","name":"approved","type":"bool"}],"name":"setApprovalForAll","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_mintingPrice","type":"uint256"}],"name":"setMintingPrice","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"baseURL","type":"string"}],"name":"setTokenBaseURL","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes4","name":"interfaceId","type":"bytes4"}],"name":"supportsInterface","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"tokenBaseURL","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"index","type":"uint256"}],"name":"tokenByIndex","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"tokenForSale","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"uint256","name":"index","type":"uint256"}],"name":"tokenOfOwnerByIndex","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"tokenURI","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalItemForSale","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"trans","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"transferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"}]''';
const erc20Abi =
    '''[{"inputs":[{"internalType":"string","name":"name_","type":"string"},{"internalType":"string","name":"symbol_","type":"string"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"subtractedValue","type":"uint256"}],"name":"decreaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"addedValue","type":"uint256"}],"name":"increaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"}]''';
const tokenSaleAbi =
    '''[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_from","type":"address"},{"indexed":false,"internalType":"uint256","name":"_value","type":"uint256"}],"name":"Deposit","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"tokenName","type":"string"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"gverseEquivalent","type":"uint256"}],"name":"PaymentReceived","type":"event"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approveBusdExpenditure","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approveGverseExpenditure","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"buyBusd","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"int256","name":"_vestingNo","type":"int256"}],"name":"claim","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"depositeGVERSE","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"receiveBNB","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"receiveBUSD","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"string","name":"tokenUsed","type":"string"},{"internalType":"uint256","name":"gverseEquivalent","type":"uint256"}],"name":"registerPayment","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_removalAddress","type":"address"}],"name":"removeBusdReminats","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_removalAddress","type":"address"}],"name":"removeGverseReminats","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_busd_contract_address","type":"address"}],"name":"set_busd_contract_address","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_gverse_contract_address","type":"address"}],"name":"set_gverse_contract_address","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"_startClaim","type":"bool"}],"name":"setStartClaim","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_walletAddress","type":"address"},{"internalType":"uint256","name":"_gverse_usd_conversion_rate","type":"uint256"}],"name":"setTeamAddressAndRate","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_usd_minimumPurchase","type":"uint256"}],"name":"setUsd_minimumPurchase","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_claimPercentage","type":"uint256"},{"internalType":"int256","name":"_vestingNo","type":"int256"}],"name":"setVestingScheduleClaimPercentage","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_timestamp","type":"uint256"},{"internalType":"int256","name":"_vestingNo","type":"int256"}],"name":"setVestingScheduleTime","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[],"name":"busd_token","outputs":[{"internalType":"contract IERC20","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"int256","name":"","type":"int256"}],"name":"claimedTokenFlags","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"bnbvalue","type":"uint256"}],"name":"getBNBtoBusdPrice","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"gverse_token","outputs":[{"internalType":"contract IERC20","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"gverse_usd_conversion_rate","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"gversePurchases","outputs":[{"internalType":"string","name":"tokenUsed","type":"string"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"uint256","name":"gverseEquivalent","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pancakeswapV2Router","outputs":[{"internalType":"contract IPancakeRouter02","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalTokensSold","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"usd_minimumPurchase","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"int256","name":"","type":"int256"}],"name":"vestingSchedule","outputs":[{"internalType":"uint256","name":"time","type":"uint256"},{"internalType":"uint256","name":"claimPercentage","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"walletAddress","outputs":[{"internalType":"address payable","name":"","type":"address"}],"stateMutability":"view","type":"function"}]''';
const tokenStakingAbi =
    '''[{"inputs":[{"internalType":"address","name":"_rewardNftCollection","type":"address"},{"internalType":"contract IERC20","name":"_rewardToken","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"inputs":[{"internalType":"address","name":"_staker","type":"address"}],"name":"availableRewards","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"balance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"claimRewards","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"commission","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_staker","type":"address"}],"name":"getStakerDetails","outputs":[{"internalType":"uint256","name":"_amountStaked","type":"uint256"},{"internalType":"uint256","name":"_lastUpdate","type":"uint256"},{"internalType":"uint256","name":"_unclaimedRewards","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getTotalRewardsClaimed","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"minimumStakeAmount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"minimumStakePeriod","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"rewardNftCollection","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"rewardPool","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"rewardToken","outputs":[{"internalType":"contract IERC20","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_commission","type":"uint256"}],"name":"setCommission","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_minimumStakeAmount","type":"uint256"}],"name":"setMinimumStake","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_minimumStakePeriod","type":"uint256"}],"name":"setMinimumStakePeriod","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_rewardNftCollection","type":"address"}],"name":"setRewardNftCollection","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_rewardPerHour","type":"uint256"}],"name":"setRewardPerHour","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_rewardPool","type":"address"}],"name":"setRewardPool","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"contract IERC20","name":"_rewardToken","type":"address"}],"name":"setRewardToken","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"stake","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"stakers","outputs":[{"internalType":"uint256","name":"amountStaked","type":"uint256"},{"internalType":"uint256","name":"timeOfLastUpdate","type":"uint256"},{"internalType":"uint256","name":"unclaimedRewards","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalAmountStaked","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalRewardClaimed","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_newOwner","type":"address"}],"name":"tranferOwner","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"unStake","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"withdraw","outputs":[],"stateMutability":"nonpayable","type":"function"}]''';
const unstoppableDomainAbi =
    '''[{"inputs":[{"internalType":"contract IUNSRegistry","name":"unsRegistry","type":"address"},{"internalType":"contract ICNSRegistry","name":"cnsRegistry","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[],"name":"NAME","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"VERSION","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"string","name":"label","type":"string"}],"name":"childIdOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"exists","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"key","type":"string"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"get","outputs":[{"internalType":"string","name":"value","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"getApproved","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"keyHash","type":"uint256"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"getByHash","outputs":[{"internalType":"string","name":"key","type":"string"},{"internalType":"string","name":"value","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string[]","name":"keys","type":"string[]"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"getData","outputs":[{"internalType":"address","name":"resolver","type":"address"},{"internalType":"address","name":"owner","type":"address"},{"internalType":"string[]","name":"values","type":"string[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256[]","name":"keyHashes","type":"uint256[]"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"getDataByHash","outputs":[{"internalType":"address","name":"resolver","type":"address"},{"internalType":"address","name":"owner","type":"address"},{"internalType":"string[]","name":"keys","type":"string[]"},{"internalType":"string[]","name":"values","type":"string[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256[]","name":"keyHashes","type":"uint256[]"},{"internalType":"uint256[]","name":"tokenIds","type":"uint256[]"}],"name":"getDataByHashForMany","outputs":[{"internalType":"address[]","name":"resolvers","type":"address[]"},{"internalType":"address[]","name":"owners","type":"address[]"},{"internalType":"string[][]","name":"keys","type":"string[][]"},{"internalType":"string[][]","name":"values","type":"string[][]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string[]","name":"keys","type":"string[]"},{"internalType":"uint256[]","name":"tokenIds","type":"uint256[]"}],"name":"getDataForMany","outputs":[{"internalType":"address[]","name":"resolvers","type":"address[]"},{"internalType":"address[]","name":"owners","type":"address[]"},{"internalType":"string[][]","name":"values","type":"string[][]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string[]","name":"keys","type":"string[]"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"getMany","outputs":[{"internalType":"string[]","name":"values","type":"string[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256[]","name":"keyHashes","type":"uint256[]"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"getManyByHash","outputs":[{"internalType":"string[]","name":"keys","type":"string[]"},{"internalType":"string[]","name":"values","type":"string[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"name":"isApprovedForAll","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"isApprovedOrOwner","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes[]","name":"data","type":"bytes[]"}],"name":"multicall","outputs":[{"internalType":"bytes[]","name":"results","type":"bytes[]"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"ownerOf","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256[]","name":"tokenIds","type":"uint256[]"}],"name":"ownerOfForMany","outputs":[{"internalType":"address[]","name":"owners","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"registryOf","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"resolverOf","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"addr","type":"address"}],"name":"reverseOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes4","name":"interfaceId","type":"bytes4"}],"name":"supportsInterface","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"tokenURI","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"}]''';
const ensResolver =
    '''[{"inputs":[{"internalType":"contract ENS","name":"_ens","type":"address"}],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"node","type":"bytes32"},{"indexed":true,"internalType":"uint256","name":"contentType","type":"uint256"}],"name":"ABIChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"node","type":"bytes32"},{"indexed":false,"internalType":"address","name":"a","type":"address"}],"name":"AddrChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"node","type":"bytes32"},{"indexed":false,"internalType":"uint256","name":"coinType","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"newAddress","type":"bytes"}],"name":"AddressChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"node","type":"bytes32"},{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"target","type":"address"},{"indexed":false,"internalType":"bool","name":"isAuthorised","type":"bool"}],"name":"AuthorisationChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"node","type":"bytes32"},{"indexed":false,"internalType":"bytes","name":"hash","type":"bytes"}],"name":"ContenthashChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"node","type":"bytes32"},{"indexed":false,"internalType":"bytes","name":"name","type":"bytes"},{"indexed":false,"internalType":"uint16","name":"resource","type":"uint16"},{"indexed":false,"internalType":"bytes","name":"record","type":"bytes"}],"name":"DNSRecordChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"node","type":"bytes32"},{"indexed":false,"internalType":"bytes","name":"name","type":"bytes"},{"indexed":false,"internalType":"uint16","name":"resource","type":"uint16"}],"name":"DNSRecordDeleted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"node","type":"bytes32"}],"name":"DNSZoneCleared","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"node","type":"bytes32"},{"indexed":true,"internalType":"bytes4","name":"interfaceID","type":"bytes4"},{"indexed":false,"internalType":"address","name":"implementer","type":"address"}],"name":"InterfaceChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"node","type":"bytes32"},{"indexed":false,"internalType":"string","name":"name","type":"string"}],"name":"NameChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"node","type":"bytes32"},{"indexed":false,"internalType":"bytes32","name":"x","type":"bytes32"},{"indexed":false,"internalType":"bytes32","name":"y","type":"bytes32"}],"name":"PubkeyChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"node","type":"bytes32"},{"indexed":true,"internalType":"string","name":"indexedKey","type":"string"},{"indexed":false,"internalType":"string","name":"key","type":"string"}],"name":"TextChanged","type":"event"},{"constant":true,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"uint256","name":"contentTypes","type":"uint256"}],"name":"ABI","outputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"bytes","name":"","type":"bytes"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"}],"name":"addr","outputs":[{"internalType":"address payable","name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"uint256","name":"coinType","type":"uint256"}],"name":"addr","outputs":[{"internalType":"bytes","name":"","type":"bytes"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"},{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"name":"authorisations","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"}],"name":"clearDNSZone","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"}],"name":"contenthash","outputs":[{"internalType":"bytes","name":"","type":"bytes"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"bytes32","name":"name","type":"bytes32"},{"internalType":"uint16","name":"resource","type":"uint16"}],"name":"dnsRecord","outputs":[{"internalType":"bytes","name":"","type":"bytes"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"bytes32","name":"name","type":"bytes32"}],"name":"hasDNSRecords","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"bytes4","name":"interfaceID","type":"bytes4"}],"name":"interfaceImplementer","outputs":[{"internalType":"address","name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"bytes[]","name":"data","type":"bytes[]"}],"name":"multicall","outputs":[{"internalType":"bytes[]","name":"results","type":"bytes[]"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"}],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"}],"name":"pubkey","outputs":[{"internalType":"bytes32","name":"x","type":"bytes32"},{"internalType":"bytes32","name":"y","type":"bytes32"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"uint256","name":"contentType","type":"uint256"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"setABI","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"uint256","name":"coinType","type":"uint256"},{"internalType":"bytes","name":"a","type":"bytes"}],"name":"setAddr","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"address","name":"a","type":"address"}],"name":"setAddr","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"address","name":"target","type":"address"},{"internalType":"bool","name":"isAuthorised","type":"bool"}],"name":"setAuthorisation","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"bytes","name":"hash","type":"bytes"}],"name":"setContenthash","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"setDNSRecords","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"bytes4","name":"interfaceID","type":"bytes4"},{"internalType":"address","name":"implementer","type":"address"}],"name":"setInterface","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"string","name":"name","type":"string"}],"name":"setName","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"bytes32","name":"x","type":"bytes32"},{"internalType":"bytes32","name":"y","type":"bytes32"}],"name":"setPubkey","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"string","name":"key","type":"string"},{"internalType":"string","name":"value","type":"string"}],"name":"setText","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"internalType":"bytes4","name":"interfaceID","type":"bytes4"}],"name":"supportsInterface","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"pure","type":"function"},{"constant":true,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"string","name":"key","type":"string"}],"name":"text","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"}]''';
const ensInterface =
    '''[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"node","type":"bytes32"},{"indexed":true,"internalType":"bytes32","name":"label","type":"bytes32"},{"indexed":false,"internalType":"address","name":"owner","type":"address"}],"name":"NewOwner","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"node","type":"bytes32"},{"indexed":false,"internalType":"address","name":"resolver","type":"address"}],"name":"NewResolver","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"node","type":"bytes32"},{"indexed":false,"internalType":"uint64","name":"ttl","type":"uint64"}],"name":"NewTTL","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"node","type":"bytes32"},{"indexed":false,"internalType":"address","name":"owner","type":"address"}],"name":"Transfer","type":"event"},{"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"}],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"}],"name":"resolver","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"address","name":"owner","type":"address"}],"name":"setOwner","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"address","name":"resolver","type":"address"}],"name":"setResolver","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"bytes32","name":"label","type":"bytes32"},{"internalType":"address","name":"owner","type":"address"}],"name":"setSubnodeOwner","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"uint64","name":"ttl","type":"uint64"}],"name":"setTTL","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"}],"name":"ttl","outputs":[{"internalType":"uint64","name":"","type":"uint64"}],"stateMutability":"view","type":"function"}]''';

solidityFunctionSig(String methodId) {
  return '0x${sha3(methodId).substring(0, 8)}';
}

enum SolanaClusters {
  mainNet,
  devNet,
  testNet,
}

enum AlgorandTypes {
  mainNet,
  testNet,
}

enum TezosTypes {
  mainNet,
  ghostNet,
}

final xrpBaseCodec =
    BaseXCodec('rpshnaf39wBUDNEGHJKLM4PQRST7VWXYZ2bcdeCg65jkm8oFqi1tuvAxyz');
solana.SolanaClient getSolanaClient(SolanaClusters solanaClusterType) {
  solanaClusterType ??= SolanaClusters.mainNet;

  String solanaRpcUrl = '';
  String solanaWebSocket = '';
  switch (solanaClusterType) {
    case SolanaClusters.mainNet:
      solanaRpcUrl = 'https://solana-api.projectserum.com';
      solanaWebSocket = 'wss://solana-api.projectserum.com';
      break;
    case SolanaClusters.devNet:
      solanaRpcUrl = 'https://api.devnet.solana.com';
      solanaWebSocket = 'wss://api.devnet.solana.com';
      break;
    case SolanaClusters.testNet:
      solanaRpcUrl = 'https://api.testnet.solana.com';
      solanaWebSocket = 'wss://api.testnet.solana.com';
      break;
    default:
      throw Exception('unimplemented error');
  }

  return solana.SolanaClient(
    rpcUrl: Uri.parse(solanaRpcUrl),
    websocketUrl: Uri.parse(solanaWebSocket),
  );
}

Future<Map> viewUserTokens(
  int chainId,
  String address, {
  bool skipNetworkRequest,
}) async {
  final pref = Hive.box(secureStorageKey);
  final tokenListKey = 'tokenListKey_$chainId-$address/__';
  final tokenList = pref.get(tokenListKey);
  Map userTokens = {
    'msg': 'could not fetch tokens',
    'success': false,
  };
  if (tokenList != null) {
    userTokens = {'msg': json.decode(tokenList) as Map, 'success': true};
  }

  if (skipNetworkRequest) return userTokens;
  try {
    String baseUrl = '';
    switch (chainId) {
      case 1:
        baseUrl =
            'https://eth-mainnet.g.alchemy.com/v2/$alchemyEthMainnetApiKey';
        break;
      case 5:
        baseUrl = 'https://eth-goerli.g.alchemy.com/v2/$alchemyEthGoerliApiKey';
        break;
      case 137:
        baseUrl =
            'https://polygon-mainnet.g.alchemy.com/v2/$alchemyPolygonApiKey';
        break;
      case 80001:
        baseUrl =
            'https://polygon-mumbai.g.alchemy.com/v2/$alchemyMumbaiApiKey';
        break;
    }
    final response = await get(
      Uri.parse(
        '$baseUrl/getNFTs?owner=$address',
      ),
    );
    final responseBody = response.body;
    if (response.statusCode ~/ 100 == 4 || response.statusCode ~/ 100 == 5) {
      throw Exception(responseBody);
    }
    await pref.put(tokenListKey, response.body);
    return {'msg': json.decode(response.body), 'success': true};
  } catch (e) {
    return userTokens;
  }
}

ipfsTohttp(String url) {
  if (url == null) return '';

  url = url.trim();
  return url.startsWith('ipfs://')
      ? 'https://ipfs.io/ipfs/${url.replaceFirst('ipfs://', '')}'
      : url;
}

String localHostToIpAddress(String url) {
  Uri uri = Uri.parse(url);
  const localhostNames = ['localhost', '127.0.0.1', '::1', '[::1]'];

  if (localhostNames.contains(uri.host)) {
    uri = uri.replace(
      scheme: Platform.isAndroid ? '10.0.2.2' : '127.0.0.1',
    );
  }
  return uri.toString();
}

buildSwapUi({
  List tokenList,
  Function onSelect,
  BuildContext context,
}) async {
  final searchCoinController = TextEditingController();

  await slideUpPanel(
    context,
    StatefulBuilder(
      builder: ((context, setState) {
        List<Widget> listToken = [];
        tokenList
            .where((element) {
              if (searchCoinController.text == '') {
                return true;
              } else {
                return element['name']
                        .toString()
                        .toLowerCase()
                        .contains(searchCoinController.text.toLowerCase()) ||
                    element['symbol']
                        .toString()
                        .toLowerCase()
                        .contains(searchCoinController.text.toLowerCase());
              }
            })
            .take(50)
            .toList()
            .forEach((element) {
              listToken.add(
                InkWell(
                  onTap: () {
                    onSelect(element);
                    Navigator.pop(context);
                  },
                  child: Row(children: [
                    Flexible(
                      child: CachedNetworkImage(
                        imageBuilder: (context, imageProvider) => Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        imageUrl: ipfsTohttp(element['logoURI']),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Loader(
                                color: appPrimaryColor,
                              ),
                            )
                          ],
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.error,
                          color: Colors.red,
                        ),
                        width: 40,
                        height: 40,
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //
                          Text(
                            ellipsify(str: element['name'] ?? ''),
                            style: //bold
                                const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              overflow: TextOverflow.fade,
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            ellipsify(str: element['symbol'] ?? ''),
                            style: const TextStyle(
                              overflow: TextOverflow.fade,
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              );

              listToken.add(const SizedBox(
                height: 20,
              ));
            });

        return Container(
          color: Colors.transparent,
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            },
                            child: const Icon(
                              Icons.arrow_back,
                              size: 30,
                            ),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          Text(
                            AppLocalizations.of(context).selectTokens,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          // border color
                          border: Border.all(
                            color: const Color(0xff2A7FE2),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(30, 0, 0, 0),
                          child: TextFormField(
                            controller: searchCoinController,
                            onChanged: (value) async {
                              setState(() {});
                            },
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.search,
                                ),
                              ),
                              hintText: AppLocalizations.of(context).searchCoin,
                              hintStyle: const TextStyle(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      ...listToken
                    ]),
              ),
            ),
          ),
        );
      }),
    ),
  );
}

Future<bool> authenticateIsAvailable() async {
  final localAuth = LocalAuthentication();
  final isAvailable = await localAuth.canCheckBiometrics;
  final isDeviceSupported = await localAuth.isDeviceSupported();
  return isAvailable && isDeviceSupported;
}

Future<bool> localAuthentication() async {
  final localAuth = LocalAuthentication();
  bool didAuthenticate = false;
  if (await authenticateIsAvailable()) {
    didAuthenticate = await localAuth.authenticate(
      localizedReason: 'Your authentication is needed.',
    );
  }

  return didAuthenticate ?? false;
}

Future<bool> authenticate(BuildContext context,
    {bool disableGoBack_, bool useLocalAuth}) async {
  bool didAuthenticate = false;
  await disEnableScreenShot();
  if (useLocalAuth ?? true) {
    didAuthenticate = await localAuthentication();
  }
  if (!didAuthenticate) {
    didAuthenticate = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Security(
          isEnterPin: true,
          useLocalAuth: useLocalAuth,
        ),
      ),
    );
  }

  await enableScreenShot();

  return didAuthenticate ?? false;
}

Future getAddTokenKey() async {
  final pref = Hive.box(secureStorageKey);
  final String mnemonicHash = sha3(pref.get(currentMmenomicKey));
  return 'userTokenList$mnemonicHash'.toLowerCase();
}

Future<Map> oneInchSwapUrlResponse({
  String fromTokenAddress,
  String toTokenAddress,
  double amountInWei,
  String fromAddress,
  double slippage,
  int chainId,
}) async {
  try {
    slippage = slippage ?? 0.1;
    String url =
        "https://api.1inch.exchange/v3.0/$chainId/swap?fromTokenAddress=$fromTokenAddress&toTokenAddress=$toTokenAddress&amount=${BigInt.from(amountInWei).toString()}&fromAddress=$fromAddress&slippage=$slippage&disableEstimate=true";

    final response = await get(Uri.parse(url)).timeout(networkTimeOutDuration);

    final responseBody = jsonDecode(response.body) as Map;
    if (response.statusCode ~/ 100 == 4 || response.statusCode ~/ 100 == 5) {
      throw Exception(responseBody);
    }
    return responseBody;
  } catch (e) {
    return null;
  }
}

Future<Map> approveTokenFor1inch(
    int chainId, double amountInWei, String contractAddr) async {
  String url =
      "https://api.1inch.exchange/v3.0/$chainId/approve/calldata?tokenAddress=$contractAddr&amount=${BigInt.from(amountInWei).toString()}";

  final response = jsonDecode((await get(Uri.parse(url))).body) as Map;
  return response;
}

Map getKnownMethodId() {
  return {
    "data": [
      {
        "contractType": "ContractType.ERC875_LEGACY",
        "methodId": "transferFrom(address,address,uint16[])"
      },
      {
        "contractType": "ContractType.ERC875_LEGACY",
        "methodId": "transfer(address,uint16[])"
      },
      {
        "contractType": "ContractType.ERC875_LEGACY",
        "methodId": "trade(uint256,uint16[],uint8,bytes32,bytes32)"
      },
      {
        "contractType": "ContractType.ERC875_LEGACY",
        "methodId": "passTo(uint256,uint16[],uint8,bytes32,bytes32,address)"
      },
      {
        "contractType": "ContractType.ERC875_LEGACY",
        "methodId": "loadNewTickets(bytes32[])"
      },
      {
        "contractType": "ContractType.ERC875_LEGACY",
        "methodId": "balanceOf(address)"
      },
      {
        "contractType": "ContractType.ERC20",
        "methodId": "transfer(address,uint256)"
      },
      {
        "contractType": "ContractType.ERC20",
        "methodId": "transfer(address,uint)"
      },
      {
        "contractType": "ContractType.ERC20",
        "methodId": "transferFrom(address,address,uint256)"
      },
      {
        "contractType": "ContractType.ERC20",
        "methodId": "approve(address,uint256)"
      },
      {
        "contractType": "ContractType.ERC20",
        "methodId": "approve(address,uint)"
      },
      {
        "contractType": "ContractType.ERC20",
        "methodId": "allocateTo(address,uint256)"
      },
      {
        "contractType": "ContractType.ERC20",
        "methodId": "allowance(address,address)"
      },
      {
        "contractType": "ContractType.ERC20",
        "methodId": "transferFrom(address,address,uint)"
      },
      {
        "contractType": "ContractType.ERC20",
        "methodId": "approveAndCall(address,uint,bytes)"
      },
      {"contractType": "ContractType.ERC20", "methodId": "balanceOf(address)"},
      {
        "contractType": "ContractType.ERC20",
        "methodId": "transferAnyERC20Token(address,uint)"
      },
      {"contractType": "ContractType.ERC20", "methodId": "delegate(address)"},
      {"contractType": "ContractType.ERC20", "methodId": "mint(address,uint)"},
      {
        "contractType": "ContractType.ERC20",
        "methodId":
            "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)"
      },
      {
        "contractType": "ContractType.ERC20",
        "methodId": "withdraw(address,uint256,address)"
      },
      {
        "contractType": "ContractType.ERC20",
        "methodId": "deposit(address,uint256,address,uint16)"
      },
      {"contractType": "ContractType.ERC20", "methodId": "deposit()"},
      {
        "contractType": "ContractType.ERC875",
        "methodId": "transferFrom(address,address,uint256[])"
      },
      {
        "contractType": "ContractType.ERC875",
        "methodId": "transfer(address,uint256[])"
      },
      {
        "contractType": "ContractType.ERC875",
        "methodId": "trade(uint256,uint256[],uint8,bytes32,bytes32)"
      },
      {
        "contractType": "ContractType.ERC875",
        "methodId": "passTo(uint256,uint256[],uint8,bytes32,bytes32,address)"
      },
      {
        "contractType": "ContractType.ERC875",
        "methodId": "loadNewTickets(uint256[])"
      },
      {"contractType": "ContractType.ERC875", "methodId": "balanceOf(address)"},
      {"contractType": "ContractType.CREATION", "methodId": "endContract()"},
      {"contractType": "ContractType.CREATION", "methodId": "selfdestruct()"},
      {"contractType": "ContractType.CREATION", "methodId": "kill()"},
      {
        "contractType": "ContractType.ERC721",
        "methodId": "safeTransferFrom(address,address,uint256,bytes)"
      },
      {
        "contractType": "ContractType.ERC721",
        "methodId": "safeTransferFrom(address,address,uint256)"
      },
      {
        "contractType": "ContractType.ERC721",
        "methodId": "transferFrom(address,address,uint256)"
      },
      {
        "contractType": "ContractType.ERC721",
        "methodId": "approve(address,uint256)"
      },
      {
        "contractType": "ContractType.ERC721",
        "methodId": "setApprovalForAll(address,bool)"
      },
      {
        "contractType": "ContractType.ERC721",
        "methodId": "getApproved(address,address,uint256)"
      },
      {
        "contractType": "ContractType.ERC721",
        "methodId": "isApprovedForAll(address,address)"
      },
      {
        "contractType": "ContractType.ERC721_LEGACY",
        "methodId": "transfer(address,uint256)"
      },
      {
        "contractType": "ContractType.ERC721",
        "methodId": "giveBirth(uint256,uint256)"
      },
      {
        "contractType": "ContractType.ERC721",
        "methodId": "breedWithAuto(uint256,uint256)"
      },
      {"contractType": "ContractType.ERC721", "methodId": "ownerOf(uint256)"},
      {
        "contractType": "ContractType.ERC721",
        "methodId": "createSaleAuction(uint256,uint256,uint256,uint256)"
      },
      {
        "contractType": "ContractType.ERC721",
        "methodId": "mixGenes(uint256,uint256,uint256)"
      },
      {
        "contractType": "ContractType.ERC721",
        "methodId": "tokensOfOwner(address)"
      },
      {"contractType": "ContractType.ERC721", "methodId": "store(uint256)"},
      {
        "contractType": "ContractType.ERC721",
        "methodId": "remix(uint256,bytes)"
      },
      {
        "contractType": "ContractType.ERC1155",
        "methodId": "safeTransferFrom(address,address,uint256,uint256,bytes)"
      },
      {
        "contractType": "ContractType.ERC1155",
        "methodId":
            "safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)"
      },
      {
        "contractType": "ContractType.CURRENCY",
        "methodId":
            "dropCurrency(uint32,uint32,uint32,uint8,bytes32,bytes32,address)"
      },
      {
        "contractType": "ContractType.CURRENCY",
        "methodId": "withdraw(uint256)"
      },
      {"contractType": "ContractType.ERC721", "methodId": "commitNFT()"}
    ]
  };
}

Map getBitCoinPOSBlockchains() {
  Map blockChains = {
    'Bitcoin': {
      'symbol': 'BTC',
      'default': 'BTC',
      'blockExplorer':
          'https://live.blockcypher.com/btc/tx/$transactionhashTemplateKey',
      'image': 'assets/bitcoin.jpg',
      'POSNetwork': bitcoin.bitcoin,
      'P2WPKH': true,
      'derivationPath': "m/84'/0'/0'/0/0"
    },
    // 'BitcoinCash': {
    //   'symbol': 'BCH',
    //   'default': 'BCH',
    //   'blockExplorer':
    //       'https://www.blockchain.com/explorer/transactions/bch/$transactionhashTemplateKey',
    //   'image': 'assets/bitcoin_cash.png',
    //   'POSNetwork': bitcoincash,
    //   'P2WPKH': false,
    //   'derivationPath': "m/44'/145'/0'/0/0"
    // },
    'Litecoin': {
      'symbol': 'LTC',
      'default': 'LTC',
      'blockExplorer':
          'https://live.blockcypher.com/ltc/tx/$transactionhashTemplateKey',
      'image': 'assets/litecoin.png',
      'POSNetwork': litecoin,
      'P2WPKH': true,
      'derivationPath': "m/84'/2'/0'/0/0"
    },
    // 'Dash': {
    //   'symbol': 'DASH',
    //   'default': 'DASH',
    //   'blockExplorer':
    //       'https://live.blockcypher.com/dash/tx/$transactionhashTemplateKey',
    //   'image': 'assets/dash.png',
    //   'POSNetwork': dash,
    //   'P2WPKH': false,
    //   'derivationPath': "m/44'/5'/0'/0/0"
    // },
    // 'ZCash': {
    //   'symbol': 'ZEC',
    //   'default': 'ZEC',
    //   'blockExplorer':
    //       'https://zcashblockexplorer.com/transactions/$transactionhashTemplateKey',
    //   'image': 'assets/zcash.png',
    //   'POSNetwork': zcash,
    //   'P2WPKH': false,
    //   'derivationPath': "m/44'/133'/0'/0/0"
    // },
    'Dogecoin': {
      'symbol': 'DOGE',
      'default': 'DOGE',
      'blockExplorer':
          'https://live.blockcypher.com/doge/tx/$transactionhashTemplateKey',
      'image': 'assets/dogecoin.png',
      'POSNetwork': dogecoin,
      'P2WPKH': false,
      'derivationPath': "m/44'/3'/0'/0/0"
    }
  };

  if (enableTestNet) {
    blockChains['Bitcoin(Test)'] = {
      'symbol': 'BTC',
      'default': 'BTC',
      'blockExplorer':
          'https://www.blockchain.com/btc-testnet/tx/$transactionhashTemplateKey',
      'image': 'assets/bitcoin.jpg',
      'POSNetwork': testnet,
      'P2WPKH': false,
      'derivationPath': "m/44'/0'/0'/0/0"
    };
  }

  return blockChains;
}

Map getCosmosBlockChains() {
  return {};
  Map blockChains = {
    'Cosmos': {
      'blockExplorer':
          'https://atomscan.com/transactions/$transactionhashTemplateKey',
      'symbol': 'ATOM',
      'default': 'ATOM',
      'image': 'assets/cosmos.png',
      'bech32Hrp': 'cosmos',
      'lcdUrl': 'https://api.cosmos.network'
    }
  };

  if (enableTestNet) {
    blockChains['Cosmos(Test)'] = {
      'blockExplorer':
          'https://explorer.theta-testnet.polypore.xyz/transactions/$transactionhashTemplateKey',
      'symbol': 'ATOM',
      'default': 'ATOM',
      'image': 'assets/cosmos.png',
      'bech32Hrp': 'cosmos',
      'lcdUrl': 'https://rest.state-sync-02.theta-testnet.polypore.xyz'
    };
  }
  return blockChains;
}

final List<String> months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];

Map getTronBlockchains() {
  return {};
  Map blockChains = {
    'Tron': {
      'blockExplorer':
          'https://tronscan.org/#/transaction/$transactionhashTemplateKey',
      'symbol': 'TRX',
      'default': 'TRX',
      'image': 'assets/tron.png',
    }
  };

  return blockChains;
}

Map getTezosBlockchains() {
  Map blockChains = {
    'Tezos': {
      'blockExplorer': 'https://tzkt.io/$transactionhashTemplateKey',
      'symbol': 'XTZ',
      'default': 'XTZ',
      'image': 'assets/tezos.png',
      'tezorType': TezosTypes.mainNet,
      'server': 'https://rpc.tzkt.io/mainnet'
    }
  };

  if (enableTestNet) {
    blockChains['Tezos(Testnet)'] = {
      'blockExplorer': 'https://ghostnet.tzkt.io/$transactionhashTemplateKey',
      'symbol': 'XTZ',
      'default': 'XTZ',
      'image': 'assets/tezos.png',
      'tezorType': TezosTypes.ghostNet,
      'server': 'https://rpc.tzkt.io/ghostnet'
    };
  }
  return blockChains;
}

Map getAlgorandBlockchains() {
  Map blockChains = {
    'Algorand': {
      'blockExplorer': 'https://algoexplorer.io/tx/$transactionhashTemplateKey',
      'symbol': 'ALGO',
      'default': 'ALGO',
      'image': 'assets/algorand.png',
      'algoType': AlgorandTypes.mainNet,
    }
  };

  if (enableTestNet) {
    blockChains['Algorand(Testnet)'] = {
      'blockExplorer':
          'https://testnet.algoexplorer.io/tx/$transactionhashTemplateKey',
      'symbol': 'ALGO',
      'default': 'ALGO',
      'image': 'assets/algorand.png',
      'algoType': AlgorandTypes.testNet,
    };
  }
  return blockChains;
}

reInstianteSeedRoot() async {
  final pref = Hive.box(secureStorageKey);
  final currentPhrase = pref.get(currentMmenomicKey);
  if (currentPhrase != null) {
    seedPhraseRoot = await compute(seedFromMnemonic, currentPhrase);
  }
}

Map getEVMBlockchains() {
  final pref = Hive.box(secureStorageKey);
  Map userAddedEVM = {};
  if (pref.get(newEVMChainKey) != null) {
    userAddedEVM = Map.from(jsonDecode(pref.get(newEVMChainKey)));
  }
  Map blockChains = {
    'Ethereum': {
      "rpc": 'https://mainnet.infura.io/v3/$infuraApiKey',
      'chainId': 1,
      'blockExplorer': 'https://etherscan.io/tx/$transactionhashTemplateKey',
      'symbol': 'ETH',
      'default': 'ETH',
      'image': 'assets/ethereum_logo.png',
      'coinType': 60
    },
    'Smart Chain': {
      "rpc": 'https://bsc-dataseed.binance.org/',
      'chainId': 56,
      'blockExplorer': 'https://bscscan.com/tx/$transactionhashTemplateKey',
      'symbol': 'BNB',
      'default': 'BNB',
      'image': 'assets/smartchain.png',
      'coinType': 60
    },
    'Polygon Matic': {
      "rpc": 'https://polygon-rpc.com',
      'chainId': 137,
      'blockExplorer': 'https://polygonscan.com/tx/$transactionhashTemplateKey',
      'symbol': 'MATIC',
      'default': 'MATIC',
      'image': 'assets/polygon.png',
      'coinType': 60
    },
    'Avalanche': {
      "rpc": 'https://api.avax.network/ext/bc/C/rpc',
      'chainId': 43114,
      'blockExplorer': 'https://snowtrace.io/tx/$transactionhashTemplateKey',
      'symbol': 'AVAX',
      'default': 'AVAX',
      'image': 'assets/avalanche.png',
      'coinType': 60
    },
    'Fantom': {
      "rpc": 'https://rpc.ftm.tools/',
      'chainId': 250,
      'blockExplorer': 'https://ftmscan.com/tx/$transactionhashTemplateKey',
      'symbol': 'FTM',
      'default': 'FTM',
      'image': 'assets/fantom.png',
      'coinType': 60
    },
    'Arbitrum': {
      "rpc": 'https://arb1.arbitrum.io/rpc',
      'chainId': 42161,
      'blockExplorer': 'https://arbiscan.io/tx/$transactionhashTemplateKey',
      'symbol': 'ETH',
      'default': 'ETH',
      'image': 'assets/arbitrum.jpg',
      'coinType': 60
    },
    'Optimism': {
      "rpc": 'https://mainnet.optimism.io',
      'chainId': 10,
      'blockExplorer':
          'https://optimistic.etherscan.io/tx/$transactionhashTemplateKey',
      'symbol': 'ETH',
      'default': 'ETH',
      'image': 'assets/optimism.png',
      'coinType': 60
    },
    'Ethereum Classic': {
      'symbol': 'ETC',
      'default': 'ETH',
      'blockExplorer':
          'https://blockscout.com/etc/mainnet/tx/$transactionhashTemplateKey',
      'rpc': 'https://www.ethercluster.com/etc',
      'chainId': 61,
      'image': 'assets/ethereum-classic.png',
      'coinType': 61
    },
    'Cronos': {
      "rpc": 'https://evm.cronos.org',
      'chainId': 25,
      'blockExplorer': 'https://cronoscan.com/tx/$transactionhashTemplateKey',
      'symbol': 'CRO',
      'default': 'CRO',
      'image': 'assets/cronos.png',
      'coinType': 60
    },
    'Milkomeda Cardano': {
      "rpc": ' https://rpc-mainnet-cardano-evm.c1.milkomeda.com',
      'chainId': 2001,
      'blockExplorer':
          'https://explorer-mainnet-cardano-evm.c1.milkomeda.com/tx/$transactionhashTemplateKey',
      'symbol': 'MilkADA',
      'default': 'MilkADA',
      'image': 'assets/milko-cardano.jpeg',
      'coinType': 60
    },
    'Huobi Chain': {
      "rpc": 'https://http-mainnet-node.huobichain.com/',
      'chainId': 128,
      'blockExplorer': 'https://hecoinfo.com/tx/$transactionhashTemplateKey',
      'symbol': 'HT',
      'default': 'HT',
      'image': 'assets/huobi.png',
      'coinType': 60
    },
    'Kucoin Chain': {
      "rpc": 'https://rpc-mainnet.kcc.network',
      'chainId': 321,
      'blockExplorer': 'https://explorer.kcc.io/tx/$transactionhashTemplateKey',
      'symbol': 'KCS',
      'default': 'KCS',
      'image': 'assets/kucoin.jpeg',
      'coinType': 60
    },
    'Elastos': {
      "rpc": 'https://api.elastos.io/eth',
      'chainId': 20,
      'blockExplorer':
          'https://explorer.elaeth.io/tx/$transactionhashTemplateKey',
      'symbol': 'ELA',
      'default': 'ELA',
      'image': 'assets/elastos.png',
      'coinType': 60
    },
    'xDai': {
      "rpc": 'https://rpc.xdaichain.com/',
      'chainId': 100,
      'blockExplorer':
          'https://blockscout.com/xdai/mainnet/tx/$transactionhashTemplateKey',
      'symbol': 'XDAI',
      'default': 'XDAI',
      'image': 'assets/xdai.jpg',
      'coinType': 60
    },
    'Ubiq': {
      "rpc": 'https://rpc.octano.dev/',
      'chainId': 8,
      'blockExplorer': 'https://ubiqscan.io/tx/$transactionhashTemplateKey',
      'symbol': 'UBQ',
      'default': 'UBQ',
      'image': 'assets/ubiq.png',
      'coinType': 60
    },
    'Celo': {
      "rpc": 'https://rpc.ankr.com/celo',
      'chainId': 42220,
      'blockExplorer':
          'https://explorer.celo.org/tx/$transactionhashTemplateKey',
      'symbol': 'CELO',
      'default': 'CELO',
      'image': 'assets/celo.png',
      'coinType': 60
    },
    'Fuse': {
      "rpc": 'https://rpc.fuse.io',
      'chainId': 122,
      'blockExplorer':
          'https://explorer.fuse.io/tx/$transactionhashTemplateKey',
      'symbol': 'FUSE',
      'default': 'FUSE',
      'image': 'assets/fuse.png',
      'coinType': 60
    },
    'Aurora': {
      "rpc": 'https://mainnet.aurora.dev',
      'chainId': 1313161554,
      'blockExplorer': 'https://aurorascan.dev/tx/$transactionhashTemplateKey',
      'symbol': 'ETH',
      'default': 'ETH',
      'image': 'assets/aurora.png',
      'coinType': 60
    },
    'Thunder Token': {
      "rpc": 'https://mainnet-rpc.thundercore.com',
      'chainId': 108,
      'blockExplorer':
          'https://viewblock.io/thundercore/tx/$transactionhashTemplateKey',
      'symbol': 'TT',
      'default': 'TT',
      'image': 'assets/thunder-token.jpeg',
      'coinType': 1001
    },
    'GoChain': {
      "rpc": 'https://rpc.gochain.io',
      'chainId': 60,
      'blockExplorer':
          'https://explorer.gochain.io/tx/$transactionhashTemplateKey',
      'symbol': 'GO',
      'default': 'GO',
      'image': 'assets/go-chain.png',
      'coinType': 6060
    },
  };

  if (enableTestNet) {
    blockChains['Smart Chain(Testnet)'] = {
      "rpc": 'https://data-seed-prebsc-2-s3.binance.org:8545/',
      'chainId': 97,
      'blockExplorer':
          'https://testnet.bscscan.com/tx/$transactionhashTemplateKey',
      'symbol': 'BNB',
      'default': 'BNB',
      'image': 'assets/smartchain.png',
      'coinType': 60
    };
    blockChains["Polygon (Mumbai)"] = {
      "rpc": "https://rpc-mumbai.maticvigil.com",
      "chainId": 80001,
      "blockExplorer":
          "https://mumbai.polygonscan.com/tx/$transactionhashTemplateKey",
      "symbol": "MATIC",
      "default": "MATIC",
      "image": "assets/polygon.png",
      'coinType': 60
    };
    blockChains['Ethereum(Goerli)'] = {
      "rpc": 'https://goerli.infura.io/v3/$infuraApiKey',
      'chainId': 5,
      'blockExplorer':
          'https://goerli.etherscan.io/tx/$transactionhashTemplateKey',
      'symbol': 'ETH',
      'default': 'ETH',
      'image': 'assets/ethereum_logo.png',
      'coinType': 60
    };
  }

  return {...blockChains, ...userAddedEVM};
}

Map getSolanaBlockChains() {
  Map blockChains = {
    'Solana': {
      'symbol': 'SOL',
      'default': 'SOL',
      'blockExplorer':
          'https://explorer.solana.com/tx/$transactionhashTemplateKey',
      'image': 'assets/solana.webp',
      'solanaCluster': SolanaClusters.mainNet,
    }
  };
  if (enableTestNet) {
    blockChains['Solana(Devnet)'] = {
      'symbol': 'SOL',
      'default': 'SOL',
      'blockExplorer':
          'https://explorer.solana.com/tx/$transactionhashTemplateKey?cluster=devnet',
      'image': 'assets/solana.webp',
      'solanaCluster': SolanaClusters.devNet,
    };
  }
  return blockChains;
}

Map getStellarBlockChains() {
  Map blockChains = {
    'Stellar': {
      'symbol': 'XLM',
      'default': 'XLM',
      'blockExplorer':
          'https://stellarchain.io/transactions/$transactionhashTemplateKey',
      'image': 'assets/stellar.png', // sdk stellar
      'sdk': stellar.StellarSDK.PUBLIC,
      'cluster': stellar.Network.PUBLIC
    }
  };
  if (enableTestNet) {
    blockChains['Stellar(Testnet)'] = {
      'symbol': 'XLM',
      'default': 'XLM',
      'blockExplorer':
          'https://testnet.stellarchain.io/transactions/$transactionhashTemplateKey',
      'image': 'assets/stellar.png',
      'sdk': stellar.StellarSDK.TESTNET,
      'cluster': stellar.Network.TESTNET
    };
  }
  return blockChains;
}

Map getXRPBlockChains() {
  Map blockChains = {
    'XRP': {
      'symbol': 'XRP',
      'default': 'XRP',
      'blockExplorer':
          'https://livenet.xrpl.org/transactions/$transactionhashTemplateKey',
      'image': 'assets/ripple.png',
      'ws': 'https://s1.ripple.com:51234/'
    }
  };
  if (enableTestNet) {
    blockChains['XRP(Testnet)'] = {
      'symbol': 'XRP',
      'default': 'XRP',
      'blockExplorer':
          'https://testnet.xrpl.org/transactions/$transactionhashTemplateKey',
      'image': 'assets/ripple.png',
      'ws': 'https://s.altnet.rippletest.net:51234/',
    };
  }
  return blockChains;
}

Map getFilecoinBlockChains() {
  return {};
  // FIXME:
  Map blockChains = {
    'Filecoin': {
      'symbol': 'FIL',
      'default': 'FIL',
      'blockExplorer':
          'https://filscan.io/tipset/message-detail?cid=$transactionhashTemplateKey',
      'image': 'assets/filecoin.png',
      'baseUrl': 'https://api.fivetoken.io/api/uip7oegcgxr6ovab296tpqoh',
      'prefix': 'f'
    }
  };
  if (enableTestNet) {
    blockChains['Filecoin(Testnet)'] = {
      'symbol': 'FIL',
      'default': 'FIL',
      'blockExplorer':
          'https://calibration.filscan.io/tipset/message-detail?cid=$transactionhashTemplateKey',
      'image': 'assets/filecoin.png',
      'baseUrl':
          'https://api.calibration.fivetoken.io/api/uip7oegcgxr6ovab296tpqoh',
      'prefix': 't'
    };
  }
  return blockChains;
}

Map getCardanoBlockChains() {
  Map blockChains = {
    'Cardano': {
      'symbol': 'ADA',
      'default': 'ADA',
      'blockExplorer':
          'https://cardanoscan.io/transaction/$transactionhashTemplateKey',
      'image': 'assets/cardano.png',
      'cardano_network': cardano.NetworkId.mainnet,
      'blockFrostKey': 'mainnetpgkQqXqQ4HjK6gzUKaHW6VU9jcmcKEbd'
    }
  };
  if (enableTestNet) {
    blockChains['Cardano(Prepod)'] = {
      'symbol': 'ADA',
      'default': 'ADA',
      'blockExplorer':
          'https://preprod.cardanoscan.io/transaction/$transactionhashTemplateKey',
      'image': 'assets/cardano.png',
      'cardano_network': cardano.NetworkId.testnet,
      'blockFrostKey': 'preprodmpCaCFGCxLihVPPxXxqEvEnp7dyFmG6J'
    };
  }
  return blockChains;
}

const coinGeckCryptoSymbolToID = {
  "BTC": "bitcoin",
  "XTZ": "tezos",
  "TRX": "tron",
  "ETH": "ethereum",
  "ALGO": "algorand",
  "BNB": "binancecoin",
  "AVAX": "avalanche-2",
  "FTM": "fantom",
  "HT": "huobi-token",
  "MATIC": "matic-network",
  "KCS": "kucoin-shares",
  "ELA": "elastos",
  "TT": "thunder-token",
  "GO": "gochain",
  "XDAI": "xdai",
  "UBQ": "ubiq",
  "CELO": "celo",
  "FUSE": "fuse-network-token",
  "LTC": "litecoin",
  "DOGE": "dogecoin",
  "CRO": "crypto-com-chain",
  "SOL": 'solana',
  'ETC': "ethereum-classic",
  'FIL': 'filecoin',
  'XRP': 'ripple',
  'ADA': 'cardano',
  'MilkADA': 'cardano',
  'USDT': 'tether',
  'DOT': 'polkadot',
  'BCH': 'bitcoin-cash',
  'UNI': 'uniswap',
  'LINK': 'chainlink',
  'USDC': 'usd-coin',
  'XLM': 'stellar',
  'AAVE': 'aave',
  'DAI': 'dai',
  'CEL': 'celsius-degree-token',
  'NEXO': 'nexo',
  'TUSD': 'true-usd',
  'GUSD': 'gemini-dollar',
  'ZEC': 'zcash',
  'DASH': 'dash',
  "ATOM": 'cosmos'
};

Map requestPaymentScheme = {
  ...coinGeckCryptoSymbolToID,
  "BTC": "bitcoin",
  "ETH": "ethereum",
  "BNB": "smartchain",
  "AVAX": "avalanchec",
  "FTM": "fantom",
  "ALGO": "algorand",
  "HT": "heco",
  "MATIC": "polygon",
  "KCS": "kcc",
  "ELA": "elastos",
  "TT": "thundertoken",
  "GO": "gochain",
  "XDAI": "xdai",
  "UBQ": "ubiq",
  "CELO": "celo",
  "FUSE": "fuse-network-token",
  "LTC": "litecoin",
  "DOGE": "doge",
  "CRO": "cronos",
  "SOL": 'solana',
  'ETC': "classic",
  'FIL': 'filecoin',
  'XRP': 'ripple',
  'ADA': 'cardano',
  'MilkADA': 'cardano',
  'USDT': 'tether',
  'DOT': 'polkadot',
  'BCH': 'bitcoincash',
  'UNI': 'uniswap',
  'LINK': 'chainlink',
  'USDC': 'usd-coin',
  'XLM': 'stellar',
  'AAVE': 'aave',
  'DAI': 'dai',
  'CEL': 'celsius-degree-token',
  'NEXO': 'nexo',
  'TUSD': 'true-usd',
  'GUSD': 'gemini-dollar',
  'ZEC': 'zcash',
  'DASH': 'dash',
  "ATOM": 'cosmos'
};

const moonPayApi =
    "https://buy.moonpay.com/?apiKey=pk_live_D4M9IUMtLoDQUpSA0qQnn8VmfusvoSSQ&baseCurrencyAmount=150&baseCurrencyCode=USD";
const moonPayCurrencyCode = {
  "BTC": "BTC",
  "BNB": "BNB_BSC",
  "ETH": "ETH",
  "AVAX": "AVAX_CCHAIN",
  "MATIC": "MATIC_POLYGON",
  "DOGE": "DOGE",
  "LTC": "LTC",
  "CELO": "CELO"
};

Future<web3.DeployedContract> getEnsResolverContract(
    String cryptoDomainName, web3.Web3Client client) async {
  cryptoDomainName = cryptoDomainName.trim();
  final nameHash_ = nameHash(cryptoDomainName);

  web3.DeployedContract ensInterfaceContract = web3.DeployedContract(
    web3.ContractAbi.fromJson(ensInterface, ''),
    web3.EthereumAddress.fromHex(ensInterfaceAddress),
  );

  final resolverAddr = (await client.call(
    contract: ensInterfaceContract,
    function: ensInterfaceContract.function('resolver'),
    params: [hexToBytes(nameHash_)],
  ))
      .first;

  return web3.DeployedContract(
    web3.ContractAbi.fromJson(ensResolver, ''),
    resolverAddr,
  );
}

Future ensToContentHashAndIPFS({String cryptoDomainName}) async {
  try {
    final rpcUrl = getEVMBlockchains()['Ethereum']['rpc'];
    final client = web3.Web3Client(rpcUrl, Client());
    final nameHash_ = nameHash(cryptoDomainName);
    web3.DeployedContract ensResolverContract =
        await getEnsResolverContract(cryptoDomainName, client);
    List<int> contentHashList = (await client.call(
      contract: ensResolverContract,
      function: ensResolverContract.function('contenthash'),
      params: [hexToBytes(nameHash_)],
    ))
        .first;

    String contentHash = bytesToHex(contentHashList);

    if (!contentHash.startsWith('0x')) {
      contentHash = "0x" + contentHash;
    }
    final ipfsCIDRegex = RegExp(
        r'^0xe3010170(([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f]*))$');

    final swarmRegex = RegExp(r'^0xe40101fa011b20([0-9a-f]*)$');

    final match = ipfsCIDRegex.firstMatch(contentHash);
    final swarmMatch = swarmRegex.firstMatch(contentHash);
    if (match != null) {
      final length = int.parse(match.group(3), radix: 16);
      if (match.group(4).length == length * 2) {
        final userFinalDecodedHash = match.group(1);
        return {
          'success': true,
          'msg': ipfsTohttp(
            "ipfs://${bs58check.base58.encode(HEX.decode(userFinalDecodedHash))}",
          )
        };
      }
      throw Exception('invalid IPFS checksum');
    } else if (swarmMatch != null) {
      if (swarmMatch.group(1).length == (32 * 2)) {
        return {'success': true, 'msg': "bzz://" + swarmMatch.group(2)};
      }
      throw Exception('invalid SWARM checksum');
    }

    throw Exception('invalid ENS checksum');
  } catch (e) {
    return {'success': false, 'msg': 'Error resolving ens'};
  }
}

Future<Map> ensToAddress({String cryptoDomainName}) async {
  try {
    cryptoDomainName = cryptoDomainName.toLowerCase();
    final rpcUrl = getEVMBlockchains()['Ethereum']['rpc'];
    final client = web3.Web3Client(rpcUrl, Client());
    final nameHash_ = nameHash(cryptoDomainName);
    web3.DeployedContract ensResolverContract =
        await getEnsResolverContract(cryptoDomainName, client);

    final userAddress = (await client.call(
      contract: ensResolverContract,
      function: ensResolverContract.findFunctionsByName('addr').toList()[0],
      params: [hexToBytes(nameHash_)],
    ))
        .first;

    return {
      'success': true,
      'msg': web3.EthereumAddress.fromHex(userAddress.toString()).hexEip55
    };
  } catch (e) {
    return {'success': false, 'msg': 'Error resolving ens'};
  }
}

Future<void> initializeAllPrivateKeys(String mnemonic) async {
  seedPhraseRoot = await compute(seedFromMnemonic, mnemonic);

  for (String i in getEVMBlockchains().keys) {
    await getEthereumFromMemnomic(
      mnemonic,
      getEVMBlockchains()[i]['coinType'],
    );
  }
  for (String i in getTezosBlockchains().keys) {
    await getTezorFromMemnomic(
      mnemonic,
      getTezosBlockchains()[i],
    );
  }
  for (String i in getBitCoinPOSBlockchains().keys) {
    await getBitcoinFromMemnomic(
      mnemonic,
      getBitCoinPOSBlockchains()[i],
    );
  }
  for (String i in getFilecoinBlockChains().keys) {
    await getFileCoinFromMemnomic(
      mnemonic,
      getFilecoinBlockChains()[i]['prefix'],
    );
  }
  for (String i in getCardanoBlockChains().keys) {
    await getCardanoFromMemnomic(
      mnemonic,
      getCardanoBlockChains()[i]['cardano_network'],
    );
  }

  for (String i in getCosmosBlockChains().keys) {
    await getCosmosFromMemnomic(
      mnemonic,
      getCosmosBlockChains()[i]['bech32Hrp'],
      getCosmosBlockChains()[i]['lcdUrl'],
    );
  }
  await getSolanaFromMemnomic(mnemonic);
  await getStellarFromMemnomic(mnemonic);
  await getAlgorandFromMemnomic(mnemonic);
  await getTronFromMemnomic(mnemonic);
  await getXRPFromMemnomic(mnemonic);
}

Future<Map> sendCardano(Map config) async {
  final walletBuilder = cardano.WalletBuilder()
    ..networkId = config['cardanoNetwork']
    ..mnemonic = config[mnemonicKey].split(' ');

  if (config['cardanoNetwork'] == cardano.NetworkId.mainnet) {
    walletBuilder.mainnetAdapterKey = config['blockfrostForCardanoApiKey'];
  } else if (config['cardanoNetwork'] == cardano.NetworkId.testnet) {
    walletBuilder.testnetAdapterKey = config['blockfrostForCardanoApiKey'];
  }
  final result = await walletBuilder.buildAndSync();
  if (result.isErr()) {
    if (kDebugMode) {
      print(result.err());
    }
    return {};
  }

  cardano.Wallet userWallet = result.unwrap();

  final coinSelection = await cardano.largestFirst(
    unspentInputsAvailable: userWallet.unspentTransactions,
    outputsRequested: [
      cardano.MultiAssetRequest.lovelace(
        config['lovelaceToSend'] + maxFeeGuessForCardano,
      )
    ],
    ownedAddresses: userWallet.addresses.toSet(),
  );

  final builder = cardano.TransactionBuilder()
    ..wallet(userWallet)
    ..blockchainAdapter(userWallet.blockchainAdapter)
    ..toAddress(config['recipientAddress'])
    ..inputs(coinSelection.unwrap().inputs)
    ..value(
      cardano.ShelleyValue(
        coin: config['lovelaceToSend'],
        multiAssets: [],
      ),
    )
    ..changeAddress(config['senderAddress']);

  final txResult = await builder.buildAndSign();

  if (txResult.isErr()) {
    if (kDebugMode) {
      print(txResult.err());
    }
    return {};
  }

  final submitTrx = await userWallet.blockchainAdapter.submitTransaction(
    txResult.unwrap().serialize,
  );

  if (submitTrx.isErr()) {
    if (kDebugMode) {
      print(submitTrx.err());
    }
    return {};
  }

  final txHash = submitTrx.unwrap();
  return {'txid': txHash.replaceAll('"', '')};
}

Future<Map> sendCosmos(Map config) async {
  final networkInfo = cosmos.NetworkInfo(
    bech32Hrp: config['bech32Hrp'],
    lcdUrl: Uri.parse(config['lcdUrl']),
  );

  final wallet =
      cosmos.Wallet.derive(config[mnemonicKey].split(' '), networkInfo);

  final message = cosmos.StdMsg(
    type: 'cosmos-sdk/MsgSend',
    value: {
      'from_address': wallet.bech32Address,
      'to_address': config['recipientAddress'],
      'amount': [
        {
          'denom': 'uatom',
          'amount': config['uatomToSend'],
        }
      ]
    },
  );

  final stdTx = cosmos.TxBuilder.buildStdTx(stdMsgs: [message]);

  final signedStdTx =
      await cosmos.TxSigner.signStdTx(wallet: wallet, stdTx: stdTx);

  final result = await cosmos.TxSender.broadcastStdTx(
    wallet: wallet,
    stdTx: signedStdTx,
  );

  if (result.success) {
    return {'txid': result.hash};
  }
  return {};
}

Future<Map> sendSolana(
  String destinationAddress,
  int lamportToSend,
  SolanaClusters solanaClustersType,
) async {
  final mnemonic = Hive.box(secureStorageKey).get(currentMmenomicKey);

  final keyPair = await compute(calculateSolanaKey, {
    mnemonicKey: mnemonic,
    'getSolanaKeys': true,
    seedRootKey: seedPhraseRoot,
  });

  final signature = await getSolanaClient(solanaClustersType).transferLamports(
    source: keyPair,
    destination: solana.Ed25519HDPublicKey.fromBase58(destinationAddress),
    lamports: lamportToSend,
  );

  return {'txid': signature};
}

Future<Map> sendAlgorand(
  String destinationAddress,
  AlgorandTypes type,
  int amount,
) async {
  final mnemonic = Hive.box(secureStorageKey).get(currentMmenomicKey);

  final keyPair = await compute(calculateAlgorandKey, {
    mnemonicKey: mnemonic,
    'getAlgorandKeys': true,
    seedRootKey: seedPhraseRoot,
  });

  String signature = await getAlgorandClient(type).sendPayment(
      account: keyPair,
      recipient: algo_rand.Address.fromAlgorandAddress(
        address: destinationAddress,
      ),
      amount: amount);

  return {'txid': signature};
}

const rampSwap = {
  "ETH": "ETH_ETH",
  "AVAX": "AVAX_AVAX",
  "BCH": "BCH_BCH",
  "BNB": "BSC_BNB",
  "BTC": "BTC_BTC",
  "ADA": "CARDANO_ADA",
  "CELO": "CELO_CELO",
  "ATOM": "COSMOS_ATOM",
  "DOGE": "DOGE_DOGE",
  "EGLD": "ELROND_EGLD",
  "FTM": "FANTOM_FTM",
  "FIL": "FILECOIN_FIL",
  "FLOW": "FLOW_FLOW",
  "FUSD": "FUSE_FUSD",
  "ONE": "HARMONY_ONE",
  "KSM": "KUSAMA_KSM",
  "LTC": "LTC_LTC",
  "MATIC": "MATIC_MATIC",
  "NEAR": "NEAR_NEAR",
  "DOT": "POLKADOT_DOT",
  "RON": "RONIN_RON",
  "RDOC": "RSK_RDOC",
  "RIF": "RSK_RIF",
  "SOL": "SOLANA_SOL",
  "XDAI": "XDAI_XDAI",
  "XLM": "XLM_XLM",
  "XRP": "XRP_XRP",
  "ZIL": "ZILLIQA_ZIL",
};
getRampLink(String asset, String userAddress) {
  return 'https://buy.ramp.network/?defaultAsset=$asset&fiatCurrency=USD&fiatValue=150.000000&hostApiKey=$rampApiKey&swapAsset=$asset&userAddress=$userAddress';
}

Future<Map> getSolanaFromMemnomic(String mnemonic) async {
  final pref = Hive.box(secureStorageKey);
  const keyName = 'solanaDetail';
  List mmenomicMapping = [];
  if (pref.get(keyName) != null) {
    mmenomicMapping = jsonDecode(pref.get(keyName)) as List;
    for (int i = 0; i < mmenomicMapping.length; i++) {
      if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
        return mmenomicMapping[i]['key'];
      }
    }
  }

  final keys = await compute(calculateSolanaKey, {
    mnemonicKey: mnemonic,
    seedRootKey: seedPhraseRoot,
  });
  mmenomicMapping.add({'key': keys, 'mmenomic': mnemonic});
  await pref.put(keyName, jsonEncode(mmenomicMapping));
  return keys;
}

Future<Map> getCardanoFromMemnomic(
  String mnemonic,
  cardano.NetworkId cardanoNetwork,
) async {
  final pref = Hive.box(secureStorageKey);

  final keyName = 'cardanoDetail${cardanoNetwork.name}';
  List mmenomicMapping = [];
  if (pref.get(keyName) != null) {
    mmenomicMapping = jsonDecode(pref.get(keyName)) as List;

    for (int i = 0; i < mmenomicMapping.length; i++) {
      if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
        return mmenomicMapping[i]['key'];
      }
    }
  }
  final keys = await compute(calculateCardanoKey, {
    mnemonicKey: mnemonic,
    'network': cardanoNetwork,
  });

  mmenomicMapping.add({'key': keys, 'mmenomic': mnemonic});

  await pref.put(keyName, jsonEncode(mmenomicMapping));
  return keys;
}

Future<Map> getStellarFromMemnomic(String mnemonic) async {
  final pref = Hive.box(secureStorageKey);
  const keyName = 'stellarDetail';
  List mmenomicMapping = [];

  if (pref.get(keyName) != null) {
    mmenomicMapping = jsonDecode(pref.get(keyName)) as List;
    for (int i = 0; i < mmenomicMapping.length; i++) {
      if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
        return mmenomicMapping[i]['key'];
      }
    }
  }
  final keys = await compute(calculateStellarKey, {mnemonicKey: mnemonic});
  mmenomicMapping.add({'key': keys, 'mmenomic': mnemonic});
  await pref.put(keyName, jsonEncode(mmenomicMapping));
  return keys;
}

Future<Map> getCosmosFromMemnomic(
  String mnemonic,
  String bech32Hrp,
  String lcdUrl,
) async {
  final pref = Hive.box(secureStorageKey);

  final keyName = sha3('cosmosDetails$bech32Hrp');
  List mmenomicMapping = [];
  if (pref.get(keyName) != null) {
    mmenomicMapping = jsonDecode(pref.get(keyName)) as List;
    for (int i = 0; i < mmenomicMapping.length; i++) {
      if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
        return mmenomicMapping[i]['key'];
      }
    }
  }
  final networkInfo = cosmos.NetworkInfo(
    bech32Hrp: bech32Hrp,
    lcdUrl: Uri.parse(lcdUrl),
  );

  final keys = await compute(
    calculateCosmosKey,
    {
      mnemonicKey: mnemonic,
      "networkInfo": networkInfo,
    },
  );
  mmenomicMapping.add({'key': keys, 'mmenomic': mnemonic});
  await pref.put(keyName, jsonEncode(mmenomicMapping));
  return keys;
}

calculateCosmosKey(Map config) {
  final wallet = cosmos.Wallet.derive(
    config[mnemonicKey].split(' '),
    config['networkInfo'],
  );

  return {'address': wallet.bech32Address};
}

Future<Map> getBitcoinFromMemnomic(
  String mnemonic,
  Map posDetails,
) async {
  final pref = Hive.box(secureStorageKey);

  final keyName =
      sha3('bitcoinDetail${posDetails['POSNetwork']}${posDetails['default']}');
  List mmenomicMapping = [];
  if (pref.get(keyName) != null) {
    mmenomicMapping = jsonDecode(pref.get(keyName)) as List;
    for (int i = 0; i < mmenomicMapping.length; i++) {
      if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
        return mmenomicMapping[i]['key'];
      }
    }
  }
  final keys = await compute(
    calculateBitCoinKey,
    Map.from(posDetails)
      ..addAll({
        mnemonicKey: mnemonic,
        seedRootKey: seedPhraseRoot,
      }),
  );
  mmenomicMapping.add({'key': keys, 'mmenomic': mnemonic});
  await pref.put(keyName, jsonEncode(mmenomicMapping));
  return keys;
}

Future<Map> getTezorFromMemnomic(
  String mnemonic,
  Map tezorDetails,
) async {
  final pref = Hive.box(secureStorageKey);
  TezosTypes tezorType = tezorDetails['tezorType'];

  final keyName = 'tezorDetails${tezorType.index}';
  List mmenomicMapping = [];
  if (pref.get(keyName) != null) {
    mmenomicMapping = jsonDecode(pref.get(keyName)) as List;
    for (int i = 0; i < mmenomicMapping.length; i++) {
      if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
        return mmenomicMapping[i]['key'];
      }
    }
  }
  final keys = await compute(
    calculateTezorKey,
    Map.from(tezorDetails)
      ..addAll({
        mnemonicKey: mnemonic,
        seedRootKey: seedPhraseRoot,
      }),
  );
  mmenomicMapping.add({'key': keys, 'mmenomic': mnemonic});
  await pref.put(keyName, jsonEncode(mmenomicMapping));
  return keys;
}

Future<String> fileCoinAddressFromCk(String ck, String addressPrefix) async {
  // FIXME:
  return '';
  // final publickKey = await Flotus.secpPrivateToPublic(ck: ck);

  // String address = await Flotus.genAddress(pk: publickKey, t: 'secp');
  // return '$addressPrefix${address.substring(1)}';
}

Future<Map> decodeAbi(String txData) async {
  JavascriptRuntime javaScriptRuntime = getJavascriptRuntime();
  try {
    final js = await rootBundle.loadString('js/abi-decoder.js');

    javaScriptRuntime.evaluate(js);
    javaScriptRuntime.evaluate('''abiDecoder.addABI($oneInchAbi)''');
    javaScriptRuntime.evaluate('''abiDecoder.addABI($uniswapAbi2)''');
    javaScriptRuntime.evaluate('''abiDecoder.addABI($uniswapAbi)''');
    javaScriptRuntime.evaluate('''abiDecoder.addABI($wrappedEthAbi)''');
    javaScriptRuntime.evaluate('''abiDecoder.addABI($erc20Abi)''');
    javaScriptRuntime.evaluate('''abiDecoder.addABI($erc721Abi)''');
    javaScriptRuntime.evaluate('''abiDecoder.addABI($tokenSaleAbi)''');
    javaScriptRuntime.evaluate('''abiDecoder.addABI($ensResolver)''');
    javaScriptRuntime.evaluate('''abiDecoder.addABI($ensInterface)''');
    javaScriptRuntime.evaluate('''abiDecoder.addABI($erc1155Abi)''');
    javaScriptRuntime.evaluate('''abiDecoder.addABI($unstoppableDomainAbi)''');

    final decode = javaScriptRuntime
        .evaluate('JSON.stringify(abiDecoder.decodeMethod("$txData"))');
    if (decode.stringResult == 'undefined') return null;
    Map result_ = json.decode(decode.stringResult);

    return result_;
  } catch (_) {
    rethrow;
  } finally {
    javaScriptRuntime.dispose();
  }
}

Future<Map> getFileCoinFromMemnomic(
  String mnemonic,
  String addressPrefix,
) async {
  final pref = Hive.box(secureStorageKey);
  final keyName = 'fileCoinDetail$addressPrefix';
  List mmenomicMapping = [];
  if (pref.get(keyName) != null) {
    mmenomicMapping = jsonDecode(pref.get(keyName)) as List;
    for (int i = 0; i < mmenomicMapping.length; i++) {
      if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
        return mmenomicMapping[i]['key'];
      }
    }
  }
  final keys = await compute(calculateFileCoinKey, {
    mnemonicKey: mnemonic,
    seedRootKey: seedPhraseRoot,
  });

  String address = await fileCoinAddressFromCk(
    keys['ck'],
    addressPrefix,
  );

  keys['address'] = address;
  mmenomicMapping.add({'key': keys, 'mmenomic': mnemonic});
  await pref.put(keyName, jsonEncode(mmenomicMapping));
  return keys;
}

Future<Map> calculateTezorKey(Map config) async {
  List<String> keys = await Dartez.restoreIdentityFromDerivationPath(
    "m/44'/1729'/0'/0'",
    config[mnemonicKey],
  );

  return {
    'address': keys[2],
    'private_key': keys[0],
    'public_key': keys[1],
  };
}

Map calculateBitCoinKey(Map config) {
  SeedPhraseRoot seedRoot_ = config[seedRootKey];
  final node = seedRoot_.root.derivePath(config['derivationPath']);

  String address;
  if (config['P2WPKH']) {
    address = P2WPKH(
      data: PaymentData(
        pubkey: node.publicKey,
      ),
      network: config['POSNetwork'],
    ).data.address;
  } else {
    address = P2PKH(
      data: PaymentData(
        pubkey: node.publicKey,
      ),
      network: config['POSNetwork'],
    ).data.address;
  }
  if (config['default'] == 'BCH') {
    if (bitbox.Address.detectFormat(address) == bitbox.Address.formatLegacy) {
      address = bitbox.Address.toCashAddress(address).split(':')[1];
    }
  }

  if (config['default'] == 'ZEC') {
    final baddr = [...bs58check.decode(address)];
    baddr.removeAt(0);

    final taddr = Uint8List(22);

    taddr.setAll(2, baddr);
    taddr.setAll(0, [0x1c, 0xb8]);

    address = bs58check.encode(taddr);
  }

  return {
    'address': address,
    'private_key': "0x${HEX.encode(node.privateKey)}"
  };
}

Map calculateFileCoinKey(Map config) {
  SeedPhraseRoot seedRoot_ = config[seedRootKey];
  final node = seedRoot_.root.derivePath("m/44'/461'/0'/0");
  final rs0 = node.derive(0);
  final ck = base64Encode(rs0.privateKey);

  return {"ck": ck};
}

algo_rand.Algorand getAlgorandClient(AlgorandTypes type) {
  final _algodClient = algo_rand.AlgodClient(
    apiUrl: type == AlgorandTypes.mainNet
        ? algo_rand.PureStake.MAINNET_ALGOD_API_URL
        : algo_rand.PureStake.TESTNET_ALGOD_API_URL,
    apiKey: pureStakeApiKey,
    tokenKey: algo_rand.PureStake.API_TOKEN_HEADER,
  );

  final _indexerClient = algo_rand.IndexerClient(
    apiUrl: type == AlgorandTypes.mainNet
        ? algo_rand.PureStake.MAINNET_INDEXER_API_URL
        : algo_rand.PureStake.TESTNET_INDEXER_API_URL,
    apiKey: pureStakeApiKey,
    tokenKey: algo_rand.PureStake.API_TOKEN_HEADER,
  );

  final _kmdClient = algo_rand.KmdClient(
    apiUrl: '127.0.0.1',
    apiKey: pureStakeApiKey,
  );

  return algo_rand.Algorand(
    algodClient: _algodClient,
    indexerClient: _indexerClient,
    kmdClient: _kmdClient,
  );
}

Future calculateAlgorandKey(Map config) async {
  SeedPhraseRoot seedRoot_ = config[seedRootKey];
  KeyData masterKey =
      await ED25519_HD_KEY.derivePath("m/44'/283'/0'/0'/0'", seedRoot_.seed);

  final account =
      await algo_rand.Account.fromPrivateKey(HEX.encode(masterKey.key));
  if (config['getAlgorandKeys'] != null && config['getAlgorandKeys'] == true) {
    return account;
  }

  return {
    'address': account.publicAddress,
  };
}

String calculateEthereumKey(Map config) {
  SeedPhraseRoot seedRoot_ = config[seedRootKey];
  return "0x${HEX.encode(seedRoot_.root.derivePath("m/44'/${config['coinType']}'/0'/0/0").privateKey)}";
}

calculateTronKey(Map config) {
  SeedPhraseRoot seedRoot_ = config[seedRootKey];
  final master = wallet.ExtendedPrivateKey.master(seedRoot_.seed, wallet.xprv);
  final root = master.forPath("m/44'/195'/0'/0/0");

  final privateKey = wallet.PrivateKey((root as wallet.ExtendedPrivateKey).key);
  final publicKey = wallet.tron.createPublicKey(privateKey);
  final address = wallet.tron.createAddress(publicKey);

  return {
    'address': address,
  };
}

Map<String, String> calculateRippleKey(Map config) {
  SeedPhraseRoot seedRoot_ = config[seedRootKey];
  final node = seedRoot_.root.derivePath("m/44'/144'/0'/0/0");

  final pubKeyHash = computePublicKeyHash(node.publicKey);

  final t = sha256
      .convert(sha256.convert([0, ...pubKeyHash]).bytes)
      .bytes
      .sublist(0, 4);

  String address =
      xrpBaseCodec.encode(Uint8List.fromList([0, ...pubKeyHash, ...t]));
  return {
    'address': address,
    'privateKey': HEX.encode(node.privateKey),
  };
}

Uint8List computePublicKeyHash(Uint8List publicKeyBytes) {
  final hash256 = sha256.convert(publicKeyBytes).bytes;
  final hash160 = RIPEMD160().update(hash256).digest();

  return Uint8List.fromList(hash160);
}

Future calculateSolanaKey(Map config) async {
  SeedPhraseRoot seedRoot_ = config[seedRootKey];

  final solana.Ed25519HDKeyPair keyPair =
      await solana.Ed25519HDKeyPair.fromSeedWithHdPath(
    seed: seedRoot_.seed,
    hdPath: "m/44'/501'/0'",
  );

  if (config['getSolanaKeys'] != null && config['getSolanaKeys'] == true) {
    return keyPair;
  }

  return {
    'address': keyPair.address,
  };
}

Map calculateCardanoKey(Map config) {
  final wallet = cardano.HdWallet.fromMnemonic(config[mnemonicKey]);
  const cardanoAccountHardOffsetKey = 0x80000000;

  String userWalletAddress = wallet
      .deriveUnusedBaseAddressKit(
          networkId: config['network'],
          index: 0,
          account: cardanoAccountHardOffsetKey,
          role: 0,
          unusedCallback: (cardano.ShelleyAddress address) => true)
      .address
      .toString();

  return {
    'address': userWalletAddress,
  };
}

Future<Map> calculateStellarKey(Map config) async {
  final wallet = await stellar.Wallet.from(config[mnemonicKey]);
  final userWalletAddress = await wallet.getKeyPair(index: 0);
  return {
    'address': userWalletAddress.accountId,
    'private_key': userWalletAddress.secretSeed,
  };
}

Future<Map> sendXRP({
  String ws,
  String recipient,
  String amount,
  String mnemonic,
}) async {
  Map accountInfo = {};
  //FIXME:
  try {
    // rippleJsRuntime
    //     .evaluate('const wallet = xrpl.Wallet.fromMnemonic("$mnemonic")');
    // rippleJsRuntime.evaluate('''const client = new xrpl.Client("$ws")''');

    // var asyncResult = await rippleJsRuntime.evaluateAsync("""
    // client.connect().submitAndWait({
    //   TransactionType: "Payment",
    //   Account: wallet.address,
    //   Amount: xrpl.xrpToDrops("$amount"),
    //   Destination: "$recipient",
    // }, {
    //   autofill: true,
    //   wallet: wallet,
    // });
    // """);

    // rippleJsRuntime.executePendingJob();
    // final promiseResolved = await rippleJsRuntime.handlePromise(asyncResult);
    // accountInfo = json.decode(promiseResolved.stringResult);
  } catch (e) {
    rethrow;
  }
  // return {
  //   'txid': accountInfo['result']['meta']['TransactionResult'],
  // };
  return {};
}

Future<double> getXRPAddressBalance(
  String address,
  String ws, {
  bool skipNetworkRequest = false,
}) async {
  final pref = Hive.box(secureStorageKey);

  final key = 'xrpAddressBalance$address$ws';

  final storedBalance = pref.get(key);

  double savedBalance = 0;

  if (storedBalance != null) {
    savedBalance = storedBalance;
  }

  if (skipNetworkRequest) return savedBalance;
  try {
    final httpFromWs = Uri.parse(ws);
    final request = await post(
      httpFromWs,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "method": "account_info",
        "params": [
          {"account": address}
        ]
      }),
    );

    if (request.statusCode ~/ 100 == 4 || request.statusCode ~/ 100 == 5) {
      throw Exception(request.body);
    }

    Map accountInfo = json.decode(request.body);

    if (accountInfo['result']['account_data'] == null) {
      throw Exception('Account not found');
    }

    final balance = accountInfo['result']['account_data']['Balance'];
    final userBalance = double.parse(balance) / pow(10, xrpDecimals);
    await pref.put(key, userBalance);

    return userBalance;
  } catch (e) {
    return savedBalance;
  }
}

Future<double> getAlgorandAddressBalance(
  String address,
  AlgorandTypes type, {
  bool skipNetworkRequest = false,
}) async {
  final pref = Hive.box(secureStorageKey);

  final key = 'algorandAddressBalance$address${type.index}';

  final storedBalance = pref.get(key);

  double savedBalance = 0;

  if (storedBalance != null) {
    savedBalance = storedBalance;
  }

  if (skipNetworkRequest) return savedBalance;

  try {
    final userBalanceMicro = await getAlgorandClient(type).getBalance(address);
    final userBalance = userBalanceMicro / pow(10, algorandDecimals);
    await pref.put(key, userBalance);

    return userBalance;
  } catch (e) {
    return savedBalance;
  }
}

Future<double> getTronAddressBalance(
  String address, {
  bool skipNetworkRequest = false,
}) async {
  final pref = Hive.box(secureStorageKey);

  final key = 'tronAddressBalance$address';

  final storedBalance = pref.get(key);

  double savedBalance = 0;

  if (storedBalance != null) {
    savedBalance = storedBalance;
  }

  if (skipNetworkRequest) return savedBalance;

  try {
    // FIXME:
    // final userBalanceMicro = await getAlgorandClient(type).getBalance(address);
    // final userBalance = userBalanceMicro / pow(10, algorandDecimals);
    // await pref.put(key, userBalance);

    // return userBalance;
    return savedBalance;
  } catch (e) {
    return savedBalance;
  }
}

Future<double> getCardanoAddressBalance(
  String address,
  cardano.NetworkId cardanoNetwork,
  String blockfrostForCardanoApiKey, {
  bool skipNetworkRequest = false,
}) async {
  final pref = Hive.box(secureStorageKey);
  final key = 'cardanoAddressBalance$address';

  final storedBalance = pref.get(key);

  double savedBalance = 0;

  if (storedBalance != null) {
    savedBalance = storedBalance;
  }

  if (skipNetworkRequest) return savedBalance;

  try {
    final cardanoBlockfrostBaseUrl =
        'https://cardano-${cardanoNetwork == cardano.NetworkId.mainnet ? 'mainnet' : 'preprod'}.blockfrost.io/api/v0/addresses/';
    final request = await get(
      Uri.parse('$cardanoBlockfrostBaseUrl$address'),
      headers: {'project_id': blockfrostForCardanoApiKey},
    );

    if (request.statusCode ~/ 100 == 4 || request.statusCode ~/ 100 == 5) {
      throw Exception('Request failed');
    }
    Map decodedData = jsonDecode(request.body);
    final String balance = (decodedData['amount'] as List)
        .where((element) => element['unit'] == 'lovelace')
        .toList()[0]['quantity'];

    final balanceFromAdaToLoveLace =
        (BigInt.parse(balance) / BigInt.from(pow(10, cardanoDecimals)))
            .toDouble();
    await pref.put(key, balanceFromAdaToLoveLace);

    return balanceFromAdaToLoveLace;
  } catch (e) {
    return savedBalance;
  }
}

Future<double> getStellarAddressBalance(
  String address,
  stellar.StellarSDK sdk,
  stellar.Network cluster, {
  bool skipNetworkRequest = false,
}) async {
  final pref = Hive.box(secureStorageKey);

  final key = 'stellarAddressBalance$address${bytesToHex(cluster.networkId)}';

  final storedBalance = pref.get(key);

  double savedBalance = 0;

  if (storedBalance != null) {
    savedBalance = storedBalance;
  }

  if (skipNetworkRequest) return savedBalance;

  try {
    stellar.AccountResponse account = await sdk.accounts.account(address);

    for (stellar.Balance balance in account.balances) {
      if (balance.assetType == stellar.Asset.TYPE_NATIVE) {
        double balanceInStellar = double.parse(balance.balance);
        await pref.put(key, balanceInStellar);
        return balanceInStellar;
      }
    }
    return 0;
  } catch (e) {
    return savedBalance;
  }
}

Future<double> getSolanaAddressBalance(
  String address,
  SolanaClusters solanaClusterType, {
  bool skipNetworkRequest = false,
}) async {
  final pref = Hive.box(secureStorageKey);

  final key = 'solanaAddressBalance$address${solanaClusterType.index}';

  final storedBalance = pref.get(key);

  double savedBalance = 0;

  if (storedBalance != null) {
    savedBalance = storedBalance;
  }

  if (skipNetworkRequest) return savedBalance;

  try {
    final balanceInLamport =
        await getSolanaClient(solanaClusterType).rpcClient.getBalance(address);
    double balanceInSol = balanceInLamport / solana.lamportsPerSol;

    await pref.put(key, balanceInSol);

    return balanceInSol;
  } catch (e) {
    return savedBalance;
  }
}

Future<double> getCosmosAddressBalance(
  String address,
  String lcdUrl, {
  bool skipNetworkRequest = false,
}) async {
  final pref = Hive.box(secureStorageKey);
  final key = 'cosmosAddressBalance$address$lcdUrl';

  final storedBalance = pref.get(key);

  double savedBalance = 0;

  if (storedBalance != null) {
    savedBalance = storedBalance;
  }

  if (skipNetworkRequest) return savedBalance;
  try {
    final response = await http.get(
      Uri.parse(
        '$lcdUrl/cosmos/bank/v1beta1/balances/$address',
      ),
    );
    final responseBody = response.body;
    if (response.statusCode ~/ 100 == 4 || response.statusCode ~/ 100 == 5) {
      throw Exception(responseBody);
    }

    List balances = jsonDecode(responseBody)['balances'];

    if (balances.isEmpty) {
      return 0;
    }

    final String balance = balances
        .where((element) => element['denom'] == 'uatom')
        .toList()[0]['amount'];

    double balanceInCosmos = double.parse(balance) / pow(10, cosmosDecimals);

    await pref.put(key, balanceInCosmos);

    return balanceInCosmos;
  } catch (e) {
    return savedBalance;
  }
}

Future<double> getFileCoinAddressBalance(
  String address, {
  String baseUrl,
  bool skipNetworkRequest = false,
}) async {
  final pref = Hive.box(secureStorageKey);
  final key = 'fileCoinAddressBalance$address$baseUrl';

  final storedBalance = pref.get(key);

  double savedBalance = 0;

  if (storedBalance != null) {
    savedBalance = storedBalance;
  }

  if (skipNetworkRequest) return savedBalance;

  try {
    final response = await http.get(Uri.parse(
        '$baseUrl/actor/balance?actor=${Uri.encodeQueryComponent(address)}'));
    final responseBody = response.body;
    if (response.statusCode ~/ 100 == 4 || response.statusCode ~/ 100 == 5) {
      throw Exception(responseBody);
    }

    double balanceInFileCoin = double.parse(
          jsonDecode(responseBody)['data']['balance'].toString(),
        ) /
        pow(10, fileCoinDecimals);

    await pref.put(key, balanceInFileCoin);

    return balanceInFileCoin;
  } catch (e) {
    return savedBalance;
  }
}

Future<String> getCryptoPrice({
  bool skipNetworkRequest = false,
}) async {
  String allCrypto = "";
  int currentIndex = 0;
  final listOfCoinGeckoValue = coinGeckCryptoSymbolToID.values;
  for (final value in listOfCoinGeckoValue) {
    if (currentIndex == listOfCoinGeckoValue.length - 1) {
      allCrypto += value;
    } else {
      allCrypto += value + ",";
    }
    currentIndex++;
  }
  const secondsToResendRequest = 15;

  final pref = Hive.box(secureStorageKey);
  final savedCryptoPrice = pref.get(coinGeckoCryptoPriceKey);

  if (savedCryptoPrice != null) {
    DateTime now = DateTime.now();
    final nowInSeconds = now.difference(MyApp.lastcoinGeckoData).inSeconds;

    final useCachedResponse = nowInSeconds < secondsToResendRequest;

    if (nowInSeconds > secondsToResendRequest) {
      MyApp.lastcoinGeckoData = DateTime.now();
      MyApp.getCoinGeckoData = true;
    }

    if (useCachedResponse || skipNetworkRequest) {
      return json.decode(savedCryptoPrice)['data'];
    }
  }

  try {
    String defaultCurrency = pref.get('defaultCurrency') ?? "usd";
    if (!MyApp.getCoinGeckoData) {
      return json.decode(savedCryptoPrice)['data'];
    }
    MyApp.getCoinGeckoData = false;
    MyApp.lastcoinGeckoData = DateTime.now();

    final dataUrl =
        '$coinGeckoBaseurl/simple/price?ids=$allCrypto&vs_currencies=$defaultCurrency&include_24hr_change=true';

    final response =
        await get(Uri.parse(dataUrl)).timeout(networkTimeOutDuration);

    final responseBody = response.body;
    // check for http status code of 4** or 5**
    if (response.statusCode ~/ 100 == 4 || response.statusCode ~/ 100 == 5) {
      throw Exception(responseBody);
    }

    await pref.put(
      coinGeckoCryptoPriceKey,
      json.encode(
        {
          'data': responseBody,
        },
      ),
    );

    return responseBody;
  } catch (e) {
    if (savedCryptoPrice != null) {
      return json.decode(savedCryptoPrice)['data'];
    }
    return null;
  }
}

Future<String> contractDetailsKey(String rpc, String contractAddress) async {
  String mnemonic = Hive.box(secureStorageKey).get(currentMmenomicKey);
  final ethereumDetails = await getEthereumFromMemnomic(
    mnemonic,
    getEVMBlockchains()['Ethereum']['coinType'],
  );
  return '${rpc.toString().toLowerCase()}${contractAddress.toString().toLowerCase()}${ethereumDetails['eth_wallet_address']}|usertoken';
}

Future getErc20Allowance({
  String owner,
  String spender,
  String rpc,
  String contractAddress,
}) async {
  web3.Web3Client client = web3.Web3Client(
    rpc,
    Client(),
  );

  final contract = web3.DeployedContract(
      web3.ContractAbi.fromJson(erc20Abi, ''),
      web3.EthereumAddress.fromHex(contractAddress));

  final allowanceFunction = contract.function('allowance');

  final allowance = (await client.call(
    contract: contract,
    function: allowanceFunction,
    params: [
      web3.EthereumAddress.fromHex(owner),
      web3.EthereumAddress.fromHex(spender),
    ],
  ))
      .first;

  return allowance;
}

Future<double> getERC20TokenBalance(
  Map tokenDetails, {
  bool skipNetworkRequest = false,
}) async {
  web3.Web3Client client = web3.Web3Client(
    tokenDetails['rpc'],
    Client(),
  );

  final pref = Hive.box(secureStorageKey);
  String mnemonic = pref.get(currentMmenomicKey);
  Map response = await getEthereumFromMemnomic(
    mnemonic,
    tokenDetails['coinType'],
  );

  final sendingAddress = web3.EthereumAddress.fromHex(
    response['eth_wallet_address'],
  );
  String elementDetailsKey = await contractDetailsKey(
    tokenDetails['rpc'],
    tokenDetails['contractAddress'],
  );

  String balanceKey = sha3('${elementDetailsKey}balance');

  final storedBalance = pref.get(balanceKey);

  double savedBalance = 0;

  if (storedBalance != null) {
    final crytoBalance = jsonDecode(pref.get(balanceKey));
    savedBalance = double.parse(crytoBalance['balance']) /
        pow(10, double.parse(crytoBalance['decimals']));
  }

  if (skipNetworkRequest) return savedBalance;

  try {
    final contract = web3.DeployedContract(
      web3.ContractAbi.fromJson(erc20Abi, ''),
      web3.EthereumAddress.fromHex(
        tokenDetails['contractAddress'],
      ),
    );

    final balanceFunction = contract.function('balanceOf');

    final decimalsFunction = contract.function('decimals');

    final decimals = (await client
            .call(contract: contract, function: decimalsFunction, params: []))
        .first
        .toString();

    final balance = (await client.call(
      contract: contract,
      function: balanceFunction,
      params: [sendingAddress],
    ))
        .first
        .toString();
    await pref.put(
      balanceKey,
      jsonEncode({
        'balance': balance,
        'decimals': decimals,
      }),
    );
    return double.parse(balance) / pow(10, double.parse(decimals));
  } catch (e) {
    return savedBalance;
  }
}

Future<double> getEtherTransactionFee(
  String rpc,
  Uint8List data,
  web3.EthereumAddress sender,
  web3.EthereumAddress to, {
  double value,
  EtherAmount gasPrice,
}) async {
  final client = web3.Web3Client(
    rpc,
    Client(),
  );

  final etherValue = value != null
      ? web3.EtherAmount.inWei(
          BigInt.from(value),
        )
      : null;

  if (gasPrice == null || gasPrice.getInWei == BigInt.from(0)) {
    gasPrice = await client.getGasPrice();
  }

  BigInt gasUnit;

  try {
    gasUnit = await client.estimateGas(
      sender: sender,
      to: to,
      data: data,
      value: etherValue,
    );
  } catch (_) {}

  if (gasUnit == null) {
    try {
      gasUnit = await client.estimateGas(
        sender: EthereumAddress.fromHex(zeroAddress),
        to: to,
        data: data,
        value: etherValue,
      );
    } catch (_) {}
  }

  if (gasUnit == null) {
    try {
      gasUnit = await client.estimateGas(
        sender: EthereumAddress.fromHex(deadAddress),
        to: to,
        data: data,
        value: etherValue,
      );
    } catch (e) {
      gasUnit = BigInt.from(0);
    }
  }

  return gasPrice.getInWei.toDouble() * gasUnit.toDouble();
}

Future<String> etherPrivateKeyToAddress(String privateKey) async {
  web3.EthPrivateKey ethereumPrivateKey =
      web3.EthPrivateKey.fromHex(privateKey);
  final uncheckedSumAddress = await ethereumPrivateKey.extractAddress();
  return web3.EthereumAddress.fromHex(uncheckedSumAddress.toString()).hexEip55;
}

Future<Map> getTronFromMemnomic(
  String mnemonic,
) async {
  String key = 'tronDetails$mnemonic';

  final pref = Hive.box(secureStorageKey);
  List mmenomicMapping = [];
  if (pref.get(key) != null) {
    mmenomicMapping = jsonDecode(pref.get(key)) as List;
    for (int i = 0; i < mmenomicMapping.length; i++) {
      if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
        return mmenomicMapping[i]['key'];
      }
    }
  }

  final keys = await compute(
    calculateTronKey,
    {
      mnemonicKey: mnemonic,
      seedRootKey: seedPhraseRoot,
    },
  );

  mmenomicMapping.add({'key': keys, 'mmenomic': mnemonic});
  await pref.put(key, jsonEncode(mmenomicMapping));
  return keys;
}

Future<Map> getXRPFromMemnomic(
  String mnemonic,
) async {
  String key = 'xrpDetails$mnemonic';

  final pref = Hive.box(secureStorageKey);
  List mmenomicMapping = [];
  if (pref.get(key) != null) {
    mmenomicMapping = jsonDecode(pref.get(key)) as List;
    for (int i = 0; i < mmenomicMapping.length; i++) {
      if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
        return mmenomicMapping[i]['key'];
      }
    }
  }

  final keys = calculateRippleKey({
    mnemonicKey: mnemonic,
    seedRootKey: seedPhraseRoot,
  });

  mmenomicMapping.add({'key': keys, 'mmenomic': mnemonic});
  await pref.put(key, jsonEncode(mmenomicMapping));
  return keys;
}

Future<Map> getAlgorandFromMemnomic(
  String mnemonic,
) async {
  String key = 'algorandDetails$mnemonic';

  final pref = Hive.box(secureStorageKey);
  List mmenomicMapping = [];
  if (pref.get(key) != null) {
    mmenomicMapping = jsonDecode(pref.get(key)) as List;
    for (int i = 0; i < mmenomicMapping.length; i++) {
      if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
        return mmenomicMapping[i]['key'];
      }
    }
  }

  final keys = await compute(
    calculateAlgorandKey,
    {
      mnemonicKey: mnemonic,
      seedRootKey: seedPhraseRoot,
    },
  );

  mmenomicMapping.add({'key': keys, 'mmenomic': mnemonic});
  await pref.put(key, jsonEncode(mmenomicMapping));
  return keys;
}

Future<Map> getEthereumFromMemnomic(
  String mnemonic,
  int coinType,
) async {
  String key = 'ethereumDetails$coinType';

  final pref = Hive.box(secureStorageKey);
  List mmenomicMapping = [];
  if (pref.get(key) != null) {
    mmenomicMapping = jsonDecode(pref.get(key)) as List;
    for (int i = 0; i < mmenomicMapping.length; i++) {
      if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
        return mmenomicMapping[i]['key'];
      }
    }
  }
  final privatekeyStr = await compute(
    calculateEthereumKey,
    {
      mnemonicKey: mnemonic,
      'coinType': coinType,
      seedRootKey: seedPhraseRoot,
    },
  );

  final address = await etherPrivateKeyToAddress(privatekeyStr);

  final keys = {
    'eth_wallet_address': address,
    'eth_wallet_privateKey': privatekeyStr,
    mnemonicKey: mnemonic
  };
  mmenomicMapping.add({'key': keys, 'mmenomic': mnemonic});
  await pref.put(key, jsonEncode(mmenomicMapping));
  return keys;
}

Future<String> getCurrencyJson() async {
  return await rootBundle.loadString('json/currencies.json');
}

Future<double> totalCryptoBalance({
  String mnemonic,
  Map allCryptoPrice,
  String defaultCurrency,
  bool skipNetworkRequest = false,
}) async {
  double totalBalance = 0.0;

  for (String i in getBitCoinPOSBlockchains().keys) {
    try {
      final Map posBlockchain = getBitCoinPOSBlockchains()[i];
      double posBlockChainPrice =
          (allCryptoPrice[coinGeckCryptoSymbolToID[posBlockchain['symbol']]]
                  [defaultCurrency.toLowerCase()] as num)
              .toDouble();

      final getBitcoinDetails = await getBitcoinFromMemnomic(
        mnemonic,
        posBlockchain,
      );

      double posBlockChainBalance = await getBitcoinAddressBalance(
        getBitcoinDetails['address'],
        posBlockchain['POSNetwork'],
        skipNetworkRequest: skipNetworkRequest,
      );

      totalBalance += posBlockChainPrice * posBlockChainBalance;
    } catch (_) {}
  }

  for (String i in getEVMBlockchains().keys) {
    try {
      final Map evmBlockchain = getEVMBlockchains()[i];
      final cryptoEVMCompPrice =
          (allCryptoPrice[coinGeckCryptoSymbolToID[evmBlockchain['symbol']]]
                  [defaultCurrency.toLowerCase()] as num)
              .toDouble();
      final getEthereumDetails = await getEthereumFromMemnomic(
        mnemonic,
        evmBlockchain['coinType'],
      );

      final cryptoEVMCompBalance = await getEthereumAddressBalance(
        getEthereumDetails['eth_wallet_address'],
        evmBlockchain['rpc'],
        coinType: evmBlockchain['coinType'],
        skipNetworkRequest: skipNetworkRequest,
      );

      totalBalance += cryptoEVMCompBalance * cryptoEVMCompPrice;
    } catch (_) {}
  }

  for (String i in getCosmosBlockChains().keys) {
    final Map cosmosBlockchain = getCosmosBlockChains()[i];
    final cosmosPrice =
        (allCryptoPrice[coinGeckCryptoSymbolToID[cosmosBlockchain['symbol']]]
                [defaultCurrency.toLowerCase()] as num)
            .toDouble();
    final getCosmosDetails = await getCosmosFromMemnomic(
      mnemonic,
      cosmosBlockchain['bech32Hrp'],
      cosmosBlockchain['lcdUrl'],
    );
    final cosmosBalance = await getCosmosAddressBalance(
      getCosmosDetails['address'],
      cosmosBlockchain['lcdUrl'],
      skipNetworkRequest: skipNetworkRequest,
    );

    totalBalance += cosmosBalance * cosmosPrice;
  }
  for (String i in getStellarBlockChains().keys) {
    final Map stellarBlockchain = getStellarBlockChains()[i];
    final cryptoStellarCompPrice =
        (allCryptoPrice[coinGeckCryptoSymbolToID[stellarBlockchain['symbol']]]
                [defaultCurrency.toLowerCase()] as num)
            .toDouble();
    final getStellarDetails = await getStellarFromMemnomic(mnemonic);
    final cryptoStellarBalance = await getStellarAddressBalance(
      getStellarDetails['address'],
      stellarBlockchain['sdk'],
      stellarBlockchain['cluster'],
      skipNetworkRequest: skipNetworkRequest,
    );

    totalBalance += cryptoStellarBalance * cryptoStellarCompPrice;
  }
  for (String i in getSolanaBlockChains().keys) {
    final Map solanaBlockchain = getSolanaBlockChains()[i];
    final solanaPrice =
        (allCryptoPrice[coinGeckCryptoSymbolToID[solanaBlockchain['symbol']]]
                [defaultCurrency.toLowerCase()] as num)
            .toDouble();
    final getSolanaDetails = await getSolanaFromMemnomic(mnemonic);
    final solanaBalance = await getSolanaAddressBalance(
      getSolanaDetails['address'],
      solanaBlockchain['solanaCluster'],
      skipNetworkRequest: skipNetworkRequest,
    );

    totalBalance += solanaBalance * solanaPrice;
  }

  for (String i in getFilecoinBlockChains().keys) {
    final Map filecoinBlockchain = getFilecoinBlockChains()[i];
    final filecoinPrice =
        (allCryptoPrice[coinGeckCryptoSymbolToID[filecoinBlockchain['symbol']]]
                [defaultCurrency.toLowerCase()] as num)
            .toDouble();
    final getFileCoinDetails = await getFileCoinFromMemnomic(
      mnemonic,
      filecoinBlockchain['prefix'],
    );

    final filecoinBalance = await getFileCoinAddressBalance(
      getFileCoinDetails['address'],
      baseUrl: filecoinBlockchain['baseUrl'],
      skipNetworkRequest: skipNetworkRequest,
    );

    totalBalance += filecoinBalance * filecoinPrice;
  }

  for (String i in getCardanoBlockChains().keys) {
    final Map cardanoBlockchain = getCardanoBlockChains()[i];
    final getCardanoDetails = await getCardanoFromMemnomic(
      mnemonic,
      cardanoBlockchain['cardano_network'],
    );

    final cardanoBalance = await getCardanoAddressBalance(
      getCardanoDetails['address'],
      cardanoBlockchain['cardano_network'],
      cardanoBlockchain['blockFrostKey'],
      skipNetworkRequest: skipNetworkRequest,
    );

    final cardanoPrice =
        (allCryptoPrice[coinGeckCryptoSymbolToID[cardanoBlockchain['symbol']]]
                [defaultCurrency.toLowerCase()] as num)
            .toDouble();

    totalBalance += cardanoBalance * cardanoPrice;
  }

  for (String i in getAlgorandBlockchains().keys) {
    final Map algorandBlockchain = getAlgorandBlockchains()[i];
    final algorandPrice =
        (allCryptoPrice[coinGeckCryptoSymbolToID[algorandBlockchain['symbol']]]
                [defaultCurrency.toLowerCase()] as num)
            .toDouble();
    final getAlgorandDetails = await getAlgorandFromMemnomic(
      mnemonic,
    );

    final algorandBalance = await getAlgorandAddressBalance(
      getAlgorandDetails['address'],
      algorandBlockchain['algoType'],
      skipNetworkRequest: skipNetworkRequest,
    );

    totalBalance += algorandBalance * algorandPrice;
  }

  for (String i in getTronBlockchains().keys) {
    final Map tronBlockchains = getTronBlockchains()[i];
    final tronPrice =
        (allCryptoPrice[coinGeckCryptoSymbolToID[tronBlockchains['symbol']]]
                [defaultCurrency.toLowerCase()] as num)
            .toDouble();
    final getTronDetails = await getTronFromMemnomic(
      mnemonic,
    );

    final tronBalance = await getTronAddressBalance(
      getTronDetails['address'],
      skipNetworkRequest: skipNetworkRequest,
    );

    totalBalance += tronBalance * tronPrice;
  }

  for (String i in getTezosBlockchains().keys) {
    final Map tezosBlockchains = getTezosBlockchains()[i];
    final tezosPrice =
        (allCryptoPrice[coinGeckCryptoSymbolToID[tezosBlockchains['symbol']]]
                [defaultCurrency.toLowerCase()] as num)
            .toDouble();
    final getTezosDetails =
        await getTezorFromMemnomic(mnemonic, tezosBlockchains);

    final tezoBalance = await getTezorAddressBalance(
      getTezosDetails['address'],
      tezosBlockchains,
      skipNetworkRequest: skipNetworkRequest,
    );

    totalBalance += tezoBalance * tezosPrice;
  }

  for (String i in getXRPBlockChains().keys) {
    final Map xrpBlockchains = getXRPBlockChains()[i];
    final xrpPrice =
        (allCryptoPrice[coinGeckCryptoSymbolToID[xrpBlockchains['symbol']]]
                [defaultCurrency.toLowerCase()] as num)
            .toDouble();
    final getXrpDetails = await getXRPFromMemnomic(mnemonic);

    final xrpBalance = await getXRPAddressBalance(
      getXrpDetails['address'],
      xrpBlockchains['ws'],
      skipNetworkRequest: skipNetworkRequest,
    );

    totalBalance += xrpBalance * xrpPrice;
  }

  return totalBalance;
}

Future<String> upload(
  File imageFile,
  String imagefileName,
  MediaType imageMediaType,
  String uploadURL,
  Map fieldsMap,
) async {
  try {
    final stream = http.ByteStream(imageFile.openRead())..cast();
    final length = await imageFile.length();

    final uri = Uri.parse(uploadURL);

    final request = http.MultipartRequest("POST", uri);
    for (final key in fieldsMap.keys) {
      request.fields[key] = fieldsMap[key];
    }

    final multipartFile = http.MultipartFile(imagefileName, stream, length,
        filename: basename(imageFile.path), contentType: imageMediaType);

    request.files.add(multipartFile);
    StreamedResponse response = await request.send();
    Uint8List responseData = await response.stream.toBytes();
    String responseBody = String.fromCharCodes(responseData);

    if (response.statusCode ~/ 100 == 4 || response.statusCode ~/ 100 == 5) {
      if (kDebugMode) {
        print(responseBody);
      }
      throw Exception(responseBody);
    }
    return responseBody;
  } catch (e) {
    if (kDebugMode) {
      print(e.toString());
    }
    return null;
  }
}

Uri blockChainToHttps(String value) {
  if (value == null) return Uri.parse(walletURL);

  value = value.trim();
  if (value.startsWith('ipfs://')) return Uri.parse(ipfsTohttp(value));

  if (isURL(value)) {
    Uri url = Uri.parse(value);
    if (url.scheme.isEmpty) {
      url = url.replace(scheme: 'http');
    }
    return url;
  }

  Uri url = Uri.tryParse(value);
  if (url != null && isLocalizedContent(url)) {
    return url;
  }
  return Uri.parse('https://www.google.com/search?q=$value');
}

Future<double> getEthereumAddressBalance(
  String address,
  String rpcUrl, {
  int coinType,
  bool skipNetworkRequest = false,
}) async {
  final preferencesInst = Hive.box(secureStorageKey);

  final tokenKey = '$rpcUrl$address/balance';
  final storedBalance = preferencesInst.get(tokenKey);

  double savedBalance = 0;

  if (storedBalance != null) savedBalance = storedBalance;

  if (skipNetworkRequest) return savedBalance;

  try {
    final httpClient = Client();
    final ethClient = Web3Client(rpcUrl, httpClient);

    double ethBalance =
        (await ethClient.getBalance(EthereumAddress.fromHex(address)))
                .getInWei
                .toDouble() /
            pow(10, etherDecimals);

    preferencesInst.put(tokenKey, ethBalance);

    return ethBalance;
  } catch (e) {
    return savedBalance;
  }
}

Future<Map> get1InchUrlList(int chainId) async {
  final response = await http
      .get(Uri.parse('https://tokens.1inch.io/v1.1/$chainId'))
      .timeout(networkTimeOutDuration);

  Map jsonResponse = {};

  jsonResponse.addAll(Map.from(json.decode(response.body)));
  return jsonResponse;
}

Map getEthereumDetailsFromChainId(int chainId) {
  List blockChains = getEVMBlockchains().values.toList();
  for (int i = 0; i < blockChains.length; i++) {
    if (blockChains[i]['chainId'] == chainId) {
      return Map.from(blockChains[i])
        ..addAll({
          'name': getEVMBlockchains().keys.toList()[i],
        });
    }
  }
  return null;
}

Map getBitcoinDetailsFromNetwork(NetworkType network) {
  List blockChains = getBitCoinPOSBlockchains().values.toList();
  for (int i = 0; i < blockChains.length; i++) {
    if (blockChains[i]['POSNetwork'] == network) {
      return blockChains[i];
    }
  }
  return null;
}

showDialogWithMessage({
  BuildContext context,
  String message,
  Function onConfirm,
}) {
  AwesomeDialog(
    closeIcon: const Icon(
      Icons.close,
    ),
    buttonsTextStyle: const TextStyle(color: Colors.white),
    context: context,
    btnOkColor: appBackgroundblue,
    dialogType: DialogType.INFO,
    buttonsBorderRadius: const BorderRadius.all(Radius.circular(10)),
    headerAnimationLoop: false,
    animType: AnimType.BOTTOMSLIDE,
    title: AppLocalizations.of(context).info,
    desc: message,
    showCloseIcon: true,
    btnOkText: AppLocalizations.of(context).ok,
    btnOkOnPress: onConfirm ?? () {},
  ).show();
}

bool seqEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) {
    return false;
  }
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

validateAddress(Map data, String recipient) {
  if (data['default'] == 'XRP') {
    final bytes = xrpBaseCodec.decode(recipient);

    final computedCheckSum = sha256
        .convert(sha256.convert(bytes.sublist(0, bytes.length - 4)).bytes)
        .bytes
        .sublist(0, 4);
    final expectedCheckSum = bytes.sublist(bytes.length - 4);

    if (!seqEqual(computedCheckSum, expectedCheckSum)) {
      throw Exception('Invalid XRP address');
    }
  } else if (data['default'] == 'ALGO') {
    algo_rand.Address.fromAlgorandAddress(
      address: recipient,
    );
  } else if (data['default'] == 'BCH') {
    bitbox.Address.detectFormat(recipient);
  } else if (data['default'] == 'XTZ') {
    if (!validateTezosAddress(recipient)) {
      throw Exception('Invalid ${data['default']} address');
    }
  } else if (data['default'] == 'TRX') {
    if (!wallet.isValidTronAddress(recipient)) {
      throw Exception('Invalid ${data['default']} address');
    }
  } else if (data['P2WPKH'] != null) {
    final NetworkType nw =
        getBitCoinPOSBlockchains()[data['name']]['POSNetwork'];
    if (Address.validateAddress(recipient, nw)) {
      return;
    }

    bool canReceivePayment = false;

    try {
      final base58DecodeRecipient = bs58check.decode(recipient);

      final pubHashString = base58DecodeRecipient[0].toRadixString(16) +
          base58DecodeRecipient[1].toRadixString(16);

      canReceivePayment = hexToInt(pubHashString).toInt() == nw.pubKeyHash;
    } catch (_) {}

    if (!canReceivePayment) {
      Bech32 sel = bech32.decode(recipient);
      canReceivePayment = nw.bech32 == sel.hrp;
    }

    if (!canReceivePayment) {
      throw Exception('Invalid ${data['symbol']} address');
    }
  } else if (data['default'] == 'SOL') {
    solana.Ed25519HDPublicKey.fromBase58(recipient);
  } else if (data['default'] == 'ADA') {
    cardano.ShelleyAddress.fromBech32(recipient);
  } else if (data['default'] == 'XLM') {
    stellar.KeyPair.fromAccountId(recipient);
  } else if (data['default'] == 'FIL') {
    //FIXME:
    // if (!await Flotus.validateAddress(recipient)) {
    //   throw Exception('not a valid filecoin address');
    // }
  } else if (data['default'] == 'ATOM') {
    Bech32 sel = bech32.decode(recipient);
    if (sel.hrp != data['bech32Hrp']) {
      throw Exception('not a valid cosmos address');
    }
  } else if (data['rpc'] != null) {
    web3.EthereumAddress.fromHex(recipient);
  }
}

addAddressBlockchain({
  Function onTap,
  BuildContext context,
  String blockchainName,
  Map excludeBlockchains,
}) {
  final blockchains = <Widget>[];
  Map allBlockchains = getAllBlockchains();

  for (String i in allBlockchains.keys) {
    if (excludeBlockchains[i] != null) continue;
    Map blockChainDetails = allBlockchains[i];
    bool isSelected = false;
    if (blockchainName != null && i == blockchainName) {
      isSelected = true;
    }

    blockchains.add(
      InkWell(
        onTap: () {
          blockChainDetails['name'] = i;
          onTap(blockChainDetails);
        },
        child: buildRow(
          blockChainDetails['image'],
          i,
          isSelected: isSelected,
        ),
      ),
    );
  }
  slideUpPanel(
    context,
    Container(
      color: Colors.transparent,
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: null,
                  icon: Icon(
                    Icons.close,
                    color: Colors.transparent,
                  ),
                ),
              ),
              Text(
                AppLocalizations.of(context).selectBlockchains,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...blockchains,
          const SizedBox(height: 20),
        ],
      ),
    ),
    canDismiss: false,
  );
}

showBlockChainDialog({
  Function onTap,
  BuildContext context,
  int selectedChainId,
}) {
  final ethEnabledBlockChain = <Widget>[];
  for (String i in getEVMBlockchains().keys) {
    Map blockChainDetails = getEVMBlockchains()[i];
    bool isSelected = false;
    if (selectedChainId != null &&
        blockChainDetails['chainId'] == selectedChainId) {
      isSelected = true;
    }

    ethEnabledBlockChain.add(
      InkWell(
        onTap: () {
          blockChainDetails['name'] = i;
          onTap(blockChainDetails);
        },
        child: buildRow(
          blockChainDetails['image'],
          i,
          isSelected: isSelected,
        ),
      ),
    );
  }
  slideUpPanel(
    context,
    Container(
      color: Colors.transparent,
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: null,
                  icon: Icon(
                    Icons.close,
                    color: Colors.transparent,
                  ),
                ),
              ),
              Text(
                AppLocalizations.of(context).selectBlockchains,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...ethEnabledBlockChain,
          const SizedBox(height: 20),
        ],
      ),
    ),
    canDismiss: false,
  );
}

Future changeBlockChainAndReturnInit(
  int chainId,
  String rpc,
) async {
  final pref = Hive.box(secureStorageKey);
  await pref.put(dappChainIdKey, chainId);
  final mnemonic = pref.get(currentMmenomicKey);
  final coinType = getEthereumDetailsFromChainId(chainId)['coinType'];
  final response = await getEthereumFromMemnomic(mnemonic, coinType);

  final address = response['eth_wallet_address'];
  return '''
   (function() {
    let isFlutterInAppWebViewReady = false;
    window.addEventListener("flutterInAppWebViewPlatformReady", function (event) {
      isFlutterInAppWebViewReady = true;
      console.log("done and ready");
    });
    var config = {                
        ethereum: {
            chainId: $chainId,
            rpcUrl: "$rpc",  
            address: "$address"
        },
        solana: {
            cluster: "mainnet-beta",
        },
        isDebug: false
    };
    trustwallet.ethereum = new trustwallet.Provider(config);
    trustwallet.solana = new trustwallet.SolanaProvider(config);
    trustwallet.postMessage = (json) => {
        const interval = setInterval(() => {
          if (isFlutterInAppWebViewReady) {
            clearInterval(interval);
            window.flutter_inappwebview.callHandler(
              "CryptoHandler",
              JSON.stringify(json)
            );
          }
        }, 100);
    }
    window.ethereum = trustwallet.ethereum;
  })();
''';
}

Future navigateToDappBrowser(
  BuildContext context,
  String data,
) async {
  final provider = await rootBundle.loadString('js/trust.min.js');
  final webNotifer = await rootBundle.loadString('js/web_notification.js');

  final pref = Hive.box(secureStorageKey);
  if (pref.get(dappChainIdKey) == null) {
    await pref.put(
      dappChainIdKey,
      getEVMBlockchains()[tokenContractNetwork]['chainId'],
    );
  }

  int chainId = pref.get(dappChainIdKey);
  final rpc = getEthereumDetailsFromChainId(chainId)['rpc'];

  final init = await changeBlockChainAndReturnInit(
    chainId,
    rpc,
  );

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Dapp(
        provider: provider,
        webNotifier: webNotifer,
        init: init,
        data: data,
      ),
    ),
  );
}

Future addEthereumChain({
  context,
  String jsonObj,
  onConfirm,
  onReject,
}) async {
  ValueNotifier isLoading = ValueNotifier(false);
  await slideUpPanel(
    context,
    Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context).addNetwork,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          JsonViewer(json.decode(jsonObj)),
          const SizedBox(
            height: 20,
          ),
          ValueListenableBuilder(
              valueListenable: isLoading,
              builder: (_, isLoading_, __) {
                if (isLoading_) {
                  return Row(
                    children: const [
                      Loader(),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: appBackgroundblue,
                        ),
                        onPressed: () async {
                          if (await authenticate(context)) {
                            isLoading.value = true;
                            try {
                              await onConfirm();
                            } catch (_) {}
                            isLoading.value = false;
                          } else {
                            onReject();
                          }
                        },
                        child: Text(
                          AppLocalizations.of(context).confirm,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: appBackgroundblue,
                        ),
                        onPressed: onReject,
                        child: Text(
                          AppLocalizations.of(context).reject,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
        ],
      ),
    ),
    canDismiss: false,
  );
}

Future<double> getTezorAddressBalance(
  String address,
  Map tezorDetails, {
  bool skipNetworkRequest = false,
}) async {
  final pref = Hive.box(secureStorageKey);

  final key = '${tezorDetails['tezorType'].index}AddressBalance$address';
  final storedBalance = pref.get(key);

  double savedBalance = 0;

  if (storedBalance != null) {
    savedBalance = storedBalance;
  }

  if (skipNetworkRequest) return savedBalance;

  try {
    double balance = 0.0;

    final res = await Dartez.getBalance(address, tezorDetails['server']);
    balance = double.parse(res) / pow(10, tezorDecimals);
    // balance = ;

    await pref.put(key, balance);

    return balance;
  } catch (e) {
    print(e);
    return savedBalance;
  }
}

switchEthereumChain({
  context,
  switchChainIdData,
  currentChainIdData,
  onConfirm,
  onReject,
}) async {
  await slideUpPanel(
    context,
    Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context).switchChainRequest,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).backgroundColor,
                backgroundImage: AssetImage(
                  currentChainIdData['image'],
                ),
              ),
              const Icon(
                Icons.arrow_right_alt_outlined,
              ),
              CircleAvatar(
                backgroundColor: Theme.of(context).backgroundColor,
                backgroundImage: AssetImage(
                  switchChainIdData['image'],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            AppLocalizations.of(context).switchChainIdMessage(
              switchChainIdData['symbol'],
              switchChainIdData['chainId'],
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: appBackgroundblue,
                  ),
                  onPressed: onConfirm,
                  child: Text(
                    AppLocalizations.of(context).confirm,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: appBackgroundblue,
                  ),
                  onPressed: onReject,
                  child: Text(
                    AppLocalizations.of(context).reject,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    canDismiss: false,
  );
}

signMessage({
  BuildContext context,
  String data,
  String networkIcon,
  String name,
  Function onConfirm,
  Function onReject,
  String messageType,
}) async {
  String decoded = data;
  if (messageType == personalSignKey && data != null && isHexString(data)) {
    try {
      decoded = ascii.decode(txDataToUintList(data));
    } catch (_) {}
  }

  slideUpPanel(
    context,
    SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(left: 25.0, right: 25, bottom: 25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: null,
                      icon: Icon(
                        Icons.close,
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context).signMessage,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.0,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          onReject();
                        }
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
            ),
            if (networkIcon != null)
              Container(
                height: 50.0,
                width: 50.0,
                padding: const EdgeInsets.only(bottom: 8.0),
                child: CachedNetworkImage(
                  imageUrl: ipfsTohttp(networkIcon),
                  placeholder: (context, url) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Loader(
                          color: appPrimaryColor,
                        ),
                      )
                    ],
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.error,
                    color: Colors.red,
                  ),
                ),
              ),
            if (name != null)
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 16.0,
                ),
              ),
            Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    AppLocalizations.of(context).message,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                  children: [
                    if (messageType == typedMessageSignKey)
                      JsonViewer(
                        json.decode(decoded),
                        fontSize: 16,
                      )
                    else
                      Text(
                        decoded,
                        style: const TextStyle(fontSize: 16.0),
                      ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: appBackgroundblue,
                    ),
                    onPressed: () async {
                      if (await authenticate(context)) {
                        onConfirm();
                      } else {
                        onReject();
                      }
                    },
                    child: Text(
                      AppLocalizations.of(context).sign,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: appBackgroundblue,
                    ),
                    onPressed: onReject,
                    child: Text(
                      AppLocalizations.of(context).reject,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    canDismiss: false,
  );
}

String decodeSolidityAbi(String dataStr) {
  final Uint8List data = txDataToUintList(dataStr);
  final String dataHex = '0x${HEX.encode(data)}'.trim();
  final List knownMethodId = getKnownMethodId()['data'];

  for (int i = 0; i < knownMethodId.length; i++) {
    final contractFunction = knownMethodId[i];
    final functionSig = solidityFunctionSig(contractFunction['methodId']);
    if (dataHex.startsWith(functionSig)) return contractFunction['methodId'];
  }
  return null;
}

signTransaction({
  Function onReject,
  String gasPriceInWei_,
  BuildContext context,
  Function onConfirm,
  String valueInWei_,
  String gasInWei_,
  String txData,
  String from,
  String to,
  String networkIcon,
  String name,
  String blockChainCurrencySymbol,
  String title,
  int chainId,
}) async {
  final rpc = getEthereumDetailsFromChainId(chainId)['rpc'];
  final _wcClient = web3.Web3Client(
    rpc,
    Client(),
  );

  double value = valueInWei_ == null ? 0 : BigInt.parse(valueInWei_).toDouble();

  double gasPrice =
      gasPriceInWei_ == null ? 0 : BigInt.parse(gasPriceInWei_).toDouble();
  txData ??= '0x';

  double userBalance = 0;

  Uint8List trxDataList = txDataToUintList(txData);
  double transactionFee = 0;
  String message = '';

  final Map decodedFunction = await decodeAbi(txData);

  final String decodedName =
      decodedFunction == null ? null : decodedFunction['name'];
  String methodId;
  Map decodedParams = {};

  if (decodedFunction != null) {
    methodId = decodedFunction['name'];
    final List params = decodedFunction['params'];

    for (int i = 0; i < params.length; i++) {
      if (i == 0) {
        methodId += "(";
      }
      methodId += params[i]['type'].toString();

      if (i == params.length - 1) {
        methodId += ")";
      } else {
        methodId += ",";
      }
      decodedParams[params[i]['name'].toString()] =
          params[i]['value'].toString();
    }
  }

  String info = AppLocalizations.of(context).info;

  ValueNotifier<bool> isSigningTransaction = ValueNotifier(false);
  slideUpPanel(
    context,
    DefaultTabController(
      length: 3,
      child: Column(
        children: <Widget>[
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: null,
                    icon: Icon(
                      Icons.close,
                      color: Colors.transparent,
                    ),
                  ),
                ),
                Text(
                  AppLocalizations.of(context).signTransaction,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        onReject();
                      }
                    },
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 50,
            child: TabBar(
              tabs: [
                Tab(
                    icon: Text(
                  "Details",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: orangTxt),
                )),
                Tab(
                    icon: Text(
                  "Data",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: orangTxt),
                )),
                Tab(
                    icon: Text(
                  "Hex",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: orangTxt),
                )),
              ],
            ),
          ),

          // create widgets for each tab bar here
          Expanded(
            child: TabBarView(
              children: [
                // first tab bar view widget
                FutureBuilder(future: () async {
                  userBalance = (await _wcClient
                          .getBalance(EthereumAddress.fromHex(from)))
                      .getInWei
                      .toDouble();

                  transactionFee = await getEtherTransactionFee(
                    rpc,
                    trxDataList,
                    web3.EthereumAddress.fromHex(from),
                    web3.EthereumAddress.fromHex(to),
                    value: value,
                    gasPrice: web3.EtherAmount.inWei(
                      BigInt.from(
                        gasPrice,
                      ),
                    ),
                  );
                  if (decodedFunction == null) return true;

                  final List params = decodedFunction['params'];

                  if (decodedName == 'safeBatchTransferFrom') {
                    List nftAmount = [];
                    for (int i = 0; i < params.length; i++) {
                      if (params[i]['name'] == 'amounts') {
                        nftAmount = params[i]['value'];
                        break;
                      }
                    }
                    int totalAmount = 0;
                    for (var amount in nftAmount) {
                      totalAmount += int.parse(amount);
                    }
                    message =
                        "$totalAmount NFT${totalAmount > 1 ? "s" : ""} would be sent out.";
                  } else if (decodedName == 'safeTransferFrom') {
                    String spender;
                    String from_;
                    String tokenId;
                    for (int i = 0; i < params.length; i++) {
                      if (params[i]['name'] == 'from') {
                        from_ = params[i]['value'].toString();
                      }
                      if (params[i]['name'] == 'to') {
                        spender = params[i]['value'].toString();
                      }
                      if (params[i]['name'] == 'tokenId') {
                        tokenId = params[i]['value'];
                      }
                      if (params[i]['name'] == 'id') {
                        tokenId = params[i]['value'];
                      }
                    }
                    message =
                        "Transfer NFT $tokenId ($to) from $from_ to $spender";
                  } else if (decodedName == 'approve' ||
                      decodedName == 'transfer' ||
                      decodedName == 'transferFrom') {
                    String spender;
                    double token;
                    String from_;
                    Map tokenDetails = await getERC20TokenDetails(
                      contractAddress: to,
                      rpc: getEthereumDetailsFromChainId(chainId)['rpc'],
                    );

                    final decimals = tokenDetails['decimals'];
                    for (int i = 0; i < params.length; i++) {
                      if (params[i]['name'] == 'spender') {
                        spender = params[i]['value'].toString();
                      }
                      if (params[i]['name'] == 'to') {
                        spender = params[i]['value'].toString();
                      }
                      if (params[i]['name'] == 'tokens') {
                        token = BigInt.parse(params[i]['value']) /
                            BigInt.from(pow(10, int.parse(decimals)));
                      }
                      if (params[i]['name'] == 'amount') {
                        token = BigInt.parse(params[i]['value']) /
                            BigInt.from(pow(10, int.parse(decimals)));
                      }
                      if (params[i]['name'] == 'from') {
                        from_ = params[i]['value'];
                      }
                    }
                    if (decodedName == "approve") {
                      message =
                          "Allow $spender to spend $token ${tokenDetails['symbol']} ($to)";
                    } else if (decodedName == 'transfer') {
                      message =
                          "Transfer $token ${tokenDetails['symbol']} ($to) to $spender";
                    } else if (decodedName == 'transferFrom') {
                      message =
                          "Transfer $token ${tokenDetails['symbol']} ($to) from $from_ to $spender";
                    }
                  }
                  return true;
                }(), builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context).couldNotFetchData,
                          style: const TextStyle(fontSize: 16.0),
                        )
                      ],
                    );
                  }
                  if (!snapshot.hasData) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Loader(),
                      ],
                    );
                  }
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 25.0, right: 25, bottom: 25),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (networkIcon != null)
                            Container(
                              height: 50.0,
                              width: 50.0,
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: CachedNetworkImage(
                                imageUrl: ipfsTohttp(networkIcon),
                                placeholder: (context, url) => Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Loader(
                                        color: appPrimaryColor,
                                      ),
                                    )
                                  ],
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                  Icons.error,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          if (name != null)
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 16.0,
                              ),
                            ),
                          if (message != '')
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    info,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    message,
                                    style: const TextStyle(fontSize: 16.0),
                                  )
                                ],
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)
                                      .receipientAddress,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  to,
                                  style: const TextStyle(fontSize: 16.0),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context).balance,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  '${userBalance / pow(10, etherDecimals)} $blockChainCurrencySymbol',
                                  style: const TextStyle(fontSize: 16.0),
                                )
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)
                                      .transactionAmount,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  '${value / pow(10, etherDecimals)} $blockChainCurrencySymbol',
                                  style: const TextStyle(fontSize: 16.0),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)
                                          .transactionFee,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.0,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      '${transactionFee / pow(10, etherDecimals)} $blockChainCurrencySymbol',
                                      style: const TextStyle(fontSize: 16.0),
                                    )
                                  ],
                                ),
                              ),
                              if (transactionFee + value > userBalance)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)
                                            .insufficientBalance,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: red,
                                          fontSize: 16.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          ValueListenableBuilder(
                              valueListenable: isSigningTransaction,
                              builder: (_, isSigningTransaction_, __) {
                                if (isSigningTransaction_) {
                                  return Row(
                                    children: const [
                                      Loader(),
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.black,
                                          backgroundColor: appBackgroundblue,
                                        ),
                                        onPressed: () async {
                                          if (await authenticate(context)) {
                                            isSigningTransaction.value = true;
                                            try {
                                              await onConfirm();
                                            } catch (_) {}
                                            isSigningTransaction.value = false;
                                          } else {
                                            onReject();
                                          }
                                        },
                                        child: Text(
                                          AppLocalizations.of(context).confirm,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16.0),
                                    Expanded(
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.black,
                                          backgroundColor: appBackgroundblue,
                                        ),
                                        onPressed: onReject,
                                        child: Text(
                                          AppLocalizations.of(context).reject,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                        ],
                      ),
                    ),
                  );
                }),

                // second tab bar viiew widget
                if (decodedFunction != null)
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 25.0, right: 25, bottom: 25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 20,
                          ),
                          Text(
                            AppLocalizations.of(context).functionType,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                          const SizedBox(height: 5.0),
                          Text(
                            methodId,
                            style: const TextStyle(
                              fontSize: 16.0,
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          for (var key in decodedParams.keys)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  key,
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5.0),
                                Text(
                                  decodedParams[key],
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                )
                              ],
                            ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(),
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 25.0, right: 25, bottom: 25),
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          tilePadding: EdgeInsets.zero,
                          title: const Text(
                            "Hex",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                          children: [
                            Text(
                              txData,
                              style: const TextStyle(fontSize: 16.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    canDismiss: false,
  );
}

Uint8List txDataToUintList(String txData) {
  if (txData == null) return null;
  return isHexString(txData) ? hexToBytes(txData) : ascii.encode(txData);
}

String ellipsify({String str, int maxLength}) {
  maxLength ??= 10;
  if (maxLength % 2 != 0) {
    maxLength++;
  }
  if (str.length <= maxLength) return str;
  // get first four and last four characters
  final first = str.substring(0, maxLength ~/ 2);
  final last = str.substring((str.length - maxLength / 2).toInt(), str.length);
  return '$first...$last';
}

Future<void> enableScreenShot() async {
  if (Platform.isAndroid) {
    await FlutterWindowManager.clearFlags(
      FlutterWindowManager.FLAG_SECURE,
    );
  }
}

Future<void> disEnableScreenShot() async {
  if (Platform.isAndroid) {
    await FlutterWindowManager.addFlags(
      FlutterWindowManager.FLAG_SECURE,
    );
  }
}

Future<Map> processEIP681(String eip681URL) async {
  Map parsedUrl;

  try {
    parsedUrl = EIP681.parse(eip681URL);

    final chainId = int.parse(parsedUrl['chainId'] ?? '1');

    final cryptoBlock = getEthereumDetailsFromChainId(chainId);

    Map sendToken = {
      "rpc": cryptoBlock['rpc'],
      "coinType": cryptoBlock['coinType'],
      "chainId": chainId,
    };

    bool isContractTransfer =
        (parsedUrl['functionName'] ?? '').toString().toLowerCase() ==
            'transfer';
    final networkName = getEVMBlockchains().keys.firstWhere((element) {
      return (getEVMBlockchains()[element]['chainId'] == chainId);
    });
    if (isContractTransfer) {
      Map erc20Details = await getERC20TokenNameSymbolDecimal(
        contractAddress: parsedUrl['target_address'],
        rpc: sendToken['rpc'],
      );

      if (erc20Details.isEmpty) throw Exception('Unable to get token Details');

      final parseUrlUint256 =
          BigInt.parse(parsedUrl['parameters']['uint256'] ?? '0');

      final parseUrlUint256Decimals =
          pow(10, double.parse(erc20Details['decimals']));

      sendToken.addAll({
        "name": erc20Details['name'],
        "symbol": erc20Details['symbol'],
        "contractAddress": parsedUrl['target_address'],
        "recipient": parsedUrl['parameters']['address'],
        "network": networkName,
        'amount':
            (parseUrlUint256 / BigInt.from(parseUrlUint256Decimals)).toString()
      });
    } else {
      final parsedUrlValue = parsedUrl['parameters']['value'];
      final parsedUrlAmount = parsedUrl['parameters']['amount'];
      String amount = '0';

      if (parsedUrlValue != null) {
        final etherBigInt = BigInt.from(pow(10, etherDecimals));
        amount = (BigInt.parse(parsedUrlValue) / etherBigInt).toString();
      } else if (parsedUrlAmount != null) {
        amount = parsedUrl['parameters']['amount'];
      }

      sendToken.addAll({
        "name": networkName,
        "symbol": cryptoBlock['symbol'],
        "default": cryptoBlock['symbol'],
        "recipient": parsedUrl['target_address'],
        'amount': amount
      });
    }

    return {'success': true, 'msg': sendToken};
  } catch (e) {
    return {'success': false, 'msg': e.toString()};
  }
}

Map getAllBlockchains() {
  return {
    ...getEVMBlockchains(),
    ...getBitCoinPOSBlockchains(),
    ...getFilecoinBlockChains(),
    ...getCardanoBlockChains(),
    ...getCosmosBlockChains(),
    ...getStellarBlockChains(),
    ...getSolanaBlockChains(),
    ...getAlgorandBlockchains(),
    ...getTronBlockchains(),
    ...getTezosBlockchains(),
  };
}

Map getInfoScheme(String coinScheme) {
  String symbol = '';
  for (String key in requestPaymentScheme.keys) {
    if (requestPaymentScheme[key] == coinScheme) {
      symbol = key;
      break;
    }
  }
  Map allBlockchains = getAllBlockchains();
  for (String i in allBlockchains.keys) {
    Map value = allBlockchains[i];
    if (value['symbol'] == symbol) {
      return Map.from(value)..addAll({'name': i});
    }
  }
  return null;
}

Future<Map> getERC20TokenDetails({
  String contractAddress,
  String rpc,
}) async {
  final client = web3.Web3Client(
    rpc,
    Client(),
  );

  final contract = web3.DeployedContract(
    web3.ContractAbi.fromJson(erc20Abi, ''),
    web3.EthereumAddress.fromHex(contractAddress),
  );

  final nameFunction = contract.function('name');
  final symbolFunction = contract.function('symbol');
  final decimalsFunction = contract.function('decimals');

  final name =
      await client.call(contract: contract, function: nameFunction, params: []);

  final symbol = await client
      .call(contract: contract, function: symbolFunction, params: []);
  final decimals = await client
      .call(contract: contract, function: decimalsFunction, params: []);

  return {
    'name': name.first,
    'symbol': symbol.first,
    'decimals': decimals.first.toString()
  };
}

Future<Map> getERC20TokenNameSymbolDecimal({
  String contractAddress,
  String rpc,
  int chainId,
}) async {
  final pref = Hive.box(secureStorageKey);
  String tokenDetailsKey = await contractDetailsKey(
    rpc,
    contractAddress,
  );

  String tokenDetailsSaved = pref.get(tokenDetailsKey);
  Map erc20TokenDetails = {};
  try {
    erc20TokenDetails = await getERC20TokenDetails(
      contractAddress: contractAddress,
      rpc: rpc,
    );
  } catch (e) {
    if (tokenDetailsSaved != null) {
      erc20TokenDetails = json.decode(tokenDetailsSaved);
    }
  }

  await pref.put(tokenDetailsKey, json.encode(erc20TokenDetails));
  return erc20TokenDetails;
}

selectImage({
  BuildContext context,
  Function(XFile) onSelect,
}) {
  AwesomeDialog(
    context: context,
    dialogType: DialogType.INFO,
    buttonsBorderRadius: const BorderRadius.all(Radius.circular(10)),
    headerAnimationLoop: false,
    animType: AnimType.BOTTOMSLIDE,
    closeIcon: const Icon(
      Icons.close,
    ),
    title: AppLocalizations.of(context).chooseImageSource,
    desc: AppLocalizations.of(context).imageSource,
    showCloseIcon: true,
    btnOkText: AppLocalizations.of(context).gallery,
    btnCancelText: AppLocalizations.of(context).camera,
    btnCancelOnPress: () async {
      XFile file = await ImagePicker().pickImage(source: ImageSource.camera);
      if (file == null) return;
      onSelect(file);
    },
    btnCancelColor: Colors.blue,
    btnOkColor: Colors.blue,
    btnOkOnPress: () async {
      XFile file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
      onSelect(file);
    },
  ).show();
}

web3.Transaction wcEthTxToWeb3Tx(WCEthereumTransaction ethereumTransaction) {
  return web3.Transaction(
    from: EthereumAddress.fromHex(ethereumTransaction.from),
    to: EthereumAddress.fromHex(ethereumTransaction.to),
    maxGas: ethereumTransaction.gasLimit != null
        ? int.tryParse(ethereumTransaction.gasLimit)
        : null,
    gasPrice: ethereumTransaction.gasPrice != null
        ? EtherAmount.inWei(BigInt.parse(ethereumTransaction.gasPrice))
        : null,
    value: EtherAmount.inWei(BigInt.parse(ethereumTransaction.value ?? '0')),
    data: hexToBytes(ethereumTransaction.data),
    nonce: ethereumTransaction.nonce != null
        ? int.tryParse(ethereumTransaction.nonce)
        : null,
  );
}

bool isLocalizedContent(Uri url) {
  return (url.scheme == "file" ||
      url.scheme == "chrome" ||
      url.scheme == "data" ||
      url.scheme == "javascript" ||
      url.scheme == "about");
}

urlIsSecure(Uri url) {
  return (url.scheme == "https") || isLocalizedContent(url);
}

Future<String> downloadFile(String url, [String filename]) async {
  var hasStoragePermission = await Permission.storage.isGranted;
  if (!hasStoragePermission) {
    final status = await Permission.storage.request();
    hasStoragePermission = status.isGranted;
  }
  if (hasStoragePermission) {
    final taskId = await FlutterDownloader.enqueue(
      url: url,
      headers: {},
      savedDir: (await getTemporaryDirectory()).path,
      saveInPublicStorage: true,
      fileName: filename,
    );
    return taskId;
  }
  return null;
}
