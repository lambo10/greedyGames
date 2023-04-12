import 'dart:convert';

import 'package:cryptowallet/coins/ethereum_coin.dart';
import 'package:cryptowallet/screens/wallet.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

import '../coins/eth_contract_coin.dart';
import '../utils/app_config.dart';
import '../utils/qr_scan_view.dart';

class AddCustomToken extends StatefulWidget {
  const AddCustomToken({Key key}) : super(key: key);

  @override
  _AddCustomTokenState createState() => _AddCustomTokenState();
}

class _AddCustomTokenState extends State<AddCustomToken> {
  List networks = getEVMBlockchains();
  String networkName;
  String networkImage;
  @override
  void initState() {
    super.initState();
    networkName = networks[0]['name'];
    networkImage = networks[0]['image'];
    contractAddrContrl.addListener(() async {
      await autoFillNameDecimalSymbol(
        contractAddrContrl.text,
      );
    });
  }

  final contractAddrContrl = TextEditingController();
  final nameContrl = TextEditingController();
  final symbolCtrl = TextEditingController();
  final decimalCtrl = TextEditingController();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  emptyInput() {
    nameContrl.text = '';
    symbolCtrl.text = '';
    decimalCtrl.text = '';
  }

  autoFillNameDecimalSymbol(String enteredContractAddress) async {
    emptyInput();
    if (enteredContractAddress.isEmpty) return;
    try {
      Map evnNetwork =
          getEVMBlockchains().firstWhere((e) => e['name'] == networkName);
      Map erc20Details = await savedERC20Details(
        contractAddress: enteredContractAddress.trim(),
        rpc: evnNetwork['rpc'],
      );
      if (erc20Details.isEmpty) return;
      nameContrl.text = erc20Details['name'];
      symbolCtrl.text = erc20Details['symbol'];
      decimalCtrl.text = erc20Details['decimals'];
    } catch (_) {}
  }

  @override
  void dispose() {
    contractAddrContrl.dispose();
    nameContrl.dispose();
    symbolCtrl.dispose();
    decimalCtrl.dispose();
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
                        Map evnNetwork = getEVMBlockchains().firstWhere(
                          (e) => e['name'] == networkName,
                        );
                        showBlockChainDialog(
                          context: context,
                          onTap: (blockChainData) async {
                            Navigator.pop(context);
                            if (mounted) {
                              setState(() {
                                networkName = blockChainData['name'];
                                networkImage = blockChainData['image'];
                              });
                              await autoFillNameDecimalSymbol(
                                contractAddrContrl.text,
                              );
                            }
                          },
                          selectedChainId: evnNetwork['chainId'],
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
                  controller: contractAddrContrl,
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
                            contractAddrContrl.text = contractAddr;
                          },
                        ),
                        InkWell(
                          onTap: () async {
                            ClipboardData cdata =
                                await Clipboard.getData(Clipboard.kTextPlain);
                            if (cdata == null) return;
                            if (cdata.text == null) return;
                            contractAddrContrl.text = cdata.text;
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
                  controller: nameContrl,
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
                  controller: symbolCtrl,
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
                  controller: decimalCtrl,
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
                      final contractAddr = contractAddrContrl.text.trim();
                      final contractName = nameContrl.text.trim();
                      final contractSymbol = symbolCtrl.text.trim();
                      final contractDecimals = decimalCtrl.text.trim();

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

                      final userTokenListKey = getAddTokenKey();
                      Map evnNetwork = getEVMBlockchains().firstWhere(
                        (e) => e['name'] == networkName,
                      );

                      final Map customTokenDetails = {
                        'contractAddress': contractAddr,
                        'name': contractName,
                        'symbol': contractSymbol,
                        'decimals': contractDecimals,
                        'network': networkName,
                        'chainId': evnNetwork['chainId'],
                        'rpc': evnNetwork['rpc'],
                        'blockExplorer': evnNetwork['blockExplorer'],
                        'coinType': evnNetwork['coinType'],
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
                          bool sameNetwork = contractNetwork == networkName;

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
