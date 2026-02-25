import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'active_session_screen.dart';
import 'app_selection_sheet.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with SingleTickerProviderStateMixin {
  int _selectedHours = 0;
  int _selectedMinutes = 2; // Default 2 minutes for testing
  bool _isRequestingPermission = false;
  bool _isFullLockMode = true;
  List<String> _selectedApps = [];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final platform = const MethodChannel('ironlock_channel');

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkAndRequestPermissions() async {
    setState(() => _isRequestingPermission = true);
    try {
      bool hasAccessibility = await platform.invokeMethod(
        'checkAccessibilityPermission',
      );
      if (!hasAccessibility) {
        await platform.invokeMethod('requestAccessibilityPermission');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable Accessibility Service for IronLock'),
            ),
          );
        }
        setState(() => _isRequestingPermission = false);
        return;
      }

      bool hasOverlay = await platform.invokeMethod('checkOverlayPermission');
      if (!hasOverlay) {
        await platform.invokeMethod('requestOverlayPermission');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please allow IronLock to draw over other apps'),
            ),
          );
        }
        setState(() => _isRequestingPermission = false);
        return;
      }

      // For Full Lock mode, we need Device Admin permission
      if (_isFullLockMode) {
        bool hasDeviceAdmin = await platform.invokeMethod(
          'isDeviceAdminEnabled',
        );
        if (!hasDeviceAdmin) {
          await platform.invokeMethod('requestDeviceAdmin');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('يرجى تفعيل صلاحية مسؤول الجهاز لإطفاء الشاشة'),
                duration: Duration(seconds: 4),
              ),
            );
          }
          setState(() => _isRequestingPermission = false);
          return;
        }
      }

      // All permissions are ok, let's start the session
      _startSession();
    } catch (e) {
      debugPrint("Failed to get permissions: $e");
    }
    setState(() => _isRequestingPermission = false);
  }

  Future<void> _startSession() async {
    int totalMillis =
        (_selectedHours * 60 * 60 * 1000) + (_selectedMinutes * 60 * 1000);
    if (totalMillis <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid duration!')),
      );
      return;
    }

    if (!_isFullLockMode && _selectedApps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one app to lock!'),
        ),
      );
      return;
    }

    try {
      await platform.invokeMethod('startSession', {
        'durationMillis': totalMillis,
        'isFullLockMode': _isFullLockMode,
        'selectedApps': _selectedApps,
      });

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ActiveSessionScreen(remainingMilli: totalMillis),
          ),
        );
      }
    } catch (e) {
      debugPrint("Failed to start session: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
              vertical: 48.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Color(0xFFE50914),
                ),
                const SizedBox(height: 16),
                const Text(
                  'IRONLOCK',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'NO ESCAPE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 10,
                    color: Colors.white54,
                  ),
                ),
                const Spacer(),
                const Text(
                  'LOCK MODE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                _buildModeSelector(),
                const SizedBox(height: 32),
                const Text(
                  'SELECT DURATION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimeSelector(
                      label: 'HOURS',
                      value: _selectedHours,
                      onIncrease: () => setState(() => _selectedHours++),
                      onDecrease: () => setState(() {
                        if (_selectedHours > 0) _selectedHours--;
                      }),
                    ),
                    const SizedBox(width: 32),
                    _buildTimeSelector(
                      label: 'MINS',
                      value: _selectedMinutes,
                      onIncrease: () => setState(() {
                        if (_selectedMinutes < 59) _selectedMinutes++;
                      }),
                      onDecrease: () => setState(() {
                        if (_selectedMinutes > 0) _selectedMinutes--;
                      }),
                    ),
                  ],
                ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'WARNING: ONCE STARTED, YOU CANNOT CANCEL OR UNINSTALL UNTIL TIME IS UP.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE50914),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: GestureDetector(
                    onTap: _isRequestingPermission
                        ? null
                        : _checkAndRequestPermissions,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
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
                        'START LOCKDOWN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('FULL LOCK'),
              selected: _isFullLockMode,
              selectedColor: const Color(0xFFE50914),
              backgroundColor: Colors.white10,
              labelStyle: TextStyle(
                color: _isFullLockMode ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
              onSelected: (val) => setState(() => _isFullLockMode = true),
            ),
            const SizedBox(width: 16),
            ChoiceChip(
              label: const Text('SPECIFIC APPS'),
              selected: !_isFullLockMode,
              selectedColor: const Color(0xFFE50914),
              backgroundColor: Colors.white10,
              labelStyle: TextStyle(
                color: !_isFullLockMode ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
              onSelected: (val) => setState(() => _isFullLockMode = false),
            ),
          ],
        ),
        if (!_isFullLockMode) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final result = await showModalBottomSheet<List<String>>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 40,
                  ),
                  child: AppSelectionSheet(initialSelectedApps: _selectedApps),
                ),
              );
              if (result != null) {
                setState(() => _selectedApps = result);
              }
            },
            icon: const Icon(Icons.apps, color: Colors.white),
            label: Text(
              _selectedApps.isEmpty
                  ? 'Select Apps to Lock'
                  : '${_selectedApps.length} Apps Selected',
              style: const TextStyle(color: Colors.white),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE50914)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required int value,
    required VoidCallback onIncrease,
    required VoidCallback onDecrease,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: onIncrease,
          icon: const Icon(
            Icons.keyboard_arrow_up,
            color: Colors.white54,
            size: 36,
          ),
        ),
        Text(
          value.toString().padLeft(2, '0'),
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w200,
            color: Colors.white,
          ),
        ),
        IconButton(
          onPressed: onDecrease,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white54,
            size: 36,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 2,
            color: Colors.white38,
          ),
        ),
      ],
    );
  }
}
