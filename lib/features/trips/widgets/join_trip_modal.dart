import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/trip_provider.dart';

import '../../../core/widgets/feedback/app_feedback.dart';

/// Opens a modal bottom-sheet that lets the user enter a 6-character trip
/// invite code. On success, the `allTripsProvider` is refreshed and the sheet
/// is dismissed with a success snackbar.
void showJoinTripModal(BuildContext context, [WidgetRef? ref]) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _JoinTripSheet(),
  );
}

// ── Private Sheet Widget ─────────────────────────────────────────────────────

class _JoinTripSheet extends ConsumerStatefulWidget {
  const _JoinTripSheet();

  @override
  ConsumerState<_JoinTripSheet> createState() => _JoinTripSheetState();
}

class _JoinTripSheetState extends ConsumerState<_JoinTripSheet> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final rawText = _codeController.text;
    final code = rawText.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter a 6-character invite code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(tripRepositoryProvider);
      final result = await repo.joinTripByCode(code);

      // Always refresh trips list and active trip cache
      ref.invalidate(allTripsProvider);
      ref.invalidate(activeTripProvider);

      if (mounted) {
        Navigator.pop(context);
        if (result.alreadyMember) {
          AppFeedback.showInfo(
            context,
            'You are already a member of "${result.tripName}".',
            title: 'Already Joined',
          );
        } else if (result.alreadyPending) {
          AppFeedback.showWarning(
            context,
            'Your join request for "${result.tripName}" is currently pending approval.',
            title: 'Pending Request',
            duration: const Duration(seconds: 4),
          );
        } else if (result.isApproved) {
          AppFeedback.showSuccess(
            context,
            'You joined "${result.tripName}"! 🎉',
            title: 'Welcome Aboard!',
          );
        } else {
          // Status is pending — organizer needs to approve
          AppFeedback.showWarning(
            context,
            'Join request sent for "${result.tripName}". Waiting for organizer approval.',
            title: 'Request Sent',
            duration: const Duration(seconds: 5),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + keyboardSpace),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ─────────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Join a Trip',
                style: AppTextStyles.headline2.copyWith(
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the 6-character invite code from your trip organizer.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 12,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. TAR4BC',
                  counterText: '',
                  errorText: _error,
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: AppColors.red, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: AppColors.red, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.tag_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                ),
                onChanged: (v) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _isLoading ? null : _join(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _join,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Join Trip',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
