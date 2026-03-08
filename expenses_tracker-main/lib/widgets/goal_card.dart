import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expenses_tracker/l10n/language_provider.dart';
import 'package:provider/provider.dart';

class GoalCard extends StatelessWidget {
  final String title;
  final int currentAmount;
  final int targetAmount;
  final int monthlySavings;

  const GoalCard({
    required this.title,
    required this.currentAmount,
    required this.targetAmount,
    required this.monthlySavings,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    double progress = targetAmount > 0 ? currentAmount / targetAmount : 0;
    final theme = Theme.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.locale.languageCode == 'ar';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.blue.shade100, width: 1.5),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Colors.blue.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$monthlySavings',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        SizedBox(width: 2),
                        Image.asset(
                          'assets/Saudi_Riyal_Symbol-1.png',
                          width: 18,
                          height: 18,
                          color: Colors.blue.shade600,
                        ),
                        Text(
                          isRTL ? '/شهر' : '/month',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        isRTL ? 'التقدم: ' : 'Progress: ',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: progress == 1
                              ? Colors.green
                              : Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$currentAmount / $targetAmount',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  color: progress == 1
                      ? Colors.green.shade400
                      : Colors.blue.shade400,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
