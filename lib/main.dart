import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/setup_screen.dart';
import 'screens/active_session_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if a session is already active via MethodChannel to jump straight to ActiveSessionScreen
  const platform = MethodChannel('ironlock_channel');
  int remainingMilli = 0;
  try {
    remainingMilli = await platform.invokeMethod('isSessionActive');
  } catch (e) {
    debugPrint("Error checking session: $e");
  }

  runApp(IronLockApp(initialRemainingTime: remainingMilli));
}

class IronLockApp extends StatelessWidget {
  final int initialRemainingTime;

  const IronLockApp({super.key, required this.initialRemainingTime});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IronLock - No Escape',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        primaryColor: const Color(0xFFE50914),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE50914),
          secondary: Color(0xFF1F1F1F),
        ),
        fontFamily: 'Roboto',
      ),
      home: initialRemainingTime > 0
          ? ActiveSessionScreen(remainingMilli: initialRemainingTime)
          : const SetupScreen(),
    );
  }
}
