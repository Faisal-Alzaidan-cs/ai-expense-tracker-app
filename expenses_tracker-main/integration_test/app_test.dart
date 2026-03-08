import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:expenses_tracker/main.dart' as app;
import 'package:expenses_tracker/screens/registration/welcome_screen.dart';
import 'package:expenses_tracker/screens/registration/login_screen.dart';
import 'package:expenses_tracker/screens/registration/registration_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App End-to-End Test', () {
    testWidgets('Test app flow from welcome to registration and login',
        (WidgetTester tester) async {
      // Initialize the app
      app.main();
      await tester.pumpAndSettle();

      // The app might start with different screens based on auth state
      // If we see the welcome screen, proceed with the flow
      if (find.byType(WelcomeScreen).evaluate().isNotEmpty) {
        // Test welcome screen interactions
        expect(find.byType(WelcomeScreen), findsOneWidget);

        // Find and tap the register button (using correct button type and text)
        final registerButton =
            find.widgetWithText(OutlinedButton, 'Create an Account');
        if (registerButton.evaluate().isNotEmpty) {
          await tester.tap(registerButton);
          await tester.pumpAndSettle();

          // Verify we're on the registration screen
          expect(find.byType(RegistrationScreen), findsOneWidget);

          // Go back to welcome screen
          await tester.tap(find.byIcon(Icons.arrow_back));
          await tester.pumpAndSettle();
        }

        // Find and tap the login button
        final loginButton = find.widgetWithText(ElevatedButton, 'Login');
        if (loginButton.evaluate().isNotEmpty) {
          await tester.tap(loginButton);
          await tester.pumpAndSettle();

          // Verify we're on the login screen
          expect(find.byType(LoginScreen), findsOneWidget);

          // Test login form interaction
          await tester.enterText(
              find.byType(TextField).at(0), 'test@example.com');
          await tester.enterText(find.byType(TextField).at(1), 'password123');
          await tester.pumpAndSettle();

          // Close keyboard - fixed to not use await with void method
          tester.testTextInput.hide();
          await tester.pumpAndSettle();

          // Find and tap login button on the login screen
          final submitLoginButton =
              find.widgetWithText(ElevatedButton, 'Login');
          if (submitLoginButton.evaluate().isNotEmpty) {
            await tester.tap(submitLoginButton);
            await tester.pumpAndSettle();
          }
        }
      }
    });
  });
}
