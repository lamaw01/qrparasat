import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'app_color.dart';
import 'data/qr_page_data.dart';
import 'widget/loading_page.dart';

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
            detectionTimeoutMs: 5000,
            facing: CameraFacing.front,
            formats: [BarcodeFormat.qrCode],
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

class _HomeState extends State<Home> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<QrPageData>().init();
    });
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    var instance = Provider.of<QrPageData>(context, listen: false);
    var camera = Provider.of<MobileScannerController>(context, listen: false);
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint(state.name);
        debugPrint(instance.isAppDoneInit.toString());
        if (instance.isAppDoneInit) {
          // _changeState(_loading);
          // await Future.delayed(const Duration(seconds: 3)).then((_) {
          //   Navigator.pushReplacement(
          //     context,
          //     MaterialPageRoute(
          //         builder: (BuildContext context) => super.widget),
          //   );
          // });
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => const LoadingPage(),
            ),
          );
        }
        break;
      case AppLifecycleState.inactive:
        debugPrint(state.name);
        camera.stop();
        break;
      case AppLifecycleState.paused:
        debugPrint(state.name);
        camera.stop();
        break;
      case AppLifecycleState.detached:
        debugPrint(state.name);
        camera.stop();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const LoadingPage();
  }
}
