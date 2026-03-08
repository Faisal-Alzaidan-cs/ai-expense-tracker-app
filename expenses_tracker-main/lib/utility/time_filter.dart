import 'package:flutter/material.dart';

class TimeRangeFilter extends StatelessWidget {
  TimeRangeFilter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F1F1),
      ),
      child: Row(
        spacing: 20,
        children: [
          const Text('Week'),
          const Text('Month'),
          const Text('Year'),
        ],
      ),
    );
  }
}
