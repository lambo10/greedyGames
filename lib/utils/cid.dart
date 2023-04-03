// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';
import 'package:bs58check/bs58check.dart';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:crypto/crypto.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

_length(value) {
  var N1 = pow(2, 7);
  var N2 = pow(2, 14);
  var N3 = pow(2, 21);
  var N4 = pow(2, 28);
  var N5 = pow(2, 35);
  var N6 = pow(2, 42);
  var N7 = pow(2, 49);
  var N8 = pow(2, 56);
  var N9 = pow(2, 63);
  return (value < N1
      ? 1
      : value < N2
          ? 2
          : value < N3
              ? 3
              : value < N4
                  ? 4
                  : value < N5
                      ? 5
                      : value < N6
                          ? 6
                          : value < N7
                              ? 7
                              : value < N8
                                  ? 8
                                  : value < N9
                                      ? 9
                                      : 10);
}

class Varint {
  static encodingLength(nuber) {
    return _length(nuber);
  }
}

enum CIDCodes { jsonCodeCID, stringCodeCID }

String genCid(
  String msg, [
  CIDCodes defaultCode = CIDCodes.jsonCodeCID,
  version = 1,
]) {
  int code;
  if (version == 0 && defaultCode != CIDCodes.stringCodeCID) {
    throw Exception('Version 0 CID must use dag-pb (code: 112) block encoding');
  }
  if (defaultCode == CIDCodes.jsonCodeCID) {
    code = 512;
  } else {
    code = 112;
  }
  final bytes = utf8.encode(msg);
  final digest = sha256.convert(bytes);
  final fullBytes = Uint8List.fromList([18, 32, ...digest.bytes]);

  if (version == 1) {
    final bytesCode = encodeCid(version, code, fullBytes);
    return 'b${Base32.encode(bytesCode).toLowerCase()}';
  } else {
    return base58.encode(fullBytes);
  }
}

Uint8List encodeTo(number, Uint8List target, [int offset = 0]) {
  target ??= Uint8List(10);
  const MSB = 0x80;
  const REST = 0x7F;
  const MSBALL = ~REST;
  const INT = 1 << 31;

  while (number >= INT) {
    target[offset++] = (number & 0xFF) | MSB;
    number /= 128;
  }

  while ((number & MSBALL) != 0) {
    target[offset++] = (number & 0xFF) | MSB;
    number >>= 7;
  }

  target[offset] = number | 0;
  return target;
}

Uint8List encodeCid(version, code, Uint8List fullBytes) {
  final codeOffset = Varint.encodingLength(version);

  final hashOffset = codeOffset + Varint.encodingLength(code);

  var bytes = Uint8List(hashOffset + fullBytes.length);
  bytes = encodeTo(version, bytes, 0);
  bytes = encodeTo(code, bytes, codeOffset);
  bytes.setAll(hashOffset, fullBytes);
  return bytes;
}

String SecpSign(String ck, String msg) {
  if (ck == "") {
    return "";
  }
  if (msg == "") {
    return "";
  }

  var ckbytes = base64.decode(ck);
  var msgbytes = base64.decode(msg);
  final b2sum = blake2bHash(msgbytes, digestSize: 32);

  // getSecp256k1().

  // var b2sum = Blake2bDigest().process(msgbytes);
  // var domainParams = ECCurve_secp256k1();
  // domainParams.
  // var signer = ECDSASigner(null, HMac(Blake2bDigest(), 64));
  // signer.init(true, PrivateKeyParameter(privKey));
  // var sig = signer.generateSignature(b2sum);

  // return base64.encode(sig);
}
