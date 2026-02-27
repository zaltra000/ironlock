import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'setup_screen.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  final platform = const MethodChannel('ironlock_channel');

  bool _hasAccessibility = false;
  bool _hasOverlay = false;
  bool _hasDeviceAdmin = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-check permissions when user comes back from system settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAllPermissions();
    }
  }

  Future<void> _checkAllPermissions() async {
    setState(() => _isChecking = true);
    try {
      _hasAccessibility =
          await platform.invokeMethod('checkAccessibilityPermission') ?? false;
      _hasOverlay =
          await platform.invokeMethod('checkOverlayPermission') ?? false;
      _hasDeviceAdmin =
          await platform.invokeMethod('isDeviceAdminEnabled') ?? false;
    } catch (e) {
      debugPrint("Error checking permissions: $e");
    }

    setState(() => _isChecking = false);

    // If all permissions are granted, navigate to setup screen
    if (_hasAccessibility && _hasOverlay && _hasDeviceAdmin && mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const SetupScreen()));
    }
  }

  Future<void> _requestPermission(String method) async {
    try {
      await platform.invokeMethod(method);
    } catch (e) {
      debugPrint("Error requesting permission: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final allGranted = _hasAccessibility && _hasOverlay && _hasDeviceAdmin;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0000), Color(0xFF1C0000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 64,
                  color: Color(0xFFE50914),
                ),
                const SizedBox(height: 16),
                const Text(
                  'إعداد الصلاحيات',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'IronLock يحتاج هذه الصلاحيات ليعمل بشكل صحيح.\nفعّلها واحدة واحدة ثم ابدأ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // 1. Accessibility
                _buildPermissionTile(
                  icon: Icons.accessibility_new,
                  title: 'إمكانية الوصول',
                  subtitle: 'لمراقبة التطبيقات المفتوحة وحظرها',
                  isGranted: _hasAccessibility,
                  onTap: () =>
                      _requestPermission('requestAccessibilityPermission'),
                ),
                const SizedBox(height: 16),

                // 2. Overlay
                _buildPermissionTile(
                  icon: Icons.layers,
                  title: 'العرض فوق التطبيقات',
                  subtitle: 'لعرض شاشة الحظر فوق التطبيقات المحظورة',
                  isGranted: _hasOverlay,
                  onTap: () => _requestPermission('requestOverlayPermission'),
                ),
                const SizedBox(height: 16),

                // 3. Device Admin
                _buildPermissionTile(
                  icon: Icons.admin_panel_settings,
                  title: 'مسؤول الجهاز',
                  subtitle: 'لإطفاء الشاشة فعلياً في وضع الإغلاق الكامل',
                  isGranted: _hasDeviceAdmin,
                  onTap: () => _requestPermission('requestDeviceAdmin'),
                ),

                const Spacer(),

                if (_isChecking)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFE50914),
                      ),
                    ),
                  )
                else if (allGranted)
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const SetupScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE50914),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFE50914,
                            ).withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Text(
                        'متابعة ➜',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'فعّل جميع الصلاحيات أعلاه',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white38),
                    ),
                  ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isGranted ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isGranted
              ? const Color(0xFF0A2E0A)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isGranted
                ? const Color(0xFF2E7D32)
                : const Color(0xFFE50914).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isGranted
                    ? const Color(0xFF2E7D32).withValues(alpha: 0.3)
                    : const Color(0xFFE50914).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isGranted ? Colors.green : const Color(0xFFE50914),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
            ),
            Icon(
              isGranted ? Icons.check_circle : Icons.arrow_forward_ios,
              color: isGranted ? Colors.green : Colors.white38,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
