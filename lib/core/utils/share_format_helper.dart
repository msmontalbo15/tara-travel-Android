import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trip_model.dart';
import '../models/itinerary_model.dart';
import '../models/expense_model.dart';
import '../models/member_model.dart';
import '../providers/itinerary_provider.dart';
import '../providers/packing_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ShareFormatHelper
//
// Produces Messenger/WhatsApp/SMS-ready plain text with:
//  • Clean emoji section headers
//  • Direct Google Maps place links per stop (lat,lng or search query)
//  • Full-day multi-waypoint route links
//  • Checklist format for packing
//  • Settlement instructions for budget splits
// ─────────────────────────────────────────────────────────────────────────────

class ShareFormatHelper {
  // ── Date helpers ──────────────────────────────────────────────────────────

  static final _dateFmt = DateFormat('EEE, MMM d yyyy');
  static final _shortDate = DateFormat('MMM d');
  static final _timeFmt = DateFormat('h:mm a');

  static String _fmtTime(TimeOfDay t) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    return _timeFmt.format(dt);
  }

  static String _currency(double v) {
    final formatter = NumberFormat('#,##0.00', 'en_PH');
    return '₱${formatter.format(v)}';
  }

  // ── Google Maps URL builders ──────────────────────────────────────────────

  /// Single-place Google Maps link (opens place in maps).
  static String _placeUrl(ItineraryStop stop) {
    final hasCoords = stop.lat != null &&
        stop.lng != null &&
        stop.lat != 0.0 &&
        stop.lng != 0.0;
    if (hasCoords) {
      return 'https://maps.google.com/?q=${stop.lat},${stop.lng}';
    }
    final query = [
      if (stop.location != null && stop.location!.trim().isNotEmpty) stop.location!.trim(),
      if (stop.title.trim().isNotEmpty) stop.title.trim(),
    ].join(', ');
    return 'https://maps.google.com/?q=${Uri.encodeComponent(query)}';
  }

  /// Full-day multi-waypoint Google Maps directions URL.
  static String? _dayRouteUrl(List<ItineraryStop> stops) {
    final navigable = stops.where((s) {
      final hasCoords = s.lat != null && s.lng != null && s.lat != 0.0 && s.lng != 0.0;
      return hasCoords ||
          (s.location != null && s.location!.trim().isNotEmpty) ||
          s.title.trim().isNotEmpty;
    }).toList();
    if (navigable.isEmpty) return null;
    if (navigable.length == 1) return _placeUrl(navigable.first);

    String target(ItineraryStop s) {
      final hasCoords = s.lat != null && s.lng != null && s.lat != 0.0 && s.lng != 0.0;
      if (hasCoords) return '${s.lat},${s.lng}';
      if (s.location != null && s.location!.trim().isNotEmpty) {
        return Uri.encodeComponent('${s.title.trim()}, ${s.location!.trim()}');
      }
      return Uri.encodeComponent(s.title.trim());
    }

    final dest = target(navigable.last);
    final waypoints = navigable.length > 1
        ? navigable.sublist(0, navigable.length - 1).map(target).join('|')
        : '';

    return 'https://www.google.com/maps/dir/?api=1'
        '&destination=$dest'
        '${waypoints.isNotEmpty ? '&waypoints=$waypoints' : ''}'
        '&travelmode=driving';
  }

  // ── Stop type emoji ───────────────────────────────────────────────────────

  static String _stopEmoji(StopType t) {
    switch (t) {
      case StopType.hotel:      return '🏨';
      case StopType.activity:   return '🎯';
      case StopType.food:       return '🍽️';
      case StopType.transport:  return '🚗';
      case StopType.custom:     return '📍';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. ITINERARY SHARE
  // ─────────────────────────────────────────────────────────────────────────

  /// Formats the full itinerary (all days) or a specific [dayIndex] for Messenger.
  static String formatItinerary({
    required TripModel trip,
    required ItineraryState itinerary,
    int? dayIndex,
  }) {
    final buf = StringBuffer();

    // Header
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('🗺️  TARA TRAVEL ITINERARY');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('📌 Trip: ${trip.name}');
    buf.writeln('📍 Destination: ${trip.destination}');
    buf.writeln('📅 ${_dateFmt.format(trip.fromDate)} → ${_dateFmt.format(trip.toDate)}');
    final nights = trip.toDate.difference(trip.fromDate).inDays;
    buf.writeln('🌙 $nights night${nights == 1 ? '' : 's'}  ·  ${trip.members.length} traveler${trip.members.length == 1 ? '' : 's'}');
    if (trip.inviteCode.isNotEmpty) {
      buf.writeln('🔑 Invite Code: ${trip.inviteCode}');
    }
    buf.writeln();

    final days = dayIndex != null
        ? (dayIndex < itinerary.days.length ? [itinerary.days[dayIndex]] : <ItineraryDay>[])
        : itinerary.days;

    for (final day in days) {
      final dayRoute = _dayRouteUrl(day.stops);

      buf.writeln('──────────────────────');
      buf.writeln('📆 DAY ${day.dayNumber} · ${_dateFmt.format(day.date)}');

      // Transport badge
      if (day.transport != null) {
        final t = day.transport!;
        buf.writeln('${t.mode.emoji} Transport: ${t.mode.label}');
        if (t.departurePoint != null && t.departurePoint!.isNotEmpty) {
          buf.writeln('   From: ${t.departurePoint}');
        }
        if (t.estimatedDuration.isNotEmpty) {
          buf.writeln('   Est. Duration: ${t.estimatedDuration}');
        }
      }

      // Full-day Google Maps route
      if (dayRoute != null) {
        buf.writeln();
        buf.writeln('🗺️  Day ${day.dayNumber} Route in Google Maps:');
        buf.writeln(dayRoute);
      }

      buf.writeln();

      if (day.stops.isEmpty) {
        buf.writeln('   (No stops planned yet)');
      } else {
        for (int i = 0; i < day.stops.length; i++) {
          final stop = day.stops[i];
          buf.writeln('${i + 1}. ${_stopEmoji(stop.type)} ${stop.title}');

          // Time
          if (stop.startTime != null) {
            final time = stop.endTime != null
                ? '${_fmtTime(stop.startTime!)} – ${_fmtTime(stop.endTime!)}'
                : _fmtTime(stop.startTime!);
            buf.writeln('   ⏰ $time');
          }

          // Location text
          if (stop.location != null && stop.location!.trim().isNotEmpty) {
            buf.writeln('   📍 ${stop.location!.trim()}');
          }

          // Google Maps place link
          buf.writeln('   🗺️  ${_placeUrl(stop)}');

          // Notes
          if (stop.notes != null && stop.notes!.trim().isNotEmpty) {
            buf.writeln('   💬 ${stop.notes!.trim()}');
          }

          // Estimated cost
          if (stop.estimatedCost != null && stop.estimatedCost! > 0) {
            buf.writeln('   💸 Est. ${_currency(stop.estimatedCost!)}');
          }

          // Transport mode for stop
          if (stop.transportMode != null) {
            buf.writeln('   ${stop.transportMode!.emoji} ${stop.transportMode!.label}');
          }

          // Confirmation number
          if (stop.confirmationNumber != null && stop.confirmationNumber!.isNotEmpty) {
            buf.writeln('   🎫 Confirmation: ${stop.confirmationNumber}');
          }

          buf.writeln();
        }

        // Day total
        final dayCost = day.totalDayCost;
        if (dayCost > 0) {
          buf.writeln('   💰 Day ${day.dayNumber} Est. Total: ${_currency(dayCost)}');
          buf.writeln();
        }
      }
    }

    _appendFooter(buf, trip);
    return buf.toString().trim();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. PACKING LIST SHARE
  // ─────────────────────────────────────────────────────────────────────────

  static String formatPackingList({
    required TripModel trip,
    required PackingState packingState,
    List<MemberModel> members = const [],
    bool includeChecked = true,
  }) {
    final buf = StringBuffer();
    final packed = packingState.packedItems;
    final total = packingState.totalItems;
    final pct = total == 0 ? 0 : ((packed / total) * 100).round();

    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('🎒  PACKING LIST');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('📌 Trip: ${trip.name}');
    buf.writeln('📍 ${trip.destination}');
    buf.writeln('📅 ${_shortDate.format(trip.fromDate)} – ${_shortDate.format(trip.toDate)}');
    buf.writeln();
    buf.writeln('📊 Progress: $packed / $total items packed ($pct%)');
    buf.writeln(packingState.allPacked ? '✅ ALL PACKED — TARA NA! 🎉' : '⏳ Packing in progress...');
    buf.writeln();

    final memberById = {for (final m in members) m.id: m};

    for (final cat in packingState.categories) {
      final catItems = includeChecked
          ? cat.items
          : cat.items.where((i) => !i.isChecked).toList();
      if (catItems.isEmpty) continue;

      buf.writeln('──────────────────────');
      buf.writeln('${_catEmoji(cat.name)} ${cat.name.toUpperCase()} (${cat.packedCount}/${cat.totalCount})');
      buf.writeln();

      for (final item in catItems) {
        final check = item.isChecked ? '✅' : '⬜';
        final critical = item.isCritical ? ' ⚠️' : '';
        final ai = item.isAiSuggested ? ' ✨' : '';
        buf.write('  $check ${item.name}$critical$ai');
        if (item.assignedMemberId != null && item.assignedMemberId!.isNotEmpty) {
          final member = memberById[item.assignedMemberId];
          if (member != null) buf.write('  → ${member.name}');
        }
        buf.writeln();
      }
      buf.writeln();
    }

    _appendFooter(buf, trip);
    return buf.toString().trim();
  }

  static String _catEmoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('cloth') || n.contains('wear') || n.contains('outfit')) return '👕';
    if (n.contains('doc') || n.contains('id') || n.contains('passport')) return '📄';
    if (n.contains('health') || n.contains('med') || n.contains('first')) return '💊';
    if (n.contains('elec') || n.contains('gadget') || n.contains('tech')) return '🔌';
    if (n.contains('hygiene') || n.contains('toilet') || n.contains('personal')) return '🧴';
    if (n.contains('food') || n.contains('snack') || n.contains('drink')) return '🍱';
    if (n.contains('entertain') || n.contains('fun') || n.contains('leisure')) return '🎮';
    if (n.contains('money') || n.contains('cash') || n.contains('finance')) return '💰';
    return '📦';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. BUDGET & SPLIT SHARE
  // ─────────────────────────────────────────────────────────────────────────

  static String formatBudgetSplit({
    required TripModel trip,
    required List<ExpenseModel> expenses,
    required List<MemberModel> members,
    required Map<String, double> shares,
    required List<BudgetSettlement> settlements,
  }) {
    final buf = StringBuffer();
    final approved = expenses.where((e) => e.status == ExpenseStatus.approved).toList();
    final total = approved.fold<double>(0, (s, e) => s + e.amount);
    final budget = trip.totalBudget;
    final remaining = budget - total;

    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('💸  TRIP BUDGET & SPLIT');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('📌 Trip: ${trip.name}');
    buf.writeln('📍 ${trip.destination}');
    buf.writeln('📅 ${_shortDate.format(trip.fromDate)} – ${_shortDate.format(trip.toDate)}');
    buf.writeln();
    buf.writeln('💰 Total Budget:   ${_currency(budget)}');
    buf.writeln('✅ Total Spent:    ${_currency(total)}');
    buf.writeln('${remaining >= 0 ? '🟢' : '🔴'} Remaining:     ${_currency(remaining)}');
    buf.writeln();

    // Member contributions
    buf.writeln('──────────────────────');
    buf.writeln('👤 MEMBER BREAKDOWN');
    buf.writeln();

    for (final m in members) {
      final paid = approved
          .where((e) => e.paidById == m.id)
          .fold<double>(0, (s, e) => s + e.amount);
      final share = shares[m.id] ?? 0;
      final net = paid - share;
      final netLabel = net.abs() < 0.5
          ? '✅ Settled'
          : net > 0
              ? '🟢 Gets back ${_currency(net)}'
              : '🔴 Owes ${_currency(-net)}';
      buf.writeln('  ${m.name}');
      buf.writeln('     Paid: ${_currency(paid)}  |  Fair Share: ${_currency(share)}');
      buf.writeln('     $netLabel');
      buf.writeln();
    }

    // Settlements
    if (settlements.isNotEmpty) {
      buf.writeln('──────────────────────');
      buf.writeln('💸 WHO PAYS WHOM');
      buf.writeln();
      for (final s in settlements) {
        buf.writeln('  • ${s.fromName} pays ${s.toName}  →  ${_currency(s.amount)}');
      }
    } else {
      buf.writeln('──────────────────────');
      buf.writeln('🎉 All expenses are settled!');
    }

    buf.writeln();
    _appendFooter(buf, trip);
    return buf.toString().trim();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. TRIP OVERVIEW SHARE
  // ─────────────────────────────────────────────────────────────────────────

  static String formatTripOverview({
    required TripModel trip,
    ItineraryState? itinerary,
    PackingState? packingState,
  }) {
    final buf = StringBuffer();
    final nights = trip.toDate.difference(trip.fromDate).inDays;

    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('✈️  TRIP OVERVIEW');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('🏷️  ${trip.name}');
    buf.writeln('📍 ${trip.destination}');
    buf.writeln('📅 ${_dateFmt.format(trip.fromDate)}');
    buf.writeln('    ↓  $nights night${nights == 1 ? '' : 's'}');
    buf.writeln('    ${_dateFmt.format(trip.toDate)}');
    buf.writeln();
    buf.writeln('👥 Travelers: ${trip.members.map((m) => m.name).join(', ')}');

    if (trip.totalBudget > 0) {
      buf.writeln('💰 Budget: ${_currency(trip.totalBudget)}');
    }

    if (itinerary != null) {
      final totalStops = itinerary.days.fold<int>(0, (s, d) => s + d.stops.length);
      buf.writeln('🗺️  Itinerary: ${itinerary.days.length} day${itinerary.days.length == 1 ? '' : 's'}, $totalStops stop${totalStops == 1 ? '' : 's'}');
    }

    if (packingState != null) {
      buf.writeln('🎒 Packing: ${packingState.packedItems}/${packingState.totalItems} items packed');
    }

    // Highlight first few stops across all days
    if (itinerary != null && itinerary.days.isNotEmpty) {
      buf.writeln();
      buf.writeln('──────────────────────');
      buf.writeln('🏆 HIGHLIGHTS');
      buf.writeln();
      int shown = 0;
      for (final day in itinerary.days) {
        for (final stop in day.stops) {
          if (shown >= 6) break;
          buf.writeln('  ${_stopEmoji(stop.type)} ${stop.title}');
          if (stop.location != null && stop.location!.trim().isNotEmpty) {
            buf.writeln('     📍 ${stop.location!.trim()}');
          }
          buf.writeln('     🗺️  ${_placeUrl(stop)}');
          shown++;
        }
        if (shown >= 6) break;
      }
    }

    buf.writeln();
    if (trip.inviteCode.isNotEmpty) {
      buf.writeln('──────────────────────');
      buf.writeln('🔑 JOIN THE TRIP');
      buf.writeln('   Invite Code: ${trip.inviteCode}');
      buf.writeln('   Open Tara Travel → Enter code to join!');
    }

    buf.writeln();
    _appendFooter(buf, trip);
    return buf.toString().trim();
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  static void _appendFooter(StringBuffer buf, TripModel trip) {
    buf.writeln();
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('📱 Shared via Tara Travel');
    if (trip.inviteCode.isNotEmpty) {
      buf.writeln('🔑 Code: ${trip.inviteCode}');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Simple data class for settlement line items (passed in from split panel)
// ─────────────────────────────────────────────────────────────────────────────

class BudgetSettlement {
  final String fromName;
  final String toName;
  final double amount;
  const BudgetSettlement({
    required this.fromName,
    required this.toName,
    required this.amount,
  });
}
