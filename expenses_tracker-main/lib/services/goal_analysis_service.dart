import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:expenses_tracker/models/goal.dart';
import 'package:expenses_tracker/services/ai_api.dart';
import 'package:expenses_tracker/services/stats_service.dart';
import 'package:expenses_tracker/screens/stats/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoalAnalysisService {
  final AIApi _aiApi = AIApi.instance;
  final StatsService _statsService = StatsService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID or null if not authenticated
  String? get currentUserId => _auth.currentUser?.uid;

  /// Analyze goal achievability based on user's spending habits
  Future<Map<String, dynamic>> analyzeGoal(Goal goal) async {
    try {
      // Fetch the user's monthly spending data
      final monthlySpendingData =
          await _statsService.fetchExpenseData(TimeRange.monthly);

      final currentMonthlySpending =
          monthlySpendingData['currentTotal'] as double;
      final monthlySpendingChange =
          monthlySpendingData['percentageChange'] as double;

      // Fetch the user's current balance
      double currentBalance = await _getUserCurrentBalance();

      // Prepare the prompt for the AI to analyze goal achievability
      final List<Map<String, String>> messages = [
        {
          'role': 'system',
          'content':
              '''You are a financial advisor AI specializing in goal analysis. 
          You will analyze a user's financial goal and their current spending habits to determine if the goal is achievable.
          Provide your analysis in JSON format with the following fields:
          - isAchievable: boolean indicating if the goal is achievable based on current spending
          - timeToGoal: estimated time in months to reach the goal
          - confidenceLevel: "high", "medium", or "low" indicating confidence in prediction
          - recommendation: a brief recommendation to help the user achieve their goal
          - savingsDeficit: if applicable, how much more the user needs to save monthly (positive number)
          - savingsSurplus: if applicable, how much extra the user is saving monthly (positive number)
          - reasoning: brief explanation of your analysis
          '''
        },
        {
          'role': 'user',
          'content': '''
          Analyze this financial goal:
          - Goal title: ${goal.title}
          - Current amount saved: ${goal.currentAmount} SAR
          - Target amount: ${goal.targetAmount} SAR
          - User's planned monthly savings: ${goal.monthlySavings} SAR
          - User's current account balance: ${currentBalance.toStringAsFixed(2)} SAR
          - User's actual monthly spending: ${currentMonthlySpending.toStringAsFixed(2)} SAR
          - Month-over-month spending change: ${monthlySpendingChange.toStringAsFixed(2)}%
          
          Determine if this goal is achievable based on the user's current financial situation and provide recommendations.
          Return your analysis in a clean JSON format.
          '''
        }
      ];

      // Make the API call to the AI service
      final response = await _aiApi.chatCompletion(
        messages: messages,
        temperature: 0.2, // Lower temperature for more predictable responses
      );

      // Parse the JSON response
      Map<String, dynamic> parsedResponse;
      try {
        parsedResponse = jsonDecode(response);
        debugPrint('AI goal analysis received: $parsedResponse');
        return parsedResponse;
      } catch (e) {
        debugPrint('Error parsing AI response: $e');

        // If parsing fails, attempt to extract JSON from the response text
        final jsonRegex = RegExp(r'\{(?:[^{}]|(?:\{[^{}]*\}))*\}');
        final match = jsonRegex.firstMatch(response);
        if (match != null) {
          final jsonStr = match.group(0);
          if (jsonStr != null) {
            try {
              parsedResponse = jsonDecode(jsonStr);
              debugPrint('Extracted JSON from response: $parsedResponse');
              return parsedResponse;
            } catch (e) {
              debugPrint('Error parsing extracted JSON: $e');
            }
          }
        }

        // Return a fallback response if parsing fails
        return {
          'isAchievable': null,
          'timeToGoal': null,
          'confidenceLevel': 'low',
          'recommendation':
              'Unable to analyze your goal at this time. Please try again later.',
          'reasoning': 'There was an error processing the AI response.',
          'error': true,
          'rawResponse': response,
        };
      }
    } catch (e) {
      debugPrint('Error analyzing goal: $e');
      return {
        'isAchievable': null,
        'timeToGoal': null,
        'confidenceLevel': 'low',
        'recommendation':
            'An error occurred while analyzing your goal. Please try again later.',
        'reasoning': 'Exception occurred: $e',
        'error': true,
      };
    }
  }

  /// Get the current user's balance from Firestore
  Future<double> _getUserCurrentBalance() async {
    try {
      final String? userId = currentUserId;
      if (userId == null) {
        debugPrint("Cannot get user balance - user not logged in");
        return 0.0;
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists || userDoc.data() == null) {
        debugPrint("User document does not exist or is empty");
        return 0.0;
      }

      final userData = userDoc.data()!;
      if (userData['balance'] != null) {
        return (userData['balance'] as num).toDouble();
      } else {
        debugPrint("Balance field not found in user document");
        return 0.0;
      }
    } catch (e) {
      debugPrint("Error getting user balance: $e");
      return 0.0;
    }
  }
}
