import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class ProgressSparkline extends StatelessWidget {
  final List<double> scores;
  const ProgressSparkline({super.key, required this.scores});

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) {
      return Center(
        child: Text('No scores yet — complete a few drills to see progress',
            style: Theme.of(context).textTheme.bodySmall),
      );
    }
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: AppConstants.primaryColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            spots: [
              for (int i = 0; i < scores.length; i++) FlSpot(i.toDouble(), scores[i]),
            ],
          )
        ],
      ),
    );
  }
}

