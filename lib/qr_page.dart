import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class Qrpage extends StatefulWidget {
  const Qrpage({super.key});

  @override
  State<Qrpage> createState() => _QrpageState();
}

class _QrpageState extends State<Qrpage> {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 5000,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    cameraController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_element
    Future<void> showMyDialog(String text) async {
      return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('AlertDialog Title'),
            content: SingleChildScrollView(
              child: ListBody(
                children: const <Widget>[
                  Text('This is a demo alert dialog.'),
                  Text('Would you like to approve of this message?'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Approve'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    SnackBar showMySnackBar(String text) {
      return SnackBar(
        content: Text(text),
      );
    }

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
          height: 300.0,
          width: 300.0,
          // child: CustomPaint(
          //   painter: Sky(),
          // ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              MobileScanner(
                scanWindow: const Rect.fromLTRB(25.0, 25.0, 275.0, 275.0),
                startDelay: false,
                fit: BoxFit.cover,
                controller: cameraController,
                onScannerStarted: (capture) {
                  debugPrint('started');
                },
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  // ignore: unused_local_variable
                  final Uint8List? image = capture.image;
                  for (final barcode in barcodes) {
                    debugPrint('Display Value! ${barcode.displayValue}');
                    debugPrint('Geo point! ${barcode.geoPoint}');
                    if (barcode.displayValue != null) {
                      //showMyDialog(barcode.rawValue!);

                      ScaffoldMessenger.of(context).showSnackBar(
                        showMySnackBar(barcode.displayValue!),
                      );
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
                height: 200.0,
                width: 200.0,
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

class BorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double sh = size.height; // for convenient shortage
    double sw = size.width; // for convenient shortage
    double cornerSide = sh * 0.1; // desirable value for corners side

    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
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
