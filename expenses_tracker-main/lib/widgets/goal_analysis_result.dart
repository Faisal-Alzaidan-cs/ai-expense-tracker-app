import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GoalAnalysisResult extends StatelessWidget {
  final Map<String, dynamic> analysis;
  final VoidCallback? onViewDetails;

  const GoalAnalysisResult({
    Key? key,
    required this.analysis,
    this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Handle error state
    if (analysis.containsKey('error') && analysis['error'] == true) {
      return _buildErrorState(context);
    }

    // Extract values from analysis with null safety
    final bool? isAchievable = analysis['isAchievable'];
    final int? timeToGoal = analysis['timeToGoal'];
    final String confidenceLevel = analysis['confidenceLevel'] ?? 'low';
    final String recommendation =
        analysis['recommendation'] ?? 'No recommendation available.';
    final num savingsDeficit = analysis['savingsDeficit'] ?? 0;
    final num savingsSurplus = analysis['savingsSurplus'] ?? 0;
    final String reasoning = analysis['reasoning'] ?? 'No reasoning provided.';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isAchievable == true
              ? [Colors.green.shade50, Colors.green.shade100]
              : isAchievable == false
                  ? [Colors.orange.shade50, Colors.orange.shade100]
                  : [Colors.grey.shade50, Colors.grey.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAchievable == true
                    ? Icons.check_circle
                    : isAchievable == false
                        ? Icons.warning
                        : Icons.help,
                color: isAchievable == true
                    ? Colors.green
                    : isAchievable == false
                        ? Colors.orange
                        : Colors.grey,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAchievable == true
                      ? 'Your goal is achievable!'
                      : isAchievable == false
                          ? 'Your goal needs attention'
                          : 'Goal analysis incomplete',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isAchievable == true
                        ? Colors.green.shade800
                        : isAchievable == false
                            ? Colors.orange.shade800
                            : Colors.grey.shade800,
                  ),
                ),
              ),
              _buildConfidenceBadge(confidenceLevel),
            ],
          ),
          const SizedBox(height: 16),
          if (timeToGoal != null) ...[
            _buildInfoRow(
              context,
              'Estimated time to goal:',
              '${timeToGoal.toString()} months',
              Icons.access_time,
            ),
            const SizedBox(height: 12),
          ],
          if (savingsDeficit > 0) ...[
            _buildInfoRow(
              context,
              'Monthly savings deficit:',
              '${savingsDeficit.toString()} SAR',
              Icons.trending_down,
              valueColor: Colors.red,
            ),
            const SizedBox(height: 12),
          ],
          if (savingsSurplus > 0) ...[
            _buildInfoRow(
              context,
              'Monthly savings surplus:',
              '${savingsSurplus.toString()} SAR',
              Icons.trending_up,
              valueColor: Colors.green,
            ),
            const SizedBox(height: 12),
          ],
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Recommendation:',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            recommendation,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          if (reasoning.isNotEmpty) ...[
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                'Reasoning',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    reasoning,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey.shade700,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceBadge(String confidenceLevel) {
    Color badgeColor;
    switch (confidenceLevel.toLowerCase()) {
      case 'high':
        badgeColor = Colors.green;
        break;
      case 'medium':
        badgeColor = Colors.orange;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${confidenceLevel.toUpperCase()} CONFIDENCE',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade700,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Analysis Error',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            analysis['recommendation'] ??
                'Unable to analyze your goal. Please try again later.',
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
