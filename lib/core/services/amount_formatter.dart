import 'package:intl/intl.dart';

class AmountFormatter {
  static String format(
    double amount, {
    String? currencySymbol,
    int decimalDigits = 2,
  }) {
    final formatter = NumberFormat.currency(
      symbol: currencySymbol ?? '',
      decimalDigits: decimalDigits,
    );

    if (amount < 0) {
      // ERP standard for negative numbers often uses parentheses
      return "(${formatter.format(amount.abs()).trim()})";
    }

    return formatter.format(amount).trim();
  }
}
