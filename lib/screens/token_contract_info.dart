import 'package:cryptowallet/interface/coin.dart';
import 'package:cryptowallet/utils/blockie_widget.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:url_launcher/url_launcher.dart';

import '../coins/ethereum_coin.dart';
import '../utils/app_config.dart';

class TokenContractInfo extends StatefulWidget {
  final Coin tokenData;
  const TokenContractInfo({Key key, this.tokenData}) : super(key: key);

  @override
  State<TokenContractInfo> createState() => _TokenContractInfoState();
}

class _TokenContractInfoState extends State<TokenContractInfo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).tokenDetails,
        ),
      ),
      body: SizedBox(
        height: double.infinity,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).token,
                          style: const TextStyle(
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 40,
                              height: 25,
                              child: BlockieWidget(
                                size: .6,
                                data: widget.tokenData.contractAddress(),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Text(
                              widget.tokenData.symbol_(),
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppLocalizations.of(context).contractAddress,
                          style: const TextStyle(
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            Text(
                              ellipsify(
                                str: widget.tokenData.contractAddress(),
                                maxLength: 24,
                              ),
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            GestureDetector(
                              onTap: () async {
                                await Clipboard.setData(ClipboardData(
                                  text: widget.tokenData.contractAddress(),
                                ));

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppLocalizations.of(context)
                                        .copiedToClipboard),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.copy,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppLocalizations.of(context).symbol,
                          style: const TextStyle(
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          widget.tokenData.symbol_(),
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppLocalizations.of(context).decimals,
                          style: const TextStyle(
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          '${widget.tokenData.decimals()}',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppLocalizations.of(context).network,
                          style: const TextStyle(
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          (widget.tokenData as EthereumCoin).name,
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          color: Colors.transparent,
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.resolveWith(
                                      (states) => appBackgroundblue),
                              shape: MaterialStateProperty.resolveWith(
                                (states) => RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              textStyle: MaterialStateProperty.resolveWith(
                                (states) =>
                                    const TextStyle(color: Colors.white),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context).viewOnBlockExplorer,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            onPressed: () async {
                              String blockExplorer =
                                  widget.tokenData.blockExplorer_();
                              blockExplorer = blockExplorer.replaceFirst(
                                  '/tx/$transactionhashTemplateKey',
                                  '/token/${widget.tokenData.contractAddress()}');
                              await launchUrl(Uri.parse(blockExplorer));
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
