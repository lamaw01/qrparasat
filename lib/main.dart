import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:wakelock/wakelock.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'position_service.dart';
import 'http_service.dart';
import 'qr_data.dart';
import 'data_logs.dart';
import 'app_color.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sirius',
      theme: ThemeData(
        primarySwatch: Palette.kMainColor,
      ),
      home: const Home(),
      debugShowCheckedModeBanner: true,
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 5000,
    formats: [BarcodeFormat.qrCode],
  );
  var deviceInfo = DeviceInfoPlugin();
  Position? positon;
  String latlng = "";
  String address = "";
  String deviceId = "";
  String branchId = "";
  bool isAppLoading = true;
  bool isDeviceAuthorized = false;
  bool hasCheckDeviceAuthorized = false;
  bool hasSendDeviceLog = false;
  var hasInternet = ValueNotifier(false);
  var previousLogs = ValueNotifier(<Data>[]);
  var errorLogs = <String>[];
  var scrollController = ScrollController();
  final deviceTimestamp =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  final currentTimeDisplay =
      ValueNotifier<String>(DateFormat.jms().format(DateTime.now()));
  final internetChecker = InternetConnectionChecker.createInstance(
    checkTimeout: const Duration(seconds: 5),
    checkInterval: const Duration(seconds: 5),
  );
  StreamSubscription<InternetConnectionStatus>? listener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initDeviceInfo();
      await initPosition();
      await initTranslateLatLng();
      await checkDeviceAuthorized();
      await insertDeviceLog();
      setState(() {
        isAppLoading = false;
      });
      listener = internetChecker.onStatusChange.listen((status) async {
        if (status == InternetConnectionStatus.connected) {
          hasInternet.value = true;
        } else {
          hasInternet.value = false;
        }
        if (!hasCheckDeviceAuthorized) await checkDeviceAuthorized();
        if (!hasSendDeviceLog) await insertDeviceLog();
        log("hasInternet ${hasInternet.value}");
      });
    });
    Timer.periodic(const Duration(seconds: 1), (_) {
      currentTimeDisplay.value = DateFormat.jms().format(DateTime.now());
    });
  }

  @override
  void dispose() {
    super.dispose();
    cameraController.dispose();
    listener!.cancel();
  }

  Future<void> initDeviceInfo() async {
    try {
      await deviceInfo.androidInfo.then((result) {
        deviceId = "${result.brand}:${result.product}:${result.id}";
      });
      log(deviceId);
    } catch (e) {
      log('$e');
      errorLogs.add('initDeviceInfo $e');
    }
  }

  Future<void> initPosition() async {
    try {
      await PositionService.getPosition().then((result) {
        positon = result;
        latlng = "${result.latitude} ${result.longitude}";
      });
      log("latlng $latlng");
    } catch (e) {
      log('$e');
      errorLogs.add('initPosition $e');
    }
  }

  Future<void> initTranslateLatLng() async {
    try {
      await placemarkFromCoordinates(positon!.latitude, positon!.longitude)
          .then((result) {
        address =
            "${result.first.subAdministrativeArea} ${result.first.locality} ${result.first.thoroughfare} ${result.first.street}";
      });
      log(address);
    } catch (e) {
      log('$e');
      errorLogs.add('initTranslateLatLng $e');
    }
  }

  Future<void> checkDeviceAuthorized() async {
    try {
      await HttpService.checkDeviceAuthorized(deviceId).then((result) {
        if (result.success) {
          isDeviceAuthorized = result.data.authorized;
          branchId = result.data.branchId;
          hasCheckDeviceAuthorized = true;
        }
      });
    } catch (e) {
      log('$e');
      errorLogs.add('checkDeviceAuthorized $e');
    }
  }

  Future<void> insertDeviceLog() async {
    try {
      await HttpService.insertDeviceLog(
              deviceId, deviceTimestamp, address, latlng)
          .then((_) => hasSendDeviceLog = true);
    } catch (e) {
      log('$e');
      errorLogs.add('insertDeviceLog $e');
    }
  }

  void _showMyDialog(
    String title, {
    bool isError = false,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: isError
              ? ListView.builder(
                  itemCount: errorLogs.length,
                  itemBuilder: (ctx, i) {
                    return Text(errorLogs[i]);
                  },
                )
              : SelectableText(deviceId),
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

  void _showMyToast(String message, {bool error = false, String logType = ''}) {
    showToastWidget(
      Container(
        height: 150.0,
        width: 300.0,
        padding: const EdgeInsets.all(5.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5.0),
          color: Palette.kMainColor,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!error) ...[
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
              ],
              Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 4,
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
      duration: const Duration(seconds: 5),
      curve: Curves.elasticOut,
      reverseCurve: Curves.linear,
    );
  }

  Future<void> insertLog(String id) async {
    try {
      QrData qrData = qrDataFromJson(id);
      await HttpService.insertLog(
              qrData.id, address, latlng, deviceId, branchId)
          .then((result) {
        if (result.success) {
          _showMyToast("${result.data.name}",
              logType: "${result.data.logType}");
          if (result.data.logType != "ALREADY IN") {
            result.data.timestamp = DateFormat.jm().format(DateTime.now());
            previousLogs.value = <Data>[...previousLogs.value, result.data];
            scrollController.animateTo(
                scrollController.position.minScrollExtent,
                duration: const Duration(seconds: 1),
                curve: Curves.bounceInOut);
            if (previousLogs.value.length > 20) previousLogs.value.removeAt(0);
          }
        } else if (result.message == "Invalid id") {
          _showMyToast(result.message, error: true);
        } else if (result.message == "User not in branch") {
          _showMyToast(result.message, error: true);
        } else {
          _showMyToast("Unkown Error", error: true);
        }
        errorLogs.add('insertLog ${result.message}');
      });
    } on FormatException catch (e) {
      log('$e');
      _showMyToast('Invalid QR Code', error: true);
      errorLogs.add('insertLog $e');
    } on TimeoutException catch (e) {
      log('$e');
      _showMyToast('Request Timeout', error: true);
      errorLogs.add('insertLog $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // var screenSize = MediaQuery.of(context).size;
    Wakelock.enable();
    if (isAppLoading) {
      return Scaffold(
        backgroundColor: Palette.kMainColor,
        body: Center(
          child: Card(
            child: SizedBox(
              height: 75.0,
              width: 200.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  Text('Loading...'),
                  CircularProgressIndicator(),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: ValueListenableBuilder<bool>(
            valueListenable: hasInternet,
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
                _showMyDialog("Device info");
              },
            ),
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
        body: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: SizedBox(
                child: MobileScanner(
                  fit: BoxFit.cover,
                  startDelay: true,
                  controller: cameraController,
                  onScannerStarted: (arg) {
                    cameraController.stop();
                  },
                  onDetect: (capture) async {
                    final List<Barcode> barcodes = capture.barcodes;
                    // for (final barcode in barcodes) {
                    log('barcode ${barcodes.first.rawValue}');
                    if (barcodes.first.rawValue != null &&
                        isDeviceAuthorized &&
                        hasInternet.value) {
                      await insertLog(barcodes.first.rawValue!);
                    } else if (hasInternet.value && !isDeviceAuthorized) {
                      _showMyToast('Device not Authorized', error: true);
                    } else {
                      _showMyToast('No internet connection', error: true);
                    }
                    // }
                  },
                  errorBuilder: (ctx, exception, widget) => SizedBox(
                    height: 150.0,
                    width: 150.0,
                    child: Center(
                      child: Text(
                        exception.errorDetails!.message!,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  placeholderBuilder: (ctx, widget) =>
                      const CircularProgressIndicator(),
                ),
              ),
            ),
            SizedBox(
              height: 200.0,
              width: 200.0,
              child: CustomPaint(
                foregroundPainter: BorderPainter(),
              ),
            ),
            Positioned(
              left: 5.0,
              bottom: 5.0,
              right: 5.0,
              child: ValueListenableBuilder<List<Data>>(
                valueListenable: previousLogs,
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
                            color: Palette.kMainColor,
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
                                          color: colorLogType(
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
                valueListenable: currentTimeDisplay,
                builder: (ctx, value, _) {
                  return GestureDetector(
                    onDoubleTap: () {
                      _showMyDialog("Error Logs", isError: true);
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
          ],
        ),
      );
    }
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
    double cornerSide = sh * 0.15; // desirable value for corners side

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
