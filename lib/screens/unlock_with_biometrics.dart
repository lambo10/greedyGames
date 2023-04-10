import 'package:cryptowallet/utils/app_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/rpc_urls.dart';

class UnlockWithBiometrics extends StatefulWidget {
  const UnlockWithBiometrics({Key key}) : super(key: key);

  @override
  State<UnlockWithBiometrics> createState() => _UnlockWithBiometricsState();
}

class _UnlockWithBiometricsState extends State<UnlockWithBiometrics> {
  final pref = Hive.box(secureStorageKey);
  bool allowedBiometrics = true;
  @override
  void initState() {
    super.initState();
    allowedBiometrics = pref.get(biometricsKey, defaultValue: true);
  }

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.9,
      child: CupertinoSwitch(
        value: allowedBiometrics,
        activeColor: appBackgroundblue,
        onChanged: (bool value) async {
          if (await authenticate(context)) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            allowedBiometrics = !allowedBiometrics;
            setState(() {});
            await pref.put(biometricsKey, allowedBiometrics);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red,
                content: Text(
                  AppLocalizations.of(context).authFailed,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}