import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:provider/provider.dart';
import 'package:qrparasat/widget/loading_page.dart';
import 'app_color.dart';
import 'data/qr_page_data.dart';
import 'view/qr_page.dart';
// ignore: unused_import
import 'widget/dialogs.dart';

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
  var battery = Battery();
  var loading = true;

  void _changeState(bool state) {
    setState(() {
      loading = !state;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<QrPageData>().init();
      battery.onBatteryStateChanged.listen((BatteryState state) async {
        switch (state) {
          case BatteryState.charging:
            // Dialogs.showMyToast(state.name, context);
            // _changeState(loading);
            // await Future.delayed(const Duration(seconds: 3)).then((_) {
            //   Navigator.pushReplacement<void, void>(
            //     context,
            //     MaterialPageRoute<void>(
            //       builder: (BuildContext context) =>
            //           QrPage(cameraController: cameraController),
            //     ),
            //   );
            // });
            // _changeState(loading);
            break;
          case BatteryState.full:
            // Dialogs.showMyToast(state.name, context);
            break;
          case BatteryState.discharging:
            // Dialogs.showMyToast(state.name, context);
            break;
          case BatteryState.unknown:
            // Dialogs.showMyToast(state.name, context);
            break;
        }
      });
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        log(state.name);
        _changeState(loading);
        await Future.delayed(const Duration(seconds: 3)).then((_) {
          Navigator.pushReplacement<void, void>(
            context,
            MaterialPageRoute<void>(
              builder: (BuildContext context) => const QrPage(),
            ),
          );
        });
        _changeState(loading);
        break;
      case AppLifecycleState.inactive:
        log(state.name);
        break;
      case AppLifecycleState.paused:
        log(state.name);
        break;
      case AppLifecycleState.detached:
        log(state.name);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const LoadingPage();
    } else {
      return const QrPage();
    }
  }
}
