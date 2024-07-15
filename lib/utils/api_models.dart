
class PlayersModel {
  int? id;
  String? nickname;

  PlayersModel({this.id, this.nickname});

  PlayersModel.fromJson(Map<String, dynamic> json) {
    id = json["id"] as int;
    nickname = json["nickname"] as String;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data["id"] = id;
    data["nickname"] = nickname;
    return data;
  }
}