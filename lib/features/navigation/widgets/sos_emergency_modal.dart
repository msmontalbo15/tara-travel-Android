import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_responsive.dart';
import '../models/navigation_models.dart';
import '../providers/navigation_provider.dart';
import 'navigate_to_member_sheet.dart';

/// Modal to trigger an emergency SOS beacon to all trip members.
class SosEmergencyModal extends StatefulWidget {
  const SosEmergencyModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const SosEmergencyModal(),
    );
  }

  @override
  State<SosEmergencyModal> createState() => _SosEmergencyModalState();
}

class _SosEmergencyModalState extends State<SosEmergencyModal> {
  final TextEditingController _msgController = TextEditingController(
    text: "I'm separated from the group and need regrouping.",
  );
  bool _isSending = false;

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        context.keyboardBottomPadding(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCEBEB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sos_rounded,
                  color: Color(0xFFE24A4A),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency SOS Beacon',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE24A4A),
                      ),
                    ),
                    Text(
                      'Broadcast live coordinates to all group members',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Presets
          const Text(
            'QUICK SITUATION PRESETS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8E8E93),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _presetChip("I'm lost, please wait"),
              _presetChip('Vehicle breakdown / Flat tire'),
              _presetChip('Medical / Urgent assistance'),
              _presetChip('Battery low (<15%)'),
            ],
          ),
          const SizedBox(height: 14),

          // Custom message field
          TextField(
            controller: _msgController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Describe your emergency or location details...',
              filled: true,
              fillColor: const Color(0xFFF9F7F5),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFECE5DE)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE24A4A), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Broadcast Button
          Consumer(
            builder: (context, ref, _) {
              return ElevatedButton.icon(
                onPressed: _isSending
                    ? null
                    : () async {
                        setState(() => _isSending = true);
                        HapticFeedback.heavyImpact();
                        await ref
                            .read(navigationProvider.notifier)
                            .triggerSos(_msgController.text.trim());
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🚨 Emergency SOS Broadcasted to all members!'),
                              backgroundColor: Color(0xFFE24A4A),
                              duration: Duration(seconds: 4),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.emergency_share_rounded, size: 20),
                label: Text(_isSending ? 'Broadcasting...' : 'BROADCAST SOS BEACON'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE24A4A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _presetChip(String text) {
    return ActionChip(
      label: Text(text),
      labelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      backgroundColor: const Color(0xFFF2F2F7),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      onPressed: () {
        HapticFeedback.selectionClick();
        setState(() {
          _msgController.text = text;
        });
      },
    );
  }
}

/// Urgent flashing SOS Alert Banner rendered across screens when a companion triggers SOS.
class ActiveSosAlertBanner extends ConsumerWidget {
  const ActiveSosAlertBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navigationProvider);
    final sos = nav.activeSos;
    if (sos == null) return const SizedBox.shrink();

    final targetMember = nav.members.firstWhere(
      (m) => m.id == sos.memberId,
      orElse: () => NavMember(
        id: sos.memberId,
        name: sos.memberName,
        initials: sos.memberName.isNotEmpty ? sos.memberName[0] : 'S',
        color: const Color(0xFFE24A4A),
        status: MemberStatus.enRoute,
        role: 'Companion',
        latitude: sos.lat,
        longitude: sos.lng,
        batteryLevel: sos.batteryLevel,
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF8A0000),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Color(0xFF8A0000),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🚨 SOS ALERT FROM ${sos.memberName.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Battery: ${sos.batteryLevel}% · ${sos.message}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFFD0D0),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () =>
                    ref.read(navigationProvider.notifier).dismissSos(),
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white70, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    ref
                        .read(navigationProvider.notifier)
                        .navigateToMember(targetMember);
                    NavigateToMemberSheet.show(context, targetMember);
                  },
                  icon: const Icon(Icons.navigation_rounded, size: 16),
                  label: const Text('NAVIGATE TO RESCUE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF8A0000),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                    minimumSize: const Size(0, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
