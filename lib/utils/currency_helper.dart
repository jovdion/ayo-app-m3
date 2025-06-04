import 'package:intl/intl.dart';

class CurrencyHelper {
  static final Map<String, double> _exchangeRates = {
    'IDR': 1.0,
    'USD': 0.000064,
    'EUR': 0.000059,
    'GBP': 0.000051,
    'JPY': 0.0095,
    'AUD': 0.000098,
    'KRW': 0.085,
    'SGD': 0.000086,
  };

  static bool hasCurrency(String text) {
    return extractCurrenciesFromText(text).isNotEmpty;
  }

  static List<Map<String, dynamic>> extractCurrenciesFromText(String text) {
    final pattern =
        RegExp(r'([0-9]+([,.][0-9]+)?)\s*(IDR|USD|EUR|GBP|JPY|AUD|KRW|SGD)');
    final matches = pattern.allMatches(text);

    return matches.map((match) {
      final amountStr = match.group(1)!.replaceAll(',', '.');
      return {
        'amount': double.parse(amountStr),
        'currency': match.group(3),
      };
    }).toList();
  }

  static double convertCurrency(
      double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;

    // Convert to IDR first (base currency)
    final amountInIDR = amount / _exchangeRates[fromCurrency]!;

    // Convert from IDR to target currency
    return amountInIDR * _exchangeRates[toCurrency]!;
  }

  static String formatCurrency(double amount, String currency) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: currency,
      decimalDigits: 2,
    );

    String formatted = formatter
        .format(amount)
        .replaceAll('IDR', 'IDR ') // Add space after currency code
        .replaceAll('USD', 'USD ')
        .replaceAll('EUR', 'EUR ')
        .replaceAll('GBP', 'GBP ')
        .replaceAll('JPY', 'JPY ')
        .replaceAll('AUD', 'AUD ')
        .replaceAll('KRW', 'KRW ')
        .replaceAll('SGD', 'SGD ');

    // Replace decimal point with comma and use dot as thousand separator
    return formatted
        .replaceAll('.', '#') // Temporarily replace dots
        .replaceAll(',', '.') // Replace comma with dot
        .replaceAll('#', ','); // Replace temporary # with comma
  }
}
