Map<String, double> exchangeRates = {
  "USD": 1.0,
  "IDR": 15000.0,
  "EUR": 0.9,
  "GBP": 0.8,
  "JPY": 110.0,
  "AUD": 1.5,
  "KRW": 1300.0,
};

List<Map<String, dynamic>> extractCurrenciesFromText(String text) {
  final matches = RegExp(r"(\\$|Rp|€|£|¥|₩|AUD)?\s?([0-9.,]+)").allMatches(text);
  return matches.map((m) {
    final symbol = m.group(1) ?? '';
    final rawAmount = m.group(2) ?? '0';
    final cleaned = rawAmount.replaceAll(RegExp(r'[.,]'), '');
    double amount = double.tryParse(cleaned) ?? 0;

    String currency = "USD";
    if (symbol.contains("Rp")) {
      currency = "IDR";
    } else if (symbol.contains("\$")) currency = "USD";
    else if (symbol.contains("€")) currency = "EUR";
    else if (symbol.contains("£")) currency = "GBP";
    else if (symbol.contains("¥")) currency = "JPY";
    else if (symbol.contains("₩")) currency = "KRW";
    else if (symbol.contains("AUD")) currency = "AUD";

    return {"currency": currency, "amount": amount};
  }).toList();
}

double convertCurrency(double amount, String from, String to) {
  if (!exchangeRates.containsKey(from) || !exchangeRates.containsKey(to)) return amount;
  double usd = amount / exchangeRates[from]!;
  return usd * exchangeRates[to]!;
}

String formatCurrency(double amount, String currency) {
  return "$currency ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ".")}";
}