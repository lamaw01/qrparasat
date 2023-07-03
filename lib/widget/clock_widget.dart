import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClockWidget extends StatelessWidget {
  const ClockWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat.jms().format(DateTime.now()),
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
            Text(
              DateFormat('yMMMMEEEEd').format(DateTime(DateTime.now().year,
                  DateTime.now().month, DateTime.now().day)),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22.0,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black,
                    offset: Offset(1.0, 1.0),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
