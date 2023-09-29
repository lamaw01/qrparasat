import 'package:flutter/material.dart';

class ErrorCameraWidget extends StatelessWidget {
  const ErrorCameraWidget({super.key, required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150.0,
      width: 150.0,
      child: Center(
        child: Text(
          'Error opening mobileScannerController $error',
          textAlign: TextAlign.center,
          maxLines: 3,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
