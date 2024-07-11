import 'dart:convert';

class PlayersModel {
  int? id;
  String? nickname;

  PlayersModel({this.id, this.nickname});

  PlayersModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int;
    nickname = json["nickname"] as String;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['nickname'] = this.nickname;
    return data;
  }
}