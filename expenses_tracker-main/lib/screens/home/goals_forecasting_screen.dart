import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expenses_tracker/models/goal.dart';
import 'package:expenses_tracker/services/goal_service.dart';
import 'package:expenses_tracker/screens/home/goal_analysis_screen.dart';

class GoalsForecastingScreen extends StatefulWidget {
  const GoalsForecastingScreen({Key? key}) : super(key: key);

  @override
  State<GoalsForecastingScreen> createState() => _GoalsForecastingScreenState();
}

class _GoalsForecastingScreenState extends State<GoalsForecastingScreen> {
  final GoalService _goalService = GoalService();
  Goal? _selectedGoal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Goals Forecasting",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF00C6FF),
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<List<Goal>>(
        stream: _goalService.getGoals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00C6FF),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading goals: ${snapshot.error}",
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }

          final goals = snapshot.data ?? [];

          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.sentiment_dissatisfied,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No goals found",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Create financial goals to track your progress",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Create sample goal for testing purposes
                      _goalService.addSampleGoal();
                    },
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
                    child: Text(
                      "Add Sample Goal",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select a Goal to Forecast",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Choose one of your financial goals to see if you can achieve it based on your current spending habits.",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      final goal = goals[index];
                      final isSelected = _selectedGoal?.title == goal.title;
                      final progress = goal.currentAmount / goal.targetAmount;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildGoalCard(
                          goal: goal,
                          isSelected: isSelected,
                          progress: progress,
                          onTap: () {
                            setState(() {
                              _selectedGoal = isSelected ? null : goal;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                if (_selectedGoal != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GoalAnalysisScreen(
                              goal: _selectedGoal!,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0072FF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Analyze Goal Feasibility",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoalCard({
    required Goal goal,
    required bool isSelected,
    required double progress,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE6F7FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0072FF) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected ? const Color(0xFF0072FF) : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF0072FF),
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(progress),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAmountInfo(
                  label: "Current",
                  amount: goal.currentAmount,
                ),
                _buildAmountInfo(
                  label: "Target",
                  amount: goal.targetAmount,
                ),
                _buildAmountInfo(
                  label: "Monthly Savings",
                  amount: goal.monthlySavings,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInfo({
    required String label,
    required int amount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "$amount SAR",
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
