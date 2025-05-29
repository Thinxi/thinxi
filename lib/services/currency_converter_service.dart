import 'package:cloud_firestore/cloud_firestore.dart';

class CurrencyConverter {
  static final _db = FirebaseFirestore.instance;

  // تبدیل مقدار از USD به هر ارز دیگر
  static Future<double> convertUSDTo(
      String targetCurrency, double amountInUSD) async {
    final doc = await _db.collection('exchangeRates').doc(targetCurrency).get();
    if (!doc.exists) throw Exception("Currency not found");

    final rateToUSD = doc.data()!['rateToUSD'];
    return amountInUSD / rateToUSD;
  }

  // تبدیل هر ارز به USD
  static Future<double> convertToUSD(
      String sourceCurrency, double amount) async {
    final doc = await _db.collection('exchangeRates').doc(sourceCurrency).get();
    if (!doc.exists) throw Exception("Currency not found");

    final rateToUSD = doc.data()!['rateToUSD'];
    return amount * rateToUSD;
  }

  // تبدیل مستقیم بین دو ارز
  static Future<double> convert(String from, String to, double amount) async {
    final fromDoc = await _db.collection('exchangeRates').doc(from).get();
    final toDoc = await _db.collection('exchangeRates').doc(to).get();

    if (!fromDoc.exists || !toDoc.exists) throw Exception("Invalid currency");

    final fromRate = fromDoc.data()!['rateToUSD'];
    final toRate = toDoc.data()!['rateToUSD'];

    double usd = amount * fromRate;
    return usd / toRate;
  }
}
