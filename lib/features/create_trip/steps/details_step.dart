import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/inputs/app_date_picker.dart';
import '../models/new_trip_model.dart';
import '../widgets/step_indicator.dart';

class DetailsStep extends StatefulWidget {
  final NewTripModel trip;
  final VoidCallback onNext;
  final VoidCallback onCancel;

  const DetailsStep({
    super.key,
    required this.trip,
    required this.onNext,
    required this.onCancel,
  });

  @override
  State<DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends State<DetailsStep> {
  late TextEditingController _nameController;
  late TextEditingController _destController;
  final _formKey = GlobalKey<FormState>();

  String? _nameError;
  String? _destError;
  String? _dateError;

  static const _tripTypes = [
    ('Beach', '🏖️'),
    ('City', '🏙️'),
    ('Adventure', '🏕️'),
    ('Nature', '🌿'),
    ('Cultural', '🏛️'),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.trip.tripName);
    _destController = TextEditingController(text: widget.trip.destination);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _destController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _nameError = _nameController.text.trim().isEmpty
          ? 'Please enter a trip name'
          : null;
      _destError = _destController.text.trim().isEmpty
          ? 'Please enter a destination'
          : null;
      _dateError = widget.trip.fromDate == null || widget.trip.toDate == null
          ? 'Please select travel dates'
          : (widget.trip.toDate!.isBefore(widget.trip.fromDate!)
              ? 'End date must be after start date'
              : null);
    });
    if (_nameError != null || _destError != null || _dateError != null) {
      ok = false;
    }
    return ok;
  }

  void _onContinue() {
    widget.trip.tripName = _nameController.text.trim();
    widget.trip.destination = _destController.text.trim();
    if (_validate()) widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onCancel,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 15,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'New trip',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 50),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Step indicator ──────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: StepIndicator(
                  currentStep: 1,
                  totalSteps: 3,
                  label: 'Trip details',
                ),
              ),
              const SizedBox(height: 24),

              // ── Form ────────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Trip name
                      AppTextField(
                        label: 'Trip name',
                        controller: _nameController,
                        hint: 'e.g. Summer in Paris',
                        errorText: _nameError,
                        prefixIcon: Icons.luggage_rounded,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) {
                          if (_nameError != null) setState(() => _nameError = null);
                          widget.trip.tripName = _nameController.text;
                        },
                        semanticsLabel: 'Trip name field',
                      ),
                      const SizedBox(height: 18),

                      // Destination
                      AppTextField(
                        label: 'Destination',
                        controller: _destController,
                        hint: 'e.g. Paris, France',
                        errorText: _destError,
                        prefixIcon: Icons.location_on_rounded,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) {
                          if (_destError != null) setState(() => _destError = null);
                          widget.trip.destination = _destController.text;
                        },
                        semanticsLabel: 'Destination field',
                      ),
                      const SizedBox(height: 18),

                      // Travel dates — side by side pickers
                      const Text(
                        'Travel dates',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepEarth,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: AppDatePicker(
                              label: 'From',
                              selectedDate: widget.trip.fromDate,
                              errorText: _dateError != null && widget.trip.fromDate == null
                                  ? ' '
                                  : null,
                              onDateSelected: (d) {
                                setState(() {
                                  widget.trip.fromDate = d;
                                  _dateError = null;
                                  // Auto-advance toDate if it's before fromDate
                                  if (widget.trip.toDate != null &&
                                      widget.trip.toDate!.isBefore(d)) {
                                    widget.trip.toDate = d.add(const Duration(days: 1));
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppDatePicker(
                              label: 'To',
                              selectedDate: widget.trip.toDate,
                              firstDate: widget.trip.fromDate,
                              errorText: _dateError != null && widget.trip.toDate == null
                                  ? ' '
                                  : null,
                              onDateSelected: (d) {
                                setState(() {
                                  widget.trip.toDate = d;
                                  _dateError = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_dateError != null) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            _dateError!,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                              color: AppColors.red,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),

                      // Trip type chips
                      const Text(
                        'Trip type',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepEarth,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tripTypes.map((entry) {
                          final type  = entry.$1;
                          final emoji = entry.$2;
                          final sel   = widget.trip.tripType == type;
                          return GestureDetector(
                            onTap: () => setState(() => widget.trip.tripType = type),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.primary : Colors.white,
                                border: Border.all(
                                  color: sel ? AppColors.primary : AppColors.cardBorder,
                                  width: sel ? 1.5 : 0.8,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: sel
                                    ? [BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.18),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      )]
                                    : [],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(emoji, style: const TextStyle(fontSize: 15)),
                                  const SizedBox(width: 6),
                                  Text(
                                    type,
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: sel ? Colors.white : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 22),

                      // Travelers
                      const Text(
                        'Travelers',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepEarth,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _travelersRow(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // ── CTA ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Continue — Budget setup',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _travelersRow() {
    return Row(
      children: [
        ...widget.trip.travelers.map((t) => _avatar(t.initials, t.color)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              if (widget.trip.travelers.length < 5) {
                widget.trip.travelers.add(
                  TravelerModel(
                    name: 'Traveler ${widget.trip.travelers.length + 1}',
                    initials: 'T${widget.trip.travelers.length + 1}',
                    color: [0xFFEAB308, 0xFF3B82F6, 0xFF10B981, 0xFF8B5CF6]
                        [widget.trip.travelers.length % 4],
                  ),
                );
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.add, size: 14, color: AppColors.primary),
                SizedBox(width: 4),
                Text(
                  'Add',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatar(String initials, int color) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Color(color),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
