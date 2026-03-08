import 'package:flutter/material.dart';
import 'package:expenses_tracker/screens/stats/enums.dart';
import 'package:expenses_tracker/l10n/app_localizations.dart';

/// Widget for selecting time range (daily, weekly, monthly)
class RangeSelector extends StatelessWidget {
  final TimeRange selectedRange;
  final Function(TimeRange) onRangeChanged;

  const RangeSelector({
    Key? key,
    required this.selectedRange,
    required this.onRangeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildRangeButton(context, TimeRange.daily, localizations.daily),
            _buildRangeButton(context, TimeRange.weekly, localizations.weekly),
            _buildRangeButton(
                context, TimeRange.monthly, localizations.monthly),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeButton(
      BuildContext context, TimeRange range, String label) {
    final isSelected = selectedRange == range;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () => onRangeChanged(range),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isSelected ? Colors.blue.shade700 : Colors.grey.shade200,
            foregroundColor: isSelected ? Colors.white : Colors.black87,
            elevation: isSelected ? 2 : 0,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
