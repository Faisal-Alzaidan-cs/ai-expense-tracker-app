// import 'package:flutter/material.dart';
// import '../services/sms_service.dart';
// import '../services/expense_service.dart';

// class SmsExpenseButton extends StatefulWidget {
//   /// Callback to run after expenses are extracted
//   final Function(List<Map<String, dynamic>>)? onExpensesExtracted;

//   /// Style and appearance customization
//   final Color? color;
//   final IconData icon;
//   final String label;
//   final bool showLabel;
//   final bool isFloatingButton;

//   const SmsExpenseButton({
//     Key? key,
//     this.onExpensesExtracted,
//     this.color,
//     this.icon = Icons.receipt_long,
//     this.label = 'Scan SMS',
//     this.showLabel = true,
//     this.isFloatingButton = false,
//   }) : super(key: key);

//   @override
//   State<SmsExpenseButton> createState() => _SmsExpenseButtonState();
// }

// class _SmsExpenseButtonState extends State<SmsExpenseButton> {
//   final SmsService _smsService = SmsService();
//   final ExpenseService _expenseService = ExpenseService();
//   bool _isLoading = false;
//   Set<String> _processedSmsIds = {};

//   @override
//   void initState() {
//     super.initState();
//     _loadProcessedSmsIds();
//   }

//   Future<void> _loadProcessedSmsIds() async {
//     final loadedIds = await _expenseService.loadProcessedSmsIds();
//     setState(() {
//       _processedSmsIds = loadedIds;
//     });
//   }

//   Future<void> _extractExpenses() async {
//     if (_isLoading) return;

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // First ensure we have up-to-date processed IDs
//       await _loadProcessedSmsIds();

//       // Check if we have SMS permission
//       final hasPermission = await _smsService.requestSmsPermission();

//       if (!hasPermission) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('SMS permission denied')),
//         );
//         return;
//       }

//       // Extract expenses from SMS
//       final extractedExpenses = await _smsService.extractExpensesFromSms(
//         processedSmsIds: _processedSmsIds,
//       );

//       if (extractedExpenses.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No new expenses found in SMS')),
//         );
//         return;
//       }

//       // Save extracted expenses to Firebase and update the processed IDs
//       await _expenseService.saveExtractedExpenses(extractedExpenses);

//       // Update processed IDs
//       for (var expense in extractedExpenses) {
//         if (expense['smsId'] != null) {
//           _processedSmsIds.add(expense['smsId'].toString());
//         }
//       }

//       // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Found ${extractedExpenses.length} new expenses'),
//           backgroundColor: Colors.green,
//         ),
//       );

//       // Call the callback if provided
//       if (widget.onExpensesExtracted != null) {
//         widget.onExpensesExtracted!(extractedExpenses);
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error extracting expenses: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (widget.isFloatingButton) {
//       return FloatingActionButton(
//         onPressed: _extractExpenses,
//         backgroundColor: widget.color,
//         child: _isLoading
//             ? const CircularProgressIndicator(color: Colors.white)
//             : Icon(widget.icon),
//       );
//     }

//     return ElevatedButton(
//       onPressed: _extractExpenses,
//       style: ElevatedButton.styleFrom(
//         backgroundColor: widget.color,
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       ),
//       child: _isLoading
//           ? const SizedBox(
//               width: 20,
//               height: 20,
//               child: CircularProgressIndicator(
//                 color: Colors.white,
//                 strokeWidth: 2,
//               ),
//             )
//           : Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(widget.icon, size: 20),
//                 if (widget.showLabel) ...[
//                   const SizedBox(width: 8),
//                   Text(widget.label),
//                 ],
//               ],
//             ),
//     );
//   }
// }
