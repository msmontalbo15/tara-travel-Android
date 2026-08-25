import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/models/member_model.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/inputs/app_numeric_field.dart';
import '../../../core/widgets/inputs/location_picker.dart';

/// Pre-populated form for editing an existing [ItineraryStop].
class EditStopForm extends StatefulWidget {
  final ItineraryStop stop;
  final List<MemberModel> members;
  final void Function(ItineraryStop updated) onSave;
  final VoidCallback onCancel;

  const EditStopForm({
    super.key,
    required this.stop,
    required this.members,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<EditStopForm> createState() => _EditStopFormState();
}

class _EditStopFormState extends State<EditStopForm> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _confirmCtrl;
  late StopType _selectedType;
  late TransportMode _selectedTransportMode;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  late final Set<String> _assignedMemberIds;
  String? _titleError;
  LocationResult? _selectedLocation;

  @override
  void initState() {
    super.initState();
    final s = widget.stop;
    _titleCtrl = TextEditingController(text: s.title);
    _notesCtrl = TextEditingController(text: s.notes ?? '');
    _costCtrl = TextEditingController(
      text: s.estimatedCost != null ? s.estimatedCost!.toStringAsFixed(0) : '',
    );
    _confirmCtrl = TextEditingController(text: s.confirmationNumber ?? '');
    _selectedType = s.type;
    _selectedTransportMode = s.transportMode ?? TransportMode.car;
    _startTime = s.startTime;
    _endTime = s.endTime;
    _assignedMemberIds = Set<String>.from(s.assignedMemberIds);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _costCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _titleError = 'Please enter a stop title');
      return;
    }
    final cleanCost = _costCtrl.text.replaceAll(',', '').trim();
    final parsedCost = cleanCost.isNotEmpty ? double.tryParse(cleanCost) : null;
    final locName = _selectedLocation != null
        ? _selectedLocation!.displayName.trim()
        : widget.stop.location;
    final hasNewCoords = _selectedLocation != null &&
        _selectedLocation!.lat != 0.0 &&
        _selectedLocation!.lon != 0.0;

    final updated = widget.stop.copyWith(
      title: _titleCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      type: _selectedType,
      startTime: _startTime,
      endTime: _endTime,
      estimatedCost: parsedCost,
      assignedMemberIds: _assignedMemberIds.toList(),
      transportMode: _selectedType == StopType.transport ? _selectedTransportMode : null,
      confirmationNumber: _confirmCtrl.text.trim().isEmpty ? null : _confirmCtrl.text.trim(),
      location: (locName != null && locName.isNotEmpty) ? locName : null,
      lat: hasNewCoords ? _selectedLocation!.lat : widget.stop.lat,
      lng: hasNewCoords ? _selectedLocation!.lon : widget.stop.lng,
    );
    widget.onSave(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Edit Stop',
                style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepEarth),
              ),
              const Spacer(),
              GestureDetector(
                onTap: widget.onCancel,
                child: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Type chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: StopType.values.map((t) {
                final active = _selectedType == t;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = t),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? t.color : t.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(t.icon, size: 14, color: active ? Colors.white : t.color),
                        const SizedBox(width: 4),
                        Text(t.label, style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : t.color)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          AppTextField(
            label: 'Stop title',
            controller: _titleCtrl,
            hint: 'e.g. Eiffel Tower visit',
            errorText: _titleError,
            prefixIcon: Icons.place_rounded,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) { if (_titleError != null) setState(() => _titleError = null); },
            semanticsLabel: 'Stop title',
          ),
          const SizedBox(height: 10),

          LocationPicker(
            initialValue: widget.stop.location,
            initialLat: widget.stop.lat,
            initialLon: widget.stop.lng,
            onLocationSelected: (loc) => setState(() => _selectedLocation = loc),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(child: _timePicker('Start', _startTime, () => _pickTime(true))),
              const SizedBox(width: 10),
              Expanded(child: _timePicker('End', _endTime, () => _pickTime(false))),
            ],
          ),
          const SizedBox(height: 10),

          AppNumericField(
            label: 'Estimated cost',
            controller: _costCtrl,
            semanticsLabel: 'Estimated cost',
          ),
          const SizedBox(height: 10),

          AppTextField(
            label: 'Confirmation #',
            controller: _confirmCtrl,
            hint: 'Booking reference (optional)',
            prefixIcon: Icons.confirmation_number_outlined,
            semanticsLabel: 'Confirmation number',
          ),
          const SizedBox(height: 10),

          AppTextField(
            label: 'Notes (optional)',
            controller: _notesCtrl,
            hint: 'Any additional details...',
            prefixIcon: Icons.notes_rounded,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            semanticsLabel: 'Stop notes',
          ),
          const SizedBox(height: 12),

          if (widget.members.isNotEmpty) ...[
            Row(
              children: [
                const Text('Assign to', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
                const Spacer(),
                if (_assignedMemberIds.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _assignedMemberIds.clear()),
                    child: const Text('Clear', style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: widget.members.map((m) {
                  final active = _assignedMemberIds.contains(m.id);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (active) {
                        _assignedMemberIds.remove(m.id);
                      } else {
                        _assignedMemberIds.add(m.id);
                      }
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? m.color : m.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: active ? m.color : Colors.transparent,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (active) ...[
                            const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            m.name.split(' ').first,
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: active ? Colors.white : m.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.muted,
                    side: const BorderSide(color: AppColors.dividerLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save_rounded, size: 16),
                  label: const Text('Save', style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timePicker(String label, TimeOfDay? time, VoidCallback onTap) {
    String display = time != null
        ? '${time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod}:${time.minute.toString().padLeft(2, '0')} ${time.period == DayPeriod.am ? 'AM' : 'PM'}'
        : label;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 16, color: AppColors.muted),
            const SizedBox(width: 6),
            Text(display, style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: time != null ? AppColors.deepEarth : AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
