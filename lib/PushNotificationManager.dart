import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
          onBackgroundMessage: _firebaseMessagingBackgroundHandler,
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
            SharedPreferences prefs = await SharedPreferences.getInstance();
            List<String> rmvd = (prefs.getStringList("notiRmvd") ?? []);
            rmvd.add(notiData["docID"]);
            prefs.setStringList("notiRmvd", rmvd);
            print(dataClass);
            navigatorKey.currentState.push(MaterialPageRoute(
                builder: (context) => (CheckboxWidget(reportData: dataClass))));
          },
          onLaunch: (message) async {
            print("onLaunch Notificaiton Handler");
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
            SharedPreferences prefs = await SharedPreferences.getInstance();
            List<String> rmvd = (prefs.getStringList("notiRmvd") ?? []);
            rmvd.add(notiData["docID"]);
            prefs.setStringList("notiRmvd", rmvd);
            print(dataClass);
            navigatorKey.currentState.push(MaterialPageRoute(
                builder: (context) => (CheckboxWidget(reportData: dataClass))));
          });
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

Future<dynamic> androidNotificationHandler(Map<String, dynamic> message) async {
  print("Android Handling Notification");
  print(message);
  var navigatorKey = SfcKeys.navKey;
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

  print(dataClass);
  navigatorKey.currentState.push(MaterialPageRoute(
      builder: (context) => (CheckboxWidget(reportData: dataClass))));
}

Future<dynamic> _firebaseMessagingBackgroundHandler(
  Map<String, dynamic> message,
) async {
  // Initialize the Firebase app

  print('onBackgroundMessage received: $message');
}
