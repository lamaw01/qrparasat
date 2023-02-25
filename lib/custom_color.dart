import 'package:flutter/material.dart';

class Palette {
  static const MaterialColor kToDark = MaterialColor(
    0xff002db3, // 0% comes in here, this will be color picked if no shade is selected when defining a Color property which doesn’t require a swatch.
    <int, Color>{
      50: Color(0xffccd9ff), //10%
      100: Color(0xff99b3ff), //20%
      200: Color(0xff668cff), //30%
      300: Color(0xff3366ff), //40%
      400: Color(0xff0040ff), //50%
      500: Color(0xff0033cc), //60%
      600: Color(0xff002db3), //70%
      700: Color(0xff002699), //80%
      800: Color(0xff001a66), //90%
      900: Color(0xff000d33), //100%
    },
  );
}
