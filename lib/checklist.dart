import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:developer';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:validators/validators.dart' as validator;
import 'package:firebase_storage/firebase_storage.dart';
import 'model.dart';
import 'package:flutter/widgets.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'data.dart';
import 'package:toast/toast.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'report.dart';
import 'dialogScreen.dart';
import 'dialog.dart';
import 'infoSource.dart';

class CheckboxWidget extends StatefulWidget {
  final InfoSource reportData;
  CheckboxWidget({Key key, @required this.reportData}) : super(key: key);
  @override
  CheckboxWidgetState createState() => new CheckboxWidgetState();
}

class CheckboxWidgetState extends State<CheckboxWidget> {
  bool exec = false;
  File _imageFile;
  File _imageFile2;
  String locWorking;
  Model model = Model();
  Data data = Data();
  Map<String, String> names = {};
  Map<String, String> errors = {};
  Map<String, String> comments = {};
  Map<String, String> audio = {};
  Map<String, int> priority = {};
  Map<String, int> status = {};
  Map<String, Map> statusText = {};
  Map<String, int> emptyStatus = {};
  Map<String, Map> workComEmpty = {};
  List<String> toDelete = [];
  String dateFinal = "Schicht:";
  String _udid = 'Unknown';
  int photoAmt = 0;
  int iteration = 0;
  Image cameraIcon = Image.asset("assets/cameraIcon.png");
  Image cameraIcon2 = Image.asset("assets/cameraIcon.png");
  Image logo = Image.asset(
    "assets/Vanoli-logo.png",
    width: 75,
  );
  StorageUploadTask _uploadTask;
  StorageUploadTask _uploadTask2;
  StorageUploadTask _deleteTask;
  var txt = TextEditingController();
  String baustelle;
  final bauController = TextEditingController(text: "Baustelle");
  var subtController = TextEditingController();
  String currentText = "";
  List<String> suggestions = ["Default"];
  GlobalKey<AutoCompleteTextFieldState<String>> key = new GlobalKey();
  SimpleAutoCompleteTextField textField;
  FocusNode _focusNode;
  Icon checkboxIcon = new Icon(Icons.check_box);
  bool secondCheck = false;
  bool reportExist = false;
  String reportID;
  Uint8List imageBytes;
  String errorMsg;
  String finalDocID;
  Icon statusLeading = Icon(Icons.check);
  Icon statusEmpty = Icon(Icons.airline_seat_flat);

  DialogData dialogData = DialogData();

  //

  // After the Selection Screen returns a result, hide any previous snackbars
  // and show the new result.
  //
  //

  Future<void> deleteCanceledFiles(List deletion) {
    final FirebaseStorage _storage =
        FirebaseStorage(storageBucket: 'gs://train-app-287911.appspot.com');
    for (int i = 0; i < deletion.length; i++) {
      _storage.ref().child(deletion[i]).delete();
    }
  }

  //
  //

  //Gets device UDID for database upload
  Future<void> getUDID() async {
    String udid;
    try {
      udid = await FlutterUdid.udid;
    } on PlatformException {
      udid = 'Failed to get UDID.';
    }

    if (!mounted) return;

    setState(() {
      print(udid);
      //print("First item of array" + names[1]);
      _udid = udid;
      data.udid = udid;
    });
  }

  //
  //

  Map<String, bool> numbers = {
    'Lade Daten...': true,
  };
  Map<String, String> subtitles = {'Lade Daten...': ' '};

  //
  //

  subtitleCut(key) {
    var subtitleWorking;
    if (subtitles[key].length != 0) {
      setState(() {
        subtitleWorking =
            subtitles[key].replaceRange(10, subtitles[key].length, "...");
      });
    } else {
      setState(() {
        subtitleWorking = " ";
      });
    }
    return subtitleWorking;
  }

  //
  //

  var pullReport;

  Future<void> getReport(String docID) async {
    final firestoreInstance = Firestore.instance;
    firestoreInstance
        .collection("issues")
        .where("__name__", isEqualTo: docID)
        .limit(1)
        .getDocuments()
        .then((value) => {
              value.documents.forEach((element) {
                print(element.documentID);
                reportID = element.documentID;
                pullReport = element.data;

                var errorsLoc = pullReport["errors"];
                var commentsLoc = pullReport["comments"];
                var checklist = pullReport["checklist"];
                var imagesLoc = pullReport["images"];
                var audioLoc = pullReport["audio"];
                var priorityLoc = pullReport["priority"];
                var statusLoc = pullReport["status"];
                var statusTextLoc = pullReport["workCom"];
                print("Checklist $checklist");
                print("image test $imagesLoc");
                setState(() {
                  subtitles.clear();
                  numbers = Map<String, bool>.from(checklist);
                  comments = Map<String, String>.from(commentsLoc);
                  errors = Map<String, String>.from(errorsLoc);
                  audio = Map<String, String>.from(audioLoc);
                  priority = Map<String, int>.from(priorityLoc);
                  if (statusLoc != null) {
                    status = Map<String, int>.from(statusLoc);
                    statusText = Map<String, Map>.from(statusTextLoc);
                  }

                  subtitles = {...errors, ...comments};
                  print(subtitles);
                  numbers.forEach((key, value) {
                    if (subtitles.containsKey(key)) {
                      print("In array");
                      print(subtitles[key]);
                      var subWork = subtitles[key];
                      print(subWork);
                      if (subWork == null) {
                        subtitles[key] = " ";
                      } else {
                        if (subWork.length > 30) {
                          subtitles[key] =
                              subWork.replaceRange(30, subWork.length, "...");
                        } else {
                          subtitles[key] = subWork;
                        }
                      }
                    } else {
                      subtitles[key] = " ";
                    }
                  });
                  print("Subtitiles $subtitles");
                  names = Map<String, String>.from(imagesLoc);
                  (context as Element).reassemble();
                });
              })
            });
  }

  //
  //
  final FirebaseStorage storage = FirebaseStorage(
      app: Firestore.instance.app,
      storageBucket: 'gs://train-app-287911.appspot.com');
  Future<void> imageLoad(String fileName) async {
    storage
        .ref()
        .child(fileName)
        .getData(10000000)
        .then((data) => setState(() {
              imageBytes = data;
            }))
        .catchError((e) => setState(() {
              errorMsg = e.error;
            }));
  }

  //
  //

  _checkNumber() {
    print(numbers);
    print(errors);
    print(comments);
  }

  _loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("Loading User");
    print(prefs.getString('user') ?? "empty");
    setState(() {
      data.user = (prefs.getString('user') ?? "empty");
    });
  }

  _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setString('user', 'empty');
      prefs.setBool('loged', false);
    });
  }

  //
  //

  _intialDate() async {
    setState(() {
      dateFinal = widget.reportData.date[0];
    });
  }

  //
  //

  @override
  void initState() {
    super.initState();
    bauController.text = widget.reportData.bauName;
    getReport(widget.reportData.docID);
    _intialDate();
    _loadUser();
    getUDID();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(232, 195, 30, 1),
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => (Report())),
              );
            }),
        title: logo,
        actions: [
          FlatButton(
            padding: EdgeInsets.only(right: 75),
            onPressed: () {},
            child: Text(
              dateFinal,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                new Flexible(
                    //Fix this and only have the baustelle name as the title and cant be edited.
                    child: textField = SimpleAutoCompleteTextField(
                        key: key,
                        controller: bauController,
                        focusNode: _focusNode,
                        suggestions: suggestions,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0)),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                        textChanged: (text) => currentText = text,
                        clearOnSubmit: false,
                        textSubmitted: (text) => setState(() {
                              if (text != "") {
                                //fetchChecklist(baustelle, bauID);
                              }
                            }))),
              ]),
          Expanded(
            //Creates the checklist dynamically based on API
            child: ListView(
              children: numbers.keys.map((String key) {
                var statusColor = Colors.black;
                //var statusIcon;
                if (status[key] == 1) {
                  statusColor = Colors.green;
                  //statusIcon = statusLeading;
                } else {
                  //statusIcon = Text("");
                }
                return new CheckboxListTile(
                  title: new Text(
                    key,
                    style: TextStyle(
                      color: statusColor,
                    ),
                  ),
                  subtitle: new Text(
                    subtitles[key],
                    style: TextStyle(
                      color: statusColor,
                    ),
                    maxLines: 1,
                  ),
                  //secondary: statusIcon,
                  value: numbers[key],
                  activeColor: Colors.green,
                  checkColor: Colors.white,
                  onChanged: (bool value) {
                    setState(() {
                      value = secondCheck;
                      print(errors[key]);
                      print(errors);
                      if (numbers[key] == true) {
                        dialogData.text = comments[key];
                      } else {
                        dialogData.text = errors[key];
                      }
                      exec = true;
                      print(numbers[key]);
                      dialogData.name = key;
                      dialogData.check = numbers[key];
                      dialogData.image1 = names[key];
                      dialogData.image2 = names[(key + "Sec")];
                      dialogData.audio = audio[key];
                      dialogData.priority = priority[key];
                      if (statusText.isNotEmpty) {
                        if (statusText[key] != null) {
                          var check = statusText[key]['text'];
                          var statusInv = statusText[key]['text'];
                          var statusUser = statusText[key]['user'];
                          var statusTime = statusText[key]['time'];
                          if (check.length == 0) {
                            statusInv = " ";
                          }
                          dialogData.statusText = statusInv;
                          dialogData.statusUser = statusUser;
                          dialogData.statusTime =
                              DateTime.fromMillisecondsSinceEpoch(statusTime);
                        } else {
                          dialogData.statusText = "";
                          dialogData.statusUser = "";
                          dialogData.statusTime =
                              DateTime.fromMillisecondsSinceEpoch(1608120399);
                        }
                      } else {
                        var statusInv = "";
                        dialogData.statusText = statusInv;
                      }

                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  (DialogScreen(dialogdata: dialogData))));
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
