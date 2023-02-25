import 'package:flutter/material.dart';
import 'custom_color.dart';
import 'get_position.dart';
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
      title: 'Sirius',
      theme: ThemeData(
        primarySwatch: Palette.kToDark,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sirius'),
      ),
      body: const Center(
        child: CircleAvatar(
          radius: 150.0,
          backgroundImage: AssetImage('asset/bg_parasat.jpg'),
        ),
      ),
      bottomNavigationBar: Ink(
        color: Palette.kToDark,
        width: double.infinity,
        height: 60.0,
        child: InkWell(
          child: Center(
            child: ValueListenableBuilder(
              valueListenable: _isLoading,
              builder: (context, state, child) {
                if (state) {
                  return const CircularProgressIndicator(color: Colors.white);
                } else {
                  return const Text(
                    'Start',
                    style: TextStyle(
                      fontSize: 20.0,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }
              },
            ),
          ),
          onTap: () async {
            _isLoading.value = true;
            await getPosition().then((value) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => Qrpage(
                    position: value,
                  ),
                ),
              );
            }).onError((error, stackTrace) {
              debugPrint(error.toString());
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(error.toString()),
                behavior: SnackBarBehavior.floating,
              ));
            });
            _isLoading.value = false;
          },
        ),
      ),
    );
  }
}
