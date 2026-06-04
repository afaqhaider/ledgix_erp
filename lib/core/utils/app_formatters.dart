import 'package:intl/intl.dart';
import 'package:ledgixerp/core/services/amount_formatter.dart';
import 'package:ledgixerp/core/services/date_formatter.dart';

class AppFormatters {
  /// Formats a number as currency (e.g., AED 52,500.00)
  static String currency(double amount, {String? symbol}) {
    // Standard ERP format: SYMBOL AMOUNT
    final s = symbol != null ? '$symbol ' : '';
    return AmountFormatter.format(amount, currencySymbol: s);
  }

  /// Formats a date (e.g., 25-Jun-2026)
  static String date(DateTime date, {String pattern = 'dd-MMM-yyyy'}) {
    return DateFormatter.format(date, pattern: pattern);
  }

  /// Formats a date and time (e.g., 25-OCT-2023 10:30 AM)
  static String dateTime(DateTime date) {
    return DateFormatter.format(date, pattern: 'dd-MMM-yyyy hh:mm a');
  }

  /// Formats a percentage (e.g., 15.00%)
  static String percentage(double value, {int decimalDigits = 2}) {
    return '${value.toStringAsFixed(decimalDigits)}%';
  }

  /// Formats a quantity (e.g., 1,250.00)
  static String quantity(double value, {int decimalDigits = 2}) {
    return NumberFormat.decimalPattern().format(value);
  }

  /// Formats a weight (e.g., 50.00 kg)
  static String weight(double value, {String unit = 'kg'}) {
    return '${NumberFormat.decimalPattern().format(value)} $unit';
  }

  /// Formats a document number (e.g., INV-00001)
  static String documentNumber(String prefix, int number) {
    return '$prefix-${number.toString().padLeft(5, '0')}';
  }
}
