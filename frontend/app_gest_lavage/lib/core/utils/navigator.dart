import 'package:flutter/widgets.dart';

class AppNavigator {
  static final globalKey = GlobalKey<NavigatorState>();

  static push(String url) =>
      Navigator.pushReplacementNamed(globalKey.currentState!.context, url);
  static pushReplacement(String url) =>
      Navigator.pushReplacementNamed(globalKey.currentState!.context, url);
}
