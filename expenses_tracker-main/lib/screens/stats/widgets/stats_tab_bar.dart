import 'package:flutter/material.dart';
import 'package:expenses_tracker/l10n/app_localizations.dart';

/// Tab bar widget for the stats screen
class StatsTabBar extends StatelessWidget {
  final TabController tabController;
  final Function(int) onTabChanged;

  const StatsTabBar({
    Key? key,
    required this.tabController,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1.0,
          ),
        ),
      ),
      child: TabBar(
        controller: tabController,
        indicatorColor: Colors.blue.shade700,
        indicatorWeight: 3.0,
        labelColor: Colors.blue.shade700,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        unselectedLabelColor: Colors.grey.shade600,
        tabs: [
          Tab(
            text: localizations.expenses,
            icon: const Icon(Icons.account_balance_wallet, size: 20),
          ),
          Tab(
            text: localizations.smsExpenses,
            icon: const Icon(Icons.message, size: 20),
          ),
        ],
        onTap: onTabChanged,
      ),
    );
  }
}
