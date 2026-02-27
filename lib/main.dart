import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/permissions_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/active_session_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if a session is already active via MethodChannel to jump straight to ActiveSessionScreen
  const platform = MethodChannel('ironlock_channel');
  int remainingMilli = 0;
  bool allPermissionsGranted = false;

  try {
    remainingMilli = await platform.invokeMethod('isSessionActive');
  } catch (e) {
    debugPrint("Error checking session: $e");
  }

  // Check all permissions to decide the starting screen
  if (remainingMilli <= 0) {
    try {
      final hasAccessibility =
          await platform.invokeMethod('checkAccessibilityPermission') ?? false;
      final hasOverlay =
          await platform.invokeMethod('checkOverlayPermission') ?? false;
      final hasDeviceAdmin =
          await platform.invokeMethod('isDeviceAdminEnabled') ?? false;
      allPermissionsGranted = hasAccessibility && hasOverlay && hasDeviceAdmin;
    } catch (e) {
      debugPrint("Error checking permissions: $e");
    }
  }

  runApp(
    IronLockApp(
      initialRemainingTime: remainingMilli,
      allPermissionsGranted: allPermissionsGranted,
    ),
  );
}

class IronLockApp extends StatelessWidget {
  final int initialRemainingTime;
  final bool allPermissionsGranted;

  const IronLockApp({
    super.key,
    required this.initialRemainingTime,
    required this.allPermissionsGranted,
  });

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (initialRemainingTime > 0) {
      home = ActiveSessionScreen(remainingMilli: initialRemainingTime);
    } else if (allPermissionsGranted) {
      home = const SetupScreen();
    } else {
      home = const PermissionsScreen();
    }

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
      home: home,
    );
  }
}
