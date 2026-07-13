import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/navigation_models.dart';

class LiveMapView extends StatelessWidget {
  final NavigationState state;
  final bool isMiniMap;

  const LiveMapView({
    super.key,
    required this.state,
    this.isMiniMap = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2D3748),
      child: Stack(
        children: [
          // ── Map Base & Roads ─────────────────────────────────
          _MapPainterWidget(
            isMiniMap: isMiniMap,
            isArriving: state.isProximityAlertActive || state.isArrived,
          ),

          // ── Destination Pin ──────────────────────────────────
          if (!state.isArrived)
            Positioned(
              top: isMiniMap ? 10 : 80,
              left: isMiniMap ? 140 : 148,
              child: _DestinationPin(isMiniMap: isMiniMap, name: state.destination.name),
            ),

          // ── Member Pins ──────────────────────────────────────
          ...state.members.map((member) {
            // Mock positions based on HTML logic
            double top = 0;
            double left = 0;
            
            if (member.isMe) {
              top = isMiniMap ? 110 : 440;
              left = isMiniMap ? 138 : 152;
            } else if (member.initials == 'C') {
              top = isMiniMap ? 76 : 310;
              left = isMiniMap ? 176 : 220;
            } else if (member.initials == 'M') {
              top = isMiniMap ? 96 : 375;
              left = isMiniMap ? 52 : 82;
            } else if (member.initials == 'L') {
              top = isMiniMap ? 56 : 258;
              left = isMiniMap ? 70 : 52;
            } else {
              return const SizedBox.shrink();
            }

            return Positioned(
              top: top,
              left: left,
              child: _MemberPin(member: member, isMiniMap: isMiniMap),
            );
          }),

          // ── Scale Indicator ──────────────────────────────────
          if (!isMiniMap)
            Positioned(
              bottom: 150,
              left: 20,
              child: Row(
                children: [
                  Container(width: 40, height: 3, decoration: BoxDecoration(color: Colors.white54, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 6),
                  const Text('500m', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MapPainterWidget extends StatelessWidget {
  final bool isMiniMap;
  final bool isArriving;

  const _MapPainterWidget({required this.isMiniMap, required this.isArriving});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _MapPainter(isMiniMap: isMiniMap, isArriving: isArriving),
    );
  }
}

class _MapPainter extends CustomPainter {
  final bool isMiniMap;
  final bool isArriving;

  _MapPainter({required this.isMiniMap, required this.isArriving});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background
    final bgPaint = Paint()..color = const Color(0xFF35404F);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. Water (Bottom Right)
    final waterPaint = Paint()..color = const Color(0xFF1E2D3D);
    canvas.drawRRect(
      RRect.fromLTRBR(size.width * 0.5, size.height * 0.75, size.width, size.height, const Radius.circular(80)),
      waterPaint,
    );

    // 3. Roads
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeCap = StrokeCap.round;

    final roadOpPaint = Paint()..color = Colors.white.withValues(alpha: 0.1);

    // Horizontal
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.16, size.width, 4), roadPaint);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.28, size.width, 3), roadOpPaint);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.4, size.width, 6), roadPaint);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.56, size.width, 3), roadOpPaint);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.68, size.width, 4), roadPaint);

    // Vertical
    canvas.drawRect(Rect.fromLTWH(size.width * 0.18, 0, 3, size.height), roadOpPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.35, 0, 5, size.height), roadPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.6, 0, 4, size.height), roadOpPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.76, 0, 7, size.height), roadPaint);

    // 4. Route Line
    if (!isArriving) {
      final routeOutline = Paint()
        ..color = const Color(0xFF992B10)
        ..strokeWidth = isMiniMap ? 5 : 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final routeFill = Paint()
        ..color = const Color(0xFFD85A30)
        ..strokeWidth = isMiniMap ? 3 : 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      if (isMiniMap) {
        path.moveTo(size.width * 0.5, size.height * 0.9);
        path.lineTo(size.width * 0.5, size.height * 0.6);
        path.lineTo(size.width * 0.75, size.height * 0.6);
        path.lineTo(size.width * 0.75, size.height * 0.35);
        path.lineTo(size.width * 0.5, size.height * 0.35);
        path.lineTo(size.width * 0.5, size.height * 0.1);
      } else {
        path.moveTo(size.width * 0.5, size.height * 0.9);
        path.lineTo(size.width * 0.5, size.height * 0.65);
        path.lineTo(size.width * 0.76, size.height * 0.65);
        path.lineTo(size.width * 0.76, size.height * 0.4);
        path.lineTo(size.width * 0.5, size.height * 0.4);
        path.lineTo(size.width * 0.5, size.height * 0.15);
      }
      canvas.drawPath(path, routeOutline);
      canvas.drawPath(path, routeFill);
    } else {
      // Arriving Arcs
      final center = Offset(size.width / 2, size.height * 0.4);
      final ringPaint = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      // Radius circles
      canvas.drawCircle(center, 90, ringPaint..style = PaintingStyle.stroke..color = AppColors.primary.withValues(alpha: 0.3));
      canvas.drawCircle(center, 40, ringPaint..style = PaintingStyle.stroke..color = AppColors.primary.withValues(alpha: 0.7));
      canvas.drawCircle(center, 40, Paint()..color = AppColors.primary.withValues(alpha: 0.08));

      // Approach path
      canvas.drawLine(Offset(size.width / 2, size.height * 0.8), center, Paint()..color = AppColors.primary..strokeWidth = 4..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DestinationPin extends StatelessWidget {
  final bool isMiniMap;
  final String name;

  const _DestinationPin({required this.isMiniMap, required this.name});

  @override
  Widget build(BuildContext context) {
    if (isMiniMap) {
      return Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.primary, border: Border.all(color: Colors.white, width: 2), shape: BoxShape.circle));
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomRight: Radius.circular(12), bottomLeft: Radius.circular(2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              const Text('Destination', style: TextStyle(color: Colors.white70, fontSize: 9)),
            ],
          ),
        ),
        Container(width: 2, height: 6, color: AppColors.primary),
        Container(width: 10, height: 10, decoration: BoxDecoration(color: AppColors.primary, border: Border.all(color: Colors.white, width: 2), shape: BoxShape.circle)),
      ],
    );
  }
}

class _MemberPin extends StatelessWidget {
  final NavMember member;
  final bool isMiniMap;

  const _MemberPin({required this.member, required this.isMiniMap});

  @override
  Widget build(BuildContext context) {
    if (member.isMe) {
      return Stack(
        alignment: Alignment.center,
        children: [
          // Heading cone
          if (!isMiniMap)
            Transform.rotate(
              angle: 0,
              child: CustomPaint(
                size: const Size(40, 40),
                painter: _HeadingConePainter(),
              ),
            ),
          // Pulse
          Container(
            width: isMiniMap ? 24 : 36,
            height: isMiniMap ? 24 : 36,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2)),
          ),
          // Avatar
          Container(
            width: isMiniMap ? 18 : 28,
            height: isMiniMap ? 18 : 28,
            decoration: BoxDecoration(color: member.color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: isMiniMap ? 1.5 : 2.5)),
            child: Center(child: Text(member.initials, style: TextStyle(color: Colors.white, fontSize: isMiniMap ? 8 : 11, fontWeight: FontWeight.bold))),
          ),
        ],
      );
    }

    return Column(
      children: [
        Container(
          width: isMiniMap ? 16 : 28,
          height: isMiniMap ? 16 : 28,
          decoration: BoxDecoration(color: member.color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: isMiniMap ? 1.5 : 2.5)),
          child: Center(child: Text(member.initials, style: TextStyle(color: Colors.white, fontSize: isMiniMap ? 8 : 10, fontWeight: FontWeight.bold))),
        ),
        if (!isMiniMap) ...[
          Container(width: 2, height: 8, color: Colors.white70),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(6)),
            child: Text(member.distanceLabel ?? 'Tracking', style: const TextStyle(color: Color(0xFFF0997B), fontSize: 9, fontWeight: FontWeight.w600)),
          ),
        ],
      ],
    );
  }
}

class _HeadingConePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primary.withValues(alpha: 0.3);
    final path = Path()
      ..moveTo(size.width / 2, size.height / 2)
      ..lineTo(size.width * 0.3, 0)
      ..lineTo(size.width * 0.7, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
