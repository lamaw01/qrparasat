import 'dart:async';

import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';

import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../app_color.dart';
import '../data/qr_page_data.dart';
import '../widget/camera_border.dart';
import '../model/log_model.dart';
import '../widget/dialogs.dart';

class QrPage extends StatefulWidget {
  const QrPage({super.key});

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  final _currentTimeDisplay = ValueNotifier<String>('00:00:00');

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 1), (_) {
      _currentTimeDisplay.value = DateFormat.jms().format(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('build qr page');
    var instance = Provider.of<QrPageData>(context, listen: false);
    var camera = Provider.of<MobileScannerController>(context, listen: false);
    var internetChecker = Provider.of<InternetConnectionChecker>(context);
    Wakelock.enable();
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<bool>(
          valueListenable: instance.hasInternet,
          builder: (ctx, value, child) {
            if (value) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  Text('Online'),
                  Icon(
                    Icons.signal_wifi_statusbar_4_bar,
                    color: Colors.green,
                  ),
                ],
              );
            } else {
              return Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  Text('Offline'),
                  Icon(
                    Icons.signal_wifi_off,
                    color: Colors.red,
                  ),
                ],
              );
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            iconSize: 30.0,
            onPressed: () {
              Dialogs.showMyDialog("Device info", context,
                  id: instance.deviceId);
            },
          ),
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: camera.torchState,
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
            onPressed: () => camera.toggleTorch(),
          ),
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: camera.cameraFacingState,
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
            onPressed: () => camera.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: SizedBox(
              child: MobileScanner(
                startDelay: true,
                fit: BoxFit.cover,
                controller: camera,
                onScannerStarted: (MobileScannerArguments? arg) {
                  instance.doneInit();
                  internetChecker.onStatusChange.listen((status) async {
                    instance.internetStatus(status);
                  });
                },
                onDetect: (capture) async {
                  final List<Barcode> barcodes = capture.barcodes;
                  debugPrint('barcode ${barcodes.first.rawValue}');
                  if (barcodes.first.rawValue != null &&
                      instance.isDeviceAuthorized &&
                      instance.hasInternet.value) {
                    await instance.insertLog(barcodes.first.rawValue!, context);
                  } else if (instance.hasInternet.value &&
                      !instance.isDeviceAuthorized) {
                    Dialogs.showMyToast('Device not Authorized', context,
                        error: true);
                  } else {
                    Dialogs.showMyToast('No internet connection', context,
                        error: true);
                  }
                },
                errorBuilder: (ctx, exception, _) {
                  var errorMessage =
                      exception.errorDetails!.message ?? "Error loading camera";
                  instance.addError(
                      "errorBuilder ${exception.errorCode.name} $errorMessage");
                  debugPrint(errorMessage);
                  camera.stop();
                  camera.start();
                  return SizedBox(
                    height: 150.0,
                    width: 150.0,
                    child: Center(
                      child: Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                },
                placeholderBuilder: (ctx, widget) {
                  return const CircularProgressIndicator();
                },
              ),
            ),
          ),
          SizedBox(
            height: 200.0,
            width: 200.0,
            child: CustomPaint(
              foregroundPainter: CameraBorder(),
            ),
          ),
          Positioned(
            left: 5.0,
            bottom: 5.0,
            right: 5.0,
            child: ValueListenableBuilder<List<Data>>(
              valueListenable: instance.previousLogs,
              builder: (ctx, data, _) {
                return SizedBox(
                  height: 75.0,
                  child: ListView.separated(
                    controller: instance.scrollController,
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemCount: data.length,
                    separatorBuilder: (ctx, i) => const SizedBox(width: 5.0),
                    itemBuilder: (ctx, i) {
                      return Container(
                        height: 75.0,
                        width: 225.0,
                        padding: const EdgeInsets.all(5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5.0),
                          color: AppColor.kMainColor,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: <TextSpan>[
                                    TextSpan(
                                      text:
                                          "${data.reversed.toList()[i].logType} ",
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        color: Dialogs.colorLogType(
                                            "${data.reversed.toList()[i].logType}"),
                                        fontWeight: FontWeight.w600,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          "${data.reversed.toList()[i].timestamp}",
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "${data.reversed.toList()[i].name}",
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 30.0,
            child: ValueListenableBuilder<String>(
              valueListenable: _currentTimeDisplay,
              builder: (ctx, value, _) {
                return GestureDetector(
                  onDoubleTap: () {
                    Dialogs.showMyDialog("Error Logs", context,
                        isError: true, list: instance.errorList);
                  },
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56.0,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black,
                          offset: Offset(1.0, 1.0),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: instance.isLogging,
            builder: (ctx, value, _) {
              if (value) {
                return const SpinKitFadingCircle(
                  color: Colors.white,
                  size: 150.0,
                );
              } else {
                return const SizedBox();
              }
            },
          ),
        ],
      ),
    );
  }
}
