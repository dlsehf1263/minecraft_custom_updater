import 'package:flutter/material.dart';

final _naviagatorKey = GlobalKey<NavigatorState>();
GlobalKey<NavigatorState> getNavigatorKey() => _naviagatorKey;

BuildContext get context => _naviagatorKey.currentContext!;

void showSnackBar(String text) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(text),
    duration: Duration(seconds: 2),
  ));
}
