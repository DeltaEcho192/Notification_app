class Data {
  String user;
  String baustelle;
  DateTime schicht;
  String udid;
  String bauID;
  Map<String, String> errors;
  Map<String, String> comments;
  Map<String, String> images;
  Map<String, String> audio;
  Map<String, int> priority;
  Map<String, bool> index;
  Map<String, Map> workCom;
  Map<String, int> status;
  Data({
    this.user,
    this.baustelle,
    this.schicht,
    this.udid,
    this.bauID,
    this.errors,
    this.comments,
    this.images,
    this.audio,
    this.priority,
    this.index,
    this.workCom,
    this.status,
  });
}
