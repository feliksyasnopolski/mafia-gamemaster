import "dart:async";
import 'dart:convert';
import "dart:io";
import './api_models.dart';
import '../game/player.dart';
import "../game/controller.dart";
import "../game/states.dart";
import 'package:http/http.dart' as http;

import "ui.dart";

const String BASE_URL = 'https://htmafia.nl';
// const String BASE_URL = 'http://localhost:3000';

class ApiCalls {
  ApiCalls() : super();

  Future<List<PlayersModel>> getPlayers() async {
    try {
      final response = await http.get(Uri.parse('$BASE_URL/users'));
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
            "role": player.role.jsonName
          }
      ]
    };
    // players.forEach((player) {
    //   json_players[player.number.toString()] = player.role.toString();
    // });
    try {
      final response = await http.post(Uri.parse('$BASE_URL/new_game'),
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

  Future<void> stopGame() async {
    try {
      final response = await http.post(Uri.parse('$BASE_URL/stop_game'),
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

  Future<void> updateStatus(Map<String, dynamic> status) async {
    try {
      final response = await http.post(Uri.parse('$BASE_URL/update_status'),
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
          Uri.parse('$BASE_URL/update_status'),
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

  Future<void> updateLog(Game game) async {
    try {
      Map<String, dynamic> json_data = {};
      final _state = game.state;

      if (_state.stage == GameStage.speaking)
      {
        final state = _state as GameStateSpeaking;
        json_data["stage"] = "speaking";
        json_data["day"] = state.day;
        json_data["speaker"] = state.currentPlayerNumber;
        json_data["speaker_accusation"] = state.accusations[state.currentPlayerNumber];
      }

      if (_state.stage == GameStage.nightKill)
      {
        final state = _state as GameStateNightKill;
        json_data["stage"] = "nightKill";
        json_data["day"] = state.day;
        json_data["killed"] = state.thisNightKilledPlayerNumber;
      }

      if (_state.stage == GameStage.nightCheck)
      {
        final state = _state as GameStateNightCheck;
        json_data["stage"] = "nightCheck";
        json_data["day"] = state.day;
        json_data["checked"] = state.activePlayerNumber;
      }

      if (_state.stage == GameStage.preVoting)
      {
        final state = _state as GameStateWithPlayers;
        json_data["stage"] = "preVoting";
        json_data["day"] = state.day;
        json_data["accused_players"] = state.playerNumbers;
      }

      if (_state.stage == GameStage.voting)
      {
        final state = _state as GameStateVoting;
        json_data["stage"] = "voting";
        json_data["day"] = state.day;
        json_data["votes_for"] = state.currentPlayerNumber;
        json_data["votes"] = state.currentPlayerVotes ?? 0;
      }

      final response = await http.post(
          Uri.parse('$BASE_URL/update_log'),
          body: json.encode(json_data),
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

  Future<void> updateVoteCandidates(List<int> players) async {
    try {
      Map<String, dynamic> json_players = {"vote_candidates": players};

      final response = await http.post(
          Uri.parse('$BASE_URL/update_votes'),
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
