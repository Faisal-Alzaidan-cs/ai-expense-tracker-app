import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:expenses_tracker/screens/home/home.dart';
import 'package:expenses_tracker/screens/registration/welcome_screen.dart';

/// AuthWrapper is a widget that checks if a user is already logged in.
/// If they are, it sends them directly to the home screen.
/// If not, it shows the welcome screen.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If we have a user logged in
        if (snapshot.hasData && snapshot.data != null) {
          // Navigate to home screen
          return const HomeScreen();
        }
        // Otherwise show the welcome screen
        return const WelcomeScreen();
      },
    );
  }
}
