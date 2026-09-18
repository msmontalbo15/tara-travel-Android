import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_vehicle_model.dart';
import '../../../core/providers/user_vehicles_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_responsive.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/feedback/app_feedback.dart';
import '../../../core/widgets/feedback/app_dialog.dart';

/// Modal sheet allowing travelers to manage vehicles in their personal garage.
class UserVehiclesSheet extends ConsumerWidget {
  const UserVehiclesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const UserVehiclesSheet(),
    );
  }

  void _openAddEditModal(BuildContext context, WidgetRef ref, [UserVehicle? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddEditVehicleModal(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(userVehiclesProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Garage',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontHeading,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Saved vehicles for route fuel estimation',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _openAddEditModal(context, ref),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Body list
            Flexible(
              child: vehiclesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text('Error loading garage: $e')),
                ),
                data: (vehicles) {
                  if (vehicles.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.garage_rounded,
                              size: 48,
                              color: AppColors.warmMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Your Garage is Empty',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Add your car, SUV, or motorcycle to automatically compute fuel consumption and road trip expenses.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: () => _openAddEditModal(context, ref),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Vehicle to Garage'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      context.safeBottomPadding(16),
                    ),
                    itemCount: vehicles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final vehicle = vehicles[index];
                      return _VehicleCard(
                        vehicle: vehicle,
                        onEdit: () => _openAddEditModal(context, ref, vehicle),
                        onDelete: () async {
                          final confirm = await AppDialog.showConfirmation(
                            context,
                            title: 'Remove Vehicle',
                            message: 'Remove "${vehicle.name}" from your garage?',
                            confirmLabel: 'Remove',
                            icon: Icons.delete_outline_rounded,
                          );
                          if (confirm == true) {
                            await ref
                                .read(userVehiclesProvider.notifier)
                                .removeVehicle(vehicle.id);
                            if (context.mounted) {
                              AppFeedback.showSuccess(
                                context,
                                'Vehicle removed from garage',
                              );
                            }
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final UserVehicle vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VehicleCard({
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: vehicle.isDefault
              ? AppColors.primary.withValues(alpha: 0.5)
              : Colors.black.withValues(alpha: 0.06),
          width: vehicle.isDefault ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: vehicle.isDefault ? AppColors.sand : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              vehicle.type.icon,
              color: vehicle.isDefault ? AppColors.primary : AppColors.deepEarth,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        vehicle.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (vehicle.isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'DEFAULT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${vehicle.fuelType.emoji} ${vehicle.fuelType.label}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const Text(' · ', style: TextStyle(color: Colors.black26)),
                    Text(
                      '⚡ ${vehicle.kmPerLiter.toStringAsFixed(1)} km/L',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    if (vehicle.plateNumber != null && vehicle.plateNumber!.isNotEmpty) ...[
                      const Text(' · ', style: TextStyle(color: Colors.black26)),
                      Text(
                        vehicle.plateNumber!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _AddEditVehicleModal extends ConsumerStatefulWidget {
  final UserVehicle? existing;
  const _AddEditVehicleModal({this.existing});

  @override
  ConsumerState<_AddEditVehicleModal> createState() => _AddEditVehicleModalState();
}

class _AddEditVehicleModalState extends ConsumerState<_AddEditVehicleModal> {
  final _nameCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _kmlCtrl = TextEditingController();

  VehicleType _type = VehicleType.sedan;
  FuelType _fuelType = FuelType.gasoline;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final v = widget.existing!;
      _nameCtrl.text = v.name;
      _plateCtrl.text = v.plateNumber ?? '';
      _kmlCtrl.text = v.kmPerLiter.toString();
      _type = v.type;
      _fuelType = v.fuelType;
      _isDefault = v.isDefault;
    } else {
      _kmlCtrl.text = _type.defaultKmPerLiter.toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _plateCtrl.dispose();
    _kmlCtrl.dispose();
    super.dispose();
  }

  void _onTypeChanged(VehicleType newType) {
    setState(() {
      _type = newType;
      if (widget.existing == null) {
        _kmlCtrl.text = newType.defaultKmPerLiter.toString();
      }
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      AppFeedback.showError(context, 'Please enter a vehicle model or nickname');
      return;
    }

    final kml = double.tryParse(_kmlCtrl.text) ?? _type.defaultKmPerLiter;
    final vehicle = UserVehicle(
      id: widget.existing?.id ?? UniqueKey().toString(),
      userId: widget.existing?.userId ?? '',
      name: name,
      type: _type,
      fuelType: _fuelType,
      kmPerLiter: kml > 0 ? kml : 12.0,
      plateNumber: _plateCtrl.text.trim().isEmpty ? null : _plateCtrl.text.trim().toUpperCase(),
      isDefault: _isDefault,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    await ref.read(userVehiclesProvider.notifier).addOrUpdateVehicle(vehicle);

    if (mounted) {
      Navigator.pop(context);
      AppFeedback.showSuccess(
        context,
        widget.existing != null ? 'Vehicle updated' : 'Vehicle added to garage',
      );
    }
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
        16,
        20,
        context.safeBottomPadding(16) + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existing != null ? 'Edit Vehicle' : 'Add Vehicle',
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontHeading,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Vehicle Nickname / Model
            const Text('Model / Nickname *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Toyota Vios 1.5G, NMAX 155',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),

            // Vehicle Type Dropdown
            const Text('Vehicle Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<VehicleType>(
              initialValue: _type,
              items: VehicleType.values.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Row(
                    children: [
                      Text(t.emoji),
                      const SizedBox(width: 8),
                      Text(t.label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => v != null ? _onTypeChanged(v) : null,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const SizedBox(height: 14),

            // Fuel Type & km/L
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fuel Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<FuelType>(
                        initialValue: _fuelType,
                        items: FuelType.values.map((f) {
                          return DropdownMenuItem(
                            value: f,
                            child: Text('${f.emoji} ${f.label}'),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _fuelType = v ?? _fuelType),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fuel Efficiency', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _kmlCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          suffixText: 'km/L',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Plate number
            const Text('Plate / Conduction (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _plateCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'e.g. NBD 1234',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Default Switch
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Primary Default Vehicle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text('Automatically select for private vehicle road trips', style: TextStyle(fontSize: 12)),
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
              activeThumbColor: AppColors.primary,
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  widget.existing != null ? 'Save Changes' : 'Add to Garage',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
