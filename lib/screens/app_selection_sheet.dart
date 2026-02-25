import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class AppSelectionSheet extends StatefulWidget {
  final List<String> initialSelectedApps;

  const AppSelectionSheet({super.key, required this.initialSelectedApps});

  @override
  State<AppSelectionSheet> createState() => _AppSelectionSheetState();
}

class _AppSelectionSheetState extends State<AppSelectionSheet> {
  List<AppInfo> _installedApps = [];
  List<AppInfo> _filteredApps = [];
  Set<String> _selectedAppPackageNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedAppPackageNames = Set.from(widget.initialSelectedApps);
    _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      // Get all installed apps excluding system apps to keep the list clean
      List<AppInfo> apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        withIcon: true,
      );

      apps.sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        _installedApps = apps;
        _filteredApps = apps;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading apps: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterApps(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredApps = _installedApps;
      } else {
        _filteredApps = _installedApps
            .where(
              (app) => app.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  void _toggleAppSelection(String packageName) {
    setState(() {
      if (_selectedAppPackageNames.contains(packageName)) {
        _selectedAppPackageNames.remove(packageName);
      } else {
        _selectedAppPackageNames.add(packageName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C0000),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Apps to Lock',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pop(_selectedAppPackageNames.toList());
                    },
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: Color(0xFFE50914),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: _filterApps,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search apps...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFE50914),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredApps.length,
                      itemBuilder: (context, index) {
                        final app = _filteredApps[index];
                        final isSelected = _selectedAppPackageNames.contains(
                          app.packageName,
                        );

                        return ListTile(
                          leading: app.icon != null
                              ? Image.memory(app.icon!, width: 40, height: 40)
                              : const Icon(
                                  Icons.android,
                                  color: Colors.white54,
                                ),
                          title: Text(
                            app.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            app.packageName,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (_) =>
                                _toggleAppSelection(app.packageName),
                            activeColor: const Color(0xFFE50914),
                            checkColor: Colors.white,
                          ),
                          onTap: () => _toggleAppSelection(app.packageName),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
