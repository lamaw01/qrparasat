import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_color.dart';
import '../data/qr_page_data.dart';
import 'no_address_page.dart';
import 'qr_page.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<QrPageData>().checkVersion();
      if (context.mounted) {
        await context.read<QrPageData>().showVersionAppDialog(context);
      }
      if (context.mounted) {
        await context.read<QrPageData>().checkLocationService(context);
      }
      if (context.mounted) {
        await context.read<QrPageData>().init().then((result) {
          if (result != '') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => const QrPage(),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => const NoAddressPage(),
              ),
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColor.kMainColor,
      body: Center(
        child: Card(
          child: SizedBox(
            height: 75.0,
            width: 200.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Loading...'),
                CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
