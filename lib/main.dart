import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'app_color.dart';
import 'data/qr_page_data.dart';
import 'view/loading_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<QrPageData>(
          create: (_) => QrPageData(),
        ),
        Provider<MobileScannerController>(
          create: (_) => MobileScannerController(
            detectionSpeed: DetectionSpeed.normal,
            detectionTimeoutMs: 4000,
            facing: CameraFacing.front,
            formats: [BarcodeFormat.qrCode],
          ),
        ),
        Provider<InternetConnectionChecker>(
          create: (_) => InternetConnectionChecker.createInstance(
            checkTimeout: const Duration(seconds: 5),
            checkInterval: const Duration(seconds: 5),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sirius',
      theme: ThemeData(
        primarySwatch: AppColor.kMainColor,
        useMaterial3: false,
      ),
      home: const LoadingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
