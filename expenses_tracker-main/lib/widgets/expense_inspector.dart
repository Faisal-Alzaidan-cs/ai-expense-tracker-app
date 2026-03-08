import 'package:flutter/material.dart';
import 'package:expenses_tracker/utility/time_filter.dart';

class ExpenseInspector extends StatelessWidget {
  const ExpenseInspector({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 20.0),
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        color: Color(0xFFffb3b3),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10.0,
          vertical: 20.0,
        ),
        child: Column(
          children: [
            const Text("Your Total Spending This Week"),
            const Text("Amount"),
            const Text("+15% more than the last week"),
          ],
        ),
      ),
    );
  }
}
