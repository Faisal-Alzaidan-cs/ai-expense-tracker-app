import 'package:expenses_tracker/screens/registration/forget_password.dart';
import 'package:expenses_tracker/screens/registration/registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:expenses_tracker/screens/home/home.dart';
import 'package:expenses_tracker/screens/registration/welcome_screen.dart';
import 'package:expenses_tracker/screens/registration/login_screen.dart';
import 'package:expenses_tracker/screens/stats/stats_screen.dart';
import 'package:expenses_tracker/screens/profile_screen.dart';
import 'package:expenses_tracker/services/auth_wrapper.dart';
import 'package:expenses_tracker/l10n/language_provider.dart';
import 'package:expenses_tracker/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

/// AppScreen class is a stateless class representing the home page
/// of the applicaiton of a logged-in user, the current home page contains
/// sets of blocks for balance, ai recommendation and saving goals.

class AppScreen extends StatelessWidget {
  const AppScreen({super.key});

  // final bool page;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LanguageProvider(),
      child: Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
        return MaterialApp(
          locale: languageProvider.locale,
          supportedLocales: const [
            Locale('en'), // English
            Locale('ar'), // Arabic
          ],
          localizationsDelegates: [
            const AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            // The main container for the applicaiton
            // Using AuthWrapper to check if user is already logged in
            body: AuthWrapper(),
          ),
          routes: {
            "/welcome": (context) => WelcomeScreen(),
            "/login": (context) => LoginScreen(),
            "/register": (context) => RegistrationScreen(),
            "/registeration": (context) => RegistrationScreen(),
            "/forgotPassword": (context) => ForgotPasswordScreen(),
            "/home": (context) => HomeScreen(),
            "/stats": (context) => StatsScreen(),
            "/profile": (context) => ProfileScreen(),
          },
        );
      }),
    );
  }
}
