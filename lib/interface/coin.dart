// ignore_for_file: non_constant_identifier_names

abstract class Coin {
  validateAddress(String address);
  Future<Map> fromMnemonic(String mnemonic);
  Future<double> getBalance(bool skipNetworkRequest);
  Future<String> transferToken(String amount, String to);
  Map getTransactions();
  int decimals();
  String name_();
  String symbol_();
  String blockExplorer_();
  String default__();
  String address_();
  String image_();
}
