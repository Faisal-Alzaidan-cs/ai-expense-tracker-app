import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expenses_tracker/services/ai_api.dart';
import 'package:expenses_tracker/services/expense_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NaturalLanguageEntryScreen extends StatefulWidget {
  const NaturalLanguageEntryScreen({Key? key}) : super(key: key);

  @override
  State<NaturalLanguageEntryScreen> createState() =>
      _NaturalLanguageEntryScreenState();
}

class _NaturalLanguageEntryScreenState
    extends State<NaturalLanguageEntryScreen> {
  final TextEditingController _expenseController = TextEditingController();
  final AIApi _aiApi = AIApi.instance;
  final ExpenseService _expenseService = ExpenseService();
  bool _isProcessing = false;
  Map<String, dynamic>? _parsedExpense;
  String? _errorMessage;
  String? _rawAIResponse; // Added to store the raw response from AI

  @override
  void dispose() {
    _expenseController.dispose();
    super.dispose();
  }

  Future<void> _processExpense() async {
    final input = _expenseController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorMessage = "Please enter an expense description";
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _parsedExpense = null;
      _errorMessage = null;
      _rawAIResponse = null; // Reset the raw response
    });

    try {
      // Using the existing AIApi class for chat completion
      final messages = [
        {
          'role': 'system',
          'content':
              '''You are a financial assistant that analyzes expense descriptions and extracts structured data.
          Extract the following information from the user's expense description:
          - merchant (where the money was spent)
          - amount (the numerical value)
          - category (e.g., food, transport, shopping, entertainment, bills, health, travel, education, or other)
          - paymentMethod (e.g., cash, credit card, debit card)
          - date (if specified, otherwise use current date)
          - notes (any additional details)
          
          Format your response as a valid JSON object with these exact field names. 
          For amount, return a numeric value without currency symbols.
          For category, make the first letter uppercase for consistency.
          
          For date handling:
          - If the user mentions a specific date, convert it to ISO format (YYYY-MM-DD)
          - If the user says "today", use ${DateTime.now().toString().split(' ')[0]}
          - If the user says "yesterday", use ${DateTime.now().subtract(const Duration(days: 1)).toString().split(' ')[0]}
          - If the user says "last week", use ${DateTime.now().subtract(const Duration(days: 7)).toString().split(' ')[0]}
          - If the user mentions no date at all, use today's date (${DateTime.now().toString().split(' ')[0]})
          
          If certain information is missing, make reasonable assumptions but include only the fields mentioned above.
          '''
        },
        {'role': 'user', 'content': input}
      ];

      try {
        // First, get the raw response
        final response = await _aiApi.chatCompletion(
          messages: messages,
          temperature: 0.2,
        );

        // Always store the raw response for debugging, regardless of parsing success
        setState(() {
          _rawAIResponse = response;
          debugPrint("Raw AI Response set: $_rawAIResponse"); // Debug log
        });

        try {
          // Parse the JSON content from the response
          final parsedJson = jsonDecode(response);

          // Ensure the amount is properly converted to a numeric value
          dynamic rawAmount = parsedJson['amount'];
          double amount;
          if (rawAmount is num) {
            amount = rawAmount.toDouble();
          } else if (rawAmount is String) {
            // Remove any currency symbols or commas that might be in the string
            final sanitizedAmount = rawAmount.replaceAll(RegExp(r'[^\d.]'), '');
            amount = double.tryParse(sanitizedAmount) ?? 0.0;
          } else {
            amount = 0.0;
          }

          // Parse the date properly - store both original date string and parsed DateTime
          DateTime parsedDate;
          try {
            if (parsedJson['date'] != null) {
              parsedDate = DateTime.parse(parsedJson['date']);
            } else {
              parsedDate = DateTime.now();
            }
          } catch (e) {
            debugPrint("❌ Error parsing date: $e");
            parsedDate = DateTime.now();
          }

          // Add additional fields needed for saving to Firestore
          final Map<String, dynamic> processedExpense = {
            ...Map<String, dynamic>.from(parsedJson),
            'amount': amount, // Use the properly parsed amount
            'date': parsedDate, // Store as DateTime object for Firestore
            'userId': FirebaseAuth.instance.currentUser?.uid,
            'automatic': false,
            'rawInput': input,
          };

          setState(() {
            _parsedExpense = processedExpense;
            _isProcessing = false;
          });
        } catch (e) {
          setState(() {
            _errorMessage =
                "JSON parsing error: $e\n\nRaw response:\n$_rawAIResponse";
            _isProcessing = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
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

  Future<void> _saveExpense() async {
    if (_parsedExpense == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Ensure all required fields are properly formatted according to expense_service.dart
      final Map<String, dynamic> formattedExpense = {
        'amount': _parsedExpense!['amount'] is double
            ? _parsedExpense!['amount']
            : double.tryParse(_parsedExpense!['amount'].toString()) ?? 0.0,
        'merchant': _parsedExpense!['merchant'] ?? 'Unknown',
        'category': _parsedExpense!['category'] ?? 'other',
        'date': _parsedExpense!['date'] ??
            DateTime.now(), // Use the date field we set in _processExpense
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'paymentMethod': _parsedExpense!['paymentMethod'] ?? 'Unknown',
        'notes': _parsedExpense!['notes'],
        'automatic': false,
        'rawInput': _parsedExpense!['rawInput'],
        // These are optional fields from expense_service.dart
        'cardNumber': _parsedExpense!['cardNumber'],
        'cardType': _parsedExpense!['cardType'],
      };

      // Debug log to verify data before saving
      debugPrint("💾 Saving expense: ${formattedExpense.toString()}");

      // Save the expense and update user balance
      await _expenseService.saveExpenseAndUpdateBalance(formattedExpense);

      // Clear the form after successful save
      _expenseController.clear();
      setState(() {
        _parsedExpense = null;
        _isProcessing = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("❌ Error saving expense: $e");
      setState(() {
        _errorMessage = 'Error saving expense: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Natural Language Entry",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6A11CB),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Enter your expense in natural language",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Example: "Lunch at Starbucks: 12.50 SAR via credit card yesterday"',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _expenseController,
                decoration: InputDecoration(
                  hintText: "Describe your expense...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _processExpense(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isProcessing ? null : _processExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A11CB),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing && _parsedExpense == null
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Analyze Expense",
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
              // Always display raw AI response if available (regardless of parsing success)
              if (_rawAIResponse != null) ...[
                const SizedBox(height: 16),
                ExpansionTile(
                  initiallyExpanded: _errorMessage !=
                      null, // Auto-expand when there's an error
                  title: Text(
                    "Raw AI Response (Debug)",
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
              if (_parsedExpense != null) ...[
                const SizedBox(height: 24),
                Text(
                  "AI Analysis Results",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildResultsCard(),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Save Expense",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    final expense = _parsedExpense!;
    final formatter = DateTime.now();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildResultRow(
              label: "Merchant",
              value: expense['merchant'] ?? 'Not specified',
              icon: Icons.store,
            ),
            _buildResultRow(
              label: "Amount",
              value: "SAR ${expense['amount']}",
              icon: Icons.attach_money,
            ),
            _buildResultRow(
              label: "Category",
              value: expense['category'] ?? 'Not specified',
              icon: Icons.category,
            ),
            _buildResultRow(
              label: "Payment Method",
              value: expense['paymentMethod'] ?? 'Not specified',
              icon: Icons.payment,
            ),
            _buildResultRow(
              label: "Date",
              value: expense['date'] is DateTime
                  ? DateFormat('yyyy-MM-dd').format(expense['date'])
                  : expense['date'] ?? formatter.toString().substring(0, 10),
              icon: Icons.calendar_today,
            ),
            if (expense['notes'] != null)
              _buildResultRow(
                label: "Notes",
                value: expense['notes'],
                icon: Icons.note,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6A11CB)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
