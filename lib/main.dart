import 'package:auto_check_temperature/pages/settings.dart';
import 'package:flutter/material.dart';
import 'package:auto_check_temperature/pages/login.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '打你🐎的卡',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      // initialRoute: '/settings',
      routes: {
        '/': (context) => LoginPage(),
        '/settings': (context) => SettingPage()
      },
    );
  }
}
