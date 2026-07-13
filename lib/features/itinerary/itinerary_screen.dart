import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/itinerary_provider.dart';
import '../../core/providers/realtime_provider.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/models/itinerary_model.dart';
import '../../core/models/member_model.dart';
import 'widgets/day_strip.dart';
import 'widgets/stop_card.dart';
import 'widgets/add_stop_form.dart';
import 'widgets/transport_badge.dart';

class ItineraryScreen extends ConsumerStatefulWidget {
  final bool showHeader;
  const ItineraryScreen({super.key, this.showHeader = true});

  @override
  ConsumerState<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends ConsumerState<ItineraryScreen> {
  bool _showAddForm = false;

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(activeTripProvider);

    return tripAsync.when(
      data: (trip) {
        if (trip == null) {
          return const Scaffold(body: Center(child: Text('No active trip found.')));
        }
        
        // Listen to live realtime stream for itinerary
        ref.watch(itineraryRealtimeProvider(trip.id));

        final itineraryAsync = ref.watch(ref.watch(itineraryProvider(trip.id)));

        return itineraryAsync.when(
          data: (itinerary) {
            final days = itinerary.days;
            final activeDay = itinerary.activeDay;
            final currentDay = days.isNotEmpty ? days[activeDay] : null;

            return Scaffold(
              backgroundColor: AppColors.deepEarth,
              body: Column(
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.fromLTRB(0, widget.showHeader ? 56 : 12, 0, 0),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A0A04), AppColors.deepEarth],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.showHeader) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                if (Navigator.canPop(context))
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                                    ),
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(trip.name, style: const TextStyle(fontFamily: 'Playfair Display', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                                      Text(trip.destination, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: Colors.white54)),
                                    ],
                                  ),
                                ),
                                // Calendar export btn
                                GestureDetector(
                                  onTap: () => _showCalendarSnack(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.calendar_month_outlined, color: Colors.white, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Map view btn
                                GestureDetector(
                                  onTap: () => _showMapView(context, currentDay),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.map_outlined, color: Colors.white, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        // Day strip — always visible
                        if (days.isNotEmpty)
                          DayStrip(
                            dayLabels: days.map((d) => 'Day ${d.dayNumber} · ${DateFormat('MMM d').format(d.date)}').toList(),
                            activeIndex: activeDay,
                            onTap: (i) => ref.read(ref.read(itineraryProvider(trip.id)).notifier).setActiveDay(i),
                          ),
                      ],
                    ),
                  ),

                  // Body
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                      ),
                      child: currentDay == null
                          ? const Center(child: Text('No itinerary yet.', style: TextStyle(fontFamily: 'DM Sans', color: AppColors.muted)))
                          : _buildDayContent(currentDay, activeDay, trip.members, trip.id),
                    ),
                  ),
                ],
              ),

              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => setState(() => _showAddForm = !_showAddForm),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                icon: Icon(_showAddForm ? Icons.close_rounded : Icons.add_rounded),
                label: Text(_showAddForm ? 'Close' : 'Add Stop', style: const TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w600)),
              ),
            );
          },
          loading: () => const Scaffold(backgroundColor: AppColors.deepEarth, body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(backgroundColor: AppColors.deepEarth, body: Center(child: Text('Itinerary Error: $e', style: const TextStyle(color: Colors.white)))),
        );
      },
      loading: () => const Scaffold(backgroundColor: AppColors.deepEarth, body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(backgroundColor: AppColors.deepEarth, body: Center(child: Text('Trip Error: $e', style: const TextStyle(color: Colors.white)))),
    );
  }

  Widget _buildDayContent(ItineraryDay day, int dayIndex, List<MemberModel> members, String tripId) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transport badge
          if (day.transport != null) ...[
            const SizedBox(height: 12),
            TransportBadge(transport: day.transport!),
          ],

          // Stops timeline
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${day.stops.length} stops · Day ${day.dayNumber}',
                  style: const TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warmMuted, letterSpacing: 1.5),
                ),
                const SizedBox(height: 14),
                ...day.stops.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: StopCard(
                    stop: e.value,
                    members: members,
                    isLast: e.key == day.stops.length - 1,
                    onTap: () => _showStopDetail(context, e.value, members, dayIndex, tripId),
                    onStatusChange: (s) => ref.read(ref.read(itineraryProvider(tripId)).notifier).updateStopStatus(dayIndex, e.value.id, s),
                  ),
                )),

                if (_showAddForm) ...[
                  const SizedBox(height: 20),
                  AddStopForm(
                    members: members,
                    onAdd: (stop) {
                      ref.read(ref.read(itineraryProvider(tripId)).notifier).addStop(dayIndex, stop);
                      setState(() => _showAddForm = false);
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStopDetail(BuildContext context, ItineraryStop stop, List<MemberModel> members, int dayIndex, String tripId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StopDetailSheet(
        stop: stop,
        members: members,
        onStatusChange: (s) => ref.read(ref.read(itineraryProvider(tripId)).notifier).updateStopStatus(dayIndex, stop.id, s),
      ),
    );
  }

  void _showMapView(BuildContext context, ItineraryDay? day) {
    if (day == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MapViewSheet(day: day),
    );
  }

  void _showCalendarSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📅 All stops exported to Google Calendar!', style: TextStyle(fontFamily: 'DM Sans')),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _StopDetailSheet extends StatelessWidget {
  final ItineraryStop stop;
  final List<MemberModel> members;
  final void Function(StopStatus) onStatusChange;

  const _StopDetailSheet({required this.stop, required this.members, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.dividerLight, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: stop.type.color.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(stop.type.icon, color: stop.type.color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(stop.title, style: const TextStyle(fontFamily: 'Playfair Display', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.deepEarth)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (stop.location != null) _infoRow(Icons.place_outlined, stop.location!),
          if (stop.estimatedCost != null) _infoRow(Icons.attach_money_rounded, '₱${stop.estimatedCost!.toInt()} estimated'),
          if (stop.confirmationNumber != null) _infoRow(Icons.confirmation_number_outlined, 'Ref: ${stop.confirmationNumber}'),
          if (stop.notes != null && stop.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Notes', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
            const SizedBox(height: 4),
            Text(stop.notes!, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: AppColors.textSecondary)),
          ],
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () { onStatusChange(StopStatus.approved); Navigator.pop(context); },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: const Text('Approve', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.green, side: const BorderSide(color: AppColors.green)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () { onStatusChange(StopStatus.arrived); Navigator.pop(context); },
                  icon: const Icon(Icons.location_on_rounded, size: 16),
                  label: const Text('Arrived', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}

class _MapViewSheet extends StatelessWidget {
  final ItineraryDay day;

  const _MapViewSheet({required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.deepEarth,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Row(
              children: [
                const Text('Day Map View', style: TextStyle(fontFamily: 'Playfair Display', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                const Spacer(),
                GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close_rounded, color: Colors.white54)),
              ],
            ),
          ),
          // Map placeholder
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A2B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Fake map grid
                  Positioned.fill(
                    child: GridView.count(
                      crossAxisCount: 8,
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(64, (i) => Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                          color: i % 13 == 0 ? Colors.white.withValues(alpha: 0.04) : Colors.transparent,
                        ),
                      )),
                    ),
                  ),
                  // Stop pins
                  ...day.stops.asMap().entries.where((e) => e.value.lat != null).map((e) =>
                    Positioned(
                      left: 50.0 + e.key * 40,
                      top: 80.0 + (e.key % 3) * 50,
                      child: _MapPin(stop: e.value, number: e.key + 1),
                    ),
                  ),
                  // Center notice
                  if (day.stops.every((s) => s.lat == null))
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.map_rounded, size: 48, color: Colors.white24),
                          const SizedBox(height: 12),
                          Text('${day.stops.length} stops for Day ${day.dayNumber}', style: const TextStyle(fontFamily: 'Playfair Display', fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          const Text('Route map loads when GPS data is available', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: Colors.white54), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Stop list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: day.stops.length,
              itemBuilder: (_, i) {
                final s = day.stops[i];
                return Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(color: s.type.color, shape: BoxShape.circle),
                      child: Center(child: Text('${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(s.title, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: Colors.white70))),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final ItineraryStop stop;
  final int number;
  const _MapPin({required this.stop, required this.number});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: stop.type.color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
          child: Center(child: Text('$number', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))),
        ),
        Container(width: 2, height: 8, color: stop.type.color),
      ],
    );
  }
}
