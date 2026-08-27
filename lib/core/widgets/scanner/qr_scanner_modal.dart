import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_colors.dart';

/// Modal bottom sheet providing a camera scanner for Tara Travel QR codes.
class QrScannerModal extends StatefulWidget {
  const QrScannerModal({
    super.key,
    this.title = 'Scan QR Code',
    this.instruction = 'Point camera at a Friend Code or Trip QR',
  });

  final String title;
  final String instruction;

  /// Convenience launcher that returns the scanned String payload or null.
  static Future<String?> show(
    BuildContext context, {
    String title = 'Scan QR Code',
    String instruction = 'Point camera at a Friend Code or Trip QR',
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QrScannerModal(
        title: title,
        instruction: instruction,
      ),
    );
  }

  @override
  State<QrScannerModal> createState() => _QrScannerModalState();
}

class _QrScannerModalState extends State<QrScannerModal> {
  late final MobileScannerController _controller;
  bool _hasDetected = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasDetected) return;
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw != null && raw.isNotEmpty) {
        _hasDetected = true;
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(raw);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final sheetHeight = mediaQuery.size.height * 0.78;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: AppColors.deepEarth,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Top Header Bar with controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Torch Toggle
                  IconButton(
                    icon: Icon(
                      _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: _isTorchOn ? AppColors.amber : Colors.white70,
                    ),
                    onPressed: () async {
                      await _controller.toggleTorch();
                      setState(() {
                        _isTorchOn = !_isTorchOn;
                      });
                    },
                  ),
                  // Camera Switch
                  IconButton(
                    icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white70),
                    onPressed: () => _controller.switchCamera(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Camera Viewport with Scanner Reticle
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                  ),

                  // Translucent Dark Overlay with square cut-out
                  CustomPaint(
                    painter: _ScannerOverlayPainter(
                      borderColor: AppColors.primary,
                      borderRadius: 18,
                      borderLength: 32,
                      borderWidth: 4,
                      cutOutSize: 240,
                    ),
                  ),

                  // Instruction label at bottom
                  Positioned(
                    bottom: 30,
                    left: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.deepEarth.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        widget.instruction,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for camera reticle box and darkened outer frame.
class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter({
    required this.borderColor,
    required this.borderRadius,
    required this.borderLength,
    required this.borderWidth,
    required this.cutOutSize,
  });

  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);

    final left = (size.width - cutOutSize) / 2;
    final top = (size.height - cutOutSize) / 2;
    final rect = Rect.fromLTWH(left, top, cutOutSize, cutOutSize);

    // Draw darkened outer area
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final r = borderRadius;
    final l = borderLength;

    // Top-Left corner
    final tl = Path()
      ..moveTo(left, top + l)
      ..lineTo(left, top + r)
      ..arcToPoint(Offset(left + r, top), radius: Radius.circular(r))
      ..lineTo(left + l, top);
    canvas.drawPath(tl, cornerPaint);

    // Top-Right corner
    final tr = Path()
      ..moveTo(left + cutOutSize - l, top)
      ..lineTo(left + cutOutSize - r, top)
      ..arcToPoint(Offset(left + cutOutSize, top + r), radius: Radius.circular(r))
      ..lineTo(left + cutOutSize, top + l);
    canvas.drawPath(tr, cornerPaint);

    // Bottom-Right corner
    final br = Path()
      ..moveTo(left + cutOutSize, top + cutOutSize - l)
      ..lineTo(left + cutOutSize, top + cutOutSize - r)
      ..arcToPoint(Offset(left + cutOutSize - r, top + cutOutSize), radius: Radius.circular(r))
      ..lineTo(left + cutOutSize - l, top + cutOutSize);
    canvas.drawPath(br, cornerPaint);

    // Bottom-Left corner
    final bl = Path()
      ..moveTo(left + l, top + cutOutSize)
      ..lineTo(left + r, top + cutOutSize)
      ..arcToPoint(Offset(left, top + cutOutSize - r), radius: Radius.circular(r))
      ..lineTo(left, top + cutOutSize - l);
    canvas.drawPath(bl, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
