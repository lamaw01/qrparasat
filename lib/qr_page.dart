import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class Qrpage extends StatefulWidget {
  const Qrpage({super.key});

  @override
  State<Qrpage> createState() => _QrpageState();
}

class _QrpageState extends State<Qrpage> {
  MobileScannerController cameraController = MobileScannerController();

  @override
  void dispose() {
    super.dispose();
    cameraController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parasat QR Scan'),
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
            iconSize: 32.0,
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
            iconSize: 32.0,
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Center(
        child: Container(
          color: Colors.orange,
          height: 500.0,
          width: 500.0,
          child: MobileScanner(
            ///scanWindow: const Rect.fromLTRB(5.0, 5.0, 5.0, 5.0),
            startDelay: false,
            fit: BoxFit.contain,
            controller: cameraController,
            onScannerStarted: (capture) {
              //
            },
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              // ignore: unused_local_variable
              final Uint8List? image = capture.image;
              for (final barcode in barcodes) {
                debugPrint('Barcode found! ${barcode.rawValue}');
              }
            },
            placeholderBuilder: (ctx, widget) => const Center(
              child: Text('Error'),
            ),
            errorBuilder: (ctx, exception, widget) => const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );
  }
}
