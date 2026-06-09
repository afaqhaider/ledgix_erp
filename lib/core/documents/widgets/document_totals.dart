import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DocumentTotals extends StatelessWidget {
  final double subtotal;
  final double taxTotal;
  final double discountTotal;
  final double totalAmount;
  final String currency;

  const DocumentTotals({
    super.key,
    required this.subtotal,
    required this.taxTotal,
    required this.discountTotal,
    required this.totalAmount,
    this.currency = 'AED',
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '$currency ');
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildRow('Subtotal', currencyFormat.format(subtotal)),
        if (discountTotal > 0)
          _buildRow(
            'Discount',
            '- ${currencyFormat.format(discountTotal)}',
            color: Colors.red,
          ),
        _buildRow('Tax (VAT)', currencyFormat.format(taxTotal)),
        const Divider(height: 24),
        _buildRow(
          'Total Amount',
          currencyFormat.format(totalAmount),
          isBold: true,
          fontSize: 18,
          color: theme.colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 14,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
