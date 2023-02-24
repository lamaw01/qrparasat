import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'check_location_permission.dart';
import 'qr_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parasat QR Scan',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Home(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _isLoading = ValueNotifier(false);
  late Position currentPosition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parasat QR Scan'),
      ),
      body: Center(
        child: ValueListenableBuilder(
          valueListenable: _isLoading,
          builder: (context, state, child) {
            if (state) {
              return const CircularProgressIndicator();
            } else {
              return TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                onPressed: () async {
                  _isLoading.value = true;
                  await determinePosition().then((value) {
                    currentPosition = value;
                    debugPrint(
                        '${currentPosition.latitude} ${currentPosition.longitude}');
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => Qrpage(
                          position: currentPosition,
                        ),
                      ),
                    );
                  }).onError((error, stackTrace) {
                    debugPrint(error.toString());
                  });
                  _isLoading.value = false;
                },
                child: const Text(
                  'Start',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
