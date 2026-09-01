import 'package:flutter/foundation.dart';

/// Represents individual change states for trip quick action modules.
@immutable
class TripQuickActionChanges {
  final bool hasItineraryChanges;
  final bool hasPackingChanges;
  final bool hasMemberChanges;
  final bool hasExpenseChanges;
  final bool hasChatChanges;

  const TripQuickActionChanges({
    this.hasItineraryChanges = false,
    this.hasPackingChanges = false,
    this.hasMemberChanges = false,
    this.hasExpenseChanges = false,
    this.hasChatChanges = false,
  });

  const TripQuickActionChanges.none()
      : hasItineraryChanges = false,
        hasPackingChanges = false,
        hasMemberChanges = false,
        hasExpenseChanges = false,
        hasChatChanges = false;

  bool get hasAnyChanges =>
      hasItineraryChanges ||
      hasPackingChanges ||
      hasMemberChanges ||
      hasExpenseChanges ||
      hasChatChanges;

  TripQuickActionChanges copyWith({
    bool? hasItineraryChanges,
    bool? hasPackingChanges,
    bool? hasMemberChanges,
    bool? hasExpenseChanges,
    bool? hasChatChanges,
  }) {
    return TripQuickActionChanges(
      hasItineraryChanges: hasItineraryChanges ?? this.hasItineraryChanges,
      hasPackingChanges: hasPackingChanges ?? this.hasPackingChanges,
      hasMemberChanges: hasMemberChanges ?? this.hasMemberChanges,
      hasExpenseChanges: hasExpenseChanges ?? this.hasExpenseChanges,
      hasChatChanges: hasChatChanges ?? this.hasChatChanges,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripQuickActionChanges &&
          runtimeType == other.runtimeType &&
          hasItineraryChanges == other.hasItineraryChanges &&
          hasPackingChanges == other.hasPackingChanges &&
          hasMemberChanges == other.hasMemberChanges &&
          hasExpenseChanges == other.hasExpenseChanges &&
          hasChatChanges == other.hasChatChanges;

  @override
  int get hashCode =>
      hasItineraryChanges.hashCode ^
      hasPackingChanges.hashCode ^
      hasMemberChanges.hashCode ^
      hasExpenseChanges.hashCode ^
      hasChatChanges.hashCode;
}
