import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expenses_tracker/screens/home/coin_ai_screen.dart';
import 'package:expenses_tracker/l10n/language_provider.dart';
import 'package:provider/provider.dart';

class Recommendations extends StatelessWidget {
  @override

  // COIN AI Section
  // This widget displays the Coin-AI recommendation card with a modern design
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.locale.languageCode == 'ar';

    return InkWell(
      onTap: () {
        // Navigate to the Coin-AI screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CoinAIScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4BC43E), Color(0xFF2E8A25)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        margin: const EdgeInsets.only(
          top: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Coin-AI",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isRTL ? Icons.arrow_back : Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isRTL
                  ? "توصيات ذكية لأموالك"
                  : "Smart recommendations for your finances",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFeatureItem(
                    Icons.coffee_outlined, isRTL ? "قهوة" : "Coffee", isRTL),
                _buildFeatureItem(Icons.commute_outlined,
                    isRTL ? "مواصلات" : "Transport", isRTL),
                _buildFeatureItem(Icons.shopping_bag_outlined,
                    isRTL ? "تسوق" : "Shopping", isRTL),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label, bool isRTL) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 24,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
