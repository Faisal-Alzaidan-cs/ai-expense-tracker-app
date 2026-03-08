import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expenses_tracker/services/ai_api.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AIExpenseAnalyzerScreen extends StatefulWidget {
  const AIExpenseAnalyzerScreen({Key? key}) : super(key: key);

  @override
  State<AIExpenseAnalyzerScreen> createState() =>
      _AIExpenseAnalyzerScreenState();
}

class _AIExpenseAnalyzerScreenState extends State<AIExpenseAnalyzerScreen> {
  bool _isLoading = false;
  bool _isLoadingExpenses = true;
  String _analysisResult = '';
  List<Map<String, dynamic>> _insights = [];
  List<Map<String, dynamic>> _expenses = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchRecentExpenses();
  }

  // Fetch the most recent expenses from Firebase
  Future<void> _fetchRecentExpenses() async {
    setState(() {
      _isLoadingExpenses = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Query the 20 most recent expenses for the current user
        final querySnapshot = await _firestore
            .collection('expenses')
            .where('userId', isEqualTo: user.uid)
            .orderBy('date', descending: true)
            .limit(20)
            .get();

        final fetchedExpenses = querySnapshot.docs.map((doc) {
          final data = doc.data();
          // Convert Firestore Timestamp to DateTime
          DateTime date;
          if (data['date'] is Timestamp) {
            date = (data['date'] as Timestamp).toDate();
          } else {
            // Fallback if date format is different
            date = DateTime.now();
          }

          return {
            'id': doc.id,
            'amount': (data['amount'] as num).toDouble(),
            'merchant': data['merchant'] ?? 'Unknown',
            'category': data['category'] ?? 'Other',
            'date': date,
            'description':
                data['merchant'] ?? 'Unknown', // Using merchant as description
          };
        }).toList();

        setState(() {
          _expenses = fetchedExpenses;
          _isLoadingExpenses = false;
        });
      } else {
        setState(() {
          _isLoadingExpenses = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingExpenses = false;
      });
      debugPrint('Error fetching expenses: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "AI Expense Analyzer",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Let AI analyze your spending patterns",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Our AI will analyze your recent expenses and provide insights to help you manage your finances better.",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                // Recent expenses section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Recent Expenses",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isLoadingExpenses)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Expense list
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isLoadingExpenses
                      ? const Center(child: Text("Loading expenses..."))
                      : _expenses.isEmpty
                          ? const Center(child: Text("No expenses found"))
                          : ListView.builder(
                              itemCount: _expenses.length,
                              itemBuilder: (context, index) {
                                final expense = _expenses[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    expense['description'],
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${DateFormat('yyyy-MM-dd').format(expense['date'])} · ${expense['category']}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Text(
                                    'SAR ${expense['amount'].toStringAsFixed(2)}',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                ),

                const SizedBox(height: 24),

                // Analysis button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading || _expenses.isEmpty
                        ? null
                        : _analyzeExpenses,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _expenses.isEmpty
                                ? "No expenses to analyze"
                                : "Analyze My Expenses",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Analysis results
                if (_insights.isNotEmpty) ...[
                  Text(
                    "AI Insights",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Display insights in a scrollable column instead of Expanded ListView
                  ..._insights
                      .map((insight) => Card(
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
                                    children: [
                                      Icon(
                                        _getIconForInsightType(insight['type']),
                                        color: _getColorForInsightType(
                                            insight['type']),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          insight['title'],
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    insight['description'],
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (insight['recommendation'] != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      "Recommendation: ${insight['recommendation']}",
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ],

                // Show loading or error message
                if (_isLoading && _insights.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),

                if (!_isLoading &&
                    _analysisResult.isNotEmpty &&
                    _insights.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _analysisResult,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.red,
                      ),
                    ),
                  ),

                // Add some bottom padding for better scrolling experience
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _analyzeExpenses() async {
    setState(() {
      _isLoading = true;
      _analysisResult = '';
      _insights = [];
    });

    try {
      // Format the expenses data for AI analysis
      final expenseData = _formatExpensesForAnalysis();
      final jsonData = json.encode(expenseData);

      // Create the AI API instance
      final aiApi = AIApi.instance;

      // Create the messages for AI analysis with explicit JSON formatting instructions
      final messages = [
        {
          'role': 'system',
          'content':
              '''You are a financial analysis AI assistant for the Expense Tracker app. Analyze the expense data and provide insights and recommendations.
          
Return your analysis in this EXACT JSON format:
[
  {
    "type": "pattern",
    "title": "Your insight title",
    "description": "Detailed description of the pattern you found",
    "recommendation": "Actionable advice for the user"
  },
  {
    "type": "anomaly",
    "title": "Unusual spending detected",
    "description": "Description of the anomaly",
    "recommendation": "What the user should do about it"
  },
  {
    "type": "saving_opportunity",
    "title": "Potential savings",
    "description": "Where the user could save money",
    "recommendation": "How to achieve these savings"
  }
]

Provide 3-4 insights total across these types. Each insight must include all four fields.
ONLY return the JSON array with no explanations before or after it.'''
        },
        {
          'role': 'user',
          'content':
              'Analyze these recent expenses and provide useful financial insights: $jsonData'
        }
      ];

      // Call the AI API - the improved JSON handling is now in the API service
      final response = await aiApi.chatCompletion(
        messages: messages,
        temperature: 0.5,
      );

      // Parse the response - should be clean JSON from the API service now
      try {
        // The API service now handles JSON cleaning, so we can parse directly
        final List<dynamic> parsedInsights = json.decode(response);

        setState(() {
          _insights = List<Map<String, dynamic>>.from(parsedInsights);
          _isLoading = false;
        });

        // If we have insights, but they're empty, show a helpful message
        if (_insights.isEmpty) {
          setState(() {
            _analysisResult =
                'No insights could be generated from your expenses. Try adding more expenses for better analysis.';
          });
        }
      } catch (parseError) {
        setState(() {
          _analysisResult = 'Unable to process AI response. Please try again.';
          _isLoading = false;
        });

        // Log the error for debugging
        debugPrint('JSON Parse Error: $parseError');
        debugPrint('Response that failed to parse: $response');
      }
    } catch (e) {
      setState(() {
        _analysisResult = 'Error analyzing expenses: $e';
        _isLoading = false;
      });
      debugPrint('Analysis error: $e');
    }
  }

  // Format expenses data for AI analysis
  List<Map<String, dynamic>> _formatExpensesForAnalysis() {
    return _expenses.map((expense) {
      return {
        'category': expense['category'],
        'amount': expense['amount'],
        'date': DateFormat('yyyy-MM-dd').format(expense['date']),
        'description': expense['description'],
      };
    }).toList();
  }

  IconData _getIconForInsightType(String type) {
    switch (type) {
      case 'pattern':
        return Icons.timeline;
      case 'anomaly':
        return Icons.warning_amber;
      case 'saving_opportunity':
        return Icons.savings;
      default:
        return Icons.insights;
    }
  }

  Color _getColorForInsightType(String type) {
    switch (type) {
      case 'pattern':
        return Colors.blue;
      case 'anomaly':
        return Colors.orange;
      case 'saving_opportunity':
        return Colors.green;
      default:
        return Colors.purple;
    }
  }
}
