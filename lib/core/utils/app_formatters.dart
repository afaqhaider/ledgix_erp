import 'package:intl/intl.dart';

class AppFormatters {
  static final _currencyFormatter = NumberFormat('#,##0.00', 'en_US');
  static final _dateFormatter = DateFormat('dd/MM/yyyy');
  static final _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');

  /// Formats amount to 1,000.00 style
  static String formatCurrency(double amount) {
    return _currencyFormatter.format(amount);
  }

  /// Formats date to dd/MM/yyyy
  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  /// Formats date and time to dd/MM/yyyy HH:mm
  static String formatDateTime(DateTime date) {
    return _dateTimeFormatter.format(date);
  }

  /// Alias for formatCurrency to match user request terminology
  static String currency(double amount, {String? symbol}) {
    // We ignore symbol for now as per "1,000.00" law,
    // but keep parameter for future compliance.
    return formatCurrency(amount);
  }

  /// Alias for formatDate to match user request terminology
  static String date(DateTime date) {
    return formatDate(date);
  }
}
