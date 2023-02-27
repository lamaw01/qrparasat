import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'http_service.dart';

class Qrpage extends StatefulWidget {
  const Qrpage({super.key, required this.position});
  final Position position;

  @override
  State<Qrpage> createState() => _QrpageState();
}

class _QrpageState extends State<Qrpage> {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 5000,
  );

  @override
  void dispose() {
    super.dispose();
    cameraController.dispose();
  }

  Future<void> insertLog(String id) async {
    String result = '';
    bool success = false;
    try {
      var data = await HttpService.postLog(id);
      result = data.data;
      success = data.success;
    } catch (e) {
      result = e.toString();
      debugPrint(result);
    } finally {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          success ? "Good Morning $result" : result,
          style: const TextStyle(color: Colors.black),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan'),
        actions: [
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            iconSize: 30.0,
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            iconSize: 30.0,
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          // height: 300.0,
          // width: 300.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              MobileScanner(
                // scanWindow: const Rect.fromLTRB(25.0, 25.0, 275.0, 275.0),
                startDelay: false,
                fit: BoxFit.cover,
                controller: cameraController,
                onDetect: (capture) async {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    debugPrint('barcode ${barcode.displayValue}');
                    if (barcode.displayValue != null) {
                      await insertLog(barcode.displayValue!);
                    }
                  }
                },
                placeholderBuilder: (ctx, widget) => const Center(
                  child: Text('Error'),
                ),
                errorBuilder: (ctx, exception, widget) => const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              SizedBox(
                height: 250.0,
                width: 250.0,
                child: CustomPaint(
                  foregroundPainter: BorderPainter(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//Paint see Rect layout
class Sky extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      const Rect.fromLTRB(25.0, 25.0, 275.0, 275.0),
      Paint()..color = const Color(0xFF0099FF),
    );
  }

  @override
  bool shouldRepaint(Sky oldDelegate) {
    return false;
  }
}

//Borders Black
class BorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double sh = size.height; // for convenient shortage
    double sw = size.width; // for convenient shortage
    double cornerSide = sh * 0.1; // desirable value for corners side

    Paint paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Path path = Path()
      ..moveTo(cornerSide, 0)
      ..quadraticBezierTo(0, 0, 0, cornerSide)
      ..moveTo(0, sh - cornerSide)
      ..quadraticBezierTo(0, sh, cornerSide, sh)
      ..moveTo(sw - cornerSide, sh)
      ..quadraticBezierTo(sw, sh, sw, sh - cornerSide)
      ..moveTo(sw, cornerSide)
      ..quadraticBezierTo(sw, 0, sw - cornerSide, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BorderPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(BorderPainter oldDelegate) => false;
}
