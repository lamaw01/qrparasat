import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
// ignore: unused_import
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';

import '../model/qr_model.dart';
import '../widget/camera_border_widget.dart';
import '../widget/camera_error_widget.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final mobileScannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 3000,
    facing: CameraFacing.front,
    formats: [BarcodeFormat.qrCode],
  );
  @override
  void initState() {
    super.initState();
  }

  Future<void> showScannedQr(String? qrData) async {
    QrModel? qrModel;
    try {
      qrModel = qrModelFromJson(qrData!);
    } catch (e) {
      debugPrint('$e showQrTestScan');
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          actionsPadding: EdgeInsets.zero,
          titlePadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (qrModel != null) ...[
                Text(
                  'Name: ${qrModel.name}',
                  maxLines: 2,
                  style: const TextStyle(fontSize: 18.0),
                ),
                const SizedBox(width: 5.0),
                Text(
                  'ID#: ${qrModel.id}',
                  maxLines: 1,
                  style: const TextStyle(fontSize: 18.0),
                ),
              ] else ...[
                Text(
                  'Unkown QR: ${qrData!}',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18.0,
                  ),
                ),
              ]
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Ok',
                style: TextStyle(fontSize: 20.0),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Wakelock.enable();

    const String title = 'Test Scan QR';
    return Scaffold(
      appBar: AppBar(
        title: const Text(title),
        actions: [
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: mobileScannerController.torchState,
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
            onPressed: () => mobileScannerController.toggleTorch(),
          ),
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: mobileScannerController.cameraFacingState,
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
            onPressed: () => mobileScannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: MobileScanner(
              fit: BoxFit.cover,
              controller: mobileScannerController,
              onScannerStarted: (arguments) {
                debugPrint('onScannerStarted');
              },
              onDetect: (capture) async {
                final List<Barcode> barcodes = capture.barcodes;
                debugPrint('barcode ${barcodes.first.rawValue}');
                await showScannedQr(barcodes.first.rawValue!);
              },
              errorBuilder: (ctx, exception, _) {
                debugPrint('errorBuilder 2');
                String errorCode = exception.errorCode.name;
                mobileScannerController.stop();
                mobileScannerController.start();
                return ErrorCameraWidget(
                  error: errorCode,
                );
              },
              placeholderBuilder: (ctx, widget) {
                return const CircularProgressIndicator();
              },
            ),
          ),
          SizedBox(
            height: 225.0,
            width: 225.0,
            child: CustomPaint(
              foregroundPainter: CameraBorderWidget(),
            ),
          ),
        ],
      ),
    );
  }
}
