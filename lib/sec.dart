// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';
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

String genCid({msg = const {'hello': 'world'}}) {
  const code = 512;
  const version = 1;
  final bytes = utf8.encode(json.encode(msg));
  final digest = sha256.convert(bytes);
  final bytesCode = encodeCid(version, code, digest);

  return 'b${Base32.encode(bytesCode).toLowerCase()}';
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

// int get bytes => encode.bytes;

// set bytes(int value) => encode.bytes = value;
// This code uses Uint8List instead of a regular array, which is a typed array optimized for byte-level operations. The encode.bytes property is used to keep track of the number of bytes written to the target array, and is set at the end of the function to be used by the caller.

Uint8List encodeCid(version, code, Digest digest) {
  final codeOffset = Varint.encodingLength(version);

  final hashOffset = codeOffset + Varint.encodingLength(code);
  final fullBytes = [18, 32, ...digest.bytes];
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
