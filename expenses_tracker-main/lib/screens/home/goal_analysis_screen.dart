import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expenses_tracker/models/goal.dart';
import 'package:expenses_tracker/services/goal_analysis_service.dart';
import 'package:expenses_tracker/services/stats_service.dart';
import 'package:expenses_tracker/screens/stats/enums.dart';
import 'package:expenses_tracker/widgets/goal_analysis_result.dart';

class GoalAnalysisScreen extends StatefulWidget {
  final Goal goal;

  const GoalAnalysisScreen({
    Key? key,
    required this.goal,
  }) : super(key: key);

  @override
  State<GoalAnalysisScreen> createState() => _GoalAnalysisScreenState();
}

class _GoalAnalysisScreenState extends State<GoalAnalysisScreen> {
  final GoalAnalysisService _analysisService = GoalAnalysisService();
  final StatsService _statsService = StatsService();
  bool _isAnalyzing = true;
  bool _isLoadingSpending = true;
  Map<String, dynamic>? _analysisResult;
  double _currentMonthlySpending = 0.0;
  double _percentageChange = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadMonthlySpending(),
      _analyzeGoal(),
    ]);
  }

  Future<void> _loadMonthlySpending() async {
    try {
      setState(() {
        _isLoadingSpending = true;
      });

      final spendingData =
          await _statsService.fetchExpenseData(TimeRange.monthly);

      setState(() {
        _currentMonthlySpending = spendingData['currentTotal'] as double;
        _percentageChange = spendingData['percentageChange'] as double;
        _isLoadingSpending = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSpending = false;
      });
    }
  }

  Future<void> _analyzeGoal() async {
    try {
      setState(() {
        _isAnalyzing = true;
      });

      final result = await _analysisService.analyzeGoal(widget.goal);

      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _analysisResult = {
          'error': true,
          'recommendation': 'An error occurred: $e',
        };
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.goal.currentAmount / widget.goal.targetAmount;
    final timeLeftEstimate =
        _analysisResult != null && _analysisResult!['timeToGoal'] != null
            ? _analysisResult!['timeToGoal']
            : ((widget.goal.targetAmount - widget.goal.currentAmount) /
                    widget.goal.monthlySavings)
                .ceil();
    final isAchievable = _analysisResult != null
        ? _analysisResult!['isAchievable'] as bool?
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Goal Analysis",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isAchievable == true
            ? Colors.green
            : isAchievable == false
                ? const Color(0xFFFF9800)
                : const Color(0xFF0072FF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.goal.title,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.insights,
                        color: Colors.white,
                        size: 28,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildProgressBar(context, progress),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGoalInfo(
                        "Current",
                        "${widget.goal.currentAmount} SAR",
                      ),
                      _buildGoalInfo(
                        "Target",
                        "${widget.goal.targetAmount} SAR",
                      ),
                      _buildGoalInfo(
                        "Monthly Savings",
                        "${widget.goal.monthlySavings} SAR",
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Add monthly spending card
            _buildMonthlySpendingCard(),
            const SizedBox(height: 24),
            _isAnalyzing
                ? const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Analyzing your goal..."),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "AI Analysis",
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isAchievable == true
                                  ? "Achievable"
                                  : isAchievable == false
                                      ? "Needs Adjustment"
                                      : "Analyzing...",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isAchievable == true
                                    ? Colors.green
                                    : isAchievable == false
                                        ? Colors.orange
                                        : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GoalAnalysisResult(
                        analysis: _analysisResult!,
                      ),
                      const SizedBox(height: 24),
                      _buildInsightCards(context, timeLeftEstimate),
                      const SizedBox(height: 40),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Refresh Analysis"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0072FF),
                            foregroundColor: Colors.white,
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
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySpendingCard() {
    return _isLoadingSpending
        ? const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: CircularProgressIndicator(),
            ),
          )
        : Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Current Monthly Spending",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(
                      Icons.account_balance_wallet,
                      color: Color(0xFF6A11CB),
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "${_currentMonthlySpending.toStringAsFixed(2)} SAR",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6A11CB),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSpendingInfo(
                      "Month-over-Month",
                      _percentageChange >= 0
                          ? "+${_percentageChange.toStringAsFixed(1)}%"
                          : "${_percentageChange.toStringAsFixed(1)}%",
                      _percentageChange >= 0 ? Colors.red : Colors.green,
                      _percentageChange >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                    ),
                    _buildSpendingToSavingsRatio(),
                  ],
                ),
              ],
            ),
          );
  }

  Widget _buildSpendingInfo(
    String label,
    String value,
    Color valueColor,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: valueColor,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingToSavingsRatio() {
    final savingsToSpendingRatio =
        widget.goal.monthlySavings / _currentMonthlySpending;
    final formattedRatio = savingsToSpendingRatio.toStringAsFixed(2);

    return Row(
      children: [
        const Icon(
          Icons.bar_chart,
          size: 16,
          color: Color(0xFF6A11CB),
        ),
        const SizedBox(width: 4),
        Text(
          "Savings/Spending Ratio:",
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          formattedRatio,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF6A11CB),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Progress",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            Text(
              "${(progress * 100).toStringAsFixed(1)}%",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(progress),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCards(BuildContext context, int timeLeftEstimate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Goal Insights",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                context,
                "Time Left",
                "$timeLeftEstimate months",
                Icons.calendar_today,
                Colors.blue.shade100,
                Colors.blue.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInsightCard(
                context,
                "Remaining",
                "${widget.goal.targetAmount - widget.goal.currentAmount} SAR",
                Icons.attach_money,
                Colors.green.shade100,
                Colors.green.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color backgroundColor,
    Color foregroundColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: foregroundColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) {
      return Colors.red;
    } else if (progress < 0.7) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
