// 🔴 قم بلصق السطر الأول الذي نسخته هنا (سطر الـ package) 🔴

import android.app.Service
import android.app.admin.DeviceAdminReceiver
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.IBinder
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// هذا الكلاس ضروري لكي يعترف الأندرويد بأن التطبيق "مدير للجهاز"
class DeviceAdmin : DeviceAdminReceiver() {}

// هذه خدمة خلفية فارغة مؤقتاً لكي لا يتعطل التطبيق، سنبرمجها لاحقاً لقفل التطبيقات المحددة
class AppLockService : Service() {
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}

class MainActivity: FlutterActivity() {
    // هذه هي القناة التي سيتواصل بها فلاتر مع أندرويد
    private val CHANNEL = "ironlock/native_lock"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val compName = ComponentName(this, DeviceAdmin::class.java)

            when (call.method) {
                // أمر للتحقق مما إذا كان المستخدم أعطى صلاحية القفل
                "isDeviceAdminEnabled" -> {
                    val active = devicePolicyManager.isAdminActive(compName)
                    result.success(active)
                }
                // أمر لفتح شاشة الإعدادات ليقوم المستخدم بتفعيل الصلاحية
                "requestDeviceAdmin" -> {
                    val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
                    intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, compName)
                    intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "يجب تفعيل هذه الصلاحية ليتمكن التطبيق من إطفاء الشاشة كلياً كزر الباور.")
                    startActivity(intent)
                    result.success(true)
                }
                // أمر القفل الفعلي (إطفاء الشاشة)
                "lockScreen" -> {
                    val active = devicePolicyManager.isAdminActive(compName)
                    if (active) {
                        devicePolicyManager.lockNow() // هذا هو كود إطفاء الشاشة الفعلي!
                        result.success(true)
                    } else {
                        // إذا لم تكن الصلاحية مفعلة، نطلب من المستخدم تفعيلها
                        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
                        intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, compName)
                        intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "التطبيق يحتاج هذه الصلاحية ليتمكن من إطفاء الشاشة.")
                        startActivity(intent)
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
