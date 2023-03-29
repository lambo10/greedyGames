import 'package:cached_network_image/cached_network_image.dart';
import 'package:cryptowallet/components/loader.dart';
import 'package:cryptowallet/screens/video_player.dart';
import 'package:flutter/material.dart';

import '../utils/app_config.dart';

class NFTImageWebview extends StatefulWidget {
  final String imageUrl;
  const NFTImageWebview({
    Key key,
    this.imageUrl,
  }) : super(key: key);
  @override
  State<NFTImageWebview> createState() => _NFTImageWebviewState();
}

class _NFTImageWebviewState extends State<NFTImageWebview> {
  final browserController = TextEditingController();

  ValueNotifier loadingPercent = ValueNotifier<double>(0);

  @override
  initState() {
    super.initState();
  }

  @override
  void dispose() {
    browserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl == null) Container();
    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      width: double.infinity,
      height: 150,
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
      errorWidget: (context, url, error) {
        return VideoPlayer(
          url: widget.imageUrl,
        );
      },
      fit: BoxFit.cover,
    );
    // return ScalableImageWidget.fromSISource(
    //   fit: BoxFit.cover,
    //   onLoading: (context) => Column(
    //     mainAxisAlignment: MainAxisAlignment.center,
    //     mainAxisSize: MainAxisSize.min,
    //     children: const [
    //       SizedBox(
    //         width: 20,
    //         height: 20,
    //         child: Loader(
    //           color: appPrimaryColor,
    //         ),
    //       )
    //     ],
    //   ),
    //   onError: (p0) {},
    //   si: ScalableImageSource.fromSvgHttpUrl(
    //     Uri.parse(widget.imageUrl),
    //   ),
    // );
  }
}
