import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import 'package:expenses_tracker/screens/home/app_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter framework is properly initialized before
  // running any code that interacts with Flutter's engine or platform channels.
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then(
    (fn) => runApp(
      AppScreen(),
    ),
  );
}
