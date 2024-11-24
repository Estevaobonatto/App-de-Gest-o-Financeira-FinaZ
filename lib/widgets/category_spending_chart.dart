import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CategorySpendingChart extends StatelessWidget {
  final List<PieChartSectionData> sections;

  CategorySpendingChart({required this.sections});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }
}
