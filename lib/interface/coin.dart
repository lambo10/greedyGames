// ignore_for_file: non_constant_identifier_names

abstract class Coin {
  validateAddress(String address);
  Future<Map> fromMnemonic(String mnemonic);
  Future<double> getBalance(bool skipNetworkRequest);
  Future<String> transferToken(String amount, String to);
  Future<Map> getTransactions();
  int decimals();
  String name_();
  String symbol_();
  String blockExplorer_();
  String default__();
  Future<String> address_();

  String image_();
  String contractAddress() {
    return null;
  }
}
