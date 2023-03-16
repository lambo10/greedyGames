import 'dart:convert';

import 'package:cryptowallet/screens/wallet.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

import '../utils/app_config.dart';
import '../utils/qr_scan_view.dart';

class AddCustomToken extends StatefulWidget {
  const AddCustomToken({Key key}) : super(key: key);

  @override
  _AddCustomTokenState createState() => _AddCustomTokenState();
}

class _AddCustomTokenState extends State<AddCustomToken> {
  List networks = getEVMBlockchains().keys.toList();
  String network;
  String networkImage;
  @override
  void initState() {
    super.initState();
    network = networks[0];
    networkImage = getEVMBlockchains().values.toList()[0]['image'];
    contractAddressController.addListener(() async {
      await autoFillNameDecimalSymbol(
        contractAddressController.text,
      );
    });
  }

  final contractAddressController = TextEditingController();
  final nameAddressController = TextEditingController();
  final symbolAddressController = TextEditingController();
  final decimalsAddressController = TextEditingController();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  emptyInput() {
    nameAddressController.text = '';
    symbolAddressController.text = '';
    decimalsAddressController.text = '';
  }

  autoFillNameDecimalSymbol(String enteredContractAddress) async {
    emptyInput();
    try {
      Map erc20Details = await getERC20TokenNameSymbolDecimal(
        contractAddress: enteredContractAddress.trim(),
        rpc: getEVMBlockchains()[network]['rpc'],
      );
      if (erc20Details.isEmpty) return;
      nameAddressController.text = erc20Details['name'];
      symbolAddressController.text = erc20Details['symbol'];
      decimalsAddressController.text = erc20Details['decimals'];
    } catch (_) {}
  }

  @override
  void dispose() {
    contractAddressController.dispose();
    nameAddressController.dispose();
    symbolAddressController.dispose();
    decimalsAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).addToken,
          style: const TextStyle(fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context).network,
                      style: const TextStyle(
                        fontSize: 20,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        showBlockChainDialog(
                          context: context,
                          onTap: (blockChainData) async {
                            Navigator.pop(context);
                            if (mounted) {
                              setState(() {
                                network = blockChainData['name'];
                                networkImage = blockChainData['image'];
                              });
                              emptyInput();
                            }
                          },
                          selectedChainId: getEVMBlockchains()[network]
                              ['chainId'],
                        );
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundImage: AssetImage(
                          networkImage ?? '',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 40,
                ),
                TextFormField(
                  controller: contractAddressController,
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
                            String contractAddr = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => const QRScanView(),
                              ),
                            );
                            if (contractAddr == null) return;
                            contractAddressController.text = contractAddr;
                          },
                        ),
                        InkWell(
                          onTap: () async {
                            ClipboardData cdata =
                                await Clipboard.getData(Clipboard.kTextPlain);
                            if (cdata == null) return;
                            if (cdata.text == null) return;
                            contractAddressController.text = cdata.text;
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

                    hintText: AppLocalizations.of(context).enterContractAddress,
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      borderSide: BorderSide.none,
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      borderSide: BorderSide.none,
                    ), // you
                    filled: true,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  readOnly: true,
                  controller: nameAddressController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).name,
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
                TextFormField(
                  readOnly: true,
                  controller: symbolAddressController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).symbol,
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
                TextFormField(
                  readOnly: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  controller: decimalsAddressController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).decimals,
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
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    color: Colors.red[100],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context).anyoneCanCreateToken,
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          AppLocalizations.of(context).includingScamTokens,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 40,
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
                      FocusManager.instance.primaryFocus?.unfocus();
                      final pref = Hive.box(secureStorageKey);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      final contractAddr =
                          contractAddressController.text.trim();
                      final contractName = nameAddressController.text.trim();
                      final contractSymbol =
                          symbolAddressController.text.trim();
                      final contractDecimals =
                          decimalsAddressController.text.trim();

                      if (contractName.isEmpty ||
                          contractSymbol.isEmpty ||
                          contractDecimals.isEmpty) {
                        await autoFillNameDecimalSymbol(contractAddr);
                      }

                      if (contractAddr.toLowerCase() ==
                          tokenContractAddress.toLowerCase()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(
                              AppLocalizations.of(context).tokenImportedAlready,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                        return;
                      }

                      if (double.tryParse(contractDecimals) == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(
                              AppLocalizations.of(context)
                                  .invalidContractAddressOrNetworkTimeout,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                        return;
                      }

                      if (contractAddr.isEmpty ||
                          contractName.isEmpty ||
                          contractSymbol.isEmpty ||
                          contractDecimals.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(
                              AppLocalizations.of(context).enterContractAddress,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                        return;
                      }

                      final userTokenListKey = await getAddTokenKey();

                      final Map customTokenDetails = {
                        'contractAddress': contractAddr,
                        'name': contractName,
                        'symbol': contractSymbol,
                        'decimals': contractDecimals,
                        'network': network,
                        'chainId': getEVMBlockchains()[network]['chainId'],
                        'rpc': getEVMBlockchains()[network]['rpc'],
                        'blockExplorer': getEVMBlockchains()[network]
                            ['blockExplorer'],
                        'coinType': getEVMBlockchains()[network]['coinType'],
                      };

                      List userTokenList = [];
                      final savedJsonImports = pref.get(userTokenListKey);

                      if (savedJsonImports != null) {
                        userTokenList = jsonDecode(savedJsonImports) as List;
                        for (int i = 0; i < userTokenList.length; i++) {
                          String contractAddress =
                              userTokenList[i]['contractAddress'];
                          String contractNetwork = userTokenList[i]['network'];

                          bool sameContractAddress =
                              contractAddress.toLowerCase() ==
                                  contractAddr.toLowerCase();
                          bool sameNetwork = contractNetwork == network;

                          if (sameNetwork && sameContractAddress) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Colors.red,
                                content: Text(
                                  'Token Imported Already',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                            return;
                          }
                        }
                      }

                      userTokenList.add(customTokenDetails);

                      await pref.put(
                        userTokenListKey,
                        jsonEncode(userTokenList),
                      );

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => const Wallet(),
                        ),
                        (r) => false,
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
