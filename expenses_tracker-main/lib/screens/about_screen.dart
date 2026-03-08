import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expenses_tracker/l10n/app_localizations.dart';
import 'package:expenses_tracker/l10n/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String appVersion = '';
  String appName = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getPackageInfo();
  }

  Future<void> _getPackageInfo() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      setState(() {
        appName = info.appName;
        appVersion = '${info.version} (${info.buildNumber})';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        appName = 'Expenses Tracker';
        appVersion = '1.0.0';
        isLoading = false;
      });
    }
  }

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
          appLocalizations.about,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: Directionality(
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFF41C041)))
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 32),
                      // App Logo
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Color(0xFF41C041),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF41C041).withOpacity(0.3),
                              offset: Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.attach_money_rounded,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 24),

                      // App Name
                      Text(
                        appName,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),

                      // Version
                      Text(
                        'Version $appVersion',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: 32),

                      // Description Section
                      _buildInfoSection(
                        title: 'Description',
                        content:
                            'Expenses Tracker is a personal finance application designed to help you track and manage your expenses efficiently. The app features SMS scanning to automatically detect and categorize your spending.',
                      ),

                      _buildInfoSection(
                        title: 'Features',
                        content:
                            '• Automatic SMS expense detection\n• Expense categorization\n• Visual statistics and reports\n• Multi-language support (English & Arabic)\n• Secure data storage',
                      ),

                      _buildInfoSection(
                        title: 'Developed By',
                        content:
                            'Osama Mohammed\nFaisal Khalid\nSaeed Faisal\n',
                      ),

                      SizedBox(height: 24),

                      // Contact Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildContactButton(
                            icon: Icons.email_outlined,
                            text: 'Email',
                            onTap: () =>
                                _launchUrl('mailto:iosamalearns@gmail.com'),
                          ),
                          SizedBox(width: 16),
                        ],
                      ),

                      SizedBox(height: 40),

                      Text(
                        '© ${DateTime.now().year} Expenses Tracker. All rights reserved.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInfoSection({required String title, required String content}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 24),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF41C041),
            ),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(
      {required IconData icon,
      required String text,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: Color(0xFF41C041).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Color(0xFF41C041), size: 20),
            SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF41C041),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $urlString')),
      );
    }
  }
}
