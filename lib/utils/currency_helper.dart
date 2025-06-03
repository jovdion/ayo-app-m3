class CurrencyHelper {
  static final RegExp currencyPattern = RegExp(
    r'(?:(?:Rp|USD|EUR|GBP|JPY|AUD|KRW|SGD|\$|€|£|¥|₩|S\$)[,.\s]*[0-9]+(?:[,.][0-9]+)*)|(?:[0-9]+(?:[,.][0-9]+)*(?:\s*(?:dollars?|euros?|pounds?|yen|won|rupiah)))',
    caseSensitive: false,
  );

  static bool hasCurrency(String text) {
    return currencyPattern.hasMatch(text);
  }

  static List<Map<String, dynamic>> extractCurrenciesFromText(String text) {
    final matches = currencyPattern.allMatches(text);
    final results = <Map<String, dynamic>>[];

    for (final match in matches) {
      final value = match.group(0)!.toLowerCase();
      double amount = 0;
      String currency = 'USD';

      // Extract numeric value and currency
      if (value.contains('rp') || value.contains('rupiah')) {
        amount = _extractNumber(value);
        currency = 'IDR';
      } else if (value.contains(r'\$') || value.contains('dollar')) {
        amount = _extractNumber(value);
        currency = 'USD';
      } else if (value.contains('€') || value.contains('euro')) {
        amount = _extractNumber(value);
        currency = 'EUR';
      } else if (value.contains('£') || value.contains('pound')) {
        amount = _extractNumber(value);
        currency = 'GBP';
      } else if (value.contains('¥') || value.contains('yen')) {
        amount = _extractNumber(value);
        currency = 'JPY';
      } else if (value.contains('₩') || value.contains('won')) {
        amount = _extractNumber(value);
        currency = 'KRW';
      } else if (value.contains('aud')) {
        amount = _extractNumber(value);
        currency = 'AUD';
      } else if (value.contains('sgd') || value.contains('s\$')) {
        amount = _extractNumber(value);
        currency = 'SGD';
      }

      results.add({
        'amount': amount,
        'currency': currency,
      });
    }

    return results;
  }

  static double _extractNumber(String value) {
    final numericPattern = RegExp(r'[0-9]+(?:[,.][0-9]+)*');
    final match = numericPattern.firstMatch(value);
    if (match == null) return 0;

    String numStr = match.group(0)!.replaceAll(',', '');
    return double.tryParse(numStr) ?? 0;
  }

  static double convertCurrency(
      double amount, String fromCurrency, String toCurrency) {
    // Exchange rates (as of a recent date)
    final rates = {
      'USD': 1.0,
      'EUR': 0.92,
      'GBP': 0.79,
      'JPY': 149.50,
      'AUD': 1.52,
      'KRW': 1331.24,
      'SGD': 1.34,
      'IDR': 15747.35,
    };

    // Convert to USD first
    double usdAmount = amount / (rates[fromCurrency] ?? 1.0);
    // Then convert to target currency
    return usdAmount * (rates[toCurrency] ?? 1.0);
  }

  static String formatCurrency(double amount, String currency) {
    String symbol = '';
    int decimals = 2;

    switch (currency) {
      case 'USD':
        symbol = '\$';
        break;
      case 'EUR':
        symbol = '€';
        break;
      case 'GBP':
        symbol = '£';
        break;
      case 'JPY':
        symbol = '¥';
        decimals = 0;
        break;
      case 'AUD':
        symbol = 'A\$';
        break;
      case 'KRW':
        symbol = '₩';
        decimals = 0;
        break;
      case 'SGD':
        symbol = 'S\$';
        break;
      case 'IDR':
        symbol = 'Rp';
        decimals = 0;
        break;
    }

    return '$symbol${amount.toStringAsFixed(decimals)}';
  }
}
