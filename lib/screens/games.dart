import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../utils/rpc_urls.dart';

class Games extends StatefulWidget {
  const Games({Key key}) : super(key: key);
  @override
  State<Games> createState() => _GamesState();
}

class _GamesState extends State<Games> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Timer timer;
  bool videoLoaded = false;
  bool gamesLoaded = false;
  List gameList = [];
  Future loadVideo() async {
    final videoRequest = await get(
      Uri.parse('https://greedyverse.co/api/getTrendingvideo.php'),
    );

    if (videoRequest.statusCode ~/ 100 == 4 ||
        videoRequest.statusCode ~/ 100 == 5) {
      throw Exception('Request failed');
    }

    final res = jsonDecode(videoRequest.body);

    if (!res['success']) return;

    final videoUrl = res['message']['video_url'];

    String videoId = YoutubePlayer.convertUrlToId(videoUrl);

    _controller.load(videoId);

    _controller.play();
    videoLoaded = true;
  }

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

  @override
  void initState() {
    super.initState();
    loadVideo();
    getGames();
    timer = Timer.periodic(
      httpPollingDelay,
      (Timer t) async {
        try {
          if (!videoLoaded) {
            await loadVideo();
          }
        } catch (_) {}
        try {
          if (!gamesLoaded) {
            await getGames();
          }
        } catch (_) {}
      },
    );
  }

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final YoutubePlayerController _controller = YoutubePlayerController(
    initialVideoId: 'c0iBcO69H4k',
    flags: const YoutubePlayerFlags(
      autoPlay: true,
    ),
  );
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        key: _scaffoldKey,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              color: Colors.transparent,
              height: MediaQuery.of(context).size.height,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            flex: 10,
                            child: TextFormField(
                              validator: (value) {
                                if (value?.trim() == "") {
                                  return 'Required';
                                } else {
                                  return null;
                                }
                              },
                              // controller: decimalsAddressController,
                              decoration: InputDecoration(
                                hintText: 'Search game...',

                                prefixIcon: IconButton(
                                  onPressed: () {},
                                  icon: const Icon(
                                    FontAwesomeIcons.search,
                                    color: Colors.grey,
                                  ),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(30.0)),
                                    borderSide: BorderSide(color: Colors.grey)),
                                border: const OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(30.0)),
                                    borderSide: BorderSide(color: Colors.grey)),
                                enabledBorder: const OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(30.0)),
                                    borderSide:
                                        BorderSide(color: Colors.grey)), // you
                                filled: false,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      YoutubePlayer(
                        controller: _controller,
                        showVideoProgressIndicator: true,
                        progressIndicatorColor: Colors.amber,
                        progressColors: const ProgressBarColors(
                          playedColor: Colors.amber,
                          handleColor: Colors.amberAccent,
                        ),
                        onReady: () {
                          // _controller.addListener(listener);
                        },
                      ),
                      const SizedBox(
                        height: 40,
                      ),
                      for (int i = 0; i < gameList.length; i++) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(15)),
                                    image: DecorationImage(
                                      image: CachedNetworkImageProvider(
                                          gameList[i]['img']),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  width: 70,
                                  height: 70,
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      gameList[i]['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Row(
                                      children: [
                                        const Icon(
                                          FontAwesomeIcons.clock,
                                          size: 15,
                                        ),
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        const Text("20:30"),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const Text(
                                  "Blomutant",
                                  style: TextStyle(color: Colors.transparent),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding:
                                          const EdgeInsets.fromLTRB(8, 8, 8, 8),
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(20)),
                                        color: Colors.lightGreen,
                                      ),
                                      child: const Text(
                                        "Fantasy",
                                        style: TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        )
                      ],
                    ]),
              ),
            ),
          ),
        ));
  }

  // return VideoPlayer(
  //         url: widget.imageUrl,
  //       );
}
