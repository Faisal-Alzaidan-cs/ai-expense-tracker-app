import 'package:flutter/material.dart';
import '../services/sms_service.dart';
import '../services/expense_service.dart';
import '../utility/sms_parser.dart'; // Add import for SmsParser

class ExpenseExtractorWidget extends StatefulWidget {
  const ExpenseExtractorWidget({super.key});

  @override
  State<StatefulWidget> createState() => _ExpenseExtractorWidgetState();
}

class _ExpenseExtractorWidgetState extends State<ExpenseExtractorWidget> {
  final SmsService _smsService = SmsService();
  final ExpenseService _expenseService = ExpenseService();
  List<Map<String, dynamic>> expenses = [];
  Set<String> processedSmsIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAndExtractExpenses();
  }

  Future<void> _initializeAndExtractExpenses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadProcessedSmsIds();

      // Check if user has any expenses
      bool hasExpenses = await _expenseService.hasExistingExpenses();

      if (!hasExpenses) {
        // User doesn't have any expenses, upload the last 50 messages
        await _uploadInitialSmsMessages();
      } else {
        // User already has expenses, just extract normally
        await extractExpenses();
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProcessedSmsIds() async {
    final loadedIds = await _expenseService.loadProcessedSmsIds();
    setState(() {
      processedSmsIds = loadedIds;
    });
  }

  Future<void> extractExpenses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if we have SMS permission
      final hasPermission = await _smsService.requestSmsPermission();

      if (!hasPermission) {
        setState(() {
          expenses = [
            {
              'merchant': 'Error',
              'amount': 0.0,
              'date': 'SMS permission denied',
              'cardNumber': 'N/A',
              'cardType': 'N/A'
            }
          ];
          _isLoading = false;
        });
        return;
      }

      // Extract expenses from SMS
      final extractedExpenses = await _smsService.extractExpensesFromSms(
        processedSmsIds: processedSmsIds,
      );

      if (extractedExpenses.isEmpty) {
        setState(() {
          expenses = [
            {
              'merchant': 'Info',
              'amount': 0.0,
              'date': 'No new expenses found in SMS',
              'cardNumber': 'N/A',
              'cardType': 'N/A'
            }
          ];
        });
        return;
      }

      setState(() {
        expenses = extractedExpenses;
      });

      // Save extracted expenses to Firebase in the background
      _saveExpensesToFirebase(extractedExpenses);
    } catch (e) {
      debugPrint("❌ Error extracting expenses: $e");
      setState(() {
        expenses = [
          {
            'merchant': 'Error',
            'amount': 0.0,
            'date': 'Error occurred: $e',
            'cardNumber': 'N/A',
            'cardType': 'N/A'
          }
        ];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Upload the last 50 SMS messages to Firebase to help the user start using the app
  Future<void> _uploadInitialSmsMessages() async {
    try {
      // Check if we have SMS permission
      final hasPermission = await _smsService.requestSmsPermission();

      if (!hasPermission) {
        setState(() {
          expenses = [
            {
              'merchant': 'Error',
              'amount': 0.0,
              'date': 'SMS permission denied',
              'cardNumber': 'N/A',
              'cardType': 'N/A'
            }
          ];
        });
        return;
      }

      // Show a message to the user that we're setting up their account
      setState(() {
        expenses = [
          {
            'merchant': 'Setting up',
            'amount': 0.0,
            'date': 'Loading your expenses from SMS...',
            'cardNumber': 'N/A',
            'cardType': 'N/A'
          }
        ];
      });

      debugPrint("🔄 Initializing account: Fetching bank SMS messages...");

      // Fetch the last 50 bank SMS messages
      final messages = await _smsService.fetchBankSmsMessages(count: 50);

      if (messages.isEmpty) {
        setState(() {
          expenses = [
            {
              'merchant': 'Info',
              'amount': 0.0,
              'date': 'No bank SMS messages found',
              'cardNumber': 'N/A',
              'cardType': 'N/A'
            }
          ];
        });
        return;
      }

      debugPrint(
          "📱 Found ${messages.length} potential bank messages for initial setup");

      // Extract expense data from the messages
      List<Map<String, dynamic>> extractedExpenses = [];

      for (var msg in messages) {
        if (msg.body != null && msg.id != null) {
          String smsId = msg.id.toString();

          // Skip messages that have already been processed
          if (processedSmsIds.contains(smsId)) {
            continue;
          }

          Map<String, dynamic> extractedData =
              SmsParser.parseTransactionMessage(msg.body!);

          if (extractedData.isNotEmpty) {
            extractedData['smsId'] = smsId;
            extractedData['timestamp'] = msg.date ?? DateTime.now();
            extractedData['rawMessage'] = msg.body;
            extractedData['sender'] = msg.address ?? 'Unknown';

            extractedExpenses.add(extractedData);
          }
        }
      }

      debugPrint(
          "✅ Extracted ${extractedExpenses.length} expenses from SMS for initial setup");

      // Save the extracted expenses to Firebase
      if (extractedExpenses.isNotEmpty) {
        await _expenseService.saveExtractedExpenses(extractedExpenses);

        // Update our local list of expenses and processed SMS IDs
        setState(() {
          expenses = extractedExpenses;
          for (var expense in extractedExpenses) {
            if (expense['smsId'] != null) {
              processedSmsIds.add(expense['smsId'].toString());
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Found and uploaded ${extractedExpenses.length} expenses from your SMS'),
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        setState(() {
          expenses = [
            {
              'merchant': 'Info',
              'amount': 0.0,
              'date': 'No expenses found in your SMS messages',
              'cardNumber': 'N/A',
              'cardType': 'N/A'
            }
          ];
        });
      }
    } catch (e) {
      debugPrint("❌ Error uploading initial SMS messages: $e");
      setState(() {
        expenses = [
          {
            'merchant': 'Error',
            'amount': 0.0,
            'date': 'Error occurred while setting up: $e',
            'cardNumber': 'N/A',
            'cardType': 'N/A'
          }
        ];
      });
    }
  }

  // Save expenses to Firebase in the background
  Future<void> _saveExpensesToFirebase(
      List<Map<String, dynamic>> expensesToSave) async {
    try {
      await _expenseService.saveExtractedExpenses(expensesToSave);
      // Add newly processed IDs to our set
      for (var expense in expensesToSave) {
        if (expense['smsId'] != null) {
          setState(() {
            processedSmsIds.add(expense['smsId'].toString());
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Error saving to Firebase: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildExpensesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          extractExpenses();
        },
        tooltip: 'Refresh Expenses',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildExpensesList() {
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("No expenses found from SMS messages."),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                extractExpenses();
              },
              child: const Text("Scan SMS for Expenses"),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          elevation: 2.0,
          child: ExpansionTile(
            title: Text(
              expense['merchant'] ?? 'Unknown Merchant',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Amount: SAR ${expense['amount']}\nDate: ${expense['date'] ?? (expense['timestamp'] != null ? expense['timestamp'].toString().substring(0, 10) : 'N/A')}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SAR ${expense['amount']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      expenses.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            children: [_buildExpansionDetails(expense)],
          ),
        );
      },
    );
  }

  Widget _buildExpansionDetails(Map<String, dynamic> expense) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              'Card: ${expense['cardNumber'] ?? 'N/A'} (${expense['cardType'] ?? 'N/A'})'),
          const SizedBox(height: 8),
          Text('Sender: ${expense['sender'] ?? 'Unknown'}'),
          const SizedBox(height: 8),
          const Text('Original SMS:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(expense['rawMessage'] ?? 'No raw message available'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  // Handle manual saving of individual expense
                  _expenseService.saveExpenseAndUpdateBalance(expense);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Expense saved')),
                  );
                },
                child: const Text('Save to Database'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
