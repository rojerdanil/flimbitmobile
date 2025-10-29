import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PortfolioGrowthChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;

  const PortfolioGrowthChart({
    super.key,
    required this.data,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: data.length.toDouble() - 1,
          minY: data.isNotEmpty
              ? data.reduce((a, b) => a < b ? a : b) - 1000
              : 0,
          maxY: data.isNotEmpty
              ? data.reduce((a, b) => a > b ? a : b) + 1000
              : 1000,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, _) {
                  int index = value.toInt();
                  if (index < 0 || index >= labels.length)
                    return const SizedBox.shrink();
                  return Text(
                    labels[index],
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 10000,
                getTitlesWidget: (value, _) {
                  return Text(
                    '₹${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                data.length,
                (index) => FlSpot(index.toDouble(), data[index]),
              ),
              isCurved: true,
              color: Colors.amber[800],
              barWidth: 3,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}
