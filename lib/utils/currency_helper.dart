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
    print('Checking for currency in text: $text');
    final result = extractCurrenciesFromText(text).isNotEmpty;
    print('Has currency: $result');
    return result;
  }

  static List<Map<String, dynamic>> extractCurrenciesFromText(String text) {
    print('Extracting currencies from text: $text');
    // Updated pattern to handle $ symbol and optional spaces
    final pattern = RegExp(
        r'(?:(?:USD|\$)\s*(\d+(?:[,.]\d+)?)|(\d+(?:[,.]\d+)?)\s*(?:IDR|USD|EUR|GBP|JPY|AUD|KRW|SGD))');
    final matches = pattern.allMatches(text);
    print('Found ${matches.length} currency matches');

    final result = matches.map((match) {
      String? amountStr;
      String currency;

      // Handle $ prefix case
      if (match.group(1) != null) {
        amountStr = match.group(1);
        currency = 'USD';
      } else {
        amountStr = match.group(2);
        currency = text.substring(match.end - 3, match.end);
      }

      amountStr = amountStr!.replaceAll(',', '.');
      final amount = double.parse(amountStr);

      print('Extracted currency: $amount $currency');
      return {
        'amount': amount,
        'currency': currency,
      };
    }).toList();

    print('Extracted currencies: $result');
    return result;
  }

  static double convertCurrency(
      double amount, String fromCurrency, String toCurrency) {
    print('Converting $amount from $fromCurrency to $toCurrency');

    // Handle $ prefix for USD
    if (fromCurrency == r'$') fromCurrency = 'USD';
    if (toCurrency == r'$') toCurrency = 'USD';

    if (fromCurrency == toCurrency) return amount;

    // Convert to IDR first (base currency)
    final amountInIDR = amount / _exchangeRates[fromCurrency]!;
    print('Amount in IDR: $amountInIDR');

    // Convert from IDR to target currency
    final result = amountInIDR * _exchangeRates[toCurrency]!;
    print('Converted amount: $result');
    return result;
  }

  static String formatCurrency(double amount, String currency) {
    print('Formatting amount: $amount $currency');
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: currency,
      decimalDigits: 2,
    );

    String formatted = formatter
        .format(amount)
        .replaceAll('IDR', 'IDR ')
        .replaceAll('USD', 'USD ')
        .replaceAll('EUR', 'EUR ')
        .replaceAll('GBP', 'GBP ')
        .replaceAll('JPY', 'JPY ')
        .replaceAll('AUD', 'AUD ')
        .replaceAll('KRW', 'KRW ')
        .replaceAll('SGD', 'SGD ');

    // Replace decimal point with comma and use dot as thousand separator
    formatted = formatted
        .replaceAll('.', '#')
        .replaceAll(',', '.')
        .replaceAll('#', ',');

    print('Formatted currency: $formatted');
    return formatted;
  }
}
