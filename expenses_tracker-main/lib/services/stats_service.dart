import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expenses_tracker/screens/stats/enums.dart';

/// Service class for managing expense data and calculations for stats
class StatsService {
  /// Get date range based on the selected time range (daily, weekly, monthly)
  Map<String, DateTime> getDateRange(TimeRange range) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    DateTime previousStartDate;
    DateTime previousEndDate;

    switch (range) {
      case TimeRange.daily:
        startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
        previousEndDate = startDate.subtract(const Duration(milliseconds: 1));
        previousStartDate = DateTime(previousEndDate.year,
            previousEndDate.month, previousEndDate.day, 0, 0, 0);
        previousEndDate = DateTime(previousEndDate.year, previousEndDate.month,
            previousEndDate.day, 23, 59, 59);
        break;
      case TimeRange.weekly:
        final daysToSubtract = now.weekday % 7;
        startDate =
            DateTime(now.year, now.month, now.day - daysToSubtract, 0, 0, 0);
        previousEndDate = startDate.subtract(const Duration(milliseconds: 1));
        previousStartDate = DateTime(previousEndDate.year,
            previousEndDate.month, previousEndDate.day - 6, 0, 0, 0);
        break;
      case TimeRange.monthly:
        startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
        previousEndDate = startDate.subtract(const Duration(milliseconds: 1));
        previousStartDate =
            DateTime(previousEndDate.year, previousEndDate.month, 1, 0, 0, 0);
        break;
    }

    return {
      'startDate': startDate,
      'endDate': endDate,
      'previousStartDate': previousStartDate,
      'previousEndDate': previousEndDate,
    };
  }

  /// Load and process expenses for a given date range
  Future<Map<String, dynamic>> loadAndProcessExpenses(
      String userId, Map<String, DateTime> dateRange) async {
    // Load all expenses for the user
    final expensesSnapshot = await FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .get();

    // Process expense data
    List<Map<String, dynamic>> allExpenses = [];
    double currentTotal = 0.0;
    double previousTotal = 0.0;

    // Convert Firestore data to usable format
    for (var doc in expensesSnapshot.docs) {
      final data = doc.data();
      final timestamp = data['date'] as Timestamp?;
      if (timestamp == null) continue;

      allExpenses.add({
        'id': doc.id,
        ...data,
        'dateTime': timestamp.toDate(),
      });
    }

    // Filter and sort expenses
    final currentExpenses = filterExpensesForPeriod(
        allExpenses, dateRange['startDate']!, dateRange['endDate']!);
    currentExpenses.sort((a, b) =>
        (b['dateTime'] as DateTime).compareTo(a['dateTime'] as DateTime));

    // Calculate totals
    currentTotal = calculateTotalAmount(currentExpenses);

    // Get previous period expenses
    final previousExpenses = filterExpensesForPeriod(allExpenses,
        dateRange['previousStartDate']!, dateRange['previousEndDate']!);
    previousTotal = calculateTotalAmount(previousExpenses);

    // Calculate percentage change
    double percentageChange = 0.0;
    if (previousTotal > 0) {
      percentageChange = ((currentTotal - previousTotal) / previousTotal) * 100;
    }

    return {
      'currentExpenses': currentExpenses,
      'currentTotal': currentTotal,
      'previousTotal': previousTotal,
      'percentageChange': percentageChange,
    };
  }

  /// Filter expenses for a specific time period
  List<Map<String, dynamic>> filterExpensesForPeriod(
      List<Map<String, dynamic>> expenses,
      DateTime startDate,
      DateTime endDate) {
    return expenses.where((expense) {
      final expenseDate = expense['dateTime'] as DateTime;
      return (expenseDate.isAtSameMomentAs(startDate) ||
              expenseDate.isAfter(startDate)) &&
          (expenseDate.isAtSameMomentAs(endDate) ||
              expenseDate.isBefore(endDate));
    }).toList();
  }

  /// Calculate total amount from a list of expenses
  double calculateTotalAmount(List<Map<String, dynamic>> expenses) {
    return expenses.fold(0.0, (sum, expense) {
      if (expense['amount'] != null) {
        return sum + (expense['amount'] as num).toDouble();
      }
      return sum;
    });
  }

  /// Update an expense in Firestore
  Future<void> updateExpense(Map<String, dynamic> expense) async {
    await FirebaseFirestore.instance
        .collection('expenses')
        .doc(expense['id'])
        .update({
      'merchant': expense['merchant'],
      'category': expense['category'],
    });
  }

  /// Get current user ID or null if not logged in
  String? getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  /// Fetch expense data based on the selected time range
  Future<Map<String, dynamic>> fetchExpenseData(TimeRange selectedRange) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      return {
        'currentTotal': 0.0,
        'percentageChange': 0.0,
        'filteredExpenses': <Map<String, dynamic>>[],
      };
    }

    final dateRange = getDateRange(selectedRange);
    final results = await loadAndProcessExpenses(userId, dateRange);

    return {
      'currentTotal': results['currentTotal'] ?? 0.0,
      'percentageChange': results['percentageChange'] ?? 0.0,
      'filteredExpenses':
          results['currentExpenses'] ?? <Map<String, dynamic>>[],
    };
  }
}
