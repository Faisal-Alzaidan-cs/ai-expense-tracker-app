import 'package:flutter/material.dart';
import 'home/layout_builder_page.dart';
import 'package:expenses_tracker/services/firebase_auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expenses_tracker/l10n/app_localizations.dart';
import 'package:expenses_tracker/l10n/language_provider.dart';
import 'package:provider/provider.dart';
import 'about_screen.dart';

class ProfileScreen extends StatelessWidget {
  final FirebaseAuthService _authService = FirebaseAuthService();

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          appLocalizations.profile,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: Directionality(
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(context),
                SizedBox(height: 16),
                _buildCategoryTitle(appLocalizations.appSettings, context),
                _buildLanguageMenuTile(
                    context, appLocalizations, languageProvider),
                SizedBox(height: 16),
                _buildCategoryTitle(appLocalizations.support, context),
                _buildMenuTile(
                  context,
                  icon: Icons.info_outline,
                  title: appLocalizations.about,
                  subtitle: appLocalizations.appInfo,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AboutScreen()),
                  ),
                ),
                SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _authService.signOut();
                      Navigator.pushNamedAndRemoveUntil(
                          context, "/welcome", (route) => false);
                    },
                    icon: Icon(Icons.logout_rounded),
                    label: Text(appLocalizations.logout),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageMenuTile(BuildContext context,
      AppLocalizations appLocalizations, LanguageProvider languageProvider) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFFE6F7E6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.language,
            color: Color(0xFF41C041),
          ),
        ),
        title: Text(
          appLocalizations.language,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          appLocalizations.changeLanguage,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        children: [
          ListTile(
            title: Text(
              appLocalizations.english,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: languageProvider.locale.languageCode == 'en'
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: languageProvider.locale.languageCode == 'en'
                    ? Color(0xFF41C041)
                    : Colors.black87,
              ),
            ),
            trailing: languageProvider.locale.languageCode == 'en'
                ? Icon(
                    Icons.check_circle,
                    color: Color(0xFF41C041),
                  )
                : null,
            onTap: () {
              languageProvider.setLocale(Locale('en'));
            },
          ),
          ListTile(
            title: Text(
              appLocalizations.arabic,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: languageProvider.locale.languageCode == 'ar'
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: languageProvider.locale.languageCode == 'ar'
                    ? Color(0xFF41C041)
                    : Colors.black87,
              ),
            ),
            trailing: languageProvider.locale.languageCode == 'ar'
                ? Icon(
                    Icons.check_circle,
                    color: Color(0xFF41C041),
                  )
                : null,
            onTap: () {
              languageProvider.setLocale(Locale('ar'));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF41C041),
            Color(0xFF2E8B2E),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF41C041).withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser?.uid)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text(
                            "Loading...",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        if (snapshot.hasError ||
                            !snapshot.hasData ||
                            !snapshot.data!.exists) {
                          return Text(
                            "User",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        final username = snapshot.data!.get('username');
                        return Text(
                          username.toString(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 4),
                    Text(
                      FirebaseAuth.instance.currentUser?.email ?? "No email",
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Edit profile action
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFFE6F7E6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Color(0xFF41C041),
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Colors.black54,
        ),
        onTap: onTap,
      ),
    );
  }
}
