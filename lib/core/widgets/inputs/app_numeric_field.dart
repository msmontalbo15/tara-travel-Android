import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

class AppNumericField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? errorText;
  final String currencySymbol;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final String? semanticsLabel;
  final bool decimal;

  const AppNumericField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.errorText,
    this.currencySymbol = '₱',
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.validator,
    this.semanticsLabel,
    this.decimal = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel ?? label,
      textField: true,
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
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: decimal),
            textInputAction: textInputAction,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                decimal
                    ? RegExp(r'^\d*\.?\d{0,2}')
                    : RegExp(r'^\d*'),
              ),
            ],
            onChanged: onChanged,
            validator: validator,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint ?? '0.00',
              hintStyle: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.warmMuted.withValues(alpha: 0.5),
              ),
              errorText: errorText,
              errorStyle: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                color: AppColors.red,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1.0,
                  child: Text(
                    currencySymbol,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              filled: true,
              fillColor: AppColors.sand.withValues(alpha: 0.4),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.cardBorder,
                  width: 0.8,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.red,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
