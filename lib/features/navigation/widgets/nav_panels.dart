import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/navigation_models.dart';
import 'nav_map_view.dart';

// ── INSTRUCTION PANEL ─────────────────────────────────────────────
class InstructionPanel extends StatelessWidget {
  final TurnInstruction turn;
  const InstructionPanel({super.key, required this.turn});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.turn_right_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(turn.distanceLabel, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                Text(turn.instruction, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${turn.kmLeft}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('km left', style: TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── STATS STRIP ──────────────────────────────────────────────────
class StatsStrip extends StatelessWidget {
  final NavDestination dest;
  final VoidCallback onEnd;

  const StatsStrip({super.key, required this.dest, required this.onEnd});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(14, 8, 14, 4 + MediaQuery.of(context).padding.bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stat('ETA', dest.eta),
          _stat('Distance', '${dest.distanceKm} km'),
          _stat('Duration', '${dest.durationMin} min'),
          GestureDetector(
            onTap: onEnd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
              child: const Text('End', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 10)),
        Text(value, style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ── GROUP TRACKER PANEL ──────────────────────────────────────────
class GroupTrackerPanel extends StatelessWidget {
  final NavigationState state;
  final VoidCallback onBack;

  const GroupTrackerPanel({super.key, required this.state, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF2F2F7),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: const Text('Map', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                const Text('Group tracker', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF34A853), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('Live', style: TextStyle(color: Color(0xFF34A853), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          // Mini Map
          Container(
            height: 150,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
              LiveMapView(state: state, isMiniMap: true),
              Positioned(
                bottom: 8, right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8)),
                  child: const Text('View full map', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MEMBERS · ${state.members.length} TRAVELERS', style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: state.members.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 0),
                      itemBuilder: (context, index) => _MemberRow(member: state.members[index]),
                    ),
                  ),
                  // Gap warning
                  Container(
                    margin: const EdgeInsets.only(bottom: 20, top: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: Color(0xFFFCEBEB), borderRadius: BorderRadius.all(Radius.circular(11))),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFA32D2D), size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Group spread: 3.5 km', style: TextStyle(color: Color(0xFFA32D2D), fontSize: 11, fontWeight: FontWeight.bold)),
                              Text('Carlo is falling behind · 6 min gap', style: TextStyle(color: Color(0xFFA32D2D), fontSize: 10)),
                            ],
                          ),
                        ),
                        Text('Alert', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final NavMember member;
  const _MemberRow({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5), width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 13),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: member.color, shape: BoxShape.circle),
                    child: Center(child: Text(member.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: member.status == MemberStatus.offline ? Colors.grey : const Color(0xFF34A853),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${member.name}${member.isMe ? ' (you)' : ''}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(
                      member.status == MemberStatus.enRoute ? 'En route · ${member.distanceLabel}' : (member.status == MemberStatus.arrived ? 'Arrived' : member.lastSeenLabel ?? 'Offline'),
                      style: TextStyle(color: member.isOnline ? const Color(0xFF34A853) : const Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (member.isOnline)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${member.speedKmh?.toInt() ?? 0} km/h', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Text('speed', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 10)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 45),
            child: Row(
              children: [
                _tag(member.role, const Color(0xFFFAECE7), const Color(0xFF993C1D)),
                const SizedBox(width: 6),
                _tag('ETA ${member.eta ?? '--'}', const Color(0xFFEAF3DE), const Color(0xFF3B6D11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: textCol, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

// ── PROXIMITY PANEL ──────────────────────────────────────────────
class ProximityPanel extends StatelessWidget {
  final NavigationState state;
  final VoidCallback onDismiss;

  const ProximityPanel({super.key, required this.state, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E5EA), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: const Color(0xFFFAECE7), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Almost there!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
                    Text('300 m from ${state.destination.name}', style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFEAF3DE), borderRadius: BorderRadius.circular(10)),
                child: const Text('2 min', style: TextStyle(color: Color(0xFF3B6D11), fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Next stop on itinerary', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11)),
                const SizedBox(height: 6),
                Text('Check-in at ${state.destination.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${state.destination.address} · Confirmation #${state.destination.confirmationCode}', style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _miniTag('Hotel', const Color(0xFFE6F1FB), const Color(0xFF185FA5)),
                    const SizedBox(width: 6),
                    _miniTag('₱28,000 · Spencer paid', const Color(0xFFFAECE7), const Color(0xFF993C1D)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('GROUP STATUS', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 7),
          ...state.members.where((m) => !m.isMe).map((m) => _StatusRow(member: m)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 13)),
                  child: const Text('Open in Maps', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF3C3C43)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniTag(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: textCol, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final NavMember member;
  const _StatusRow({required this.member});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 24, height: 24, decoration: BoxDecoration(color: member.color, shape: BoxShape.circle), child: Center(child: Text(member.initials, style: const TextStyle(color: Colors.white, fontSize: 9)))),
              const SizedBox(width: 7),
              Text(member.name.split(' ')[0], style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Container(width: 8, height: 8, decoration: BoxDecoration(color: _statusCol(), shape: BoxShape.circle)),
            ],
          ),
          Text(_statusText(), style: TextStyle(color: _statusCol(), fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Color _statusCol() {
    if (member.status == MemberStatus.arrived) return const Color(0xFF34A853);
    if (member.status == MemberStatus.enRoute) return const Color(0xFFEF9F27);
    return const Color(0xFFC7C7CC);
  }

  String _statusText() {
    if (member.status == MemberStatus.arrived) return 'Already arrived';
    if (member.status == MemberStatus.enRoute) return '~18 min away';
    return 'Offline';
  }
}

// ── ARRIVAL FEED PANEL ──────────────────────────────────────────
class ArrivalFeedPanel extends StatelessWidget {
  final NavigationState state;
  const ArrivalFeedPanel({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A0A04),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          const SizedBox(height: 10),
          // Main banner
          _notificationBanner(
            title: "You've arrived at ${state.destination.name}!",
            sub: "Lia is already here. Carlo is 18 min away. Mark your check-in?",
            showButtons: true,
          ),
          const SizedBox(height: 8),
          _activityNote(initials: "L", name: "Lia Cruz", time: "2 min ago", text: "Just arrived at the hotel! Room looks amazing. See you all soon!", color: const Color(0xFFF0997B)),
          const SizedBox(height: 8),
          _activityNote(initials: "C", name: "Carlo Reyes", time: "5 min ago", text: "Stuck in traffic near Caticlan pier. ETA updated to 4:38 PM.", color: const Color(0xFF712B13)),
          const SizedBox(height: 14),
          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ARRIVAL SUMMARY', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 12),
                ...state.members.map((m) => _SummaryRow(member: m)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Next step
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Next on itinerary', style: TextStyle(color: Colors.white60, fontSize: 11)),
                      Text('${state.destination.nextStopName} · ${state.destination.nextStopTime}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _notificationBanner({required String title, required String sub, bool showButtons = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 16)),
              const SizedBox(width: 9),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Tara Travel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)), Text('now', style: TextStyle(color: Colors.white38, fontSize: 10))])),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          Text(sub, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          if (showButtons)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Expanded(child: Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(8)), child: const Center(child: Text('Check in', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12))))),
                  const SizedBox(width: 8),
                  Expanded(child: Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)), child: const Center(child: Text('Later', style: TextStyle(color: Colors.white38, fontSize: 12))))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _activityNote({required String initials, required String name, required String time, required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 30, height: 30, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)), child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)), Text(time, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10))])),
            ],
          ),
          const SizedBox(height: 6),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final NavMember member;
  const _SummaryRow({required this.member});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 26, height: 26, decoration: BoxDecoration(color: member.color, shape: BoxShape.circle), child: Center(child: Text(member.initials, style: const TextStyle(color: Colors.white, fontSize: 10)))),
              const SizedBox(width: 7),
              Text(member.name.split(' ')[0], style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: _statusCol(), shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(_statusText(), style: TextStyle(color: _statusCol(), fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusCol() {
    if (member.status == MemberStatus.arrived) return const Color(0xFF34A853);
    if (member.status == MemberStatus.enRoute) return const Color(0xFFEF9F27);
    return const Color(0xFFC7C7CC);
  }

  String _statusText() {
    if (member.status == MemberStatus.arrived) return 'Arrived · ${member.arrivedAt}';
    if (member.status == MemberStatus.enRoute) return 'En route · ${member.eta}';
    return 'Offline';
  }
}
