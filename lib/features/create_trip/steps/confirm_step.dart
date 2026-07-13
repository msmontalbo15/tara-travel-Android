import 'package:flutter/material.dart';
import '../models/new_trip_model.dart';
import '../widgets/step_indicator.dart';

class ConfirmStep extends StatelessWidget {
  final NewTripModel trip;
  final VoidCallback onConfirm;
  final VoidCallback onSaveDraft;
  final VoidCallback onBack;

  const ConfirmStep({
    super.key,
    required this.trip,
    required this.onConfirm,
    required this.onSaveDraft,
    required this.onBack,
  });

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  String _fmtBudget(double? v) {
    if (v == null) return '—';
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '₱${buf.toString()}';
  }

  int get _nights {
    if (trip.fromDate == null || trip.toDate == null) return 0;
    return trip.toDate!.difference(trip.fromDate!).inDays;
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF1A0A04);
    const card = Color(0xFF2C1510);
    const muted = Color(0xFF9C7B70);
    const white = Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded,
                            size: 16, color: Color(0xFFD85A30)),
                        SizedBox(width: 4),
                        Text(
                          'Back',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 15,
                            color: Color(0xFFD85A30),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Review trip',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: white,
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
                currentStep: 3,
                totalSteps: 3,
                label: 'Review & create',
                isDark: true,
              ),
            ),
            const SizedBox(height: 24),

            // ── Content ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TRIP SUMMARY',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: muted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Summary card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Trip name + destination
                          Text(
                            trip.tripName.isEmpty
                                ? 'Untitled Trip'
                                : trip.tripName,
                            style: const TextStyle(
                              fontFamily: 'Playfair Display',
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 14, color: muted),
                              const SizedBox(width: 4),
                              Text(
                                trip.destination.isEmpty
                                    ? 'Destination TBD'
                                    : trip.destination,
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 13,
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFF3D2018), height: 1),
                          const SizedBox(height: 16),

                          // Dates + Budget row
                          Row(
                            children: [
                              _summaryBox(
                                label: 'Dates',
                                value:
                                    '${_fmtDate(trip.fromDate)} – ${_fmtDate(trip.toDate)}',
                                sub: '$_nights days',
                              ),
                              const SizedBox(width: 12),
                              _summaryBox(
                                label: 'Budget',
                                value: _fmtBudget(trip.totalBudget),
                                sub: trip.splitEqually &&
                                        trip.travelers.isNotEmpty
                                    ? '${_fmtBudget((trip.totalBudget ?? 0) / trip.travelers.length)}/person'
                                    : '',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFF3D2018), height: 1),
                          const SizedBox(height: 16),

                          // Travelers
                          Text(
                            'TRAVELERS · ${trip.travelers.length}',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: muted,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              ...trip.travelers.map((t) => Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: Color(t.color),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              t.initials,
                                              style: const TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          t.name,
                                          style: const TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 11,
                                            color: muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // What happens next
                    const Text(
                      'WHAT HAPPENS NEXT',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: muted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _nextItem(
                      index: 1,
                      text: 'Build your day-by-day itinerary',
                      active: true,
                    ),
                    _nextItem(
                      index: 2,
                      text: 'Invite travelers & track expenses',
                      active: false,
                    ),
                    _nextItem(
                      index: 3,
                      text: 'Pack your bags & go!',
                      active: false,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // ── CTAs ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD85A30),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Create my trip',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: onSaveDraft,
              child: const Text(
                'Save as draft',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  color: Colors.white54,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _summaryBox(
      {required String label, required String value, String sub = ''}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF3D2018),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                color: Color(0xFF9C7B70),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (sub.isNotEmpty)
              Text(
                sub,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  color: Color(0xFF9C7B70),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _nextItem({required int index, required String text, required bool active}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFFD85A30)
                  : const Color(0xFF3D2018),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : const Color(0xFF9C7B70),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              color: active ? Colors.white : const Color(0xFF9C7B70),
            ),
          ),
        ],
      ),
    );
  }
}
