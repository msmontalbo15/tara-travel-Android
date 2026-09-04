import 'package:tara_travel/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AiPackingDialog extends StatefulWidget {
  final String destination;
  final String tripType;
  final int durationDays;
  final Function({
    required String destination,
    required String tripType,
    required int durationDays,
    String? weatherCondition,
    String? transportMode,
  }) onGenerate;

  const AiPackingDialog({
    super.key,
    required this.destination,
    required this.tripType,
    required this.durationDays,
    required this.onGenerate,
  });

  static Future<void> show(
    BuildContext context, {
    required String destination,
    required String tripType,
    required int durationDays,
    required Function({
      required String destination,
      required String tripType,
      required int durationDays,
      String? weatherCondition,
      String? transportMode,
    }) onGenerate,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AiPackingDialog(
        destination: destination,
        tripType: tripType,
        durationDays: durationDays,
        onGenerate: onGenerate,
      ),
    );
  }

  @override
  State<AiPackingDialog> createState() => _AiPackingDialogState();
}

class _AiPackingDialogState extends State<AiPackingDialog> {
  late TextEditingController _destCtrl;
  late String _selectedType;
  String _selectedWeather = 'Sunny / Clear';
  String _selectedTransport = 'Flight';

  final List<String> _tripTypes = ['Beach', 'Mountain / Hiking', 'City / Culture', 'Road Trip / Camping'];
  final List<String> _weatherOptions = ['☀️ Sunny / Clear', '🌧️ Rainy / Stormy', '❄️ Cold / Chilly', '⛅ Cloudy / Mild'];
  final List<String> _transportOptions = ['✈️ Flight', '🚗 Car / Van', '⛴️ Ferry / Boat', '🚌 Bus'];

  @override
  void initState() {
    super.initState();
    _destCtrl = TextEditingController(text: widget.destination);
    _selectedType = _resolveTripType(widget.tripType);
  }

  String _resolveTripType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('beach')) return 'Beach';
    if (lower.contains('mountain') || lower.contains('hike')) return 'Mountain / Hiking';
    if (lower.contains('road') || lower.contains('camp')) return 'Road Trip / Camping';
    return 'City / Culture';
  }

  @override
  void dispose() {
    _destCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.dividerLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Packing Suggestions',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontHeading,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepEarth,
                          ),
                        ),
                        Text(
                          'Context-aware checklist tailored to your trip',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Destination Field
              const Text(
                'DESTINATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.warmMuted,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _destCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. Boracay, Sagada, Tokyo',
                  prefixIcon: const Icon(Icons.location_on_outlined,
                      size: 20, color: AppColors.primary),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.dividerLight),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Trip Type Chips
              const Text(
                'TRIP VIBE & TYPE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.warmMuted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tripTypes.map((type) {
                  final isSel = _selectedType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSel,
                    onSelected: (sel) => setState(() => _selectedType = type),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? AppColors.primary : AppColors.deepEarth,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSel ? AppColors.primary : AppColors.dividerLight,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Weather Forecast Selector
              const Text(
                'WEATHER FORECAST',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.warmMuted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _weatherOptions.map((weather) {
                  final isSel = _selectedWeather == weather;
                  return ChoiceChip(
                    label: Text(weather),
                    selected: isSel,
                    onSelected: (sel) => setState(() => _selectedWeather = weather),
                    selectedColor: AppColors.amber.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? AppColors.amber : AppColors.deepEarth,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSel ? AppColors.amber : AppColors.dividerLight,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Transport Mode Selector
              const Text(
                'MODE OF TRANSPORT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.warmMuted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _transportOptions.map((trans) {
                  final isSel = _selectedTransport == trans;
                  return ChoiceChip(
                    label: Text(trans),
                    selected: isSel,
                    onSelected: (sel) => setState(() => _selectedTransport = trans),
                    selectedColor: AppColors.blue.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? AppColors.blue : AppColors.deepEarth,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSel ? AppColors.blue : AppColors.dividerLight,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Generate Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onGenerate(
                      destination: _destCtrl.text.trim(),
                      tripType: _selectedType,
                      durationDays: widget.durationDays,
                      weatherCondition: _selectedWeather,
                      transportMode: _selectedTransport,
                    );
                  },
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text(
                    'Generate Smart Suggestions',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
