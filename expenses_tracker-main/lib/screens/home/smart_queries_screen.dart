import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expenses_tracker/services/ai_api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SmartQueriesScreen extends StatefulWidget {
  const SmartQueriesScreen({Key? key}) : super(key: key);

  @override
  State<SmartQueriesScreen> createState() => _SmartQueriesScreenState();
}

class _SmartQueriesScreenState extends State<SmartQueriesScreen> {
  final TextEditingController _queryController = TextEditingController();
  final AIApi _aiApi = AIApi.instance;
  bool _isProcessing = false;
  Map<String, dynamic>? _aiResponse;
  String? _errorMessage;
  String? _rawAIResponse;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _processQuery() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _errorMessage = "Please enter a question";
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _aiResponse = null;
      _errorMessage = null;
      _rawAIResponse = null;
    });

    try {
      // Using the AIApi class for chat completion
      final messages = [
        {
          'role': 'system',
          'content':
              '''You are Coin-AI, a sophisticated financial assistant for the Expense Tracker app. 
          Your job is to help users understand their spending habits and provide personalized financial advice.

          When the user asks about their spending, provide detailed insights and actionable recommendations.
          Format your response as a valid JSON object with these fields:
          - "summary": A brief 1-2 sentence summary of the spending analysis
          - "details": Detailed information about their spending related to their query
          - "insights": 2-3 key insights about their spending habits
          - "recommendations": 2-3 practical recommendations for improving financial health
          - "metrics": Any relevant metrics you can provide in response to their query (e.g., "total": 1234.56, "average": 123.45)
          
          make sure to use saudi riyals in your response 
          For example, if they ask "How much did I spend on food this month?", you should provide:
          - A summary of their food spending
          - Details about frequency, patterns, or comparisons
          - Insights about their food spending habits
          - Practical recommendations to optimize food expenses
          - Metrics with the total spent on food and perhaps the average per meal

          Keep your tone friendly and supportive. Focus on being helpful rather than judgmental.
          Today's date is ${DateFormat('yyyy-MM-dd').format(DateTime.now())}.
          '''
        },
        {'role': 'user', 'content': query}
      ];

      try {
        // Get the response from AI
        final response = await _aiApi.chatCompletion(
          messages: messages,
          temperature: 0.7,
        );

        // Store the raw response for debugging
        setState(() {
          _rawAIResponse = response;
        });

        try {
          // Parse the JSON content from the response
          final parsedJson = jsonDecode(response);

          setState(() {
            _aiResponse = parsedJson;
            _isProcessing = false;
          });
        } catch (e) {
          setState(() {
            _errorMessage =
                "Could not parse the AI response: $e\n\nRaw response:\n$_rawAIResponse";
            _isProcessing = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = "AI service error: ${e.toString()}";
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Smart Queries",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFF6A00),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Ask anything about your finances",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Example: "How much did I spend on food this month?"',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _queryController,
                decoration: InputDecoration(
                  hintText: "Ask about your spending...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.help_outline),
                ),
                maxLines: 2,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _processQuery(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isProcessing ? null : _processQuery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A00),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing && _aiResponse == null
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Ask Coin-AI",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.inter(color: Colors.red),
                  ),
                ),
              ],
              if (_aiResponse != null) ...[
                const SizedBox(height: 24),
                _buildResponseCard(),
              ],
              // Debug section with raw response (collapsible)
              if (_rawAIResponse != null) ...[
                const SizedBox(height: 16),
                ExpansionTile(
                  initiallyExpanded: _errorMessage != null,
                  title: Text(
                    "Debug Information",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      width: double.infinity,
                      child: SelectableText(
                        _rawAIResponse!,
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponseCard() {
    final response = _aiResponse!;

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
            // Summary section
            if (response['summary'] != null) ...[
              Text(
                "Summary",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF6A00),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                response['summary'],
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Divider(height: 24),
            ],

            // Details section
            if (response['details'] != null) ...[
              Text(
                "Details",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF6A00),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                response['details'],
                style: GoogleFonts.inter(fontSize: 14),
              ),
              const SizedBox(height: 16),
            ],

            // Metrics section (if present)
            if (response['metrics'] != null) ...[
              Text(
                "Metrics",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF6A00),
                ),
              ),
              const SizedBox(height: 8),
              _buildMetricsSection(response['metrics']),
              const SizedBox(height: 16),
            ],

            // Insights section
            if (response['insights'] != null) ...[
              Text(
                "Insights",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF6A00),
                ),
              ),
              const SizedBox(height: 8),
              _buildListSection(response['insights']),
              const SizedBox(height: 16),
            ],

            // Recommendations section
            if (response['recommendations'] != null) ...[
              Text(
                "Recommendations",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF6A00),
                ),
              ),
              const SizedBox(height: 8),
              _buildListSection(response['recommendations']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsSection(dynamic metrics) {
    if (metrics is Map<String, dynamic>) {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: metrics.entries.map((entry) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  entry.key.toString().toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.value.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF6A00),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    } else if (metrics is String) {
      return Text(metrics, style: GoogleFonts.inter(fontSize: 14));
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildListSection(dynamic items) {
    if (items is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.arrow_right, color: Color(0xFFFF6A00)),
                Expanded(
                  child: Text(
                    item.toString(),
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    } else if (items is String) {
      return Text(items, style: GoogleFonts.inter(fontSize: 14));
    } else {
      return const SizedBox.shrink();
    }
  }
}
