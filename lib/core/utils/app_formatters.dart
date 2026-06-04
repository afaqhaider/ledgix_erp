import 'package:intl/intl.dart';

class AppFormatters {
  static final _currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);
  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final _quantityFormat = NumberFormat('#,##0.##');

  /// Formats a number as currency with company base currency (e.g., AED 52,500.00)
  static String currency(double amount, {String? symbol}) {
    final s = symbol ?? 'AED';
    return '$s ${_currencyFormat.format(amount)}';
  }

  /// Formats a date (e.g., 01 Jan 2024)
  static String date(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Formats a date and time (e.g., 01 Jan 2024, 10:30 AM)
  static String dateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Formats a percentage (e.g., 5.5%)
  static String percentage(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  /// Formats a quantity (e.g., 1,250.5)
  static String quantity(double value) {
    return _quantityFormat.format(value);
  }

  /// Formats a weight (e.g., 50.00 kg)
  static String weight(double value, {String unit = 'kg'}) {
    return '${_quantityFormat.format(value)} $unit';
  }

  /// Formats a document number (e.g., INV-00001)
  static String documentNumber(String prefix, int number) {
    return '$prefix-${number.toString().padLeft(5, '0')}';
  }
}
