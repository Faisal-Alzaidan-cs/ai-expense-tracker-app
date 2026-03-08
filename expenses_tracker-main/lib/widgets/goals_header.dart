import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expenses_tracker/l10n/language_provider.dart';
import 'package:provider/provider.dart';

class GoalsHeader extends StatelessWidget {
  final VoidCallback onAddGoal;

  GoalsHeader({super.key, required this.onAddGoal});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.locale.languageCode == 'ar';

    return GestureDetector(
      onTap: onAddGoal,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              isRTL ? 'إضافة هدف' : 'Add Goal',
              style: GoogleFonts.poppins(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 4),
            Icon(
              Icons.add_circle,
              color: Colors.blue.shade800,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
