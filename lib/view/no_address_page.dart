import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NoAddressPage extends StatelessWidget {
  const NoAddressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('No Address'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              // color: Colors.teal,
              width: 300.0,
              height: 200.0,
              child: Center(
                child: Text(
                  'No address retrieve. Please enable location service, close the app and try again.',
                  // maxLines: 2,
                  style: TextStyle(
                    fontSize: 24.0,
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                SystemNavigator.pop();
              },
              child: const Text('Exit'),
            ),
          ],
        ),
      ),
    );
  }
}
