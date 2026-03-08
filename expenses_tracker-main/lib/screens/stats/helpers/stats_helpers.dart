import 'package:flutter/material.dart';

/// Helper functions for the stats screen
class StatsHelpers {
  /// Returns an icon for a given expense category
  static IconData getCategoryIcon(String category) {
    final Map<String, IconData> categoryIcons = {
      'Food': Icons.restaurant,
      'Coffee': Icons.coffee,
      'Transport': Icons.directions_car,
      'Shopping': Icons.shopping_bag,
      'Entertainment': Icons.movie,
      'Bills': Icons.receipt_long,
      'Health': Icons.medical_services,
      'Travel': Icons.flight,
      'Education': Icons.school,
      'Other': Icons.category,
    };

    return categoryIcons[category] ?? Icons.attach_money;
  }

  /// Formats a DateTime into a human-readable string
  static String? formatDate(DateTime? date, {bool includeTime = false}) {
    if (date == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return includeTime ? 'Today, ${formatTime(date)}' : 'Today';
    } else if (dateOnly == yesterday) {
      return includeTime ? 'Yesterday, ${formatTime(date)}' : 'Yesterday';
    }

    return includeTime
        ? '${formatDateShort(date)}, ${formatTime(date)}'
        : formatDateShort(date);
  }

  /// Formats a date into a short representation (day and month)
  static String formatDateShort(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  /// Formats time in 12-hour format
  static String formatTime(DateTime date) {
    final hour =
        date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
