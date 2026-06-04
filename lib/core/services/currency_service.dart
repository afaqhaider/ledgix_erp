class CurrencyService {
  // Simple in-memory storage for now, could be fetched from API or Firestore
  final Map<String, String> _currencies = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'SAR': 'SR',
    'AED': 'DH',
    'PKR': 'Rs',
  };

  String getSymbol(String code) {
    return _currencies[code] ?? code;
  }

  List<String> getSupportedCodes() {
    return _currencies.keys.toList();
  }
}
