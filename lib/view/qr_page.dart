import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'dart:async';

import '../app_color.dart';
import '../data/qr_page_data.dart';
import '../model/qr_model.dart';
import '../service/debouncer.dart';
import '../widget/camera_border_widget.dart';
import '../model/log_model.dart';
import '../widget/camera_error_widget.dart';
import '../widget/clock_widget.dart';

class QrPage extends StatefulWidget {
  const QrPage({super.key});

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  final debouncer = Debouncer();
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var internetChecker =
          Provider.of<InternetConnectionChecker>(context, listen: false);
      var instance = Provider.of<QrPageData>(context, listen: false);
      internetChecker.onStatusChange.listen((status) {
        instance.internetStatus(status: status, context: context);
      });
      Timer.periodic(const Duration(minutes: 30), (timer) async {
        await instance.getAppVersion().then((_) {
          instance.showVersionAppDialog(context);
        });
      });
    });
  }

  Color colorLogType(String logType) {
    switch (logType) {
      case 'IN':
        return Colors.green;
      case 'OUT':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  void showMyToast({
    required String name,
    required String logType,
  }) {
    showToastWidget(
      Container(
        height: 150.0,
        width: 300.0,
        padding: const EdgeInsets.all(5.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5.0),
          color: AppColor.kMainColor,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                logType,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 30.0,
                  color: colorLogType(logType),
                  fontWeight: FontWeight.w600,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 24.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      context: context,
      animation: StyledToastAnimation.scale,
      reverseAnimation: StyledToastAnimation.fade,
      position: StyledToastPosition.center,
      animDuration: const Duration(seconds: 1),
      duration: const Duration(milliseconds: 3500),
      curve: Curves.elasticOut,
      reverseCurve: Curves.linear,
    );
  }

  void showMyToastError({required String errorMessage}) {
    showToastWidget(
      Container(
        height: 150.0,
        width: 300.0,
        padding: const EdgeInsets.all(5.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5.0),
          color: AppColor.kMainColor,
        ),
        child: Center(
          child: Text(
            errorMessage,
            textAlign: TextAlign.center,
            maxLines: 4,
            style: const TextStyle(
              fontSize: 24.0,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
      context: context,
      animation: StyledToastAnimation.scale,
      reverseAnimation: StyledToastAnimation.fade,
      position: StyledToastPosition.center,
      animDuration: const Duration(seconds: 1),
      duration: const Duration(milliseconds: 3500),
      curve: Curves.elasticOut,
      reverseCurve: Curves.linear,
    );
  }

  void showAppVersionDialog({
    required String title,
    required String id,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SelectableText(id),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showErrorLogsDialog({required List<String> list}) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error logs'),
          content: SizedBox(
            height: MediaQuery.of(context).size.height * 0.50,
            width: MediaQuery.of(context).size.width * 0.80,
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (ctx, i) {
                return Text(list[i]);
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
    var instance = Provider.of<QrPageData>(context, listen: false);
    var camera = Provider.of<MobileScannerController>(context, listen: false);
    const double iconSplash = 26.0;

    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<bool>(
          valueListenable: instance.hasInternet,
          builder: (ctx, value, child) {
            if (value) {
              return const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('Online'),
                  Icon(
                    Icons.signal_wifi_statusbar_4_bar,
                    color: Colors.green,
                  ),
                ],
              );
            } else {
              return const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
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
            splashRadius: iconSplash,
            iconSize: 30.0,
            icon: ValueListenableBuilder<bool>(
              valueListenable: instance.scanMode,
              builder: (context, state, child) {
                if (state) {
                  return const Text(
                    'DTR',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                } else {
                  // return const Icon(Icons.live_help_outlined);
                  return const Icon(Icons.live_help_outlined);
                }
              },
            ),
            onPressed: () {
              instance.scanModeState();
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            iconSize: 30.0,
            splashRadius: iconSplash,
            onPressed: () {
              showAppVersionDialog(
                title: 'Sirius ${instance.appVersion}',
                id: 'Device ID: ${instance.deviceId}',
              );
            },
          ),
          IconButton(
            splashRadius: iconSplash,
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
            splashRadius: iconSplash,
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
          GestureDetector(
            onDoubleTap: () {
              camera.switchCamera();
            },
            child: Center(
              child: MobileScanner(
                fit: BoxFit.cover,
                controller: camera,
                onScannerStarted: (arguments) {
                  debugPrint('onScannerStarted');
                },
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  debugPrint('barcode ${barcodes.first.rawValue}');
                  debouncer.call(() async {
                    if (!instance.hasInternet.value &&
                        !instance.scanMode.value) {
                      showMyToastError(errorMessage: 'No internet connection');
                    } else if (!instance.isDeviceAuthorized &&
                        !instance.scanMode.value) {
                      showMyToastError(errorMessage: 'Device not Authorized');
                    } else if (instance.scanMode.value) {
                      await showScannedQr(barcodes.first.rawValue);
                    } else {
                      var result = await instance.insertLog(
                        qrData: barcodes.first.rawValue!,
                        context: context,
                      );
                      switch (result.result) {
                        case LogResult.success:
                          if (result.result == LogResult.success) {
                            showMyToast(
                              name: result.model!.data.name!,
                              logType: result.model!.data.logType!,
                            );
                            if (result.model!.data.logType != "ALREADY IN") {
                              result.model!.data.timestamp =
                                  DateFormat.jm().format(DateTime.now());
                              instance.previousLogs.value = <Data>[
                                ...instance.previousLogs.value,
                                result.model!.data
                              ];
                              scrollController.animateTo(
                                scrollController.position.minScrollExtent,
                                duration: const Duration(seconds: 1),
                                curve: Curves.bounceInOut,
                              );
                              if (instance.previousLogs.value.length > 20) {
                                instance.previousLogs.value.removeAt(0);
                              }
                            }
                          }
                          break;
                        case LogResult.invalidId:
                          showMyToastError(errorMessage: 'Invalid ID');
                          break;
                        case LogResult.userNotInBranch:
                          showMyToastError(errorMessage: 'User not in branch');
                          break;
                        case LogResult.invalidQr:
                          showMyToastError(errorMessage: 'Invalid QR Code');
                          break;
                        case LogResult.requestTimeout:
                          showMyToastError(errorMessage: 'Request Timeout');
                          break;
                        case LogResult.unkownError:
                          showMyToastError(errorMessage: 'Unkown Error');
                          break;
                      }
                    }
                  });
                },
                errorBuilder: (ctx, exception, _) {
                  debugPrint('errorBuilder 1');
                  String errorCode = exception.errorCode.name;
                  camera.stop();
                  camera.start();
                  return ErrorCameraWidget(
                    error: errorCode,
                  );
                },
                placeholderBuilder: (ctx, widget) {
                  return const CircularProgressIndicator();
                },
              ),
            ),
          ),
          SizedBox(
            height: 225.0,
            width: 225.0,
            child: CustomPaint(
              foregroundPainter: CameraBorderWidget(),
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
                    controller: scrollController,
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
                                          '${data.reversed.toList()[i].logType} ',
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        color: colorLogType(
                                            data.reversed.toList()[i].logType!),
                                        fontWeight: FontWeight.w600,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    TextSpan(
                                      text: data.reversed.toList()[i].timestamp,
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
                                data.reversed.toList()[i].name!,
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
            child: ValueListenableBuilder<bool>(
              valueListenable: instance.scanMode,
              builder: (context, state, child) {
                if (state) {
                  return GestureDetector(
                    onTap: () {
                      showErrorLogsDialog(list: instance.errorList);
                    },
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.20,
                      width: MediaQuery.of(context).size.width * 0.85,
                      decoration: BoxDecoration(
                        color: Colors.amber[500],
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: const Center(
                        child: Text(
                          'Scan Mode\nTest your QR',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 44.0,
                            shadows: [
                              Shadow(
                                blurRadius: 5.0,
                                color: Colors.white,
                                offset: Offset(1.0, 1.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return GestureDetector(
                    onTap: () {
                      showErrorLogsDialog(list: instance.errorList);
                    },
                    child: const ClockWidget(),
                  );
                }
              },
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: instance.isLogging,
            builder: (context, value, child) {
              if (value) {
                return const SpinKitFadingCircle(
                  color: Colors.white,
                  size: 150.0,
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }
}
