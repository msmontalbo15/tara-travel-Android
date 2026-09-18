import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State of the floating travel bubble overlay
class FloatingBubbleState {
  final bool isVisible;
  final bool isExpanded;
  final Offset position;
  final String? tripId;
  final String? nextStopName;
  final String? nextStopEta;
  final double? nextStopDistanceKm;
  final double? closestCompanionDistanceKm;
  final String? closestCompanionName;

  const FloatingBubbleState({
    this.isVisible = false,
    this.isExpanded = false,
    this.position = const Offset(16, 200),
    this.tripId,
    this.nextStopName,
    this.nextStopEta,
    this.nextStopDistanceKm,
    this.closestCompanionDistanceKm,
    this.closestCompanionName,
  });

  FloatingBubbleState copyWith({
    bool? isVisible,
    bool? isExpanded,
    Offset? position,
    String? tripId,
    String? nextStopName,
    String? nextStopEta,
    double? nextStopDistanceKm,
    double? closestCompanionDistanceKm,
    String? closestCompanionName,
  }) {
    return FloatingBubbleState(
      isVisible: isVisible ?? this.isVisible,
      isExpanded: isExpanded ?? this.isExpanded,
      position: position ?? this.position,
      tripId: tripId ?? this.tripId,
      nextStopName: nextStopName ?? this.nextStopName,
      nextStopEta: nextStopEta ?? this.nextStopEta,
      nextStopDistanceKm: nextStopDistanceKm ?? this.nextStopDistanceKm,
      closestCompanionDistanceKm:
          closestCompanionDistanceKm ?? this.closestCompanionDistanceKm,
      closestCompanionName: closestCompanionName ?? this.closestCompanionName,
    );
  }
}

/// Provider managing floating bubble visibility, coordinates, and telemetry state
final floatingBubbleProvider =
    NotifierProvider<FloatingBubbleNotifier, FloatingBubbleState>(
  FloatingBubbleNotifier.new,
);

class FloatingBubbleNotifier extends Notifier<FloatingBubbleState> {
  @override
  FloatingBubbleState build() {
    return const FloatingBubbleState();
  }

  /// Toggles visibility of the floating bubble
  void toggleVisibility() {
    state = state.copyWith(isVisible: !state.isVisible);
  }

  /// Explicitly shows the floating bubble with active trip stats
  void showBubble({
    String? tripId,
    String? nextStopName,
    String? nextStopEta,
    double? nextStopDistanceKm,
    double? closestCompanionDistanceKm,
    String? closestCompanionName,
  }) {
    state = state.copyWith(
      isVisible: true,
      isExpanded: false,
      tripId: tripId ?? state.tripId,
      nextStopName: nextStopName ?? state.nextStopName,
      nextStopEta: nextStopEta ?? state.nextStopEta,
      nextStopDistanceKm: nextStopDistanceKm ?? state.nextStopDistanceKm,
      closestCompanionDistanceKm:
          closestCompanionDistanceKm ?? state.closestCompanionDistanceKm,
      closestCompanionName: closestCompanionName ?? state.closestCompanionName,
    );
  }

  /// Dismisses / hides the bubble
  void hideBubble() {
    state = state.copyWith(isVisible: false, isExpanded: false);
  }

  /// Toggles expanded mini-HUD card
  void toggleExpanded() {
    state = state.copyWith(isExpanded: !state.isExpanded);
  }

  /// Updates bubble drag position with snap-to-edge calculation
  void updatePosition(Offset newPos, Size screenSize) {
    const bubbleSize = 56.0;
    const topPad = 80.0;
    final bottomPad = screenSize.height - 140.0;

    final clampedY = newPos.dy.clamp(topPad, bottomPad);

    // Magnetic snap to left or right margin (16px inset)
    final snapX = (newPos.dx < screenSize.width / 2)
        ? 16.0
        : (screenSize.width - bubbleSize - 16.0);

    state = state.copyWith(position: Offset(snapX, clampedY));
  }

  /// Temporary raw drag without snap until released
  void dragTo(Offset newPos) {
    state = state.copyWith(position: newPos);
  }
}
