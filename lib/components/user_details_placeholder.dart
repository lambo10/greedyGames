import 'package:cached_network_image/cached_network_image.dart';
import 'package:cryptowallet/coins/ethereum_coin.dart';
import 'package:cryptowallet/components/loader.dart';
import 'package:cryptowallet/utils/blockie_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import '../main.dart';
import '../utils/app_config.dart';
import '../utils/rpc_urls.dart';

class UserDetailsPlaceHolder extends StatefulWidget {
  final double size;
  final bool showHi;
  final double textSize;

  const UserDetailsPlaceHolder({Key key, this.size, this.showHi, this.textSize})
      : super(key: key);

  @override
  State<UserDetailsPlaceHolder> createState() => _UserDetailsPlaceHolderState();
}

class _UserDetailsPlaceHolderState extends State<UserDetailsPlaceHolder> {
  Map userDetails_ = {};
  Future<void> getUserDetails() async {
    try {
      final currentWalletName = pref.get(currentUserWalletNameKey);
      final mnemonic = pref.get(currentMmenomicKey);
      Map ethereumMap =
          getEVMBlockchains().firstWhere((e) => e['name'] == 'Ethereum');

      final web3Response = await EthereumCoin.fromJson(Map.from(ethereumMap))
          .fromMnemonic(mnemonic);

      final String useraddress = web3Response['address'];

      Map userDetails = {
        'user_address': useraddress.toLowerCase(),
      };
      userDetails['name'] = currentWalletName;

      if (mounted) {
        setState(() {
          userDetails_ = userDetails;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      return {};
    }
  }

  @override
  void didUpdateWidget(UserDetailsPlaceHolder widget) {
    super.didUpdateWidget(widget);
    getUserDetails();
  }

  @override
  void initState() {
    super.initState();
    getUserDetails();
  }

  @override
  Widget build(BuildContext context) {
    const loader = SizedBox(
      width: 20,
      height: 20,
      child: Loader(
        color: appBackgroundblue,
      ),
    );
    if (userDetails_.isEmpty) {
      return loader;
    }

    if (userDetails_['name'] == null) {
      userDetails_['name'] = AppLocalizations.of(context).user;
    }

    final blockieGreetingWidget = Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: BlockieWidget(
        size: .6,
        data: userDetails_['user_address'],
      ),
    );

    return Row(
      children: [
        Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(75)),
          ),
          child: userDetails_['image_url'] == null
              ? blockieGreetingWidget
              : CachedNetworkImage(
                  imageUrl: ipfsTohttp(userDetails_['image_url']),
                  imageBuilder: (context, imageProvider) => Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  placeholder: (context, url) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: const [loader],
                  ),
                  errorWidget: (context, url, error) {
                    return blockieGreetingWidget;
                  },
                ),
        ),
        const SizedBox(
          width: 10,
        ),
        Text(
          '${(widget.showHi ?? false) ? AppLocalizations.of(context).hi : ''} ${ellipsify(str: userDetails_['name'])}',
          style: TextStyle(fontSize: widget.textSize),
        )
      ],
    );
  }
}
