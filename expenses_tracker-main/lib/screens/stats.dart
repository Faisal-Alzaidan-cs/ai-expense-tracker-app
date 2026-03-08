// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:fl_chart/fl_chart.dart';
// import '../services/sms_service.dart';
// import '../services/expense_service.dart';

// enum TimeRange { daily, weekly, monthly }

// class StatsScreen extends StatefulWidget {
//   const StatsScreen({super.key});

//   @override
//   State<StatsScreen> createState() => _StatsScreenState();
// }

// class _StatsScreenState extends State<StatsScreen>
//     with SingleTickerProviderStateMixin {
//   // Core state variables
//   TimeRange _selectedRange = TimeRange.weekly;
//   bool _isLoading = false;
//   double _currentPeriodTotal = 0.0;
//   double _percentageChange = 0.0;
//   List<Map<String, dynamic>> _filteredExpenses = [];

//   // SMS expenses state
//   late TabController _tabController;
//   final SmsService _smsService = SmsService();
//   final ExpenseService _expenseService = ExpenseService();
//   List<Map<String, dynamic>> _smsExpenses = [];
//   Set<String> _processedSmsIds = {};
//   bool _loadingSms = false;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _fetchExpenseData();
//     _loadProcessedSmsIds();
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   // Helper methods for SMS expense management
//   Future<void> _loadProcessedSmsIds() async {
//     _processedSmsIds = await _expenseService.loadProcessedSmsIds();
//     if (mounted) setState(() {});
//   }

//   Future<void> _extractSmsExpenses() async {
//     if (_loadingSms) return;
//     setState(() => _loadingSms = true);

//     try {
//       await _loadProcessedSmsIds();
//       final hasPermission = await _smsService.requestSmsPermission();

//       if (!hasPermission) {
//         _showSnackBar('SMS permission denied');
//         setState(() => _loadingSms = false);
//         return;
//       }

//       final extractedExpenses = await _smsService.extractExpensesFromSms(
//         processedSmsIds: _processedSmsIds,
//       );

//       if (mounted) {
//         setState(() {
//           _smsExpenses = extractedExpenses;
//           _loadingSms = false;
//         });
//       }

//       if (extractedExpenses.isEmpty) {
//         _showSnackBar('No new expenses found in SMS');
//       }
//     } catch (e) {
//       debugPrint("❌ Error extracting SMS expenses: $e");
//       _showSnackBar('Error extracting expenses: $e', isError: true);
//       if (mounted) setState(() => _loadingSms = false);
//     }
//   }

//   void _showSnackBar(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red : null,
//       ),
//     );
//   }

//   // Methods for date management
//   Map<String, DateTime> _getDateRange(TimeRange range) {
//     final now = DateTime.now();
//     DateTime startDate;
//     DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
//     DateTime previousStartDate;
//     DateTime previousEndDate;

//     switch (range) {
//       case TimeRange.daily:
//         startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
//         previousEndDate = startDate.subtract(const Duration(milliseconds: 1));
//         previousStartDate = DateTime(previousEndDate.year,
//             previousEndDate.month, previousEndDate.day, 0, 0, 0);
//         previousEndDate = DateTime(previousEndDate.year, previousEndDate.month,
//             previousEndDate.day, 23, 59, 59);
//         break;
//       case TimeRange.weekly:
//         final daysToSubtract = now.weekday % 7;
//         startDate =
//             DateTime(now.year, now.month, now.day - daysToSubtract, 0, 0, 0);
//         previousEndDate = startDate.subtract(const Duration(milliseconds: 1));
//         previousStartDate = DateTime(previousEndDate.year,
//             previousEndDate.month, previousEndDate.day - 6, 0, 0, 0);
//         break;
//       case TimeRange.monthly:
//         startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
//         previousEndDate = startDate.subtract(const Duration(milliseconds: 1));
//         previousStartDate =
//             DateTime(previousEndDate.year, previousEndDate.month, 1, 0, 0, 0);
//         break;
//     }

//     return {
//       'startDate': startDate,
//       'endDate': endDate,
//       'previousStartDate': previousStartDate,
//       'previousEndDate': previousEndDate,
//     };
//   }

//   // Core expense data retrieval and processing
//   Future<void> _fetchExpenseData() async {
//     if (FirebaseAuth.instance.currentUser == null) return;

//     setState(() => _isLoading = true);

//     try {
//       final userId = FirebaseAuth.instance.currentUser!.uid;
//       final dateRange = _getDateRange(_selectedRange);
//       final expenses = await _loadAndProcessExpenses(userId, dateRange);

//       if (mounted) {
//         setState(() {
//           _currentPeriodTotal = expenses['currentTotal'] ?? 0.0;
//           _percentageChange = expenses['percentageChange'] ?? 0.0;
//           _filteredExpenses = expenses['currentExpenses'] ?? [];
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error fetching expense data: $e');
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   Future<Map<String, dynamic>> _loadAndProcessExpenses(
//       String userId, Map<String, DateTime> dateRange) async {
//     // Load all expenses for the user
//     final expensesSnapshot = await FirebaseFirestore.instance
//         .collection('expenses')
//         .where('userId', isEqualTo: userId)
//         .get();

//     // Process expense data
//     List<Map<String, dynamic>> allExpenses = [];
//     double currentTotal = 0.0;
//     double previousTotal = 0.0;

//     // Convert Firestore data to usable format
//     for (var doc in expensesSnapshot.docs) {
//       final data = doc.data();
//       final timestamp = data['date'] as Timestamp?;
//       if (timestamp == null) continue;

//       allExpenses.add({
//         'id': doc.id,
//         ...data,
//         'dateTime': timestamp.toDate(),
//       });
//     }

//     // Filter and sort expenses
//     final currentExpenses = _filterExpensesForPeriod(
//         allExpenses, dateRange['startDate']!, dateRange['endDate']!);
//     currentExpenses.sort((a, b) =>
//         (b['dateTime'] as DateTime).compareTo(a['dateTime'] as DateTime));

//     // Calculate totals
//     currentTotal = _calculateTotalAmount(currentExpenses);

//     // Get previous period expenses
//     final previousExpenses = _filterExpensesForPeriod(allExpenses,
//         dateRange['previousStartDate']!, dateRange['previousEndDate']!);
//     previousTotal = _calculateTotalAmount(previousExpenses);

//     // Calculate percentage change
//     double percentageChange = 0.0;
//     if (previousTotal > 0) {
//       percentageChange = ((currentTotal - previousTotal) / previousTotal) * 100;
//     }

//     return {
//       'currentExpenses': currentExpenses,
//       'currentTotal': currentTotal,
//       'previousTotal': previousTotal,
//       'percentageChange': percentageChange,
//     };
//   }

//   List<Map<String, dynamic>> _filterExpensesForPeriod(
//       List<Map<String, dynamic>> expenses,
//       DateTime startDate,
//       DateTime endDate) {
//     return expenses.where((expense) {
//       final expenseDate = expense['dateTime'] as DateTime;
//       return (expenseDate.isAtSameMomentAs(startDate) ||
//               expenseDate.isAfter(startDate)) &&
//           (expenseDate.isAtSameMomentAs(endDate) ||
//               expenseDate.isBefore(endDate));
//     }).toList();
//   }

//   double _calculateTotalAmount(List<Map<String, dynamic>> expenses) {
//     return expenses.fold(0.0, (sum, expense) {
//       if (expense['amount'] != null) {
//         return sum + (expense['amount'] as num).toDouble();
//       }
//       return sum;
//     });
//   }

//   // Method to handle editing an expense
//   Future<void> _editExpense(Map<String, dynamic> expense) async {
//     try {
//       final TextEditingController merchantController =
//           TextEditingController(text: expense['merchant'] ?? '');
//       final TextEditingController categoryController =
//           TextEditingController(text: expense['category'] ?? '');
//       String? selectedCategory = expense['category'];

//       // List of common expense categories
//       final List<String> categories = [
//         'Food',
//         'Coffee',
//         'Transport',
//         'Shopping',
//         'Entertainment',
//         'Bills',
//         'Health',
//         'Travel',
//         'Education',
//         'Other'
//       ];

//       final result = await showDialog<Map<String, dynamic>>(
//         context: context,
//         builder: (context) => StatefulBuilder(
//           builder: (context, setState) => AlertDialog(
//             title: const Text('Edit Expense'),
//             content: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   TextField(
//                     controller: merchantController,
//                     decoration: const InputDecoration(
//                       labelText: 'Merchant',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   const Text('Category:'),
//                   const SizedBox(height: 8),
//                   Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: categories.map((category) {
//                       return ChoiceChip(
//                         label: Text(category),
//                         selected: selectedCategory == category,
//                         onSelected: (selected) {
//                           setState(() {
//                             selectedCategory = selected ? category : null;
//                             if (selected) {
//                               categoryController.text = category;
//                             }
//                           });
//                         },
//                       );
//                     }).toList(),
//                   ),
//                   const SizedBox(height: 16),
//                   TextField(
//                     controller: categoryController,
//                     decoration: const InputDecoration(
//                       labelText: 'Custom Category',
//                       hintText: 'Or enter a custom category',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     'Amount: SAR ${(expense['amount'] as num).toStringAsFixed(2)}',
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   const Text('(Amount cannot be modified)',
//                       style:
//                           TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () {
//                   final updatedExpense = {
//                     ...expense,
//                     'merchant': merchantController.text.trim(),
//                     'category': categoryController.text.trim().isEmpty
//                         ? (selectedCategory ?? 'Other')
//                         : categoryController.text.trim(),
//                   };
//                   Navigator.of(context).pop(updatedExpense);
//                 },
//                 child: const Text('Save'),
//               ),
//             ],
//           ),
//         ),
//       );

//       // If result is not null, user confirmed the edit
//       if (result != null) {
//         // Update the expense in Firestore
//         await FirebaseFirestore.instance
//             .collection('expenses')
//             .doc(expense['id'])
//             .update({
//           'merchant': result['merchant'],
//           'category': result['category'],
//         });

//         _showSnackBar('Expense updated successfully');
//         _fetchExpenseData(); // Refresh the expense list
//       }
//     } catch (e) {
//       debugPrint('Error updating expense: $e');
//       _showSnackBar('Error updating expense: $e', isError: true);
//     }
//   }

//   // SMS expense management
//   Future<void> _saveSmsExpense(Map<String, dynamic> expense, int index) async {
//     try {
//       await _expenseService.saveExpenseAndUpdateBalance(expense);

//       if (expense['smsId'] != null) {
//         _processedSmsIds.add(expense['smsId'].toString());
//       }

//       setState(() => _smsExpenses.removeAt(index));
//       _showSnackBar('Expense saved successfully');
//       _fetchExpenseData();
//     } catch (e) {
//       _showSnackBar('Error saving expense: $e', isError: true);
//     }
//   }

//   Future<void> _saveAllSmsExpenses() async {
//     if (_smsExpenses.isEmpty) return;

//     setState(() => _loadingSms = true);

//     try {
//       await _expenseService.saveExtractedExpenses(_smsExpenses);

//       for (var expense in _smsExpenses) {
//         if (expense['smsId'] != null) {
//           _processedSmsIds.add(expense['smsId'].toString());
//         }
//       }

//       _showSnackBar('Saved ${_smsExpenses.length} expenses');
//       setState(() {
//         _smsExpenses = [];
//         _loadingSms = false;
//       });

//       _fetchExpenseData();
//     } catch (e) {
//       _showSnackBar('Error saving expenses: $e', isError: true);
//       setState(() => _loadingSms = false);
//     }
//   }

//   // UI change handlers
//   void _onRangeChanged(TimeRange newRange) {
//     if (_selectedRange != newRange) {
//       setState(() => _selectedRange = newRange);
//       _fetchExpenseData();
//     }
//   }

//   // Helper text methods
//   String _getRangeTitle() {
//     switch (_selectedRange) {
//       case TimeRange.daily:
//         return 'Your Total Spending Today';
//       case TimeRange.weekly:
//         return 'Your Total Spending This Week';
//       case TimeRange.monthly:
//         return 'Your Total Spending This Month';
//     }
//   }

//   String _getComparisonText() {
//     final direction = _percentageChange >= 0 ? 'more' : 'less';
//     final percentage = _percentageChange.abs().toStringAsFixed(1);

//     switch (_selectedRange) {
//       case TimeRange.daily:
//         return '$percentage% $direction than yesterday';
//       case TimeRange.weekly:
//         return '$percentage% $direction than last week';
//       case TimeRange.monthly:
//         return '$percentage% $direction than last month';
//     }
//   }

//   // UI Widgets
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.blue.shade50, Colors.white],
//           ),
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildHeader(),
//             _buildTabBar(),
//             Expanded(
//               child: TabBarView(
//                 controller: _tabController,
//                 children: [
//                   _buildExpensesTab(),
//                   _buildSmsExpensesTab(),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.only(bottom: 16.0),
//           child: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.shade700,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Icon(
//                   Icons.insights,
//                   color: Colors.white,
//                   size: 20,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               const Text(
//                 "Insights",
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   letterSpacing: 0.5,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const Spacer(),
//         FloatingActionButton(
//           mini: true,
//           onPressed: () => _tabController.index == 1
//               ? _extractSmsExpenses()
//               : _fetchExpenseData(),
//           backgroundColor: Colors.blue.shade700,
//           child: Icon(_tabController.index == 1 ? Icons.message : Icons.refresh,
//               size: 20),
//         ),
//       ],
//     );
//   }

//   Widget _buildTabBar() {
//     return Container(
//       decoration: BoxDecoration(
//         border: Border(
//           bottom: BorderSide(
//             color: Colors.grey.shade300,
//             width: 1.0,
//           ),
//         ),
//       ),
//       child: TabBar(
//         controller: _tabController,
//         indicatorColor: Colors.blue.shade700,
//         indicatorWeight: 3.0,
//         labelColor: Colors.blue.shade700,
//         labelStyle: const TextStyle(
//           fontWeight: FontWeight.bold,
//           fontSize: 16,
//         ),
//         unselectedLabelColor: Colors.grey.shade600,
//         tabs: const [
//           Tab(
//             text: "Expenses",
//             icon: Icon(Icons.account_balance_wallet, size: 20),
//           ),
//           Tab(
//             text: "SMS Expenses",
//             icon: Icon(Icons.message, size: 20),
//           ),
//         ],
//         onTap: (index) {
//           if (index == 1 && _smsExpenses.isEmpty) {
//             _extractSmsExpenses();
//           }
//         },
//       ),
//     );
//   }

//   Widget _buildExpensesTab() {
//     return _isLoading
//         ? const Center(child: CircularProgressIndicator())
//         : RefreshIndicator(
//             onRefresh: _fetchExpenseData,
//             child: SingleChildScrollView(
//               physics: const AlwaysScrollableScrollPhysics(),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const SizedBox(height: 16),
//                   _buildRangeSelector(),
//                   const SizedBox(height: 16),
//                   _buildExpenseInspectorCard(),
//                   const SizedBox(height: 16),
//                   _buildCategoryPieChart(),
//                   const SizedBox(height: 16),
//                   _buildExpenseList(),
//                 ],
//               ),
//             ),
//           );
//   }

//   Widget _buildRangeSelector() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             _buildRangeButton(TimeRange.daily, 'Daily'),
//             _buildRangeButton(TimeRange.weekly, 'Weekly'),
//             _buildRangeButton(TimeRange.monthly, 'Monthly'),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRangeButton(TimeRange range, String label) {
//     final isSelected = _selectedRange == range;
//     return Expanded(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 4.0),
//         child: ElevatedButton(
//           onPressed: () => _onRangeChanged(range),
//           style: ElevatedButton.styleFrom(
//             backgroundColor:
//                 isSelected ? Colors.blue.shade700 : Colors.grey.shade200,
//             foregroundColor: isSelected ? Colors.white : Colors.black87,
//             elevation: isSelected ? 2 : 0,
//             padding: const EdgeInsets.symmetric(vertical: 10),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//           child: Text(
//             label,
//             style: TextStyle(
//               fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//               fontSize: 13,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildExpenseInspectorCard() {
//     final comparisonColor =
//         _percentageChange >= 0 ? Colors.red.shade700 : Colors.green.shade700;

//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         width: double.infinity,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [Colors.blue.shade700, Colors.blue.shade900],
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               _getRangeTitle(),
//               style: const TextStyle(
//                 color: Colors.white70,
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'SAR ${_currentPeriodTotal.toStringAsFixed(2)}',
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             if (_percentageChange != 0)
//               Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.15),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       _percentageChange >= 0
//                           ? Icons.arrow_upward
//                           : Icons.arrow_downward,
//                       color: _percentageChange >= 0
//                           ? Colors.red.shade300
//                           : Colors.green.shade300,
//                       size: 16,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       _getComparisonText(),
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.9),
//                         fontSize: 12,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCategoryPieChart() {
//     if (_filteredExpenses.isEmpty) {
//       return _buildEmptyState(
//         "No expenses in this period",
//         "Try selecting a different time range",
//         Icons.pie_chart,
//       );
//     }

//     // Calculate and sort expenses by category
//     final categorySums = <String, double>{};
//     for (var expense in _filteredExpenses) {
//       final category = expense['category'] ?? 'Other';
//       categorySums[category] =
//           (categorySums[category] ?? 0) + expense['amount'];
//     }

//     // Calculate percentages and prepare data
//     final categories = categorySums.keys.toList();
//     categories.sort((a, b) => categorySums[b]!.compareTo(categorySums[a]!));

//     // Generate unique colors for categories
//     final colors = [
//       Colors.blue.shade700,
//       Colors.green.shade600,
//       Colors.purple.shade500,
//       Colors.orange.shade600,
//       Colors.teal.shade500,
//       Colors.red.shade500,
//       Colors.indigo.shade500,
//       Colors.amber.shade600,
//       Colors.pink.shade400,
//       Colors.lime.shade600,
//     ];

//     // Prepare pie sections and legends
//     final sections = <PieChartSectionData>[];
//     final legends = <Widget>[];

//     for (int i = 0; i < categories.length; i++) {
//       final category = categories[i];
//       final amount = categorySums[category]!;
//       final percentage = (amount / _currentPeriodTotal) * 100;
//       final color = i < colors.length ? colors[i] : Colors.grey.shade500;

//       // Add pie section
//       sections.add(
//         PieChartSectionData(
//           color: color,
//           value: amount,
//           title: percentage >= 5 ? '${percentage.toStringAsFixed(1)}%' : '',
//           radius: 60,
//           titleStyle: const TextStyle(
//             color: Colors.white,
//             fontSize: 12,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       );

//       // Add legend
//       legends.add(
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 1.0),
//           child: Row(
//             children: [
//               Container(
//                 width: 14,
//                 height: 14,
//                 decoration: BoxDecoration(
//                   color: color,
//                   shape: BoxShape.circle,
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   category,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w500,
//                     fontSize: 13,
//                   ),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               Text(
//                 'SAR ${amount.toStringAsFixed(2)}',
//                 style: TextStyle(
//                   color: Colors.grey.shade700,
//                   fontWeight: FontWeight.w500,
//                   fontSize: 13,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       color: Colors.white,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Padding(
//               padding: EdgeInsets.only(bottom: 16.0),
//               child: Text(
//                 'Spending by Category',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 SizedBox(
//                   height: 180,
//                   width: 180,
//                   child: PieChart(
//                     PieChartData(
//                       sections: sections,
//                       centerSpaceRadius: 30,
//                       sectionsSpace: 2,
//                       borderData: FlBorderData(show: false),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: legends,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildExpenseList() {
//     if (_filteredExpenses.isEmpty) {
//       return const SizedBox.shrink();
//     }

//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Padding(
//               padding: EdgeInsets.only(bottom: 16.0),
//               child: Text(
//                 'Recent Expenses',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             ListView.separated(
//               physics: const NeverScrollableScrollPhysics(),
//               shrinkWrap: true,
//               itemCount:
//                   _filteredExpenses.length > 10 ? 10 : _filteredExpenses.length,
//               separatorBuilder: (context, index) => Divider(
//                 color: Colors.grey.shade200,
//                 height: 1,
//               ),
//               itemBuilder: (context, index) {
//                 final expense = _filteredExpenses[index];
//                 final date = expense['dateTime'] as DateTime;
//                 final category = expense['category'] ?? 'Other';

//                 // Generate a consistent color for the category
//                 final colors = {
//                   'Food': Colors.orange.shade700,
//                   'Coffee': Colors.brown.shade600,
//                   'Transport': Colors.blue.shade700,
//                   'Shopping': Colors.purple.shade700,
//                   'Entertainment': Colors.pink.shade600,
//                   'Bills': Colors.red.shade600,
//                   'Health': Colors.green.shade600,
//                   'Travel': Colors.teal.shade600,
//                   'Education': Colors.indigo.shade600,
//                   'Other': Colors.grey.shade700,
//                 };

//                 final color = colors[category] ?? Colors.grey.shade700;

//                 return ListTile(
//                   contentPadding: EdgeInsets.zero,
//                   leading: CircleAvatar(
//                     backgroundColor: color.withOpacity(0.2),
//                     child: Icon(
//                       _getCategoryIcon(category),
//                       color: color,
//                       size: 20,
//                     ),
//                   ),
//                   title: Text(
//                     expense['merchant'] ?? 'Unknown Merchant',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w600,
//                       fontSize: 15,
//                     ),
//                   ),
//                   subtitle: Text(
//                     '${_formatDate(date)} • $category',
//                     style: TextStyle(
//                       color: Colors.grey.shade600,
//                       fontSize: 13,
//                     ),
//                   ),
//                   trailing: Text(
//                     'SAR ${expense['amount'].toStringAsFixed(2)}',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 14,
//                     ),
//                   ),
//                   onTap: () => _editExpense(expense),
//                 );
//               },
//             ),
//             if (_filteredExpenses.length > 10)
//               Padding(
//                 padding: const EdgeInsets.only(top: 12.0),
//                 child: Center(
//                   child: TextButton.icon(
//                     onPressed: () {
//                       // Show all expenses in a modal
//                       showModalBottomSheet(
//                         context: context,
//                         isScrollControlled: true,
//                         shape: const RoundedRectangleBorder(
//                           borderRadius: BorderRadius.vertical(
//                             top: Radius.circular(20),
//                           ),
//                         ),
//                         builder: (context) => DraggableScrollableSheet(
//                           initialChildSize: 0.7,
//                           maxChildSize: 0.9,
//                           minChildSize: 0.5,
//                           expand: false,
//                           builder: (context, scrollController) =>
//                               _buildFullExpenseList(scrollController),
//                         ),
//                       );
//                     },
//                     icon: const Icon(Icons.visibility),
//                     label: const Text('View All Expenses'),
//                     style: TextButton.styleFrom(
//                       foregroundColor: Colors.blue.shade700,
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildFullExpenseList(ScrollController scrollController) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Text(
//                 'All Expenses',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const Spacer(),
//               IconButton(
//                 icon: const Icon(Icons.close),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ],
//           ),
//           const Divider(),
//           Expanded(
//             child: ListView.separated(
//               controller: scrollController,
//               itemCount: _filteredExpenses.length,
//               separatorBuilder: (context, index) => Divider(
//                 color: Colors.grey.shade200,
//                 height: 1,
//               ),
//               itemBuilder: (context, index) {
//                 final expense = _filteredExpenses[index];
//                 final date = expense['dateTime'] as DateTime;
//                 final category = expense['category'] ?? 'Other';

//                 // Reuse the same color mapping as in _buildExpenseList
//                 final colors = {
//                   'Food': Colors.orange.shade700,
//                   'Coffee': Colors.brown.shade600,
//                   'Transport': Colors.blue.shade700,
//                   'Shopping': Colors.purple.shade700,
//                   'Entertainment': Colors.pink.shade600,
//                   'Bills': Colors.red.shade600,
//                   'Health': Colors.green.shade600,
//                   'Travel': Colors.teal.shade600,
//                   'Education': Colors.indigo.shade600,
//                   'Other': Colors.grey.shade700,
//                 };

//                 final color = colors[category] ?? Colors.grey.shade700;

//                 return ListTile(
//                   contentPadding: EdgeInsets.zero,
//                   leading: CircleAvatar(
//                     backgroundColor: color.withOpacity(0.2),
//                     child: Icon(
//                       _getCategoryIcon(category),
//                       color: color,
//                       size: 20,
//                     ),
//                   ),
//                   title: Text(
//                     expense['merchant'] ?? 'Unknown Merchant',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w600,
//                       fontSize: 15,
//                     ),
//                   ),
//                   subtitle: Text(
//                     '${_formatDate(date, includeTime: true)} • $category',
//                     style: TextStyle(
//                       color: Colors.grey.shade600,
//                       fontSize: 13,
//                     ),
//                   ),
//                   trailing: Text(
//                     'SAR ${expense['amount'].toStringAsFixed(2)}',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 14,
//                     ),
//                   ),
//                   onTap: () => _editExpense(expense),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSmsExpensesTab() {
//     if (_loadingSms) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (_smsExpenses.isEmpty) {
//       return _buildEmptyState(
//         "No SMS expenses found",
//         "Tap the refresh button to scan your messages for expenses",
//         Icons.message_outlined,
//       );
//     }

//     return Column(
//       children: [
//         const SizedBox(height: 16),
//         Card(
//           elevation: 2,
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'SMS Expenses',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           Text(
//                             'Found ${_smsExpenses.length} expenses from SMS',
//                             style: TextStyle(
//                               color: Colors.grey.shade600,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     ElevatedButton.icon(
//                       onPressed: _saveAllSmsExpenses,
//                       icon: const Icon(Icons.save, size: 18),
//                       label: const Text('Save All'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blue.shade700,
//                         foregroundColor: Colors.white,
//                         elevation: 2,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(height: 16),
//         Expanded(
//           child: ListView.builder(
//             itemCount: _smsExpenses.length,
//             itemBuilder: (context, index) {
//               final expense = _smsExpenses[index];

//               return Dismissible(
//                 key: Key(expense['smsId']?.toString() ?? index.toString()),
//                 background: Container(
//                   alignment: Alignment.centerRight,
//                   padding: const EdgeInsets.only(right: 20),
//                   color: Colors.green.shade700,
//                   child: const Icon(
//                     Icons.save,
//                     color: Colors.white,
//                   ),
//                 ),
//                 direction: DismissDirection.endToStart,
//                 onDismissed: (direction) => _saveSmsExpense(expense, index),
//                 child: Card(
//                   margin: const EdgeInsets.only(bottom: 12),
//                   elevation: 2,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             CircleAvatar(
//                               backgroundColor: Colors.blue.shade50,
//                               child: Icon(
//                                 Icons.sms,
//                                 color: Colors.blue.shade700,
//                                 size: 20,
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     expense['merchant'] ?? 'Unknown Merchant',
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 16,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 4),
//                                   Text(
//                                     expense['smsBody'] ?? '',
//                                     style: TextStyle(
//                                       color: Colors.grey.shade600,
//                                       fontSize: 14,
//                                     ),
//                                     maxLines: 2,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                         const Divider(height: 24),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Date',
//                                   style: TextStyle(
//                                     color: Colors.grey.shade600,
//                                     fontSize: 13,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   _formatDate(expense['dateTime'] as DateTime?,
//                                           includeTime: true) ??
//                                       'Unknown Date',
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.w500,
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             Column(
//                               crossAxisAlignment: CrossAxisAlignment.end,
//                               children: [
//                                 Text(
//                                   'Amount',
//                                   style: TextStyle(
//                                     color: Colors.grey.shade600,
//                                     fontSize: 13,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   'SAR ${expense['amount']?.toStringAsFixed(2) ?? '0.00'}',
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 16,
//                                     color: Colors.black,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 16),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                           children: [
//                             Expanded(
//                               child: OutlinedButton.icon(
//                                 onPressed: () {
//                                   setState(() => _smsExpenses.removeAt(index));
//                                 },
//                                 icon:
//                                     const Icon(Icons.delete_outline, size: 18),
//                                 label: const Text('Ignore'),
//                                 style: OutlinedButton.styleFrom(
//                                   foregroundColor: Colors.grey.shade700,
//                                   side: BorderSide(color: Colors.grey.shade300),
//                                   padding:
//                                       const EdgeInsets.symmetric(vertical: 12),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: ElevatedButton.icon(
//                                 onPressed: () =>
//                                     _saveSmsExpense(expense, index),
//                                 icon: const Icon(Icons.save, size: 18),
//                                 label: const Text('Save'),
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.blue.shade700,
//                                   foregroundColor: Colors.white,
//                                   elevation: 1,
//                                   padding:
//                                       const EdgeInsets.symmetric(vertical: 12),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildEmptyState(String title, String subtitle, IconData icon) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.blue.shade50,
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 icon,
//                 size: 48,
//                 color: Colors.blue.shade700,
//               ),
//             ),
//             const SizedBox(height: 24),
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               subtitle,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey.shade600,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   IconData _getCategoryIcon(String category) {
//     final Map<String, IconData> categoryIcons = {
//       'Food': Icons.restaurant,
//       'Coffee': Icons.coffee,
//       'Transport': Icons.directions_car,
//       'Shopping': Icons.shopping_bag,
//       'Entertainment': Icons.movie,
//       'Bills': Icons.receipt_long,
//       'Health': Icons.medical_services,
//       'Travel': Icons.flight,
//       'Education': Icons.school,
//       'Other': Icons.category,
//     };

//     return categoryIcons[category] ?? Icons.attach_money;
//   }

//   String? _formatDate(DateTime? date, {bool includeTime = false}) {
//     if (date == null) return null;

//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final yesterday = today.subtract(const Duration(days: 1));
//     final dateOnly = DateTime(date.year, date.month, date.day);

//     if (dateOnly == today) {
//       return includeTime ? 'Today, ${_formatTime(date)}' : 'Today';
//     } else if (dateOnly == yesterday) {
//       return includeTime ? 'Yesterday, ${_formatTime(date)}' : 'Yesterday';
//     }

//     return includeTime
//         ? '${_formatDateShort(date)}, ${_formatTime(date)}'
//         : _formatDateShort(date);
//   }

//   String _formatDateShort(DateTime date) {
//     final months = [
//       'Jan',
//       'Feb',
//       'Mar',
//       'Apr',
//       'May',
//       'Jun',
//       'Jul',
//       'Aug',
//       'Sep',
//       'Oct',
//       'Nov',
//       'Dec'
//     ];
//     return '${date.day} ${months[date.month - 1]}';
//   }

//   String _formatTime(DateTime date) {
//     final hour =
//         date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
//     final minute = date.minute.toString().padLeft(2, '0');
//     final period = date.hour >= 12 ? 'PM' : 'AM';
//     return '$hour:$minute $period';
//   }
// }
