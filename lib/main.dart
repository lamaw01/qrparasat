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
import 'position_service.dart';
import 'http_service.dart';
import 'qr_data.dart';
import 'data_logs.dart';
import 'app_color.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 5000,
    formats: [BarcodeFormat.qrCode],
  );
  var deviceInfo = DeviceInfoPlugin();
  Position? positon;
  AndroidDeviceInfo? androidInfo;
  String address = "";
  ValueNotifier<List<Data>> timeLine = ValueNotifier(<Data>[]);
  var scrollController = ScrollController();
  var isLoading = true;
  var isDeviceAuthorized = false;
  final currentTime =
      ValueNotifier<String>(DateFormat.jms().format(DateTime.now()));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initDeviceInfo();
      await initPosition();
      await initTranslateLatLng();
      setState(() {
        isLoading = false;
      });
    });
    Timer.periodic(const Duration(seconds: 1), (timer) {
      currentTime.value = DateFormat.jms().format(DateTime.now());
    });
  }

  @override
  void dispose() {
    super.dispose();
    cameraController.dispose();
  }

  Future<void> initDeviceInfo() async {
    try {
      androidInfo = await deviceInfo.androidInfo;
      var uniqueId =
          "${androidInfo!.brand}:${androidInfo!.product}:${androidInfo!.id}";
      log(uniqueId);
    } catch (e) {
      log('$e');
    } finally {
      await checkDeviceAuthorized(
          "${androidInfo!.brand}:${androidInfo!.product}:${androidInfo!.id}");
    }
  }

  Future<void> initPosition() async {
    try {
      positon = await PositionService.getPosition();
      log("latlng ${positon!.latitude} ${positon!.longitude}");
    } catch (e) {
      log('$e');
      _showMyDialog('Location', '$e');
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
    }
  }

  void _showMyDialog(String title, String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
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

  void _showMyToast(String message) {
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
          child: Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 4,
            style: const TextStyle(
              fontSize: 20.0,
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
      duration: const Duration(seconds: 5),
      curve: Curves.elasticOut,
      reverseCurve: Curves.linear,
    );
  }

  Future<void> insertLog(String id) async {
    QrData qrData = qrDataFromJson(id);
    try {
      await HttpService.postLog(qrData.id, address).then((result) {
        if (result.success) {
          _showMyToast("${result.data.logType} ${result.data.name}");
          if (result.data.logType != "ALREADY IN") {
            timeLine.value = <Data>[...timeLine.value, result.data];
            scrollController.animateTo(
                scrollController.position.minScrollExtent,
                duration: const Duration(seconds: 1),
                curve: Curves.bounceInOut);
            if (timeLine.value.length > 10) timeLine.value.removeAt(0);
          }
        } else {
          _showMyToast(result.message);
        }
      });
    } catch (e) {
      log('$e');
      _showMyToast('$e');
    }
  }

  Future<void> checkDeviceAuthorized(String id) async {
    try {
      await HttpService.getDeviceAuthorized(id).then((result) {
        if (result.success) isDeviceAuthorized = result.data.authorized!;
      });
    } catch (e) {
      log('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // var screenSize = MediaQuery.of(context).size;
    Wakelock.enable();
    if (isLoading) {
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
          title: const Text('Sirius'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info),
              iconSize: 30.0,
              onPressed: () {
                _showMyDialog("Device info",
                    "${androidInfo!.brand}:${androidInfo!.product}:${androidInfo!.id}");
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
            SizedBox(
              child: MobileScanner(
                fit: BoxFit.cover,
                controller: cameraController,
                onDetect: (capture) async {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    log('barcode ${barcode.rawValue}');
                    if (barcode.rawValue != null && isDeviceAuthorized) {
                      await insertLog(barcode.rawValue!);
                    } else {
                      _showMyToast('Device not Authorized');
                    }
                  }
                },
                errorBuilder: (ctx, exception, widget) => const Center(
                  child: CircularProgressIndicator(),
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
                valueListenable: timeLine,
                builder: (ctx, data, _) {
                  return SizedBox(
                    height: 70.0,
                    child: ListView.separated(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      itemCount: data.length,
                      separatorBuilder: (ctx, i) => const SizedBox(width: 5.0),
                      itemBuilder: (ctx, i) {
                        return Container(
                          height: 70.0,
                          width: 200.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0),
                            color: Palette.kMainColor,
                          ),
                          child: Center(
                            child: Text(
                              "${data.reversed.toList()[i].logType} ${data.reversed.toList()[i].name}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16.0,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                overflow: TextOverflow.ellipsis,
                              ),
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
              top: 50.0,
              child: ValueListenableBuilder<String>(
                valueListenable: currentTime,
                builder: (ctx, value, _) {
                  return Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      shadows: [
                        Shadow(
                          blurRadius: 5.0,
                          color: Palette.kMainColor.shade300,
                          offset: const Offset(1.0, 1.0),
                        ),
                      ],
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
