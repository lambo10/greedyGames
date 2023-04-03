
import 'dart:convert';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/signers/ecdsa_signer.dart';
import 'package:pointycastle/digests/blake2b.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:pointycastle/signers/ecdsa_signer.dart';
import 'package:pointycastle/api.dart';

// func SecpSign(ck string, msg string) string {
// 	if ck == "" {
// 		return ""
// 	}
// 	if msg == "" {
// 		return ""
// 	}

// 	ckbytes, err := base64.StdEncoding.DecodeString(ck)
// 	if err != nil {
// 		return ""
// 	}

// 	msgbytes, err := base64.StdEncoding.DecodeString(msg)
// 	if err != nil {
// 		return ""
// 	}

// 	b2sum := blake2b.Sum256(msgbytes)
// 	sig, err := crypto.Sign(ckbytes, b2sum[:])
// 	if err != nil {
// 		return ""
// 	}

// 	return base64.StdEncoding.EncodeToString(sig)
// }

  // print(Base32.encode(base64.decode(await Flotus.messageCid(msg: msg_))));

  // final msg = {'hello': 'world'};
  // final code = 512;
  // final version = 1;
  // final bytes = utf8.encode(json.encode(msg));
  // final digest = sha256.convert(bytes);
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