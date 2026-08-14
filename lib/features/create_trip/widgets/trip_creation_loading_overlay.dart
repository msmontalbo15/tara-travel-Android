import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../models/new_trip_model.dart';

enum TripCreationLoadingMode {
  create,
  draft,
}

class TripCreationLoadingOverlay extends StatefulWidget {
  final NewTripModel trip;
  final TripCreationLoadingMode mode;
  final double progress; // 0.0 to 1.0
  final bool isCompleted;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  const TripCreationLoadingOverlay({
    super.key,
    required this.trip,
    this.mode = TripCreationLoadingMode.create,
    required this.progress,
    this.isCompleted = false,
    this.errorMessage,
    this.onRetry,
    this.onCancel,
  });

  @override
  State<TripCreationLoadingOverlay> createState() =>
      _TripCreationLoadingOverlayState();
}

class _TripCreationLoadingOverlayState extends State<TripCreationLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _checkScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeOutBack,
    );

    if (widget.isCompleted) {
      _checkController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant TripCreationLoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isCompleted && widget.isCompleted) {
      _checkController.forward();
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  Color get _accentColor {
    if (widget.trip.coverColor != null) {
      return Color(widget.trip.coverColor!);
    }
    return AppColors.primary;
  }

  String _formatDateRange(DateTime? from, DateTime? to) {
    if (from == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (to == null || from.isAtSameMomentAs(to)) {
      return '${months[from.month - 1]} ${from.day}';
    }
    if (from.month == to.month) {
      return '${months[from.month - 1]} ${from.day} – ${to.day}';
    }
    return '${months[from.month - 1]} ${from.day} – ${months[to.month - 1]} ${to.day}';
  }

  String _getStatusText(double p) {
    if (widget.isCompleted) {
      return widget.mode == TripCreationLoadingMode.draft
          ? 'Draft saved'
          : 'Trip created';
    }
    if (widget.mode == TripCreationLoadingMode.draft) {
      return 'Saving draft…';
    }
    if (p < 0.35) return 'Saving trip details…';
    if (p < 0.70) return 'Setting up packing list…';
    return 'Finalizing…';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;
    final progressVal = widget.progress.clamp(0.0, 1.0);
    final percent = (progressVal * 100).round();
    final isDone = widget.isCompleted;

    final tripName = widget.trip.tripName.trim().isNotEmpty
        ? widget.trip.tripName.trim()
        : 'New Trip';
    final destination = widget.trip.destination.trim();
    final dateStr = _formatDateRange(widget.trip.fromDate, widget.trip.toDate);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Semi-transparent backdrop
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.65),
            ),
          ),

          // Clean Center Dialog
          Center(
            child: Container(
              width: 310,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1A19),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: widget.errorMessage != null
                  ? _buildErrorView()
                  : _buildMainView(
                      accent: accent,
                      tripName: tripName,
                      destination: destination,
                      dateStr: dateStr,
                      progressVal: progressVal,
                      percent: percent,
                      isDone: isDone,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainView({
    required Color accent,
    required String tripName,
    required String destination,
    required String dateStr,
    required double progressVal,
    required int percent,
    required bool isDone,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Spinner / Completed Checkmark
        SizedBox(
          width: 54,
          height: 54,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!isDone)
                CircularProgressIndicator(
                  value: progressVal > 0.05 ? progressVal : null,
                  strokeWidth: 3.2,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              if (!isDone)
                Icon(
                  widget.mode == TripCreationLoadingMode.draft
                      ? Icons.bookmark_border_rounded
                      : Icons.near_me_outlined,
                  size: 22,
                  color: accent,
                ),
              if (isDone)
                ScaleTransition(
                  scale: _checkScale,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Title
        Text(
          tripName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),

        // Destination & Date Subtitle
        if (destination.isNotEmpty || dateStr.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            [if (destination.isNotEmpty) destination, if (dateStr.isNotEmpty) dateStr]
                .join(' • '),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.55),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],

        const SizedBox(height: 18),

        // Thin Sleek Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: isDone ? 1.0 : progressVal,
            minHeight: 3.5,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(
              isDone ? const Color(0xFF10B981) : accent,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Status Label & Percentage
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _getStatusText(progressVal),
                key: ValueKey<String>(_getStatusText(progressVal)),
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDone
                      ? const Color(0xFF10B981)
                      : Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ),
            Text(
              isDone ? '100%' : '$percent%',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 26,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Unable to Save Trip',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.errorMessage ?? 'Please check your connection and try again.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12.5,
            color: Colors.white.withValues(alpha: 0.6),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            if (widget.onCancel != null)
              Expanded(
                child: TextButton(
                  onPressed: widget.onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white60,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    'Dismiss',
                    style: TextStyle(fontFamily: 'DM Sans', fontSize: 13),
                  ),
                ),
              ),
            if (widget.onRetry != null)
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
