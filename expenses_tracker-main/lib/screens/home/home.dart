import 'package:expenses_tracker/screens/profile_screen.dart';
import 'package:expenses_tracker/screens/stats/stats_screen.dart';
import 'package:expenses_tracker/widgets/goals_section.dart';
import 'package:expenses_tracker/widgets/recommendations.dart';
import 'package:flutter/material.dart';
import 'package:expenses_tracker/widgets/balance.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expenses_tracker/l10n/app_localizations.dart';
import 'package:expenses_tracker/l10n/language_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // existing state variable

  // new refresh function
  Future<void> _handleRefresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {});
  }

  // updated helper for home page content with refresh support
  Widget _buildHomePage() {
    final appLocalizations = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.locale.languageCode == 'ar';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // ensures refresh gesture
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .get(),
                        builder: (context, snapshot) {
                          String greeting = isRTL ? "مرحباً" : "G'day";
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Text(
                              "$greeting ...",
                              style: GoogleFonts.inter(
                                color: const Color(0xff1E1E1E),
                                fontWeight: FontWeight.bold,
                                fontSize: 30,
                              ),
                            );
                          }
                          if (snapshot.hasError ||
                              !snapshot.hasData ||
                              !snapshot.data!.exists) {
                            return Text(
                              "$greeting ${isRTL ? 'المستخدم' : 'User'}",
                              style: GoogleFonts.inter(
                                color: const Color(0xff1E1E1E),
                                fontWeight: FontWeight.bold,
                                fontSize: 30,
                              ),
                            );
                          }
                          final username = snapshot.data!.get('username');
                          return Text(
                            "$greeting $username",
                            style: GoogleFonts.inter(
                              color: const Color(0xff1E1E1E),
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                Balance(),
                Recommendations(),
                const SizedBox(height: 28),
                GoalsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // new placeholder for stats page
  Widget _buildStatsPage() {
    return StatsScreen();
  }

  // new placeholder for profile page
  Widget _buildProfilePage() {
    return ProfileScreen();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.locale.languageCode == 'ar';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() {
            _selectedIndex = index;
            // navigation changed by updating _selectedIndex
          }),
          elevation: 10,
          backgroundColor: Colors.white,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.normal,
            fontSize: 11,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: isRTL ? 'الرئيسية' : 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: isRTL ? 'الإحصائيات' : 'Stats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: isRTL ? 'الملف الشخصي' : 'Profile',
            ),
          ],
        ),
        // body changed to display pages based on selected index
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomePage(),
            _buildStatsPage(),
            _buildProfilePage(),
          ],
        ),
      ),
    );
  }
}
