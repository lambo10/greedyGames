import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cryptowallet/components/loader.dart';
import 'package:cryptowallet/screens/nft_image_webview.dart';
import 'package:cryptowallet/screens/send_token.dart';
import 'package:cryptowallet/screens/video_player.dart';
import 'package:cryptowallet/utils/app_config.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive/hive.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:mime/mime.dart';

class ViewAllNFTs extends StatefulWidget {
  const ViewAllNFTs({Key key}) : super(key: key);

  @override
  State<ViewAllNFTs> createState() => _ViewAllNFTsState();
}

class _ViewAllNFTsState extends State<ViewAllNFTs>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool isLoaded = false;
  ScrollController controller = ScrollController();
  ValueNotifier nftLoaded = ValueNotifier(false);
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: SizedBox(
        height: double.infinity,
        child: SafeArea(
          child: SingleChildScrollView(
            controller: controller,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    const Text(
                      'NFTs',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    ValueListenableBuilder(
                      valueListenable: nftLoaded,
                      builder: (context, value, _) {
                        return value == true
                            ? Container()
                            : Text(
                                AppLocalizations.of(context)
                                    .yourAssetWillAppear,
                                style: const TextStyle(fontSize: 18),
                              );
                      },
                    ),
                    for (String nft in getAlchemyNFTs())
                      BlockChainNFTs(
                        nftLoaded: nftLoaded,
                        chainId: getEVMBlockchains()[nft]['chainId'],
                        coinType: getEVMBlockchains()[nft]['coinType'],
                        networkName: nft,
                        controller: controller,
                      )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BlockChainNFTs extends StatefulWidget {
  final int coinType;
  final int chainId;

  final String networkName;
  final ValueNotifier nftLoaded;
  final ScrollController controller;
  const BlockChainNFTs({
    Key key,
    this.controller,
    this.coinType,
    this.networkName,
    this.chainId,
    this.nftLoaded,
  }) : super(key: key);

  @override
  State<BlockChainNFTs> createState() => _BlockChainNFTsState();
}

class _BlockChainNFTsState extends State<BlockChainNFTs> {
  Timer timer;

  String networkName;
  List nftData;

  bool skipNetworkRequest = true;
  ScrollController controller;
  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    networkName = widget.networkName;
    getAllNFTs();
    timer = Timer.periodic(
      httpPollingDelay,
      (Timer t) async => await getAllNFTs(),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future getAllNFTs() async {
    try {
      final mnemonic = Hive.box(secureStorageKey).get(currentMmenomicKey);
      final response = await getEthereumFromMemnomic(
        mnemonic,
        widget.coinType,
      );
      final data = await viewUserTokens(
        widget.chainId,
        response['eth_wallet_address'],
        skipNetworkRequest: skipNetworkRequest,
      );

      if (skipNetworkRequest) skipNetworkRequest = false;

      if (data['success'] != null && data['success']) {
        List nfts = data['msg']['ownedNfts'];
        if (widget.nftLoaded.value == false && nfts.isNotEmpty) {
          widget.nftLoaded.value = true;
        }
        if (nfts.isNotEmpty) {
          nftData = nfts;
          if (mounted) setState(() {});
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return nftData == null
        ? Container()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(
                networkName,
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                height: 350,
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: nftData.length,
                    itemBuilder: (BuildContext context, int index) {
                      Map nftDetails = nftData[index];
                      Map nftEvmDetails = getEVMBlockchains()[networkName];
                      String name =
                          nftDetails['contractMetadata']['name'] ?? 'NFT';
                      String symbol =
                          nftDetails["contractMetadata"]['symbol'] ?? 'NFT';
                      BigInt tokenId = BigInt.parse(
                        nftDetails['id']['tokenId'],
                      );
                      String contractAddress =
                          nftDetails['contract']['address'];
                      String rpc = nftEvmDetails['rpc'];
                      int chainId = nftEvmDetails['chainId'];
                      int coinType = nftEvmDetails['coinType'];
                      String tokenType =
                          nftDetails['contractMetadata']['tokenType'] ?? '';
                      String description = nftDetails['description'] ?? '';
                      String image;

                      String balance = nftDetails['balance'];
                      try {
                        image = ipfsTohttp(nftDetails["metadata"]['image']);
                      } catch (_) {}

                      return SizedBox(
                        width: 250,
                        height: 300,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              10,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: NotificationListener<OverscrollNotification>(
                              onNotification: (OverscrollNotification value) {
                                if (value.overscroll < 0 &&
                                    controller.offset + value.overscroll <= 0) {
                                  if (controller.offset != 0) {
                                    controller.jumpTo(0);
                                  }
                                  return true;
                                }
                                if (controller.offset + value.overscroll >=
                                    controller.position.maxScrollExtent) {
                                  if (controller.offset !=
                                      controller.position.maxScrollExtent) {
                                    controller.jumpTo(
                                        controller.position.maxScrollExtent);
                                  }
                                  return true;
                                }
                                controller.jumpTo(
                                    controller.offset + value.overscroll);
                                return true;
                              },
                              child: ListView(
                                children: [
                                  if (image != null && image.isNotEmpty)
                                    SizedBox(
                                      height: 150,
                                      child: NFTImageWebview(
                                        imageUrl: image,
                                      ),
                                    )
                                  else
                                    SizedBox(
                                      width: double.infinity,
                                      height: 150,
                                      child: Center(
                                        child: Text(
                                          AppLocalizations.of(context)
                                              .couldNotFetchData,
                                          style: const TextStyle(
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),

                                  //   CachedNetworkImage(
                                  //     imageUrl: (image),
                                  //     width: double.infinity,
                                  //     height: 150,
                                  //     placeholder: (context, url) => Column(
                                  //       mainAxisAlignment:
                                  //           MainAxisAlignment.center,
                                  //       mainAxisSize: MainAxisSize.min,
                                  //       children: const [
                                  //         SizedBox(
                                  //           width: 20,
                                  //           height: 20,
                                  //           child: Loader(
                                  //             color: appPrimaryColor,
                                  //           ),
                                  //         )
                                  //       ],
                                  //     ),
                                  //     errorWidget: (context, url, error) {
                                  //       return VideoPlayer(
                                  //         url: url,
                                  //       );
                                  //     },
                                  //     fit: BoxFit.cover,
                                  //   )

                                  const SizedBox(height: 10),
                                  Text(
                                    name,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${ellipsify(
                                      str: balance,
                                    )} ${ellipsify(
                                      str: symbol,
                                    )}',
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  ListTileTheme(
                                    dense: true,
                                    horizontalTitleGap: 0.0,
                                    minLeadingWidth: 0,
                                    contentPadding: const EdgeInsets.all(0),
                                    child: ExpansionTile(
                                      tilePadding:
                                          const EdgeInsets.only(left: 0),
                                      expandedCrossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      expandedAlignment: Alignment.centerLeft,
                                      title: Text(
                                        AppLocalizations.of(context).info,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.0,
                                        ),
                                      ),
                                      children: [
                                        Text(
                                          AppLocalizations.of(context).tokenId,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16.0,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            '#$tokenId',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        if (description != '') ...[
                                          Text(
                                            AppLocalizations.of(context)
                                                .description,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16.0,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 5,
                                          ),
                                          Text(
                                            description,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              overflow: TextOverflow.fade,
                                              color: Colors.grey,
                                            ),
                                          )
                                        ],
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Text(
                                          AppLocalizations.of(context)
                                              .contractAddress,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16.0,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                          '$contractAddress ($tokenType)',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            overflow: TextOverflow.fade,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Text(
                                          AppLocalizations.of(context).network,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16.0,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                          networkName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            overflow: TextOverflow.fade,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Container(
                                    color: Colors.transparent,
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      style: ButtonStyle(
                                        textStyle:
                                            MaterialStateProperty.resolveWith(
                                          (states) => const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor:
                                            MaterialStateProperty.resolveWith(
                                          (states) => appBackgroundblue,
                                        ),
                                        shape:
                                            MaterialStateProperty.resolveWith(
                                          (states) => RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                      onPressed: () async {
                                        try {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (ctx) => SendToken(
                                                data: {
                                                  'name': name,
                                                  'symbol': symbol,
                                                  'isNFT': true,
                                                  'tokenId': tokenId,
                                                  'contractAddress':
                                                      contractAddress,
                                                  'network': networkName,
                                                  'rpc': rpc,
                                                  'chainId': chainId,
                                                  'coinType': coinType,
                                                  'tokenType': tokenType,
                                                },
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              backgroundColor: Colors.red,
                                              content: Text(
                                                e.toString(),
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Text(
                                        AppLocalizations.of(context).send,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
              ),
              const SizedBox(
                height: 20,
              ),
            ],
          );
  }
}
