import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FinovaLineChart extends StatelessWidget {
  const FinovaLineChart({
    super.key,
    required this.income,
    required this.expense,
    required this.labels,
  });
  final List<int> income;
  final List<int> expense;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final maxValue = [
      ...income,
      ...expense,
    ].fold<int>(0, (a, b) => a > b ? a : b);
    if (maxValue == 0)
      return const Center(child: Text('Belum ada data pada periode ini.'));
    List<FlSpot> spots(List<int> values) => values
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();
    LineChartBarData line(List<int> values, Color color) => LineChartBarData(
      spots: spots(values),
      isCurved: true,
      curveSmoothness: .28,
      color: color,
      barWidth: 3.5,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .28), color.withValues(alpha: 0)],
        ),
      ),
    );
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxValue * 1.15,
        minX: 0,
        maxX: (labels.length - 1).toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue / 4,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: labels.length > 8 ? 2 : 1,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                return index >= 0 && index < labels.length
                    ? Text(
                        labels[index],
                        style: Theme.of(context).textTheme.labelSmall,
                      )
                    : const SizedBox.shrink();
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                Theme.of(context).colorScheme.inverseSurface,
          ),
        ),
        lineBarsData: [
          line(income, const Color(0xFF20C997)),
          line(expense, const Color(0xFFFF7A59)),
        ],
      ),
      duration: const Duration(milliseconds: 650),
    );
  }
}
