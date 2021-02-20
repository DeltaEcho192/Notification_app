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

      _firebaseMessaging.configure(
        onMessage: (message) async {},
        onResume: (message) async {
          print("Onresume Notificaiton Handler");
          Map notiData = await _handleNotification(message);
          InfoSource dataClass = new InfoSource();
          print(notiData);
          //var data = message['data'] ?? message;
          if (notiData["date"] is String) {
            print("date is string");
          } else {
            print("date is not a string");
          }

          dataClass.bauID = notiData["bauID"];
          dataClass.bauName = notiData["bauName"];
          dataClass.date = [notiData["date"], "11:00:00.000Z"];
          dataClass.docID = notiData["docID"];
          dataClass.userID = notiData["userID"];

          /*
          dataClass.bauID = "6";
          dataClass.bauName = "VKS-NB Industriehalle Bassersdorf";
          dataClass.date = ["2020-11-24", "10:41:49.000Z"];
          dataClass.docID = "R0LIzEYcyef4XYwsQOD6";
          dataClass.userID = "milenkomilovanovic";
          */
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

  Future<Map> _handleNotification(Map<dynamic, dynamic> message) async {
    var notiData = {};
    var data = message['data'] ?? message;
    print(data["bauID"]);
    print(data["bauName"]);
    print(data["date"]);
    print(data["docID"]);
    print(data["userID"]);

    notiData["bauID"] = data["bauID"];
    notiData["bauName"] = data["bauName"];
    notiData["date"] = data["date"];
    notiData["docID"] = data["docID"];
    notiData["userID"] = data["userID"];
    return notiData;
  }
}
