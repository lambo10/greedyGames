// ignore_for_file: constant_identifier_names

import 'package:eth_sig_util/util/utils.dart';
import 'package:hex/hex.dart';
import 'package:bs58check/bs58check.dart' as bs58check;

const ADDRESS_PREFIX = '41';
String tronAddressToHex(String address) {
  if (isHexString(address)) {
    return address.replaceFirst('0x', ADDRESS_PREFIX).toUpperCase();
  }
  return HEX.encode(bs58check.decode(address)).toUpperCase();
}
