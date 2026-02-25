import 'package:flutter/services.dart';

class NativeLockService {
  // اسم القناة يجب أن يتطابق مع ما كتبناه في الأندرويد
  static const MethodChannel _channel = MethodChannel('ironlock/native_lock');

  /// طلب صلاحية القفل من المستخدم (تفتح شاشة إعدادات الأندرويد ليوافق المستخدم)
  static Future<void> requestDeviceAdmin() async {
    try {
      await _channel.invokeMethod('requestDeviceAdmin');
    } on PlatformException catch (e) {
      print("خطأ في طلب الصلاحية: '${e.message}'.");
    }
  }

  /// التحقق مما إذا كان المستخدم قد وافق على إعطاء التطبيق صلاحية إغلاق الشاشة
  static Future<bool> isDeviceAdminEnabled() async {
    try {
      final bool result = await _channel.invokeMethod('isDeviceAdminEnabled');
      return result;
    } on PlatformException catch (e) {
      print("خطأ في فحص الصلاحية: '${e.message}'.");
      return false;
    }
  }

  /// أمر الإغلاق الفعلي (يطفئ الشاشة كلياً وكأنك ضغطت زر الباور)
  static Future<void> lockScreen() async {
    try {
      await _channel.invokeMethod('lockScreen');
    } on PlatformException catch (e) {
      print("خطأ في إغلاق الشاشة: '${e.message}'.");
    }
  }
}
