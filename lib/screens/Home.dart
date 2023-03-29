import 'dart:async';
import 'dart:convert';
import 'package:cryptowallet/screens/trandingGames.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import '../utils/rpc_urls.dart';

class Home extends StatefulWidget {
  const Home({Key key}) : super(key: key);
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Timer timer;
  bool gamesLoaded = false;
  List gameList = [];
  bool trendingGameLoaded = false;
  List trandingGamesList = [];

  Future getGames() async {
    final request = await get(
      Uri.parse('https://greedyverse.co/api/getgames.php'),
    );

    if (request.statusCode ~/ 100 == 4 || request.statusCode ~/ 100 == 5) {
      throw Exception('Request failed');
    }

    final res = jsonDecode(request.body);

    if (!res['success']) return;

    gameList = jsonDecode(res['message']);
    gamesLoaded = true;
    if (mounted) {
      setState(() {});
    }
  }

  Future getTrendingGames() async {
    final request = await get(
      Uri.parse('https://greedyverse.co/api/getTrendingGames.php'),
    );

    if (request.statusCode ~/ 100 == 4 || request.statusCode ~/ 100 == 5) {
      throw Exception('Request failed');
    }

    final res = jsonDecode(request.body);

    if (!res['success']) return;

    trandingGamesList = jsonDecode(res['message']);
    trendingGameLoaded = true;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    getGames();
    timer = Timer.periodic(
      httpPollingDelay,
      (Timer t) async {
        try {
          if (!gamesLoaded) {
            await getGames();
          }
        } catch (_) {}
        try {
          if (!trendingGameLoaded) {
            await getTrendingGames();
          }
        } catch (_) {}
      },
    );
  }

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        key: _scaffoldKey,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).games,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 25),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      SizedBox(
                          height: 210.0,
                          child: trandingGames(
                              responseItems: trandingGamesList,
                              cardHeight: 500.0,
                              cardWidth: 250.0)),
                      const SizedBox(
                        height: 40,
                      ),
                      // for (int i = 0; i < gameList.length; i++) ...[
                      //   Row(
                      //     crossAxisAlignment: CrossAxisAlignment.center,
                      //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //     children: [
                      //       Row(
                      //         children: [
                      //           Container(
                      //             decoration: BoxDecoration(
                      //               borderRadius: const BorderRadius.all(
                      //                   Radius.circular(15)),
                      //               image: DecorationImage(
                      //                 image: CachedNetworkImageProvider(
                      //                     gameList[i]['img']),
                      //                 fit: BoxFit.cover,
                      //               ),
                      //             ),
                      //             width: 70,
                      //             height: 70,
                      //           ),
                      //           const SizedBox(
                      //             width: 20,
                      //           ),
                      //           Column(
                      //             crossAxisAlignment: CrossAxisAlignment.start,
                      //             mainAxisAlignment: MainAxisAlignment.start,
                      //             children: [
                      //               Text(
                      //                 gameList[i]['name'],
                      //                 style: const TextStyle(
                      //                   fontWeight: FontWeight.bold,
                      //                   fontSize: 16,
                      //                 ),
                      //               ),
                      //               const SizedBox(
                      //                 height: 5,
                      //               ),
                      //               Text(
                      //                 gameList[i]['status'],
                      //                 style: const TextStyle(
                      //                     color:
                      //                         Color.fromARGB(255, 233, 183, 9)),
                      //               )
                      //             ],
                      //           ),
                      //         ],
                      //       ),
                      //       Column(
                      //         crossAxisAlignment: CrossAxisAlignment.start,
                      //         mainAxisAlignment: MainAxisAlignment.start,
                      //         children: [
                      //           const Text(
                      //             "Blomutant",
                      //             style: TextStyle(color: Colors.transparent),
                      //           ),
                      //           Row(
                      //             children: [
                      //               Container(
                      //                 padding:
                      //                     EdgeInsets.fromLTRB(15, 8, 15, 8),
                      //                 decoration: BoxDecoration(
                      //                   borderRadius: BorderRadius.all(
                      //                       Radius.circular(20)),
                      //                   color:
                      //                       gameList[i]['status'] == "Published"
                      //                           ? appBackgroundblue
                      //                           : Colors.grey,
                      //                 ),
                      //                 child: Text(
                      //                   "Install",
                      //                   style: TextStyle(
                      //                       color: Colors.black,
                      //                       fontWeight: FontWeight.bold),
                      //                 ),
                      //               )
                      //             ],
                      //           ),
                      //         ],
                      //       ),
                      //     ],
                      //   ),
                      //   const SizedBox(
                      //     height: 5,
                      //   ),
                      //   const Divider(),
                      //   const SizedBox(
                      //     height: 5,
                      //   ),
                      // ],
                      SizedBox(
                          height: 200.0,
                          child: trandingGames(
                              responseItems: trandingGamesList,
                              cardHeight: 500.0,
                              cardWidth: 350.0)),
                    ]),
              ),
            ),
          ),
        ));
  }
}
