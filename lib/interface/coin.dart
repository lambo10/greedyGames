abstract class Coin {
  validateAddress(String address);
  Future<Map> fromMnemonic(String mnemonic);
  Future<double> getBalance(bool skipNetworkRequest);
  Future<String> transferToken(String amount, String to);
  Map getTransactions();
}
