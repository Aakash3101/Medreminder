import 'package:flutter/material.dart';
import 'services/authentication.dart';
import 'pages/root_page.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: 'Med Reminder',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: Colors.green,
          accentColor: Colors.greenAccent,
          brightness: Brightness.dark,
        ),
        home: RootPage(auth: Auth()));
  }
}
