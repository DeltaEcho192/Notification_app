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

class _ReportState extends State<Report> {
  PushNotificationsManager notificationInit = new PushNotificationsManager();

  TextEditingController editingController = TextEditingController();
  List<String> mainDataList = [];
  List<String> newDataList = [];
  List<Map> reportApi = [
    {
      "docID": "6CEAvn1pOu4UziwMuGD3",
      "date": ["2020-11-26", "09:51:11.000Z"],
      "userID": "ad",
      "bauID": "2",
      "bauName": "Zürich-9221"
    },
    {
      "docID": "6GTqk2ONKcwIpkqUW5Nc",
      "date": ["2020-11-11", "13:47:48.000Z"],
      "userID": "jd",
      "bauID": "2",
      "bauName": "Zürich-9221"
    },
    {
      "docID": "7Mkz2RVcYCysOegOm0uo",
      "date": ["2020-11-10", "11:00:00.000Z"],
      "userID": "jd",
      "bauID": "2",
      "bauName": "Zürich-9221"
    },
    {
      "docID": "CwLREV01arFFbcimEnNj",
      "date": ["2020-11-12", "09:19:15.000Z"],
      "userID": "jd",
      "bauID": "2",
      "bauName": "Zürich-9221"
    }
  ];
  List<Map> searchedList = [
    {
      "docID": "6CEAvn1pOu4UziwMuGD3",
      "date": ["2020-11-26", "09:51:11.000Z"],
      "userID": "ad",
      "bauID": "2",
      "bauName": "Zürich-9221"
    },
    {
      "docID": "6GTqk2ONKcwIpkqUW5Nc",
      "date": ["2020-11-11", "13:47:48.000Z"],
      "userID": "jd",
      "bauID": "2",
      "bauName": "Zürich-9221"
    },
    {
      "docID": "7Mkz2RVcYCysOegOm0uo",
      "date": ["2020-11-10", "11:00:00.000Z"],
      "userID": "jd",
      "bauID": "2",
      "bauName": "Zürich-9221"
    },
    {
      "docID": "CwLREV01arFFbcimEnNj",
      "date": ["2020-11-12", "09:19:15.000Z"],
      "userID": "jd",
      "bauID": "2",
      "bauName": "Zürich-9221"
    },
  ];

  InfoSource testing = InfoSource();
  var usr = "";
  var notiCount = 0;
  List<String> notiArray = [];
  List<String> notiRmvd = [];

  Map bauSugg = {"bauName": "Loading"};
  var bauIDS = {};
  /*
  Future<void> getBaustelle() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
    var host = GlobalConfiguration().getValue("host");
    var port = GlobalConfiguration().getValue("port");
    final response =
        await http.get("https://" + host + ":" + port + '/reports/' + usr);

    if (response.statusCode == 200) {
      reportApi = await jsonDecode(response.body);
      searchedList = reportApi;
      print(reportApi[0]);
    } else {
      throw Exception("Failed to get Baustelle");
    }
  }
  */
  _sortList() {
    searchedList.sort((a, b) => (b["date"][0]).compareTo(a["date"][0]));
    print(searchedList);
  }

  _loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("Loading User");
    print(prefs.getString('user') ?? "empty");
    setState(() {
      usr = (prefs.getString('user') ?? "empty");
      _tokenInit();
      //getBaustelle();
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
    print(token);
    await GlobalConfiguration().loadFromAsset("app_settings");
    var host = GlobalConfiguration().getValue("host");
    var port = GlobalConfiguration().getValue("port");
    var urlLocal = "https://" + host + ":" + port + '/updateToken/';
    print(urlLocal);
    print(jsonEncode({"userid": usr, "token": token}));
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

  @override
  void initState() {
    _loadUser();
    _notificationCountTesting();
    _sortList();
    super.initState();
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
    setState(() {
      FlutterAppBadger.updateBadgeCount(notiArrayLocal.length);
    });
  }

  _notificationCountTesting() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    notiArray = [];
    notiRmvd = (prefs.getStringList('notiRmvd') ?? []);
    print("Counting Notifications");
    for (var x = 0; x < reportApi.length; x++) {
      var workingID = reportApi[x]["docID"];
      print("Removed Notifications DocID" + notiRmvd.toString());
      if (notiRmvd.contains(workingID) == false) {
        print("Adding ID" + workingID);
        notiArray.add(workingID);
      }
    }
    setState(() {
      prefs.setStringList("notiArray", notiArray);
      print(notiArray);
      _notificationCheck(notiArray);
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

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("Bitte Baustelle auswählen"),
          backgroundColor: Color.fromRGBO(232, 195, 30, 1),
          actions: [
            IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  //getBaustelle();
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
                    print("Notification Array" + notiArray.toString());
                    print("Notification Removed" + notiRmvd.toString());
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
                      onTap: () {
                        //_writeDocID(data["docID"]);
                        print(data["bauID"]);
                        print(reportApi);
                        _notificationRead(data["docID"]);
                        var bauTest = data["bauID"];
                        testing.bauID = bauTest;
                        testing.bauName = data["bauName"];
                        testing.date = data["date"];
                        testing.docID = data["docID"];
                        testing.userID = data["userID"];
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    (CheckboxWidget(reportData: testing))));
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
            _logout();
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => (LoginKey())));
          },
          child: Icon(Icons.exit_to_app),
        ));
  }
}
