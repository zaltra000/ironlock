import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class NativeLockService {
  static const platform = MethodChannel('ironlock_channel');

  /// Check if Device Admin permission is enabled
  static Future<bool> isDeviceAdminEnabled() async {
    try {
      final result = await platform.invokeMethod('isDeviceAdminEnabled');
      return result as bool;
    } catch (e) {
      debugPrint("Error checking Device Admin: $e");
      return false;
    }
  }

  /// Request Device Admin permission (opens system dialog)
  static Future<void> requestDeviceAdmin() async {
    try {
      await platform.invokeMethod('requestDeviceAdmin');
    } catch (e) {
      debugPrint("Error requesting Device Admin: $e");
    }
  }

  /// Lock the screen immediately (like pressing the power button)
  static Future<void> lockScreen() async {
    try {
      await platform.invokeMethod('lockScreen');
    } catch (e) {
      debugPrint("Error locking screen: $e");
    }
  }
}
