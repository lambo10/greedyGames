import 'dart:convert';
import 'dart:typed_data';
import 'package:algorand_dart/algorand_dart.dart';
import 'package:base32/base32.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:hex/hex.dart';
import 'package:crypto/crypto.dart';

Uint8List addressAsBytes(String address) {
  final protocolIndicator = int.parse(address[1], radix: 16);

  switch (protocolIndicator) {
    case ProtocolIndicator.ID:
      final encoded = lebEncode(int.parse(address.substring(2)));
      return Uint8List.fromList([protocolIndicator] + encoded);
    case ProtocolIndicator.SECP256K1:
    case ProtocolIndicator.ACTOR:
      final decoded = base32.decode(address.substring(2).toUpperCase());
      final payload = decoded.sublist(0, decoded.length - 4);
      final checksum = decoded.sublist(decoded.length - 4);
      if (payload.length != 20) {
        throw Exception('InvalidPayloadLength');
      }
      final bytesAddress = Uint8List.fromList([protocolIndicator] + payload);
      final calculatedChecksum = getChecksum(bytesAddress);
      // if (!seqEqual(calculatedChecksum, checksum)) {
      //   throw Exception('InvalidChecksumAddress');
      // }
      return bytesAddress;
    case ProtocolIndicator.BLS:
      throw Exception('ProtocolNotSupported');
    default:
      throw Exception('UnknownProtocolIndicator');
  }
}

Uint8List serializeBigNum(String gasprice) {
  if (gasprice == "0") {
    return Uint8List(0);
  }
  final gaspriceBigInt = BigInt.parse(gasprice);
  return Uint8List.fromList([0, ...gaspriceBigInt.toUint8List()]);
}

List<int> lebEncode(int value) {
  final bytes = <int>[];
  do {
    var byte = value & 0x7f;
    value >>= 7;
    if (value != 0) {
      byte |= 0x80;
    }
    bytes.add(byte);
  } while (value != 0);
  return bytes;
}

Uint8List getChecksum(Uint8List bytes) {
  final sha = sha256.convert(bytes);
  final sha2 = sha256.convert(sha.bytes);
  return sha2.bytes.sublist(0, 4);
}

class ProtocolIndicator {
  static const ID = 0;
  static const SECP256K1 = 1;
  static const ACTOR = 2;
  static const BLS = 3;
}
