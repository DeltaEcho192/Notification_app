import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vanoli_notification/login/loginKey.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'checklist.dart';
import 'infoSource.dart';
import 'PushNotificationManager.dart';
import 'lifeCycle.dart';
import 'navKey.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new Report(title: 'Report Select'),
    );
  }
}

class Report extends StatefulWidget {
  Report({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _ReportState createState() => new _ReportState();
}

class _ReportState extends State<Report> with WidgetsBindingObserver {
  PushNotificationsManager notificationInit = new PushNotificationsManager();
  LifecycleEventHandler lifecycleCheck = new LifecycleEventHandler();

  TextEditingController editingController = TextEditingController();
  List<String> mainDataList = [];
  List<String> newDataList = [];
  List<dynamic> reportApi = [];
  List<dynamic> searchedList = [];

  InfoSource dataClass = InfoSource();
  var usr = "";
  var notiCount = 0;
  List<String> notiArray = [];
  List<String> notiRmvd = [];
  bool badgeInit = false;

  Map bauSugg = {"bauName": "Loading"};
  var bauIDS = {};

  Future<void> getBaustelle() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
    var host = GlobalConfiguration().getValue("host");
    var port = GlobalConfiguration().getValue("port");
    final response =
        await http.get("https://" + host + ":" + port + '/reports/' + usr);

    if (response.statusCode == 200) {
      reportApi = await jsonDecode(response.body);
      setState(() {
        searchedList = List<dynamic>.from(reportApi);
        _notificationCountTesting();
        _sortList();
      });
    } else {
      throw Exception("Failed to get Baustelle");
    }
  }

  _sortList() {
    searchedList.sort((a, b) => (b["date"][0]).compareTo(a["date"][0]));
  }

  _sortGreens() {
    List<dynamic> greenList = [];
    List<dynamic> blackList = [];
    searchedList.forEach((value) => ({
          if (notiArray.contains(value["docID"]))
            {greenList.add(value)}
          else
            {blackList.add(value)}
        }));
    setState(() {
      searchedList.clear();
      searchedList = [...greenList, ...blackList];
    });
  }

  _loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("Loading User");
    print(prefs.getString('user') ?? "empty");
    setState(() {
      usr = (prefs.getString('user') ?? "empty");
      _tokenInit();
      getBaustelle();
    });
  }

  _writeDocID(String docID) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setString('docIDPref', docID);
    });
  }

  Future<void> _tokenInit() async {
    var token = await notificationInit.init();
    if (token != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString("token", token);
      print(token);
    } else {
      print("There has been a issue gettting notification token");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      token = prefs.getString("token");
      print(token);
    }
    await GlobalConfiguration().loadFromAsset("app_settings");
    var host = GlobalConfiguration().getValue("host");
    var port = GlobalConfiguration().getValue("port");
    var urlLocal = "https://" + host + ":" + port + '/updateToken/';
    print(urlLocal);
    print(jsonEncode({"userid": usr, "token": token}));
    if (token == "null") {
      print("Token can not be null");
    } else {
      final check = await http.post(urlLocal,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({"userid": usr, "token": token}));

      if (check.statusCode == 201) {
        print("User token updated");
      } else {
        throw Exception('Failed to update user token');
      }
    }
  }

  Future<void> _tokenLogout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = (prefs.getString("token") ?? "null");
    if (token != "null") {
      print(token);
      await GlobalConfiguration().loadFromAsset("app_settings");
      var host = GlobalConfiguration().getValue("host");
      var port = GlobalConfiguration().getValue("port");
      var urlLocal = "https://" + host + ":" + port + '/tokenLogout/';
      print(urlLocal);
      print(jsonEncode({"userid": usr, "token": token}));
      if (token == null) {
        print("Token can not be null");
      } else {
        final check = await http.post(urlLocal,
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode({"userid": usr, "token": token}));

        if (check.statusCode == 201) {
          print("User token Logged out");
        } else {
          throw Exception('Failed to logout user token');
        }
      }
    }
  }

  @override
  void initState() {
    _loadUser();
    _notificationCountTesting();
    _sortList();
    super.initState();

    WidgetsBinding.instance.addObserver(LifecycleEventHandler(
        resumeCallBack: () async => setState(() {
              // do something
              getBaustelle();
              _notificationCountTesting();

              print("resumed State");
            })));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  //Change to reflect the map and search based on 'data.bauName'
  onItemChanged(String value) {
    setState(() {
      searchedList = reportApi
          .where((string) =>
              string["bauName"].toLowerCase().contains(value.toLowerCase()))
          .toList();
    });
  }

  _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setString('user', 'empty');
      prefs.setBool('loged', false);
    });
  }

  _notificationCheck(List<String> notiArrayLocal) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var badgeInit = prefs.getBool('badgeInit') ?? false;
    if (badgeInit == false) {
      var check = await FlutterAppBadger.isAppBadgeSupported();
      if (check == true) {
        print(check);
        print("App badger is true");
        setState(() {
          FlutterAppBadger.updateBadgeCount(notiArrayLocal.length);
          print("Writing badge Icons");
        });
      } else {
        _badgeFalseDialog();
      }
      prefs.setBool("badgeInit", true);
    } else {
      setState(() {
        FlutterAppBadger.updateBadgeCount(notiArrayLocal.length);
        print("Writing badge Icons");
      });
    }
  }

  _notificationCountTesting() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    notiArray = [];
    notiRmvd = (prefs.getStringList('notiRmvd') ?? []);
    print("Counting Notifications");
    for (var x = 0; x < reportApi.length; x++) {
      var workingID = reportApi[x]["docID"];
      if (notiRmvd.contains(workingID) == false) {
        notiArray.add(workingID);
      }
    }
    setState(() {
      prefs.setStringList("notiArray", notiArray);
      _notificationCheck(notiArray);
      _sortGreens();
    });
  }

  _notificationRead(var rmDocID) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    notiArray.remove(rmDocID);
    FlutterAppBadger.updateBadgeCount(notiArray.length);
    setState(() {
      List<String> rmvd = (prefs.getStringList("notiRmvd") ?? []);
      rmvd.add(rmDocID);

      notiRmvd = rmvd;
      prefs.setStringList("notiRmvd", rmvd);
      prefs.setStringList("notiArray", notiArray);
    });
  }

  _notificationLongPress(var addDocID) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      notiArray.add(addDocID);
      FlutterAppBadger.updateBadgeCount(notiArray.length);
      List<String> rmvd = (prefs.getStringList("notiRmvd") ?? []);
      while (rmvd.remove(addDocID) == true) {
        rmvd.remove(addDocID);
      }
      notiRmvd = rmvd;
      print("Unread Report");
      prefs.setStringList("notiRmvd", rmvd);
      prefs.setStringList("notiArray", notiArray);
    });
  }

  Future<void> _showLongPressDialog(var dialogDocID) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Unread Report'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to unread this report?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                _notificationLongPress(dialogDocID);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _badgeFalseDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('System incompatible'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('This android phone is incompatible with app badges'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Okay'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _unreadAllDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sind sie sicher?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Sind Sie sicher, dass Sie alle Berichte ungelesen haben möchten?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Ja'),
              onPressed: () {
                _unreadAllreports();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Nein'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  _unreadAllreports() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var notiRmvdWorking = (prefs.getStringList('notiRmvd') ?? []);
    var totalRmvd = [...notiRmvdWorking, ...notiArray];
    setState(() {
      prefs.setStringList("notiRmvd", totalRmvd);
      notiArray.clear();
      prefs.setStringList("notiArray", notiArray);
      print("Read All reports");
      getBaustelle();
      _notificationCountTesting();
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("Report auswählen"),
          backgroundColor: Color.fromRGBO(232, 195, 30, 1),
          actions: [
            IconButton(
                icon: Icon(Icons.mark_as_unread),
                onPressed: () {
                  _unreadAllDialog();
                }),
            IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  getBaustelle();
                })
          ],
        ),
        body: Container(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  onChanged: onItemChanged,
                  controller: editingController,
                  decoration: InputDecoration(
                      labelText: "Baustellensuche",
                      hintText: "Baustellensuche",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(25.0)))),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(12.0),
                  children: searchedList.map((data) {
                    var statusColor = Colors.black;

                    if (notiArray.contains(data["docID"])) {
                      statusColor = Colors.green;
                    }
                    var dateW = data["date"];
                    var dateFinal = dateW[0];
                    return ListTile(
                      title: Text(
                        data['bauName'],
                        style: TextStyle(
                          color: statusColor,
                        ),
                      ),
                      subtitle: Text(dateFinal),
                      trailing: Text(data["userID"]),
                      onLongPress: () {
                        _showLongPressDialog(data["docID"]);
                      },
                      onTap: () {
                        //_writeDocID(data["docID"]);

                        _notificationRead(data["docID"]);
                        var bauTest = data["bauID"];
                        dataClass.bauID = bauTest;
                        dataClass.bauName = data["bauName"];
                        print(data["date"]);
                        dataClass.date = data["date"];
                        dataClass.docID = data["docID"];
                        dataClass.userID = data["userID"];
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    (CheckboxWidget(reportData: dataClass))));
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Color.fromRGBO(232, 195, 30, 1),
          onPressed: () {
            _tokenLogout();
            _logout();

            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => (LoginKey())));
          },
          child: Icon(Icons.exit_to_app),
        ));
  }
}
