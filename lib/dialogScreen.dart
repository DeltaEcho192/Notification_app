import 'dart:typed_data';
import 'dart:io' as io;
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'checklist.dart';
import 'model.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'data.dart';
import 'package:toast/toast.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:global_configuration/global_configuration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dialogScreen.dart';
import 'dialog.dart';
import 'size_helpers.dart';

class DialogScreen extends StatefulWidget {
  final DialogData dialogdata;
  DialogScreen({Key key, this.dialogdata}) : super(key: key);

  _DialogState createState() => new _DialogState();
}

class _DialogState extends State<DialogScreen> {
  bool exec = false;
  File _imageFile;
  File _imageFile2;
  String locWorking;
  DialogData data = DialogData();
  Model model = Model();
  Map<String, String> names = {};
  Map<String, String> errors = {};
  Map<String, String> comments = {};
  List<String> toDelete = [];
  String dateFinal = "Schicht:";
  String _udid = 'Unknown';
  int photoAmt = 0;
  int iteration = 0;
  Image cameraIcon = Image.asset("assets/cameraIcon.png");
  Image cameraIcon2 = Image.asset("assets/cameraIcon.png");
  StorageUploadTask _uploadTask;
  StorageUploadTask _uploadTask2;
  StorageUploadTask _uploadTaskAudio;
  StorageUploadTask _deleteTask;
  var txt = TextEditingController();
  var statusRes = TextEditingController();
  var statusUsr = TextEditingController();
  String baustelle;
  final bauController = TextEditingController(text: "Baustelle");
  var subtController = TextEditingController();
  String currentText = "";
  List<String> suggestions = ["Default"];
  FocusNode _focusNode;
  Icon checkboxIcon = new Icon(Icons.check_box);
  bool secondCheck = false;
  bool reportExist = false;
  String reportID;
  Uint8List imageBytes;
  Uint8List imageBytes2;
  String errorMsg;
  FlutterAudioRecorder _recorder;
  Recording _current;
  RecordingStatus _currentStatus = RecordingStatus.Unset;
  String audioFilePath = "";
  Icon playBtn = Icon(
    Icons.play_circle_filled,
    color: Colors.black,
  );
  String dropdownValue = "Normal";

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
              cameraIcon = Image.memory(
                imageBytes,
                fit: BoxFit.cover,
              );
            }))
        .catchError((e) => setState(() {
              errorMsg = e.error;
            }));
  }

  Future<void> imageLoad2(String fileName) async {
    storage
        .ref()
        .child(fileName)
        .getData(10000000)
        .then((data) => setState(() {
              imageBytes2 = data;
              cameraIcon2 = Image.memory(
                imageBytes2,
                fit: BoxFit.cover,
              );
            }))
        .catchError((e) => setState(() {
              errorMsg = e.error;
            }));
  }

  Future<void> audioLoad(String fileName) async {
    storage.ref().child(fileName).getDownloadURL().then((value) => setState(() {
          AudioPlayer audioPlayer = AudioPlayer();
          audioPlayer.play(value);
        }));
  }

  //
  //

  //
  //

  void _imageCheck() {
    if (widget.dialogdata.image1 != null) {
      imageLoad(widget.dialogdata.image1);
    }
    if (widget.dialogdata.image2 != null) {
      imageLoad2(widget.dialogdata.image2);
    }
  }

  void _iconCheck() {
    print(widget.dialogdata.check);
    if (widget.dialogdata.check == false) {
      setState(() {
        checkboxIcon = Icon(Icons.check_box_outline_blank);
      });
    } else {
      setState() {
        checkboxIcon = Icon(Icons.check_box);
      }
    }
  }

  void audioCheck() {
    if (widget.dialogdata.audio == null) {
      setState(() {
        playBtn = Icon(
          Icons.play_circle_fill,
          color: Colors.grey,
        );
      });
    }
  }

  void _priorityCheck() {
    if (widget.dialogdata.priority != null) {
      switch (widget.dialogdata.priority) {
        case 1:
          {
            setState(() {
              print("high");
              dropdownValue = "Hoch";
            });
          }
          break;
        case 2:
          {
            setState(() {
              print("Normal Case");
              dropdownValue = "Normal";
            });
          }
          break;
        case 3:
          {
            setState(() {
              print("Low");
              dropdownValue = "Tief";
            });
          }
      }
    } else {
      print("Normal");
      dropdownValue = "Normal";
    }
  }

  //
  //

  _init() async {
    try {
      if (await FlutterAudioRecorder.hasPermissions) {
        String customPath = '/audio';
        io.Directory appDocDirectory;
//        io.Directory appDocDirectory = await getApplicationDocumentsDirectory();
        if (io.Platform.isIOS) {
          appDocDirectory = await getApplicationDocumentsDirectory();
        } else {
          appDocDirectory = await getExternalStorageDirectory();
        }

        var time = DateTime.now().millisecondsSinceEpoch.toString();
        audioFilePath = customPath + "/" + time;
        // can add extension like ".mp4" ".wav" ".m4a" ".aac"
        customPath = appDocDirectory.path + customPath + time;

        // .wav <---> AudioFormat.WAV
        // .mp4 .m4a .aac <---> AudioFormat.AAC
        // AudioFormat is optional, if given value, will overwrite path extension when there is conflicts.
        _recorder =
            FlutterAudioRecorder(customPath, audioFormat: AudioFormat.WAV);

        await _recorder.initialized;
        // after initialization
        var current = await _recorder.current(channel: 0);
        print(current);
        // should be "Initialized", if all working fine
        setState(() {
          _current = current;
          _currentStatus = current.status;
          print(_currentStatus);
        });
      } else {
        Scaffold.of(context).showSnackBar(
            new SnackBar(content: new Text("You must accept permissions")));
      }
    } catch (e) {
      print(e);
    }
  }

  _start() async {
    try {
      await _recorder.start();
      var recording = await _recorder.current(channel: 0);
      setState(() {
        _current = recording;
      });

      const tick = const Duration(milliseconds: 50);
      new Timer.periodic(tick, (Timer t) async {
        if (_currentStatus == RecordingStatus.Stopped) {
          t.cancel();
        }

        var current = await _recorder.current(channel: 0);
        // print(current.status);
        setState(() {
          _current = current;
          _currentStatus = _current.status;
        });
      });
    } catch (e) {
      print(e);
    }
  }

  _resume() async {
    await _recorder.resume();
    setState(() {});
  }

  _pause() async {
    await _recorder.pause();
    setState(() {});
  }

  _stop() async {
    var result = await _recorder.stop();
    print("Stop recording: ${result.path}");
    print("Stop recording: ${result.duration}");

    final FirebaseStorage _storage =
        FirebaseStorage(storageBucket: 'gs://train-app-287911.appspot.com');
    setState(() {
      File file = File(result.path);
      widget.dialogdata.audio = audioFilePath;
      _uploadTaskAudio = _storage.ref().child(audioFilePath).putFile(file);
      _current = result;
      _currentStatus = _current.status;
    });
    await _uploadTaskAudio.onComplete;
    print("Audio is uploaded to firebase");
    Toast.show("Audio ist auf Server gespeichert", context,
        duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
  }

  Widget _buildText(RecordingStatus status) {
    Icon icon;
    switch (_currentStatus) {
      case RecordingStatus.Initialized:
        {
          icon = Icon(
            Icons.mic,
            color: Colors.green,
          );
          break;
        }
      case RecordingStatus.Recording:
        {
          icon = Icon(
            Icons.mic,
            color: Colors.red,
          );
          break;
        }
      case RecordingStatus.Stopped:
        {
          icon = Icon(
            Icons.mic,
            color: Colors.green,
          );
          _init();
          break;
        }
      default:
        icon = Icon(
          Icons.mic,
          color: Colors.green,
        );
        break;
    }
    return icon;
  }

  //
  //
  bool statusFlagB = false;
  var genString;
  _loadStatusMessage() {
    if (widget.dialogdata.statusText != "") {
      var genString = "Erledigt Von " +
          widget.dialogdata.statusUser +
          " am (" +
          widget.dialogdata.statusTime.toString().substring(
              0, (widget.dialogdata.statusTime.toString().length - 7)) +
          ")\n";
      statusRes.text = genString + widget.dialogdata.statusText;
      statusUsr.text = widget.dialogdata.statusText;
    } else {
      statusRes.text = "";
      statusUsr.text = "";
    }
    print("Status type: ");
    print(widget.dialogdata.status);
    if (widget.dialogdata.status == 1) {
      statusFlag = widget.dialogdata.status;
      statusFlagB = true;
    }
  }

  Future<void> _statusMessageDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Status Message?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                new TextField(
                  controller: statusUsr,
                  minLines: 3,
                  maxLines: 3,
                  readOnly: false,
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                )
              ],
            ),
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () {
                _statusUpload(statusUsr.text);
                _changeAlertStatus(
                    widget.dialogdata.docID, widget.dialogdata.name);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  _reWriteComment(var user, DateTime time, var text) {
    var genString = "Erledigt Von " +
        user +
        " am (" +
        time.toString().substring(0, (time.toString().length - 7)) +
        ")\n";
    statusRes.text = genString + text;
  }

  int statusFlag = 0;
  var usr;
  Future<void> _statusUpload(var statusText) async {
    var host = GlobalConfiguration().getValue("host");
    var port = GlobalConfiguration().getValue("webPort");
    var urlLocal = "https://" + host + ":" + port + '/statusUpload/';
    print(urlLocal);
    print(statusText);
    Map<String, dynamic> statusData = {};
    statusData["text"] = statusText;
    statusData["key"] = widget.dialogdata.name;
    statusData["user"] = usr;
    statusData["docID"] = widget.dialogdata.docID;
    statusData["status"] = statusFlag;
    statusData["time"] = DateTime.now().millisecondsSinceEpoch;
    print(statusData);
    _reWriteComment(usr, DateTime.now(), statusText);

    final check = await http.post(urlLocal,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(statusData));

    if (check.statusCode == 201) {
      print("Status update is successful");
    } else {
      print("There has been an issue with updating status message");
    }
  }

  _loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("Loading User");
    print(prefs.getString('user') ?? "empty");
    setState(() {
      usr = (prefs.getString('user') ?? "empty");
    });
  }

  Future<void> _changeAlertStatus(var docID, var key) async {
    var host = GlobalConfiguration().getValue("host");
    var port = GlobalConfiguration().getValue("mobilePort");
    var urlLocal = "https://" + host + ":" + port + '/statusChangeAlert/';

    var alertData = {};
    alertData["docID"] = docID;
    alertData["key"] = key;

    print(alertData.toString() + " :alertData");

    final check = await http.post(urlLocal,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(alertData));

    if (check.statusCode == 201) {
      print("Status update is successful");
    } else {
      print("There has been an issue with updating status message");
    }
  }

  @override
  void initState() {
    super.initState();
    txt.text = widget.dialogdata.text;
    _loadStatusMessage();
    _loadUser();
    print(widget.dialogdata.image2);
    _iconCheck();
    audioCheck();
    _imageCheck();
    _init();
    _priorityCheck();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Color.fromRGBO(232, 195, 30, 1),
        title: Text(widget.dialogdata.name),
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            }),
      ),
      body: new Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              new Flexible(
                child: new TextField(
                  controller: txt,
                  minLines: 4,
                  maxLines: 4,
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: "Problem Beschreibung",
                    contentPadding: const EdgeInsets.only(left: 10, right: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ],
          ),
          new Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              new SizedBox(
                height: 300,
                width: displayWidth(context) * 0.5,
                child: IconButton(
                  padding: new EdgeInsets.all(5.0),
                  icon: cameraIcon,
                ),
              ),
              new SizedBox(
                width: displayWidth(context) * 0.5,
                height: 300,
                child: IconButton(
                  padding: new EdgeInsets.all(5.0),
                  icon: cameraIcon2,
                ),
              )
            ],
          ),
          new Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new Text("Keine Probleme"),
              new IconButton(
                icon: checkboxIcon,
              ),
              new Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 5, 0),
                child: Text("Priorität:"),
              ),
              new Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 5, 0),
                child: Text(dropdownValue),
              ),
            ],
          ),
          new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Voice Message"),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: new IconButton(
                      icon: playBtn,
                      onPressed: () {
                        if (widget.dialogdata.audio != null) {
                          audioLoad(widget.dialogdata.audio);
                        }
                      }),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Fertig?"),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Checkbox(
                    value: statusFlagB,
                    onChanged: (bool value) {
                      setState(() {
                        if (value == true) {
                          statusFlag = 1;
                        } else {
                          statusFlag = 0;
                        }
                        statusFlagB = value;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: IconButton(
                    icon: Icon(Icons.history_edu),
                    onPressed: () {
                      _statusMessageDialog();
                    },
                  ),
                )
              ]),
          new Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new Flexible(
                  child: new TextField(
                controller: statusRes,
                minLines: 3,
                maxLines: 3,
                readOnly: false,
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }
}
