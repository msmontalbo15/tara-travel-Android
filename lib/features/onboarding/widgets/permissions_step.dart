import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';

class PermissionsStep extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  const PermissionsStep({super.key, required this.onNext, required this.onSkip});

  @override
  State<PermissionsStep> createState() => _PermissionsStepState();
}

class _OnboardingPermissionHandler {
  static Future<bool> request(Permission permission) async {
    final status = await permission.request();
    return status.isGranted;
  }
}

class _PermissionsStepState extends State<PermissionsStep>
    with SingleTickerProviderStateMixin {
  bool _locationEnabled = false;
  bool _notificationsEnabled = false;
  bool _cameraEnabled = false;
  bool _calendarEnabled = false;

  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _animCtrl.forward();
    _checkInitialPermissions();
  }

  Future<void> _checkInitialPermissions() async {
    final results = await Future.wait([
      Permission.locationWhenInUse.status,
      Permission.notification.status,
      Permission.camera.status,
      Permission.calendarFullAccess.status,
    ]);

    if (mounted) {
      setState(() {
        _locationEnabled = results[0].isGranted;
        _notificationsEnabled = results[1].isGranted;
        _cameraEnabled = results[2].isGranted;
        _calendarEnabled = results[3].isGranted;
      });
    }
  }

  Future<void> _togglePermission(Permission permission, bool value, Function(bool) update) async {
    if (value) {
      final granted = await _OnboardingPermissionHandler.request(permission);
      update(granted);
    } else {
      // System permissions cannot be toggled off programmatically easily.
      // We just update the local UI state to reflect user preference.
      update(false);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: FadeTransition(
          opacity: _animCtrl,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),

                // Step pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Step 2 of 6',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                const Text(
                  'Quick\npermissions',
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enable what you need. Change these anytime in Settings.',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 28),

                // Permissions list
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder, width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _PermissionRow(
                        icon: Icons.location_on_outlined,
                        title: 'Location',
                        subtitle: 'Maps & nearby places',
                        value: _locationEnabled,
                        onChanged: (v) => _togglePermission(Permission.locationWhenInUse, v, (res) => setState(() => _locationEnabled = res)),
                        isFirst: true,
                      ),
                      _divider(),
                      _PermissionRow(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Trip reminders & updates',
                        value: _notificationsEnabled,
                        onChanged: (v) => _togglePermission(Permission.notification, v, (res) => setState(() => _notificationsEnabled = res)),
                      ),
                      _divider(),
                      _PermissionRow(
                        icon: Icons.photo_camera_outlined,
                        title: 'Camera & Photos',
                        subtitle: 'Upload receipts & photos',
                        value: _cameraEnabled,
                        onChanged: (v) => _togglePermission(Permission.camera, v, (res) => setState(() => _cameraEnabled = res)),
                      ),
                      _divider(),
                      _PermissionRow(
                        icon: Icons.calendar_today_outlined,
                        title: 'Calendar',
                        subtitle: 'Add trips to your calendar',
                        value: _calendarEnabled,
                        onChanged: (v) => _togglePermission(Permission.calendarFullAccess, v, (res) => setState(() => _calendarEnabled = res)),
                        isLast: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Center(
                  child: Text(
                    'Tara will ask again when you use features\nthat need these permissions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      color: AppColors.warmMuted.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                ),

                const Spacer(),

                // Continue button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: (_locationEnabled &&
                            _notificationsEnabled &&
                            _cameraEnabled &&
                            _calendarEnabled)
                        ? widget.onNext
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Skip for now
                Center(
                  child: GestureDetector(
                    onTap: widget.onSkip,
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() => const Divider(
        height: 0.5,
        indent: 56,
        endIndent: 0,
        color: AppColors.dividerLight,
      );
}

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isFirst;
  final bool isLast;

  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: value ? AppColors.sand : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: value ? AppColors.primary : AppColors.warmMuted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
