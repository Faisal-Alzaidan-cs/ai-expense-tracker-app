import 'package:flutter/material.dart';
import 'package:expenses_tracker/screens/stats/enums.dart';
import 'package:expenses_tracker/l10n/app_localizations.dart';

/// Widget that displays the expense summary card with totals and comparison
class ExpenseSummaryCard extends StatelessWidget {
  final TimeRange selectedRange;
  final double currentPeriodTotal;
  final double percentageChange;

  const ExpenseSummaryCard({
    Key? key,
    required this.selectedRange,
    required this.currentPeriodTotal,
    required this.percentageChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade700, Colors.blue.shade900],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getRangeTitle(context),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/Saudi_Riyal_Symbol-1.png',
                  height: 24,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  currentPeriodTotal.toStringAsFixed(2),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (percentageChange != 0)
                    Icon(
                      percentageChange > 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: percentageChange > 0
                          ? Colors.red.shade300
                          : Colors.green.shade300,
                      size: 16,
                    ),
                  if (percentageChange == 0)
                    Icon(
                      Icons.horizontal_rule,
                      color: Colors.amber.shade300,
                      size: 16,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    _getComparisonText(context),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRangeTitle(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    switch (selectedRange) {
      case TimeRange.daily:
        return localizations.total;
      case TimeRange.weekly:
        return localizations.thisWeek;
      case TimeRange.monthly:
        return localizations.thisMonth;
    }
  }

  String _getComparisonText(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (percentageChange == 0) {
      String periodText;
      switch (selectedRange) {
        case TimeRange.daily:
          periodText = 'yesterday';
          break;
        case TimeRange.weekly:
          periodText = 'last week';
          break;
        case TimeRange.monthly:
          periodText = 'last month';
          break;
      }
      return 'No change from $periodText';
    }

    final direction = percentageChange > 0 ? 'more' : 'less';
    final percentage = percentageChange.abs().toStringAsFixed(1);

    String periodText;
    switch (selectedRange) {
      case TimeRange.daily:
        periodText = 'yesterday';
        break;
      case TimeRange.weekly:
        periodText = 'week';
        break;
      case TimeRange.monthly:
        periodText = 'month';
        break;
    }

    return '$percentage% $direction ${localizations.fromLast} $periodText';
  }
}
