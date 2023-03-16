import 'package:cryptowallet/utils/app_config.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class DappUI extends StatefulWidget {
  const DappUI({Key key}) : super(key: key);

  @override
  State<DappUI> createState() => _DappUIState();
}

class _DappUIState extends State<DappUI> with AutomaticKeepAliveClientMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final searchController = TextEditingController();
  @override
  bool get wantKeepAlive => true;
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DApps',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                    IconButton(
                      onPressed: () async {
                        await navigateToDappBrowser(context, null);
                      },
                      icon: const Icon(
                        Icons.search,
                        size: 30,
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Image.asset('assets/header_dapp.png'),
                const SizedBox(
                  height: 20,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppLocalizations.of(context).favourites,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 16, letterSpacing: 3),
                  ),
                ),
                // search field with search icon
                const Divider(),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          navigateToDappBrowser(
                            context,
                            walletDexProviderUrl,
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(children: [
                              SvgPicture.asset('assets/swap_dapp.svg'),
                              const SizedBox(
                                width: 10,
                              ),
                              const Text('Dex')
                            ]),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          await navigateToDappBrowser(
                              context, stakeDexProviderUrl);
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(children: [
                              SvgPicture.asset('assets/stake_dapp.svg'),
                              const SizedBox(
                                width: 10,
                              ),
                              Text(AppLocalizations.of(context).stake)
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          await navigateToDappBrowser(
                              context, fiatDexProviderUrl);
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(children: [
                              SvgPicture.asset('assets/fiat_dapp.svg'),
                              const SizedBox(
                                width: 10,
                              ),
                              Text(AppLocalizations.of(context).fiat)
                            ]),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          await navigateToDappBrowser(
                              context, browserDexProviderUrl);
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(children: [
                              SvgPicture.asset('assets/browser_dapp.svg'),
                              const SizedBox(
                                width: 10,
                              ),
                              Text(AppLocalizations.of(context).browser)
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppLocalizations.of(context).all,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                // search field with search icon
                const Divider(),
                const SizedBox(
                  height: 20,
                ),
                // card widget
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await navigateToDappBrowser(
                          context,
                          marketPlaceUrl,
                        );
                      },
                      child: Container(
                        decoration:
                            const BoxDecoration(color: Colors.transparent),
                        clipBehavior: Clip.hardEdge,
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SvgPicture.asset('assets/social_dapp.svg'),
                              const SizedBox(
                                width: 20,
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)
                                            .nftMarketPlace,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      SvgPicture.asset('assets/new_dapp.svg'),
                                    ],
                                  ),
                                  Text(
                                    AppLocalizations.of(context)
                                        .nftMarketPlaceDescription,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                    overflow: TextOverflow.fade,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Divider(),
                    GestureDetector(
                      onTap: () async {
                        await navigateToDappBrowser(
                          context,
                          vrUrl,
                        );
                      },
                      child: Container(
                        decoration:
                            const BoxDecoration(color: Colors.transparent),
                        clipBehavior: Clip.hardEdge,
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SvgPicture.asset('assets/vr-dapp.svg'),
                              const SizedBox(
                                width: 20,
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)
                                            .virtualReality,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      SvgPicture.asset('assets/new_dapp.svg'),
                                    ],
                                  ),
                                  Text(
                                    AppLocalizations.of(context)
                                        .virtualRealityDescription,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Divider(),
                    GestureDetector(
                      onTap: () async {
                        await navigateToDappBrowser(
                          context,
                          ecommerceUrl,
                        );
                      },
                      child: Container(
                        decoration:
                            const BoxDecoration(color: Colors.transparent),
                        clipBehavior: Clip.hardEdge,
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SvgPicture.asset('assets/e-commerce-dapp.svg'),
                              const SizedBox(
                                width: 20,
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        AppLocalizations.of(context).eCommerce,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      SvgPicture.asset('assets/new_dapp.svg'),
                                    ],
                                  ),
                                  Text(
                                    AppLocalizations.of(context)
                                        .eCommerceDescription,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Divider(),
                    GestureDetector(
                      onTap: () async {
                        await navigateToDappBrowser(
                          context,
                          blogUrl,
                        );
                      },
                      child: Container(
                        decoration:
                            const BoxDecoration(color: Colors.transparent),
                        clipBehavior: Clip.hardEdge,
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SvgPicture.asset('assets/news.svg'),
                              const SizedBox(
                                width: 20,
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context).blog,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    AppLocalizations.of(context)
                                        .blogDescription,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Divider(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
