import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expenses_tracker/services/ai_api.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class SmartBudgetAdvisorScreen extends StatefulWidget {
  const SmartBudgetAdvisorScreen({Key? key}) : super(key: key);

  @override
  State<SmartBudgetAdvisorScreen> createState() =>
      _SmartBudgetAdvisorScreenState();
}

class _SmartBudgetAdvisorScreenState extends State<SmartBudgetAdvisorScreen> {
  final AIApi _aiApi = AIApi.instance;
  bool _isLoading = true;
  bool _isGeneratingBudget = false;
  Map<String, dynamic>? _budgetRecommendation;
  String? _errorMessage;
  Map<String, double> _categoryTotals = {};
  double _totalSpending = 0;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _fetchUserExpenses();
  }

  Future<void> _fetchUserExpenses() async {
    if (_userId.isEmpty) {
      setState(() {
        _errorMessage = "User not logged in";
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Calculate date range (last 3 months)
      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);

      debugPrint('Fetching expenses for user: $_userId');
      debugPrint(
          'Date range: ${threeMonthsAgo.toIso8601String()} to ${now.toIso8601String()}');

      // Convert to Timestamps for Firestore if needed
      final threeMonthsAgoTimestamp = Timestamp.fromDate(threeMonthsAgo);

      // First try to get data - attempt with Timestamp comparison
      try {
        final expensesSnapshot = await FirebaseFirestore.instance
            .collection('expenses')
            .where('userId', isEqualTo: _userId)
            .where('date', isGreaterThanOrEqualTo: threeMonthsAgoTimestamp)
            .orderBy('date', descending: true)
            .get();

        debugPrint('Fetched ${expensesSnapshot.docs.length} expenses');

        // Process expense data by category
        _processExpenseData(expensesSnapshot.docs);
      } catch (firestoreError) {
        debugPrint(
            'Error fetching with Timestamp, trying with DateTime: $firestoreError');

        // Alternative query without date filter if that's the issue
        final expensesSnapshot = await FirebaseFirestore.instance
            .collection('expenses')
            .where('userId', isEqualTo: _userId)
            .orderBy('date', descending: true)
            .get();

        debugPrint(
            'Fetched ${expensesSnapshot.docs.length} expenses without date filter');

        // Process expense data, but filter dates manually
        _processExpenseData(expensesSnapshot.docs.where((doc) {
          final expense = doc.data();
          final expenseDate = expense['date'];

          // Handle different date formats in Firestore
          DateTime? date;
          if (expenseDate is Timestamp) {
            date = expenseDate.toDate();
          } else if (expenseDate is DateTime) {
            date = expenseDate;
          } else if (expenseDate is String) {
            try {
              date = DateTime.parse(expenseDate);
            } catch (_) {}
          }

          return date != null && date.isAfter(threeMonthsAgo);
        }).toList());
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error in _fetchUserExpenses: $e');
      setState(() {
        _errorMessage = "Error fetching expense data: $e";
        _isLoading = false;
      });
    }
  }

  void _processExpenseData(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    _categoryTotals = {};
    _totalSpending = 0;

    for (var doc in docs) {
      final expense = doc.data();
      final category = expense['category'] ?? 'Other';

      // Safely convert amount to double, handling different data types
      double amount = 0.0;
      final rawAmount = expense['amount'];

      if (rawAmount is num) {
        amount = rawAmount.toDouble();
      } else if (rawAmount is String) {
        amount = double.tryParse(rawAmount) ?? 0.0;
      }

      _categoryTotals[category] = (_categoryTotals[category] ?? 0) + amount;
      _totalSpending += amount;
    }

    debugPrint('Processed ${docs.length} expenses, total: $_totalSpending');
    debugPrint('Categories: ${_categoryTotals.keys.join(', ')}');

    // Generate budget recommendation if we have data
    if (docs.isNotEmpty) {
      _generateBudgetRecommendation();
    }
  }

  Future<void> _generateBudgetRecommendation() async {
    if (_categoryTotals.isEmpty) {
      setState(() {
        _errorMessage = "No expense data available for budget recommendation";
      });
      return;
    }

    setState(() {
      _isGeneratingBudget = true;
      _errorMessage = null;
    });

    try {
      // Convert category totals to formatted string for AI prompt
      final categoryDataString = _categoryTotals.entries
          .map((e) => "${e.key}: SAR ${e.value.toStringAsFixed(2)}")
          .join(", ");

      // Prepare messages for AI API
      final messages = [
        {
          'role': 'system',
          'content':
              '''You are a smart financial budget advisor for the Expense Tracker app.
          Your task is to analyze a user's spending patterns and recommend an optimized monthly budget.
          
          Based on their spending data, provide:
          1. An overall monthly budget recommendation
          2. Category-specific budget allocations
          3. Savings recommendations
          4. Areas where they can potentially reduce spending
          
          Format your response as a valid JSON object with these fields:
          - "summary": A 1-2 sentence overview of the budget recommendation
          - "monthlyBudget": Recommended total monthly budget as a number
          - "categoryBudgets": Object with category names as keys and recommended budget amounts as numeric values
          - "savingsTarget": Recommended monthly savings amount as a number
          - "savingsPercentage": Recommended savings as a percentage of income (number)
          - "reductionAreas": Array of 2-3 categories where spending can be reduced
          - "reductionTips": Array of 3-4 practical tips to reduce spending
          
          Today's date is ${DateFormat('yyyy-MM-dd').format(DateTime.now())}.
          '''
        },
        {
          'role': 'user',
          'content':
              '''Analyze my spending patterns and recommend a monthly budget.
          
          My average monthly spending over the last 3 months:
          Total: SAR ${_totalSpending / 3}
          Breakdown by category: ${categoryDataString}
          
          Please provide a complete budget recommendation based on this data.
          '''
        }
      ];

      // Get the response from AI
      final response = await _aiApi.chatCompletion(
        messages: messages,
        temperature: 0.5,
      );

      // Parse the JSON response
      final parsedJson = jsonDecode(response);

      setState(() {
        _budgetRecommendation = parsedJson;
        _isGeneratingBudget = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error generating budget recommendation: $e";
        _isGeneratingBudget = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Smart Budget Advisor",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF00C6FF),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.red),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchUserExpenses,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your Spending Patterns",
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Spending visualization card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Last 3 Months Average",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00C6FF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "SAR ${(_totalSpending / 3).toStringAsFixed(2)} / month",
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Top Spending Categories",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00C6FF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _categoryTotals.isEmpty
                        ? Center(
                            child: Text(
                              "No expense data available",
                              style: GoogleFonts.inter(color: Colors.grey),
                            ),
                          )
                        : _buildPieChart(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Budget recommendation section
          if (_budgetRecommendation == null && !_isGeneratingBudget) ...[
            Center(
              child: ElevatedButton.icon(
                onPressed: _generateBudgetRecommendation,
                icon: const Icon(Icons.auto_awesome),
                label: Text(
                  "Generate Budget Recommendation",
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C6FF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else if (_isGeneratingBudget) ...[
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Generating smart budget recommendation..."),
                ],
              ),
            ),
          ] else if (_budgetRecommendation != null) ...[
            _buildBudgetRecommendationCard(),
            const SizedBox(height: 24),
            _buildSavingsRecommendationCard(),
            const SizedBox(height: 24),
            _buildReductionTipsCard(),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: _generateBudgetRecommendation,
                icon: const Icon(Icons.refresh),
                label: const Text("Regenerate Budget"),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF00C6FF),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    // Sort categories by amount descending
    final sortedCategories = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Pick top 5 categories, group the rest as "Other"
    final topCategories = sortedCategories.take(5).toList();

    double otherTotal = 0;
    if (sortedCategories.length > 5) {
      for (int i = 5; i < sortedCategories.length; i++) {
        otherTotal += sortedCategories[i].value;
      }
    }

    // Prepare chart data
    final List<PieChartSectionData> sections = [];

    // Color palette for chart
    final colors = [
      const Color(0xFF00C6FF),
      const Color(0xFF0072FF),
      const Color(0xFF6A11CB),
      const Color(0xFFFF6A00),
      const Color(0xFFFFA500),
      const Color(0xFF757575), // for "Other"
    ];

    // Add top categories
    for (int i = 0; i < topCategories.length; i++) {
      final category = topCategories[i];
      sections.add(
        PieChartSectionData(
          value: category.value,
          title:
              '${(category.value / _totalSpending * 100).toStringAsFixed(1)}%',
          color: colors[i % colors.length],
          radius: 80,
          titleStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    // Add "Other" if needed
    if (otherTotal > 0) {
      sections.add(
        PieChartSectionData(
          value: otherTotal,
          title: '${(otherTotal / _totalSpending * 100).toStringAsFixed(1)}%',
          color: colors.last,
          radius: 80,
          titleStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 30,
              sectionsSpace: 2,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...topCategories.map((category) => _buildCategoryIndicator(
                    category.key,
                    colors[topCategories.indexOf(category) % colors.length],
                    category.value,
                  )),
              if (otherTotal > 0)
                _buildCategoryIndicator('Other', colors.last, otherTotal),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryIndicator(String category, Color color, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetRecommendationCard() {
    final recommendation = _budgetRecommendation!;
    final monthlyBudget = recommendation['monthlyBudget'] ?? 0.0;
    final categoryBudgets =
        recommendation['categoryBudgets'] as Map<String, dynamic>? ?? {};

    // Sort categories by budget amount
    final sortedCategories = categoryBudgets.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF00C6FF)),
                const SizedBox(width: 8),
                Text(
                  "Recommended Budget",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (recommendation['summary'] != null)
              Text(
                recommendation['summary'],
                style: GoogleFonts.inter(fontSize: 14),
              ),
            const SizedBox(height: 16),
            Text(
              "SAR ${monthlyBudget.toStringAsFixed(2)} / month",
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00C6FF),
              ),
            ),
            const Divider(height: 24),
            Text(
              "Category Breakdown",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...sortedCategories.map((entry) => _buildBudgetRow(
                  category: entry.key,
                  amount: entry.value is num
                      ? (entry.value as num).toDouble()
                      : 0.0,
                  totalBudget:
                      monthlyBudget is num ? monthlyBudget.toDouble() : 0.0,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetRow({
    required String category,
    required double amount,
    required double totalBudget,
  }) {
    final percentage = totalBudget > 0 ? (amount / totalBudget * 100) : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "SAR ${amount.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            color: const Color(0xFF00C6FF),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsRecommendationCard() {
    final recommendation = _budgetRecommendation!;
    final savingsTarget = recommendation['savingsTarget'] ?? 0.0;
    final savingsPercentage = recommendation['savingsPercentage'] ?? 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.savings, color: Color(0xFF00C6FF)),
                const SizedBox(width: 8),
                Text(
                  "Savings Recommendation",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      "Monthly Target",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "SAR ${savingsTarget.toStringAsFixed(2)}",
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00C6FF),
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 50,
                  width: 1,
                  color: Colors.grey[300],
                ),
                Column(
                  children: [
                    Text(
                      "Savings Rate",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${savingsPercentage.toStringAsFixed(1)}%",
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00C6FF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReductionTipsCard() {
    final recommendation = _budgetRecommendation!;
    final reductionAreas =
        recommendation['reductionAreas'] as List<dynamic>? ?? [];
    final reductionTips =
        recommendation['reductionTips'] as List<dynamic>? ?? [];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Color(0xFF00C6FF)),
                const SizedBox(width: 8),
                Text(
                  "Smart Saving Tips",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (reductionAreas.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                "Areas to Reduce",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...reductionAreas.map((area) => _buildTipItem(area.toString())),
            ],
            if (reductionTips.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                "Money-Saving Tips",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...reductionTips.map((tip) => _buildTipItem(tip.toString())),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            size: 20,
            color: Color(0xFF00C6FF),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
