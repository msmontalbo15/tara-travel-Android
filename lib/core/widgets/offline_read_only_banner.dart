import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';

/// Subtle, modern top-level banner notifying travelers when in Read-Only Offline Mode.
/// Automatically slides in when connection is lost and slides away when back online.
class OfflineReadOnlyBanner extends ConsumerWidget {
  const OfflineReadOnlyBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final isOnline = isOnlineAsync.value ?? true;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) => SizeTransition(
        sizeFactor: anim,
        axisAlignment: -1.0,
        child: child,
      ),
      child: !isOnline
          ? Container(
              key: const ValueKey('offline_banner_visible'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF2C1A14),
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE67E22),
                    width: 1.5,
                  ),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 16,
                    color: Color(0xFFF39C12),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Offline Mode — Viewing saved trip data (Read-Only)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFDEBD0),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(key: ValueKey('offline_banner_hidden')),
    );
  }
}
