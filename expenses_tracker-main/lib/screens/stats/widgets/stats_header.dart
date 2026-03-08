import 'package:flutter/material.dart';
import 'package:expenses_tracker/l10n/app_localizations.dart';

/// Header widget for the stats screen
class StatsHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  final int currentTabIndex;

  const StatsHeader({
    Key? key,
    required this.onRefresh,
    required this.currentTabIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.insights,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                localizations.statistics,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        FloatingActionButton(
          mini: true,
          onPressed: onRefresh,
          backgroundColor: Colors.blue.shade700,
          child: Icon(currentTabIndex == 1 ? Icons.message : Icons.refresh,
              size: 20),
        ),
      ],
    );
  }
}
