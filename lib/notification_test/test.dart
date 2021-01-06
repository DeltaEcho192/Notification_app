import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';
//import '../checkbox/location.dart';
import 'package:http/http.dart' as http;
import 'package:package_info/package_info.dart';
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NotificationTest',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NotificationTest(),
    );
  }
}

class NotificationTest extends StatefulWidget {
  NotificationTest({Key key}) : super(key: key);

  @override
  _NotificationTestState createState() => _NotificationTestState();
}

class _NotificationTestState extends State<NotificationTest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notification Test"),
        backgroundColor: Color.fromRGBO(232, 195, 30, 1),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Row(
              children: <Widget>[
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.only(
                          left: 25,
                          right: 73,
                        ),
                        child: Text("Notification Test"))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
