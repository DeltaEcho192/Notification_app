import 'package:firebase_messaging/firebase_messaging.dart';
import 'checklist.dart';
import 'infoSource.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'navKey.dart';

class PushNotificationsManager {
  PushNotificationsManager._();

  factory PushNotificationsManager() => _instance;

  static final PushNotificationsManager _instance =
      PushNotificationsManager._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool _initialized = false;

  Future<String> init() async {
    if (!_initialized) {
      // For iOS request permission first.
      final navigatorKey = SfcKeys.navKey;
      _firebaseMessaging.requestNotificationPermissions();
      InfoSource dataClass = InfoSource();
      _firebaseMessaging.configure(
        onMessage: (message) async {},
        onResume: (message) async {
          var testDocID = await _handleNotification(message);
          print("Notification Docid " + testDocID);
          dataClass.bauID = "eewk41kiu3kc3k";
          dataClass.bauName = "Test";
          dataClass.date = ["2021-02-16", "19:34:05.000Z"];
          dataClass.docID = "JUKcmuKmQde898VIavwz";
          dataClass.userID = "ad";
          print(dataClass);
          navigatorKey.currentState.push(MaterialPageRoute(
              builder: (context) => (CheckboxWidget(reportData: dataClass))));
        },
      );

      // For testing purposes print the Firebase Messaging token
      String token = await _firebaseMessaging.getToken();
      print("FirebaseMessaging token: $token");
      _initialized = true;
      return token;
    }
  }

  Future<String> _handleNotification(Map<dynamic, dynamic> message) async {
    var data = message['data'] ?? message;
    String docIDMessage = data['docID'];
    return docIDMessage;
  }
}
