class DialogData {
  String text;
  String image1;
  String image2;
  String audio;
  int priority;
  bool check;
  String name;
  String statusText;
  String statusUser;
  DateTime statusTime;
  String docID;
  int status;


  DialogData(
      {this.text,
      this.image1,
      this.image2,
      this.audio,
      this.priority,
      this.check,
      this.name,
      this.statusText,
      this.statusTime,
      this.statusUser,
      this.status,
      this.docID});
}
