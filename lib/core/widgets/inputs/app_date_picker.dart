import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';

class AppDatePicker extends StatelessWidget {
  final String label;
  final String? hint;
  final DateTime? selectedDate;
  final DateTimeRange? selectedRange;
  final ValueChanged<DateTime>? onDateSelected;
  final ValueChanged<DateTimeRange>? onRangeSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? errorText;

  const AppDatePicker({
    super.key,
    required this.label,
    this.hint,
    this.selectedDate,
    this.selectedRange,
    this.onDateSelected,
    this.onRangeSelected,
    this.firstDate,
    this.lastDate,
    this.errorText,
  });

  String _formatDisplayValue() {
    final format = DateFormat('MMM dd, yyyy');
    if (selectedRange != null) {
      return '${format.format(selectedRange!.start)} - ${format.format(selectedRange!.end)}';
    }
    if (selectedDate != null) {
      return format.format(selectedDate!);
    }
    return '';
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final start = firstDate ?? now.subtract(const Duration(days: 365 * 5));
    final end = lastDate ?? now.add(const Duration(days: 365 * 5));

    if (onRangeSelected != null) {
      final initialRange = selectedRange ??
          DateTimeRange(
            start: now,
            end: now.add(const Duration(days: 3)),
          );
      final range = await showDateRangePicker(
        context: context,
        firstDate: start,
        lastDate: end,
        initialDateRange: initialRange,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );
      if (range != null) {
        onRangeSelected!(range);
      }
    } else if (onDateSelected != null) {
      final initialDate = selectedDate ?? now;
      final date = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: start,
        lastDate: end,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );
      if (date != null) {
        onDateSelected!(date);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayVal = _formatDisplayValue();

    return Semantics(
      label: label,
      button: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.deepEarth,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _pickDate(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: errorText != null
                      ? AppColors.red
                      : AppColors.cardBorder,
                  width: errorText != null ? 1.5 : 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: errorText != null
                        ? AppColors.red
                        : AppColors.warmMuted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      displayVal.isNotEmpty ? displayVal : (hint ?? 'Select Date'),
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 15,
                        color: displayVal.isNotEmpty
                            ? AppColors.textPrimary
                            : AppColors.warmMuted.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                errorText!,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  color: AppColors.red,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
