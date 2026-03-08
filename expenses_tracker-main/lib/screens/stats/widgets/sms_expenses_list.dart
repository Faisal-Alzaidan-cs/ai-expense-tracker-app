import 'package:flutter/material.dart';
import '../helpers/stats_helpers.dart';
import 'package:expenses_tracker/l10n/app_localizations.dart';

/// Widget that displays SMS expenses that can be imported
class SmsExpensesList extends StatelessWidget {
  final List<Map<String, dynamic>> smsExpenses;
  final Function(Map<String, dynamic>, int) onSaveSmsExpense;
  final VoidCallback onSaveAll;
  final bool isLoading;

  const SmsExpensesList({
    Key? key,
    required this.smsExpenses,
    required this.onSaveSmsExpense,
    required this.onSaveAll,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Column(
      children: [
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.smsExpenses,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Found ${smsExpenses.length} expenses from SMS',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : onSaveAll,
                      icon: const Icon(Icons.save, size: 18),
                      label: Text(localizations.saveAll),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: smsExpenses.length,
            itemBuilder: (context, index) {
              final expense = smsExpenses[index];

              return Dismissible(
                key: Key(expense['smsId']?.toString() ?? index.toString()),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.green.shade700,
                  child: const Icon(
                    Icons.save,
                    color: Colors.white,
                  ),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) => onSaveSmsExpense(expense, index),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              child: Icon(
                                Icons.sms,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expense['merchant'] ?? 'Unknown Merchant',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    expense['smsBody'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  StatsHelpers.formatDate(
                                          expense['dateTime'] as DateTime?,
                                          includeTime: true) ??
                                      'Unknown Date',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  localizations.amount,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'SAR ${expense['amount']?.toStringAsFixed(2) ?? '0.00'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Remove from the list without saving
                                  onSaveSmsExpense(expense, index);
                                },
                                icon:
                                    const Icon(Icons.delete_outline, size: 18),
                                label: Text(localizations.cancel),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey.shade700,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    onSaveSmsExpense(expense, index),
                                icon: const Icon(Icons.save, size: 18),
                                label: Text(localizations.save),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  elevation: 1,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
