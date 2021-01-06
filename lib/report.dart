import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vanoli_notification/login/loginKey.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new Location(title: 'Report Select'),
    );
  }
}

class Location extends StatefulWidget {
  Location({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _LocationState createState() => new _LocationState();
}

class _LocationState extends State<Location> {
  TextEditingController editingController = TextEditingController();
  List<String> mainDataList = [];
  List<String> newDataList = [];
  List<Map> reportApi = [
    {
      "bauName": "Loading",
      "date": ["loading"],
      "userID": "Loading"
    }
  ];
  var usr = "";

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
      print(reportApi[0]);
    } else {
      throw Exception("Failed to get Baustelle");
    }
  }

  _loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("Loading User");
    print(prefs.getString('user') ?? "empty");
    setState(() {
      usr = (prefs.getString('user') ?? "empty");
      getBaustelle();
    });
  }

  _writeDocID(String docID) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setString('docIDPref', docID);
    });
  }

  @override
  void initState() {
    _loadUser();

    super.initState();
  }

  //Change to reflect the map and search based on 'data.bauName'
  onItemChanged(String value) {
    setState(() {
      newDataList = mainDataList
          .where((string) => string.toLowerCase().contains(value.toLowerCase()))
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
                  children: reportApi.map((data) {
                    var dateW = data["date"];
                    var dateFinal = dateW[0];
                    return ListTile(
                      title: Text(data['bauName']),
                      subtitle: Text(dateFinal),
                      trailing: Text(data["userID"]),
                      onTap: () {
                        print(data);
                        _writeDocID(data["docID"]);
                        /*Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => (CheckboxWidget())));
                      */
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
