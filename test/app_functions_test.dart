// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart' as cardano;
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:cryptowallet/eip/eip681.dart';
import 'package:cryptowallet/model/seed_phrase_root.dart';
import 'package:cryptowallet/utils/cid.dart';
import 'package:cryptowallet/utils/alt_ens.dart';
import 'package:cryptowallet/utils/app_config.dart';
import 'package:cryptowallet/utils/coin_pay.dart';
import 'package:cryptowallet/utils/ethereum_blockies.dart';
import 'package:cryptowallet/utils/filecoin_util.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:cryptowallet/xrp_transaction/xrp_transaction.dart';
import 'package:elliptic/elliptic.dart';
import 'package:flutter/services.dart';
import 'package:hex/hex.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive_test/hive_test.dart';
import 'package:leb128/leb128.dart';
import 'package:sacco/sacco.dart' as cosmos;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart' as cardano;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await setUpTestHive();
    await Hive.openBox(secureStorageKey);
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  final blockInstance = EthereumBlockies();
  final blockInstanceTwo = EthereumBlockies();
  const busdContractAddress = '0xe9e7cea3dedca5984780bafc599bd69add087d56';
  const address = '0x6Acf5505DF3Eada0BF0547FAb88a85b1A2e03F15';
  const addressTwo = '0x3064c83F8b28193d9B6E7c0717754163DDF3C70b';
  const ensAddress = 'vitalik.eth';
  const eip681String =
      'ethereum:ethereum-$busdContractAddress@56/transfer?address=$address&uint256=1000000000000000000';
  const unstoppableAddress = 'brad.crypto';

  test('can generate transactionSignLotus cid', () {
    final cid = transactionSignLotus(
      {
        'Version': 0,
        'To': "f153zbrv25wvfrqf2vrvlk2qmpietuu6wexiyerja",
        'From': "f125p5nhte6kwrigoxrcaxftwpinlgspfnqd2zaui",
        'Nonce': 0,
        'Value': "10000000000000000000",
        'GasLimit': 1000000000000,
        'GasFeeCap': "10000000",
        'GasPremium': "10000000",
        'Method': 0,
        'Params': "",
      },
      'ebb58c44303695d99f710f3b0d21c2cbea692acde24b2363c5f043edd47af10c',
    );
    final cid2 = transactionSignLotus(
      {
        'Version': 0,
        'To': "f125p5nhte6kwrigoxrcaxftwpinlgspfnqd2zaui",
        'From': "f153zbrv25wvfrqf2vrvlk2qmpietuu6wexiyerja",
        'Nonce': 0,
        'Value': "10000000000000000000",
        'GasLimit': 1000000000000,
        'GasFeeCap': "10000000",
        'GasPremium': "10000000",
        'Method': 0,
        'Params': "",
      },
      'ebb58c44303695d99f710f3b0d21c2cbea692acde24b2363c5f043edd47af10c',
    );
    final cid3 = transactionSignLotus(
      {
        'Version': 0,
        'To': "f1655h66sk2dgp3d7uksbnhgk7n56xjeofpe2lpwq",
        'From': "f1erk23ics4ecpk3ny2g4orliwejklw7e6goxujji",
        'Nonce': 0,
        'Value': "10000000000000000000",
        'GasLimit': 3229228282,
        'GasFeeCap': "10000000",
        'GasPremium': "10000000",
        'Method': 0,
        'Params': "",
      },
      'ebb58c44303695d99f710f3b0d21c2cbea692acde24b2363c5f043edd47af10c',
    );
    expect(cid,
        'kx9WoSmQGC3V1Vk24csxAERzZpShXl38HVdQBaST3r0Ia6YtlZVuO6bDvG3YA2ZK6NC8C3z8ap1w5XXil/ryVgE=');
    expect(cid2,
        'jHF0ghnCwyl7XNEfgXx1+9sjbg3lJe09gEux/+m5pRFudpQEeFxxt9ZACHNDE//u31r3GBZ4aYixpV8xYp57HgA=');
    expect(cid3,
        'yPzGMXOoxqlmjIPlAFU2swX8VcwBaeDJho+RUNMy/PA17wJ5H1Cq86yPVvyQlLIau5tEmQZlavWtqmFwFppdIgE=');
  });
  test('can generate filecoin cid', () {
    expect(
      genCid(
        jsonEncode(
          {
            "Version": 0,
            "To": "f125p5nhte6kwrigoxrcaxftwpinlgspfnqd2zaui",
            "From": "f153zbrv25wvfrqf2vrvlk2qmpietuu6wexiyerja",
            "Nonce": 0,
            "Value": "10000000000000000000",
            "GasLimit": 1000000000000,
            "GasFeeCap": "10000000",
            "GasPremium": "10000000",
            "Method": 0,
            "Params": ""
          },
        ),
      ),
      'bagaaieranzmqkatxqfe2unslsoqq5n6mmvn5xjri65m2xkiuq4f2ofmmzf5q',
    );
    expect(
      genCid('OMG!', CIDCodes.dagPBCode),
      'bafybeig6xv5nwphfmvcnektpnojts33jqcuam7bmye2pb54adnrtccjlsu',
    );
    expect(
      genCid(
          jsonEncode(
              '🚀🪐⭐💻😅💪🥳😴🎂👉💧📍🌴😪😮🎈🚩🙈😥😰🔵😡✊🍒🐾🎉😇🎤❌😏🌍🌘🥂✋😹📍🙄'),
          CIDCodes.dagPBCode,
          0),
      'QmW5xcH8ydwYtnS8FsMYxZfjpsN6p4YTVv7n5YbvoooZy4',
    );
    expect(
      genCid(jsonEncode({'hello': 'world'})),
      'bagaaierasords4njcts6vs7qvdjfcvgnume4hqohf65zsfguprqphs3icwea',
    );
    expect(
      genCid(jsonEncode(
          {'s39oe93p;;i3i3lL.//dkdkdlaid': 'kskslei3i9aekdkl39zlallk'})),
      'bagaaierafwnjryt63d5n7l2c76blfv7jddxgfeuhl4bvcdzuniggxo2eqngq',
    );
  });
  test('can convert from cid v0 to cid v1', () {
    expect(
      fromV0ToV1('QmW5xcH8ydwYtnS8FsMYxZfjpsN6p4YTVv7n5YbvoooZy4'),
      'bafybeidtdic3panzxksm5vva52ru222wlasitwpuio2vxszuhfgizrhlim',
    );

    expect(
      fromV0ToV1('QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n'),
      'bafybeihdwdcefgh4dqkjv67uzcmw7ojee6xedzdetojuzjevtenxquvyku',
    );
    expect(
      fromV0ToV1('QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR'),
      'bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi',
    );
  });
  test('can decode known abis', () {
    expect(solidityFunctionSig('withdraw(uint256)'), '0x2e1a7d4d');
    expect(solidityFunctionSig('ownerOf(uint256)'), '0x6352211e');
    expect(solidityFunctionSig('balanceOf(address)'), '0x70a08231');
    expect(solidityFunctionSig('transfer(address,uint256)'), '0xa9059cbb');
    expect(solidityFunctionSig('approve(address,uint256)'), '0x095ea7b3');
    expect(solidityFunctionSig('solversk()'), '0xffb5eff0');
  });

  test('get ethereum address blockie image data and colors', () {
    blockInstance.seedrand(address.toLowerCase());
    HSL color = blockInstance.createColor();
    HSL bgColor = blockInstance.createColor();
    HSL spotColor = blockInstance.createColor();
    List imageData = blockInstance.createImageData();
    expect(sha3(json.encode(blockInstance.randseed)),
        '89b8a19e375159267d7d16447f53766cbd210d6b0328779cc897a03a9922b914');
    expect(
        color.toString(), 'H: 25.0 S: 62.20454423791009 L: 50.21168109970711');
    expect(bgColor.toString(),
        'H: 108.0 S: 57.542195253792315 L: 43.62102017906542');
    expect(spotColor.toString(),
        'H: 31.0 S: 48.8115822751129 L: 50.77201500570961');
    expect(sha3(json.encode(imageData)),
        'd935e1c2fa18d0a7b7f92604e3ea282ab4572124852411306d70e302fb5447a4');

    /// Account two
    blockInstanceTwo.seedrand(addressTwo.toLowerCase());
    HSL colorTwo = blockInstanceTwo.createColor();
    HSL bgColorTwo = blockInstanceTwo.createColor();
    HSL spotColorTwo = blockInstanceTwo.createColor();
    List imageDataTwo = blockInstanceTwo.createImageData();
    expect(sha3(json.encode(blockInstanceTwo.randseed)),
        '491a7d9b769c9e62f67019b5ea33b5b100e8a38e55b1efc0680ac4edaaa18f79');
    expect(colorTwo.toString(),
        'H: 240.0 S: 77.89883877052871 L: 42.880431070402466');
    expect(bgColorTwo.toString(),
        'H: 302.0 S: 52.13426684594446 L: 15.5695927401863');
    expect(spotColorTwo.toString(),
        'H: 252.0 S: 74.00470713805626 L: 64.89102061134344');
    expect(sha3(json.encode(imageDataTwo)),
        '0da3e2aa1ee73f4caae2c09cd4febd40ebdf3a0128b2e6c4686ec93055f221d7');
  });

  test('javalongToInt accuracy convert java long numbers to int', () {
    expect(blockInstance.javaLongToInt(-32839282839282), 37105934);
  });

  test('CoinPay data is correct', () {
    const scheme = 'ethereum';
    const amount = 10.0;
    final payment =
        CoinPay(amount: amount, recipient: address, coinScheme: scheme).toUri();

    expect(payment, 'ethereum:$address?amount=10.0');

    final parsedUrl = CoinPay.parseUri('$scheme:$address?amount=10.0');
    expect(parsedUrl.amount, 10.0);
    expect(parsedUrl.recipient, address);
    expect(parsedUrl.coinScheme, scheme);
  });
  test('eip681 conversion', () {
    expect(
        EIP681.build(
          prefix: 'ethereum',
          targetAddress: busdContractAddress,
          chainId: '56',
          functionName: 'transfer',
          parameters: {
            'uint256': (1e18).toString(),
            'address': address,
          },
        ),
        eip681String);

    expect(
      sha3(json.encode(EIP681.parse(eip681String))),
      '5a9e3c6f895795edc845d1bcc17a8e23fe4e176b887f9fb86e952e8a0a3e2908',
    );
  });

  test('name hash working correctly', () async {
    expect(
      nameHash(unstoppableAddress),
      '0x756e4e998dbffd803c21d23b06cd855cdc7a4b57706c95964a37e24b47c10fc9',
    );

    expect(
      nameHash(ensAddress),
      '0xee6c4522aab0003e8d14cd40a6af439055fd2577951148c14b6cea9a53475835',
    );
  });

  test('ens resolves correctly to address and content hash', () async {
    Map ensToAddressMap = await ensToAddress(
      cryptoDomainName: ensAddress,
    );

    Map ensToContentHash = await ensToContentHashAndIPFS(
      cryptoDomainName: ensAddress,
    );
    if (ensToAddressMap['success']) {
      expect(
        ensToAddressMap['msg'],
        startsWith('0x'),
      );
    } else {
      throw Exception(ensToAddressMap['msg']);
    }

    if (ensToContentHash['success']) {
      expect(
        ensToContentHash['msg'],
        startsWith('https://ipfs.io/ipfs/'),
      );
    } else {
      throw Exception(ensToContentHash['msg']);
    }
  });

  test('unstoppable domain resolves correctly to address', () async {
    const domainAddress = unstoppableAddress;
    Map domainResult = await unstoppableDomainENS(
      cryptoDomainName: domainAddress,
      currency: 'BTC',
    );
    if (domainResult['success']) {
      expect(domainResult['msg'], 'bc1q359khn0phg58xgezyqsuuaha28zkwx047c0c3y');
    } else {
      throw Exception(domainResult['msg']);
    }
  });
  test('test solidity sha3(keccak256) returns correct data', () {
    expect(sha3('hello world'),
        '47173285a8d7341e5e972fc677286384f802f8ef42a5ec5f03bbfa254cb01fad');
  });

  test('can encode xrp json transaction', () async {
    expect(
      encodeXrpJson({
        "Account": "rGWrZyQqhTp9Xu7G5Pkayo7bXjH4k4QYpf",
        "Fee": "0",
        "Sequence": 38292838,
        "LastLedgerSequence": 38383,
        "TransactionType": "Payment",
        "SigningPubKey": "abcdef38383833",
        "Amount": "40000",
        "Destination": "r3SVzk8ApofDJuVBPKdmbbLjWGCCXpBQ2g"
      }),
      '535458001200002402484D66201B000095EF614000000000009C406840000000000000007307ABCDEF383838338114AA066C988C712815CC37AF71472B7CBBBD4E2A0A8314519B7BE6889CF12EAA50978FF51630E0DED92809',
    );

    expect(
      encodeXrpJson({
        "Account": "rQfZM9WRQJmTJeGroRC9pSyEC3jYeXKfuL",
        "Fee": "40000",
        "Sequence": 78697,
        "LastLedgerSequence": 8760876,
        "TransactionType": "Payment",
        "SigningPubKey": "abcdef38383833",
        "Amount": "40000",
        "Destination": "rJrRMgiRgrU6hDF4pgu5DXQdWyPbY35ErN"
      }),
      '535458001200002400013369201B0085AE2C614000000000009C40684000000000009C407307ABCDEF383838338114FD8864194C0A66B88A79A0CD4B1E5D15718A67DA8314BA8E78626EE42C41B46D46C3048DF3A1C3C87072',
    );
    expect(
      encodeXrpJson({
        "Account": "XVaH3tVKvGo4HTCCEauvs6NYHKVSqkDVVzALJGM8wfLyquA",
        "Fee": "485600",
        "Sequence": 3882,
        "LastLedgerSequence": 789282,
        "TransactionType": "Payment",
        "SigningPubKey": "abc38383833def",
        "Amount": "1388920",
        "Destination": "rPRiXRLGkw5hVwP5NePE2tXTQPi684bzrz"
      }),
      '5354580012000023000000002400000F2A201B000C0B226140000000001531786840000000000768E07307ABC38383833DEF81147BA497AF24A988B63747BADDBCEB572156D156618314F606175DD417B8D2EBB12E559DA1E5ED7AE74BEF',
    );
    expect(
      encodeXrpJson({
        "Account": "rUGmHgeFC6bRRG8r6gqP9FkZUtfRqGsH4x",
        "Fee": "485600",
        "Sequence": 3882,
        "LastLedgerSequence": 789282,
        "TransactionType": "Payment",
        "SigningPubKey": "abc38383833def",
        "Amount": "1388920",
        "Destination": "rPRiXRLGkw5hVwP5NePE2tXTQPi684bzrz"
      }),
      '535458001200002400000F2A201B000C0B226140000000001531786840000000000768E07307ABC38383833DEF81147BA497AF24A988B63747BADDBCEB572156D156618314F606175DD417B8D2EBB12E559DA1E5ED7AE74BEF',
    );
  });

  test('can get the correct signature to transfer xrp', () {
    final signedXrpJson = signXrpTransaction(
      'ebb58c44303695d99f710f3b0d21c2cbea692acde24b2363c5f043edd47af10c',
      {
        "Account": "rUGmHgeFC6bRRG8r6gqP9FkZUtfRqGsH4x",
        "Fee": "485600",
        "Sequence": 3882,
        "LastLedgerSequence": 789282,
        "TransactionType": "Payment",
        "SigningPubKey": "abc38383833def",
        "Amount": "1388920",
        "Destination": "rPRiXRLGkw5hVwP5NePE2tXTQPi684bzrz"
      },
    );
    final signedXrpJson2 = signXrpTransaction(
      'ebb58c44303695d99f710f3b0d21c2cbea692acde24b2363c5f043edd47af10c',
      {
        "Account": "XVaH3tVKvGo4HTCCEauvs6NYHKVSqkDVVzALJGM8wfLyquA",
        "Fee": "485600",
        "Sequence": 3882,
        "LastLedgerSequence": 789282,
        "TransactionType": "Payment",
        "SigningPubKey": "abc38383833def",
        "Amount": "1388920",
        "Destination": "rPRiXRLGkw5hVwP5NePE2tXTQPi684bzrz"
      },
    );
    expect(
      signedXrpJson['TxnSignature'],
      '3045022100E076F27C34E7608C92D6071497BA834E87BB35FF89874DB66DF1F804D0CF42CC0220557ADCDDCF7BE5FCFE25C98F052A9668B4370DA37AC972CF5853DB948D878FF3',
    );
    expect(
      signedXrpJson2['TxnSignature'],
      '3045022100B2888EC378A6DD16BE2612155D85B36CD476DF6071CFC2E4468E20C696C17D5A02201014F4ABE53B2A31BD75E377A9807D155D7203D2859E00CA93C4BC5C00D34A95',
    );
  });
  test('convert xrp X-Address to classicAddress', () {
    expect(
      xaddress_to_classic_address(
        'XVaH3tVKvGo4HTCCEauvs6NYHKVSqkDVVzALJGM8wfLyquA',
      )['classicAddress'],
      'rUGmHgeFC6bRRG8r6gqP9FkZUtfRqGsH4x',
    );
    expect(
      xaddress_to_classic_address(
        'XVQyfVBqvb4bcBm5cboWKTTfaSG32QiRKyoH7QKkEPtfQ4N',
      )['classicAddress'],
      'rJrRMgiRgrU6hDF4pgu5DXQdWyPbY35ErN',
    );
    expect(
      xaddress_to_classic_address(
        'XV5d53BfA9JaZtn2dkJVVxhCf6wDuHt6SpWYiVchZQyDswg',
      )['classicAddress'],
      'rPRiXRLGkw5hVwP5NePE2tXTQPi684bzrz',
    );
  });
  test('validate addresses', () {
    final btcMap = {'default': "BTC", 'name': 'Bitcoin', 'P2WPKH': ''};
    final ethMap = {
      'default': "ETH",
      'rpc': getEVMBlockchains()['Ethereum']['rpc']
    };
    final bchMap = {'default': "BCH"};
    final ltcMap = {'default': "LTC", 'name': 'Litecoin', 'P2WPKH': ''};
    final dashMap = {'default': "DASH", 'name': 'Dash', 'P2WPKH': ''};
    final trxMap = {'default': "TRX"};
    final solMap = {'default': "SOL"};
    final xlmMap = {'default': "XLM"};
    final algoMap = {'default': "ALGO"};
    final cosmosMap = {'default': "ATOM", 'bech32Hrp': 'cosmos'};
    final zecMap = {'default': "ZEC", 'name': 'ZCash', 'P2WPKH': ''};
    final xtz = {'default': "XTZ"};
    final adaMap = {'default': "ADA"};
    final xrpMap = {'default': "XRP"};
    final filMap = {'default': "FIL"};

    // valid addresses
    validateAddress(btcMap, 'bc1qzd9a563p9hfd93e3e2k3986m3ve0nmy4dtruaf');
    validateAddress(ethMap, '0x4AA3f03885Ad09df3d0CD08CD1Fe9cC52Fc43dBF');
    validateAddress(bchMap, 'qr4rwp766lf2xysphv8wz2qglphuzx5y7gku3hqruj');
    validateAddress(ltcMap, 'ltc1qsru3fe2ttd3zgjfhn3r5eqz6tpe5cfzqszg8s7');
    validateAddress(dashMap, 'Xy1VVEXaiJstcmA9Jr1k38rcr3sGn3kQti');
    validateAddress(trxMap, 'TSwpGWaJtfZfyE8kd1NYD1xYgTQUSGLsSM');
    validateAddress(solMap, '5rxJLW9p2NQPMRjKM1P3B7CQ7v2RASpz45T7QP39bX5W');
    validateAddress(
        xlmMap, 'GA5MO26YHJK7VMDCTODG7DYO5YATNMRYQVTXNMNKKRFYXZOINJYQEXYT');
    validateAddress(
        algoMap, 'GYFNCWZJM3NKKXXFIHNDGNL2BLKBMPKA5UZBUWZUQKUIGYWCG5L2SBPB2U');
    validateAddress(cosmosMap, 'cosmos1f36h4udjp9yxaewrrgyrv75phtemqsagep85ne');
    validateAddress(zecMap, 't1UNRtPu3WJUVTwwpFQHUWcu2LAhCrwDWuU');
    validateAddress(xtz, 'tz1RcTV9WGm2Tiok995LncZDgZHFjVXbnnWK');
    validateAddress(adaMap,
        'addr1q9r4l5l6xzsvum2g5s7u99wt630p8qd9xpepf73reyyrmxpqde5sugs7jg27gp04fcq7a9z90gz3ac8mq7p7k5vwedsq34lpxc');
    validateAddress(xrpMap, 'rQfZM9WRQJmTJeGroRC9pSyEC3jYeXKfuL');
    validateAddress(filMap, 'f1st7wiqbxz5plebdu32jpqgxrcduf2y6p22fmz3i');
    validateAddress(filMap, 'f01782');
    validateAddress(filMap,
        'f3sg22lqqjewwczqcs2cjr3zp6htctbovwugzzut2nkvb366wzn5tp2zkfvu5xrfqhreowiryxump7l5e6jaaq');

    // invalid address

    const invalidAddress = 'bc1qzmy4dtruaf';

    expect(() => validateAddress(btcMap, invalidAddress),
        throwsA(isA<Exception>()));
    expect(() => validateAddress(ethMap, invalidAddress),
        throwsA(isA<ArgumentError>()));
    expect(() => validateAddress(bchMap, invalidAddress),
        throwsA(isA<Exception>()));
    expect(() => validateAddress(ltcMap, invalidAddress),
        throwsA(isA<Exception>()));
    expect(() => validateAddress(dashMap, invalidAddress),
        throwsA(isA<Exception>()));
    expect(() => validateAddress(trxMap, invalidAddress),
        throwsA(isA<Exception>()));
    expect(() => validateAddress(solMap, invalidAddress),
        throwsA(isA<ArgumentError>()));
    expect(() => validateAddress(xlmMap, invalidAddress),
        throwsA(isA<Exception>()));
    expect(() => validateAddress(algoMap, invalidAddress),
        throwsA(isA<Exception>()));
    expect(() => validateAddress(cosmosMap, invalidAddress),
        throwsA(isA<Exception>()));
    expect(() => validateAddress(zecMap, invalidAddress),
        throwsA(isA<Exception>()));
    expect(
        () => validateAddress(xtz, invalidAddress), throwsA(isA<Exception>()));
    expect(() => validateAddress(adaMap, invalidAddress),
        throwsA(isA<Exception>()));
    expect(() => validateAddress(xrpMap, invalidAddress),
        throwsA(isA<Exception>()));
    expect(() => validateAddress(filMap, invalidAddress),
        throwsA(isA<Exception>()));
  });

  test('bitcoin-kind of blockchain pos network,hd path, p2wpkh not null', () {
    for (String i in getBitCoinPOSBlockchains().keys) {
      expect(getBitCoinPOSBlockchains()[i]['POSNetwork'], isNotNull);
      expect(getBitCoinPOSBlockchains()[i]['P2WPKH'], isNotNull);
      expect(getBitCoinPOSBlockchains()[i]['derivationPath'], isNotNull);
      expect(getBitCoinPOSBlockchains()[i]['symbol'], isNotNull);
      expect(getBitCoinPOSBlockchains()[i]['default'], isNotNull);
      expect(getBitCoinPOSBlockchains()[i]['blockExplorer'], isNotNull);
      expect(getBitCoinPOSBlockchains()[i]['image'], isNotNull);
    }
  });
  test('ethereum-kind block have all valid inputs', () {
    for (String i in getEVMBlockchains().keys) {
      expect(getEVMBlockchains()[i]['rpc'], isNotNull);
      expect(getEVMBlockchains()[i]['chainId'], isNotNull);
      expect(getEVMBlockchains()[i]['blockExplorer'], isNotNull);
      expect(getEVMBlockchains()[i]['symbol'], isNotNull);
      expect(getEVMBlockchains()[i]['default'], isNotNull);
      expect(getEVMBlockchains()[i]['image'], isNotNull);
      expect(getEVMBlockchains()[i]['coinType'], isNotNull);
    }
  });
  test('stellar-kind block have all valid inputs', () {
    for (String i in getStellarBlockChains().keys) {
      expect(getStellarBlockChains()[i]['symbol'], isNotNull);
      expect(getStellarBlockChains()[i]['default'], isNotNull);
      expect(getStellarBlockChains()[i]['blockExplorer'], isNotNull);
      expect(getStellarBlockChains()[i]['image'], isNotNull);
      expect(getStellarBlockChains()[i]['sdk'], isNotNull);
      expect(getStellarBlockChains()[i]['cluster'], isNotNull);
    }
  });
  test('filecoin-kind block have all valid inputs', () {
    for (String i in getFilecoinBlockChains().keys) {
      expect(getFilecoinBlockChains()[i]['symbol'], isNotNull);
      expect(getFilecoinBlockChains()[i]['default'], isNotNull);
      expect(getFilecoinBlockChains()[i]['blockExplorer'], isNotNull);
      expect(getFilecoinBlockChains()[i]['image'], isNotNull);
      expect(getFilecoinBlockChains()[i]['baseUrl'], isNotNull);
      expect(getFilecoinBlockChains()[i]['prefix'], isNotNull);
    }
  });
  test('cardano-kind block have all valid inputs', () {
    for (String i in getCardanoBlockChains().keys) {
      expect(getCardanoBlockChains()[i]['symbol'], isNotNull);
      expect(getCardanoBlockChains()[i]['default'], isNotNull);
      expect(getCardanoBlockChains()[i]['blockExplorer'], isNotNull);
      expect(getCardanoBlockChains()[i]['blockFrostKey'], isNotNull);
      expect(getCardanoBlockChains()[i]['cardano_network'], isNotNull);
      expect(getCardanoBlockChains()[i]['image'], isNotNull);
    }
  });
  test('solana-kind block have all valid inputs', () {
    for (String i in getSolanaBlockChains().keys) {
      expect(getSolanaBlockChains()[i]['symbol'], isNotNull);
      expect(getSolanaBlockChains()[i]['default'], isNotNull);
      expect(getSolanaBlockChains()[i]['blockExplorer'], isNotNull);
      expect(getSolanaBlockChains()[i]['image'], isNotNull);
      expect(getSolanaBlockChains()[i]['solanaCluster'], isNotNull);
    }
  });

  test('cosmos-kind block have all valid inputs', () {
    for (String i in getCosmosBlockChains().keys) {
      expect(getCosmosBlockChains()[i]['symbol'], isNotNull);
      expect(getCosmosBlockChains()[i]['default'], isNotNull);
      expect(getCosmosBlockChains()[i]['blockExplorer'], isNotNull);
      expect(getCosmosBlockChains()[i]['image'], isNotNull);
      expect(getCosmosBlockChains()[i]['bech32Hrp'], isNotNull);
      expect(getCosmosBlockChains()[i]['lcdUrl'], isNotNull);
    }
  });

  test('check if seed phrase generates the correct crypto address', () async {
    // WARNING: These accounts, and their private keys, are publicly known.
    // Any funds sent to them on Mainnet or any other live network WILL BE LOST.
    const mnemonic =
        'express crane road good warm suggest genre organ cradle tuition strike manual';

    seedPhraseRoot = await compute(seedFromMnemonic, mnemonic);

    final bitcoinKeyLive = await compute(
      calculateBitCoinKey,
      Map.from(getBitCoinPOSBlockchains()['Bitcoin'])
        ..addAll({seedRootKey: seedPhraseRoot, mnemonicKey: mnemonic}),
    );

    final litecoinKey = await compute(
      calculateBitCoinKey,
      Map.from(getBitCoinPOSBlockchains()['Litecoin'])
        ..addAll({seedRootKey: seedPhraseRoot, mnemonicKey: mnemonic}),
    );

    final bitcoinCashKey = await compute(
      calculateBitCoinKey,
      Map.from(getBitCoinPOSBlockchains()['BitcoinCash'])
        ..addAll({seedRootKey: seedPhraseRoot, mnemonicKey: mnemonic}),
    );

    final dogecoinKey = await compute(
      calculateBitCoinKey,
      Map.from(getBitCoinPOSBlockchains()['Dogecoin'])
        ..addAll({seedRootKey: seedPhraseRoot, mnemonicKey: mnemonic}),
    );

    final zcashKey = await compute(
      calculateBitCoinKey,
      Map.from(getBitCoinPOSBlockchains()['ZCash'])
        ..addAll({seedRootKey: seedPhraseRoot, mnemonicKey: mnemonic}),
    );
    final dashKey = await compute(
      calculateBitCoinKey,
      Map.from(getBitCoinPOSBlockchains()['Dash'])
        ..addAll({seedRootKey: seedPhraseRoot, mnemonicKey: mnemonic}),
    );

    // final tezosKey = await compute(
    //   calculateTezorKey,
    //   {seedRootKey: seedPhraseRoot, mnemonicKey: mnemonic},
    // );

    final ethereumKey = await compute(
      calculateEthereumKey,
      {
        seedRootKey: seedPhraseRoot,
        mnemonicKey: mnemonic,
        'coinType': getEVMBlockchains()['Ethereum']['coinType'],
      },
    );
    final ethereumClassicKey = await compute(
      calculateEthereumKey,
      {
        seedRootKey: seedPhraseRoot,
        mnemonicKey: mnemonic,
        'coinType': getEVMBlockchains()['Ethereum Classic']['coinType'],
      },
    );
    final cardanoLiveKey = await compute(
      calculateCardanoKey,
      {mnemonicKey: mnemonic, 'network': cardano.NetworkId.mainnet},
    );
    final cardanoTestNetKey = await compute(
      calculateCardanoKey,
      {mnemonicKey: mnemonic, 'network': cardano.NetworkId.testnet},
    );
    final stellarKey = await compute(
      calculateStellarKey,
      {
        mnemonicKey: mnemonic,
        seedRootKey: seedPhraseRoot,
      },
    );

    final filecoinKey = await compute(calculateFileCoinKey, {
      mnemonicKey: mnemonic,
      seedRootKey: seedPhraseRoot,
      'addressPrefix': 'f'
    });

    final cosmosKey = await compute(calculateCosmosKey, {
      mnemonicKey: mnemonic,
      seedRootKey: seedPhraseRoot,
      "networkInfo": cosmos.NetworkInfo(
        bech32Hrp: 'cosmos',
        lcdUrl: Uri.parse(''),
      )
    });
    final solanaKey = await compute(
      calculateSolanaKey,
      {
        mnemonicKey: mnemonic,
        seedRootKey: seedPhraseRoot,
      },
    );

    final rippleKey = await compute(
      calculateRippleKey,
      {
        mnemonicKey: mnemonic,
        seedRootKey: seedPhraseRoot,
      },
    );

    final algorandKey = await compute(
      calculateAlgorandKey,
      {
        mnemonicKey: mnemonic,
        seedRootKey: seedPhraseRoot,
      },
    );
    final tronKey = await compute(
      calculateTronKey,
      {
        mnemonicKey: mnemonic,
        seedRootKey: seedPhraseRoot,
      },
    );

    if (enableTestNet) {
      final bitcoinKeyTest = await compute(
        calculateBitCoinKey,
        Map.from(getBitCoinPOSBlockchains()['Bitcoin(Test)'])
          ..addAll({seedRootKey: seedPhraseRoot, mnemonicKey: mnemonic}),
      );
      expect(bitcoinKeyTest['address'], 'n4fpz8NjzHwBkyzHBhSYoAegc7LjWZ175E');
    }
    expect(bitcoinKeyLive['address'],
        'bc1qzd9a563p9hfd93e3e2k3986m3ve0nmy4dtruaf');

    expect(bitcoinCashKey['address'],
        'qr4rwp766lf2xysphv8wz2qglphuzx5y7gku3hqruj');
    expect(rippleKey['address'], 'rQfZM9WRQJmTJeGroRC9pSyEC3jYeXKfuL');

    expect(
        litecoinKey['address'], 'ltc1qsru3fe2ttd3zgjfhn3r5eqz6tpe5cfzqszg8s7');
    expect(dashKey['address'], 'Xy1VVEXaiJstcmA9Jr1k38rcr3sGn3kQti');
    expect(dogecoinKey['address'], 'DF6pp77Q4ms37ABLberK4EuBtREiB1BGJz');
    expect(zcashKey['address'], 't1UNRtPu3WJUVTwwpFQHUWcu2LAhCrwDWuU');
    expect(algorandKey['address'],
        'GYFNCWZJM3NKKXXFIHNDGNL2BLKBMPKA5UZBUWZUQKUIGYWCG5L2SBPB2U');
    expect(tronKey['address'], 'TSwpGWaJtfZfyE8kd1NYD1xYgTQUSGLsSM');
    // expect(tezosKey['address'], 'tz1dSW1iQguZHMEZoAgNTU6VBRcNnyfb5BA7');
    expect(
        cosmosKey['address'], 'cosmos1f36h4udjp9yxaewrrgyrv75phtemqsagep85ne');
    expect(stellarKey['address'],
        'GA5MO26YHJK7VMDCTODG7DYO5YATNMRYQVTXNMNKKRFYXZOINJYQEXYT');
    expect(
      await etherPrivateKeyToAddress(ethereumKey),
      '0x4AA3f03885Ad09df3d0CD08CD1Fe9cC52Fc43dBF',
    );
    expect(
      await etherPrivateKeyToAddress(ethereumClassicKey),
      '0x5C4b9839FDD8D5156549bE3eD5a00c933AaA3544',
    );
    expect(filecoinKey['address'], 'f16kbqwbyroghqd76fm5j4uiat5vasumclk7nezpa');
    expect(
      solanaKey['address'],
      '5rxJLW9p2NQPMRjKM1P3B7CQ7v2RASpz45T7QP39bX5W',
    );
    expect(
      cardanoLiveKey['address'],
      'addr1q9r4l5l6xzsvum2g5s7u99wt630p8qd9xpepf73reyyrmxpqde5sugs7jg27gp04fcq7a9z90gz3ac8mq7p7k5vwedsq34lpxc',
    );
    expect(
      cardanoTestNetKey['address'],
      'addr_test1qpr4l5l6xzsvum2g5s7u99wt630p8qd9xpepf73reyyrmxpqde5sugs7jg27gp04fcq7a9z90gz3ac8mq7p7k5vwedsqjrzp28',
    );
  });

  test('user pin length and pin trials is secured and correct.', () async {
    expect(pinLength, greaterThanOrEqualTo(4));
    expect(userPinTrials, greaterThanOrEqualTo(1));
    expect(maximumTransactionToSave, greaterThanOrEqualTo(10));
    expect(maximumBrowserHistoryToSave, greaterThanOrEqualTo(10));
  });

  test('dapp browser signing key are correct.', () {
    expect(personalSignKey, 'Personal');
    expect(normalSignKey, 'Normal Sign');
    expect(typedMessageSignKey, "Typed Message");
  });

  test('can import token from blockchain', () async {
    Map bep20TokenDetails = await getERC20TokenDetails(
      contractAddress: busdContractAddress,
      rpc: getEVMBlockchains()['Smart Chain']['rpc'],
    );

    expect(bep20TokenDetails['name'], 'BUSD Token');
    expect(bep20TokenDetails['symbol'], 'BUSD');
    expect(bep20TokenDetails['decimals'], '18');
  });
}
