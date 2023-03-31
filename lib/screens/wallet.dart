import 'package:cryptowallet/screens/dapp_ui.dart';
import 'package:cryptowallet/screens/exchange_token.dart';
import 'package:cryptowallet/screens/view_all_nfts.dart';
import 'package:cryptowallet/screens/wallet_main_body.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';

import '../config/colors.dart';

class Wallet extends StatefulWidget {
  const Wallet({Key key}) : super(key: key);

  @override
  _WalletState createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  PageController pageController;
  int currentIndex_ = 0;

  int currentIndex = 0;
  static const int walletMainBody = 0;
  static const int dappUI = 1;
  static const int exchangeToken = 2;
  static const int viewAllNFTs = 3;

  Widget currentPage = const WalletMainBody();

  void onTabTapped(int index) {
    setState(() {
      currentIndex = index;
      switch (currentIndex) {
        case walletMainBody:
          currentPage = const WalletMainBody();
          break;
        case dappUI:
          currentPage = const DappUI();
          break;
        case exchangeToken:
          currentPage = const ExchangeToken();
          break;
        case viewAllNFTs:
          currentPage = const ViewAllNFTs();
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    enableScreenShot();
    FocusManager.instance.primaryFocus?.unfocus();
    pageController = PageController(initialPage: 0);
  }

  _onTapped(int index) {
    setState(() {
      currentIndex_ = index;
    });
    // remove keyboard focus
    FocusManager.instance.primaryFocus?.unfocus();
    pageController.animateToPage(index,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  void onPageChanged(int index) {
    setState(() {
      currentIndex_ = index;
      // remove focus
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  final pages = [
    // const Home(),
    const WalletMainBody(),
    const DappUI(),
    const ExchangeToken(),
    const ViewAllNFTs()
  ];

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(child: currentPage),
      bottomNavigationBar: Container(
        //margin: const EdgeInsets.all(20),
        height: 65,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            // BoxShadow(
            //   color: const Color.fromARGB(255, 154, 54, 235).withOpacity(.15),
            //   blurRadius: 50,
            //   offset: const Offset(0, 10),
            // ),
            BoxShadow(
              blurRadius: 24,
              spreadRadius: 16,
              color: Colors.black.withOpacity(0.2),
            )
          ],
          //borderRadius: BorderRadius.circular(50),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(20.0),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 40.0,
              sigmaY: 40.0,
            ),
            child: Container(
              height: 60,
              width: 500,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(20.0),
                  ),
                  border: Border.all(
                    width: 1.5,
                    color: Colors.white.withOpacity(0.2),
                  )),
              child: Center(
                child: ListView.builder(
                  itemCount: iconTypes.length,
                  scrollDirection: Axis.horizontal,
                  addAutomaticKeepAlives: true,
                  physics:
                      const NeverScrollableScrollPhysics(), // <-- this will disable scroll
                  shrinkWrap: true,
                  // padding: EdgeInsets.symmetric(horizontal: size.width * .01),
                  itemBuilder: (context, index) => InkWell(
                    onTap: () {
                      setState(
                        () {
                          currentIndex = index;
                          onTabTapped(index);
                        },
                      );
                    },
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            height: 5,
                            width: 45,
                            decoration: BoxDecoration(
                                color: index == currentIndex
                                    ? greedyblendpurple
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 1500),
                          curve: Curves.fastLinearToSlowEaseIn,
                          margin: EdgeInsets.only(
                            bottom:
                                index == currentIndex ? 0 : size.width * .001,
                            right: size.width * .0422,
                            left: size.width * .1,
                          ),
                          width: size.width * .0999,
                          height: index == currentIndex ? size.width * .012 : 0,
                        ),
                        Icon(
                          iconTypes[index],
                          size: 18.5,
                          color: index == currentIndex
                              ? Colors.white
                              : Colors.white70.withOpacity(0.5),
                        ),
                        Text(
                          iconName[index],
                          style: TextStyle(
                              color: index == currentIndex
                                  ? Colors.white
                                  : Colors.white70,
                              fontSize: 17),
                        ),
                        SizedBox(height: size.width * .03),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

      // bottomNavigationBar: GlassBox(
      //   child: BottomNavigationBar(
      //     currentIndex: currentIndex_,
      //     onTap: _onTapped,
      //     selectedItemColor: Colors.white,
      //     unselectedItemColor: Colors.grey[300],
      //     backgroundColor: Colors.transparent,
      //     showSelectedLabels: true,
      //     showUnselectedLabels: true,
      //     elevation: 5,
      //     type: BottomNavigationBarType.fixed,
      //     items: <BottomNavigationBarItem>[
      //       // BottomNavigationBarItem(
      //       //   icon: Icon(
      //       //     FontAwesomeIcons.gamepad,
      //       //     size: 25,
      //       //     color: currentIndex_ == 0
      //       //         ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
      //       //         : Theme.of(context)
      //       //             .bottomNavigationBarTheme
      //       //             .unselectedItemColor,
      //       //   ),
      //       //   label: AppLocalizations.of(context).games,
      //       // ),
      //       BottomNavigationBarItem(
      //         icon: Icon(
      //           FontAwesomeIcons.wallet,
      //           size: 25,
      //           color: currentIndex_ == 0
      //               ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
      //               : Theme.of(context)
      //                   .bottomNavigationBarTheme
      //                   .unselectedItemColor,
      //         ),
      //         label: AppLocalizations.of(context).wallet,
      //       ),
      //       BottomNavigationBarItem(
      //         icon: Icon(
      //           FontAwesomeIcons.cubes,
      //           size: 25,
      //           color: currentIndex_ == 1
      //               ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
      //               : Theme.of(context)
      //                   .bottomNavigationBarTheme
      //                   .unselectedItemColor,
      //         ),
      //         label: "Dapp",
      //       ),
      //       BottomNavigationBarItem(
      //         icon: Icon(
      //           FontAwesomeIcons.exchangeAlt,
      //           size: 25,
      //           color: currentIndex_ == 2
      //               ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
      //               : Theme.of(context)
      //                   .bottomNavigationBarTheme
      //                   .unselectedItemColor,
      //         ),
      //         label: AppLocalizations.of(context).swap,
      //       ),
      //       BottomNavigationBarItem(
      //         icon: Icon(
      //           FontAwesomeIcons.solidImage,
      //           size: 25,
      //           color: currentIndex_ == 3
      //               ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
      //               : Theme.of(context)
      //                   .bottomNavigationBarTheme
      //                   .unselectedItemColor,
      //         ),
      //         label: "NFTs",
      //       )
      //     ],
      //   ),
      // ),
      // body: PageView(
      //   physics: const NeverScrollableScrollPhysics(),
      //   controller: pageController,
      //   onPageChanged: onPageChanged,
      //   children: pages,
      // ),
    );
  }

  static const iconTypes = <IconData>[
    FontAwesomeIcons.wallet,
    FontAwesomeIcons.cubes,
    FontAwesomeIcons.exchangeAlt,
    FontAwesomeIcons.solidImage,
  ];
  static const iconName = <String>[
    "Wallet",
    "Dapp",
    "Exchange",
    "NFts",
  ];
}
//cigar rocket flight stage reveal piano man cream slim pond stage lazy







