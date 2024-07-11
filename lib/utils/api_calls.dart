import "dart:async";
import 'dart:convert';
import "dart:io";
import './api_models.dart';
import '../game/player.dart';
import 'package:http/http.dart' as http;

import "ui.dart";

class ApiCalls {
  ApiCalls() : super();

  Future<List<PlayersModel>> getPlayers() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/users'));
      final body = json.decode(response.body) as List;
      if (response.statusCode == 200) {
        return body.map((dynamic json) {
          final map = json as Map<String, dynamic>;
          return PlayersModel(
            id: map['id'] as int,
            nickname: map['nickname'] as String,
          );
        }).toList();
      }
    } on SocketException {
      await Future.delayed(const Duration(milliseconds: 1800));
      throw Exception('No Internet Connection');
    } on TimeoutException {
      throw Exception('');
    }
    throw Exception('error fetching data');
  }

  Future<void> startGame(List<Player> players) async {
    Map<String, dynamic> json_players = {
      "players": [
        for (var player in players)
          {
            "number": player.number,
            "nickname": player.nickname
                .toString(), // "nickname": "Игрок ${player.number}
            "role": player.role.prettyName
          }
      ]
    };
    // players.forEach((player) {
    //   json_players[player.number.toString()] = player.role.toString();
    // });
    try {
      final response = await http.post(
          Uri.parse('http://localhost:3000/new_game'),
          body: json.encode(json_players),
          headers: {"Content-Type": "application/json"});
      if (response.statusCode == 200) {
        return;
      }
    } on SocketException {
      await Future.delayed(const Duration(milliseconds: 1800));
      throw Exception('No Internet Connection');
    } on TimeoutException {
      throw Exception('');
    }
    throw Exception('error fetching data');
  }

  Future<void> updateStatus(Map<String,dynamic> status) async {
    try {
      final response = await http.post(
          Uri.parse('http://localhost:3000/update_status'),
          body: json.encode(status),
          headers: {"Content-Type": "application/json"});
      if (response.statusCode == 200) {
        return;
      }
    } on SocketException {
      await Future.delayed(const Duration(milliseconds: 1800));
      throw Exception('No Internet Connection');
    } on TimeoutException {
      throw Exception('');
    }
  }

  Future<void> updatePlayers(List<Player> players) async {
    try {
      Map<String, dynamic> json_players = {
        "players": [
          for (var player in players)
            {
              "number": player.number,
              "nickname": player.nickname,
              "alive": player.isAlive
            }
        ]
      };
      final response = await http.post(
          Uri.parse('http://localhost:3000/update_status'),
          body: json.encode(json_players),
          headers: {"Content-Type": "application/json"});
      if (response.statusCode == 200) {
        return;
      }
    } on SocketException {
      await Future.delayed(const Duration(milliseconds: 1800));
      throw Exception('No Internet Connection');
    } on TimeoutException {
      throw Exception('');
    }
  }
}
