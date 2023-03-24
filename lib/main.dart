import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_color.dart';
import 'data/qr_page_data.dart';
import 'view/qr_page.dart';
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
  var loading = true;

  void _changeState(bool state) {
    setState(() {
      loading = !state;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<QrPageData>().init();
      _changeState(loading);
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
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint(state.name);
        debugPrint(instance.isAppDoneInit.toString());
        if (instance.isAppDoneInit) {
          _changeState(loading);
          await Future.delayed(const Duration(seconds: 3)).then((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => super.widget),
            );
          });
        }
        break;
      case AppLifecycleState.inactive:
        debugPrint(state.name);
        break;
      case AppLifecycleState.paused:
        debugPrint(state.name);
        break;
      case AppLifecycleState.detached:
        debugPrint(state.name);
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
