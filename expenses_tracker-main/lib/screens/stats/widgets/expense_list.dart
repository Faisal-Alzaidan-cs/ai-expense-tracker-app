import 'package:flutter/material.dart';
import '../helpers/stats_helpers.dart';
import 'package:expenses_tracker/l10n/app_localizations.dart';

/// Widget that displays a list of expenses with the ability to edit them
class ExpenseList extends StatelessWidget {
  final List<Map<String, dynamic>> expenses;
  final Function(Map<String, dynamic>) onEditExpense;
  final int limit;
  final bool showViewAll;

  const ExpenseList({
    Key? key,
    required this.expenses,
    required this.onEditExpense,
    this.limit = 10,
    this.showViewAll = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (expenses.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayedExpenses = expenses.length > limit && limit > 0
        ? expenses.sublist(0, limit)
        : expenses;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200, width: 0.5),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long,
                    size: 22,
                    color: Color(0xFF4285F4),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    localizations.recentExpenses,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${displayedExpenses.length} of ${expenses.length}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: displayedExpenses.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.grey.shade100,
                height: 16,
              ),
              itemBuilder: (context, index) {
                final expense = displayedExpenses[index];
                final date = expense['dateTime'] as DateTime;
                final category = expense['category'] ?? 'Other';

                // Generate a consistent color for the category
                final colors = {
                  'Food': Colors.orange.shade700,
                  'Coffee': Colors.brown.shade600,
                  'Transport': Colors.blue.shade700,
                  'Shopping': Colors.purple.shade700,
                  'Entertainment': Colors.pink.shade600,
                  'Bills': Colors.red.shade600,
                  'Health': Colors.green.shade600,
                  'Travel': Colors.teal.shade600,
                  'Education': Colors.indigo.shade600,
                  'Other': Colors.grey.shade700,
                };

                final color = colors[category] ?? Colors.grey.shade700;

                return InkWell(
                  onTap: () => onEditExpense(expense),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              StatsHelpers.getCategoryIcon(category),
                              color: color,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense['merchant'] ?? 'Unknown Merchant',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${StatsHelpers.formatDate(date)} • $category',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/Saudi_Riyal_Symbol-1.png',
                                  height: 15,
                                  width: 15,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  ' ${expense['amount'].toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (showViewAll && expenses.length > limit)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: InkWell(
                  onTap: () {
                    // Show all expenses in a modal
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => DraggableScrollableSheet(
                        initialChildSize: 0.7,
                        maxChildSize: 0.9,
                        minChildSize: 0.5,
                        expand: false,
                        builder: (context, scrollController) =>
                            _buildFullExpenseList(context, scrollController),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 18,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            localizations.expenses,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullExpenseList(
      BuildContext context, ScrollController scrollController) {
    final localizations = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar for draggable sheet
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.receipt_long,
                size: 24,
                color: Color(0xFF4285F4),
              ),
              const SizedBox(width: 10),
              Text(
                localizations.expenses,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              itemCount: expenses.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.grey.shade100,
                height: 16,
              ),
              itemBuilder: (context, index) {
                final expense = expenses[index];
                final date = expense['dateTime'] as DateTime;
                final category = expense['category'] ?? 'Other';

                // Reuse the same color mapping as in the regular list
                final colors = {
                  'Food': Colors.orange.shade700,
                  'Coffee': Colors.brown.shade600,
                  'Transport': Colors.blue.shade700,
                  'Shopping': Colors.purple.shade700,
                  'Entertainment': Colors.pink.shade600,
                  'Bills': Colors.red.shade600,
                  'Health': Colors.green.shade600,
                  'Travel': Colors.teal.shade600,
                  'Education': Colors.indigo.shade600,
                  'Other': Colors.grey.shade700,
                };

                final color = colors[category] ?? Colors.grey.shade700;

                return InkWell(
                  onTap: () => onEditExpense(expense),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              StatsHelpers.getCategoryIcon(category),
                              color: color,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense['merchant'] ?? 'Unknown Merchant',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${StatsHelpers.formatDate(date, includeTime: true)} • $category',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/Saudi_Riyal_Symbol-1.png',
                                  height: 15,
                                  width: 15,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  ' ${expense['amount'].toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
