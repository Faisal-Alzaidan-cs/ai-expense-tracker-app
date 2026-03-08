import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expenses_tracker/l10n/app_localizations.dart';

/// Widget that displays category distribution as a pie chart
class CategoryPieChart extends StatelessWidget {
  final List<Map<String, dynamic>> expenses;
  final double totalAmount;

  const CategoryPieChart({
    Key? key,
    required this.expenses,
    required this.totalAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (expenses.isEmpty) {
      return _buildEmptyState(context);
    }

    // Calculate and sort expenses by category
    final categorySums = <String, double>{};
    for (var expense in expenses) {
      final category = expense['category'] ?? 'Other';
      categorySums[category] =
          (categorySums[category] ?? 0) + expense['amount'];
    }

    // Calculate percentages and prepare data
    final categories = categorySums.keys.toList();
    categories.sort((a, b) => categorySums[b]!.compareTo(categorySums[a]!));

    // Generate unique colors for categories
    final colors = [
      Colors.blue.shade700,
      Colors.green.shade600,
      Colors.purple.shade500,
      Colors.orange.shade600,
      Colors.teal.shade500,
      Colors.red.shade500,
      Colors.indigo.shade500,
      Colors.amber.shade600,
      Colors.pink.shade400,
      Colors.lime.shade600,
    ];

    // Prepare pie sections and legends
    final sections = <PieChartSectionData>[];
    final legends = <Widget>[];

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final amount = categorySums[category]!;
      final percentage = (amount / totalAmount) * 100;
      final color = i < colors.length ? colors[i] : Colors.grey.shade500;

      // Add pie section
      sections.add(
        PieChartSectionData(
          color: color,
          value: amount,
          title: '', // Remove the title text since we're using badge
          titlePositionPercentageOffset: 0.6,
          radius: 60,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          badgeWidget: amount >= totalAmount * 0.05
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Image.asset(
                      'assets/Saudi_Riyal_Symbol-1.png',
                      width: 12,
                      height: 12,
                      color: Colors.white,
                    ),
                  ],
                )
              : null,
          badgePositionPercentageOffset:
              0.5, // Changed from 0.8 to 0.5 to move more toward the middle
        ),
      );

      // Add legend
      legends.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.0),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                localizations.byCategory,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 180,
                  width: 180,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 30,
                      sectionsSpace: 2,
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: legends,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return _buildGenericEmptyState(
      context,
      "No expenses in this period",
      "Try selecting a different time range",
      Icons.pie_chart,
    );
  }

  Widget _buildGenericEmptyState(
      BuildContext context, String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
