import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expenses_tracker/screens/home/natural_language_entry_screen.dart';
import 'package:expenses_tracker/screens/home/goals_forecasting_screen.dart';
import 'package:expenses_tracker/screens/home/smart_queries_screen.dart';
import 'package:expenses_tracker/screens/home/smart_budget_advisor_screen.dart';
import 'package:expenses_tracker/screens/home/ai_expense_analyzer_screen.dart';

class CoinAIScreen extends StatelessWidget {
  const CoinAIScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Coin-AI",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                "Smart Features",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildFeatureBox(
                  context: context,
                  title: "Natural Language Entry",
                  icon: Icons.translate,
                  gradientColors: const [Color(0xFF6A11CB), Color(0xFF2575FC)],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const NaturalLanguageEntryScreen(),
                      ),
                    );
                  },
                ),
                _buildFeatureBox(
                  context: context,
                  title: "Goals Forecasting",
                  icon: Icons.trending_up,
                  gradientColors: const [Color(0xFF00C6FF), Color(0xFF0072FF)],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GoalsForecastingScreen(),
                      ),
                    );
                  },
                ),
                _buildFeatureBox(
                  context: context,
                  title: "Smart Queries",
                  icon: Icons.search,
                  gradientColors: const [Color(0xFFFF6A00), Color(0xFFFFA500)],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SmartQueriesScreen(),
                      ),
                    );
                  },
                ),
                _buildFeatureBox(
                  context: context,
                  title: "Smart Budget Advisor",
                  icon: Icons.account_balance_wallet,
                  gradientColors: const [Color(0xFF00C9A7), Color(0xFF00C6FF)],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SmartBudgetAdvisorScreen(),
                      ),
                    );
                  },
                ),
                _buildFeatureBox(
                  context: context,
                  title: "AI Expense Analyzer",
                  icon: Icons.analytics,
                  gradientColors: const [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AIExpenseAnalyzerScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBox({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
