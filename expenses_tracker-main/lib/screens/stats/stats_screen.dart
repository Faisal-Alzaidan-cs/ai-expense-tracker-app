import 'package:flutter/material.dart';
import 'package:expenses_tracker/services/sms_service.dart';
import 'package:expenses_tracker/services/expense_service.dart';
import 'package:expenses_tracker/l10n/app_localizations.dart';

import 'enums.dart';
import '../../services/stats_service.dart';
import 'widgets/stats_header.dart';
import 'widgets/stats_tab_bar.dart';
import 'widgets/range_selector.dart';
import 'widgets/expense_summary_card.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/expense_list.dart';
import 'widgets/sms_expenses_list.dart';
import 'widgets/empty_state_widget.dart';

/// Main Stats Screen that shows expense analytics and allows SMS expense import
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  // Core state variables
  TimeRange _selectedRange = TimeRange.weekly;
  bool _isLoading = false;
  double _currentPeriodTotal = 0.0;
  double _percentageChange = 0.0;
  List<Map<String, dynamic>> _filteredExpenses = [];

  // SMS expenses state
  late TabController _tabController;
  final SmsService _smsService = SmsService();
  final ExpenseService _expenseService = ExpenseService();
  final StatsService _statsService = StatsService();
  List<Map<String, dynamic>> _smsExpenses = [];
  Set<String> _processedSmsIds = {};
  bool _loadingSms = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchExpenseData();
    _loadProcessedSmsIds();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper methods for SMS expense management
  Future<void> _loadProcessedSmsIds() async {
    _processedSmsIds = await _expenseService.loadProcessedSmsIds();
    if (mounted) setState(() {});
  }

  Future<void> _extractSmsExpenses() async {
    if (_loadingSms) return;
    setState(() => _loadingSms = true);

    try {
      await _loadProcessedSmsIds();
      final hasPermission = await _smsService.requestSmsPermission();

      if (!hasPermission) {
        _showSnackBar('SMS permission denied');
        setState(() => _loadingSms = false);
        return;
      }

      final extractedExpenses = await _smsService.extractExpensesFromSms(
        processedSmsIds: _processedSmsIds,
      );

      if (mounted) {
        setState(() {
          _smsExpenses = extractedExpenses;
          _loadingSms = false;
        });
      }

      if (extractedExpenses.isEmpty) {
        _showSnackBar('No new expenses found in SMS');
      }
    } catch (e) {
      debugPrint("❌ Error extracting SMS expenses: $e");
      _showSnackBar('Error extracting expenses: $e', isError: true);
      if (mounted) setState(() => _loadingSms = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  // Core expense data retrieval and processing
  Future<void> _fetchExpenseData() async {
    setState(() => _isLoading = true);

    try {
      final result = await _statsService.fetchExpenseData(_selectedRange);

      if (mounted) {
        setState(() {
          _currentPeriodTotal = result['currentTotal'];
          _percentageChange = result['percentageChange'];
          _filteredExpenses = result['filteredExpenses'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching expense data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Method to handle editing an expense
  Future<void> _editExpense(Map<String, dynamic> expense) async {
    try {
      final TextEditingController merchantController =
          TextEditingController(text: expense['merchant'] ?? '');
      final TextEditingController categoryController =
          TextEditingController(text: expense['category'] ?? '');
      String? selectedCategory = expense['category'];

      // List of common expense categories
      final List<String> categories = [
        'Food',
        'Coffee',
        'Transport',
        'Shopping',
        'Entertainment',
        'Bills',
        'Health',
        'Travel',
        'Education',
        'Other'
      ];

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Edit Expense'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: merchantController,
                    decoration: const InputDecoration(
                      labelText: 'Merchant',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Category:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((category) {
                      return ChoiceChip(
                        label: Text(category),
                        selected: selectedCategory == category,
                        onSelected: (selected) {
                          setState(() {
                            selectedCategory = selected ? category : null;
                            if (selected) {
                              categoryController.text = category;
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Custom Category',
                      hintText: 'Or enter a custom category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Amount: SAR ${(expense['amount'] as num).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text('(Amount cannot be modified)',
                      style:
                          TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final updatedExpense = {
                    ...expense,
                    'merchant': merchantController.text.trim(),
                    'category': categoryController.text.trim().isEmpty
                        ? (selectedCategory ?? 'Other')
                        : categoryController.text.trim(),
                  };
                  Navigator.of(context).pop(updatedExpense);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );

      // If result is not null, user confirmed the edit
      if (result != null) {
        // Update the expense in Firestore
        await _statsService.updateExpense(result);

        _showSnackBar('Expense updated successfully');
        _fetchExpenseData(); // Refresh the expense list
      }
    } catch (e) {
      debugPrint('Error updating expense: $e');
      _showSnackBar('Error updating expense: $e', isError: true);
    }
  }

  // SMS expense management
  Future<void> _saveSmsExpense(Map<String, dynamic> expense, int index) async {
    try {
      await _expenseService.saveExpenseAndUpdateBalance(expense);

      if (expense['smsId'] != null) {
        _processedSmsIds.add(expense['smsId'].toString());
      }

      setState(() => _smsExpenses.removeAt(index));
      _showSnackBar('Expense saved successfully');
      _fetchExpenseData();
    } catch (e) {
      _showSnackBar('Error saving expense: $e', isError: true);
    }
  }

  Future<void> _saveAllSmsExpenses() async {
    if (_smsExpenses.isEmpty) return;

    setState(() => _loadingSms = true);

    try {
      await _expenseService.saveExtractedExpenses(_smsExpenses);

      for (var expense in _smsExpenses) {
        if (expense['smsId'] != null) {
          _processedSmsIds.add(expense['smsId'].toString());
        }
      }

      _showSnackBar('Saved ${_smsExpenses.length} expenses');
      setState(() {
        _smsExpenses = [];
        _loadingSms = false;
      });

      _fetchExpenseData();
    } catch (e) {
      _showSnackBar('Error saving expenses: $e', isError: true);
      setState(() => _loadingSms = false);
    }
  }

  // UI change handlers
  void _onRangeChanged(TimeRange newRange) {
    if (_selectedRange != newRange) {
      setState(() => _selectedRange = newRange);
      _fetchExpenseData();
    }
  }

  void _onTabChanged(int index) {
    if (index == 1 && _smsExpenses.isEmpty) {
      _extractSmsExpenses();
    }
  }

  void _onRefreshPressed() {
    if (_tabController.index == 1) {
      _extractSmsExpenses();
    } else {
      _fetchExpenseData();
    }
  }

  // UI Widgets
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatsHeader(
              onRefresh: _onRefreshPressed,
              currentTabIndex: _tabController.index,
            ),
            StatsTabBar(
              tabController: _tabController,
              onTabChanged: _onTabChanged,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExpensesTab(),
                  _buildSmsExpensesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchExpenseData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  RangeSelector(
                    selectedRange: _selectedRange,
                    onRangeChanged: _onRangeChanged,
                  ),
                  const SizedBox(height: 16),
                  ExpenseSummaryCard(
                    selectedRange: _selectedRange,
                    currentPeriodTotal: _currentPeriodTotal,
                    percentageChange: _percentageChange,
                  ),
                  const SizedBox(height: 16),
                  CategoryPieChart(
                    expenses: _filteredExpenses,
                    totalAmount: _currentPeriodTotal,
                  ),
                  const SizedBox(height: 16),
                  ExpenseList(
                    expenses: _filteredExpenses,
                    onEditExpense: _editExpense,
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildSmsExpensesTab() {
    final localizations = AppLocalizations.of(context);

    if (_loadingSms) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_smsExpenses.isEmpty) {
      return EmptyStateWidget(
        title: localizations.noSmsExpensesFound,
        subtitle: localizations.tapRefreshButton,
        icon: Icons.message_outlined,
      );
    }

    return SmsExpensesList(
      smsExpenses: _smsExpenses,
      onSaveSmsExpense: _saveSmsExpense,
      onSaveAll: _saveAllSmsExpenses,
      isLoading: _loadingSms,
    );
  }
}
