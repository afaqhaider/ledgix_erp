import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ledgixerp/core/theme/app_colors.dart';

class DashboardChart extends StatelessWidget {
  final String title;
  final bool isLineChart;
  final List<double> data;
  final List<double>? secondaryData;
  final List<String> labels;
  final String? emptyMessage;

  static const _lineAccent = Color(0xFF5B8DEF);
  static const _secondaryLineAccent = Color(0xFFD18B45);
  static const _barAccent = Color(0xFF6F93D2);
  static const _barAlternateAccent = Color(0xFFE29A43);

  const DashboardChart({
    super.key,
    required this.title,
    this.isLineChart = true,
    required this.data,
    this.secondaryData,
    required this.labels,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.darkCard.withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.72);
    final borderColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.86);

    if (data.isEmpty && (secondaryData == null || secondaryData!.isEmpty)) {
      return Container(
        height: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text(emptyMessage ?? 'No data available yet', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.18)
                : const Color(0xFF94A3B8).withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              _buildLegend(isDark),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: isLineChart
                ? _buildLineChart(isDark)
                : _buildBarChart(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(bool isDark) {
    if (secondaryData == null) return const SizedBox.shrink();
    return Row(
      children: [
        _legendItem('Revenue', _lineAccent),
        const SizedBox(width: 12),
        _legendItem('Expenses', _secondaryLineAccent),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildLineChart(bool isDark) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? Colors.white10 : Colors.grey[200]!,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < labels.length) {
                  return Text(
                    labels[value.toInt()],
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontSize: 10,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value / 1000).toStringAsFixed(0)}k',
                  style: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              data.length,
              (index) => FlSpot(index.toDouble(), data[index]),
            ),
            isCurved: true,
            color: _lineAccent,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: _lineAccent.withValues(alpha: 0.12),
            ),
          ),
          if (secondaryData != null)
            LineChartBarData(
              spots: List.generate(
                secondaryData!.length,
                (index) => FlSpot(index.toDouble(), secondaryData![index]),
              ),
              isCurved: true,
              color: _secondaryLineAccent,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: _secondaryLineAccent.withValues(alpha: 0.12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBarChart(bool isDark) {
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      labels[value.toInt()],
                      style: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          data.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data[index],
                color: index % 2 == 0 ? _barAccent : _barAlternateAccent,
                width: 16,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
