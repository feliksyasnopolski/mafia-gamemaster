// ignore_for_file: inference_failure_on_instance_creation

import "dart:async";
import "dart:convert";
import "dart:io";

import "package:http/http.dart" as http;

import "../game/controller.dart";
import "../game/player.dart";
import "../game/states.dart";
import "./api_models.dart";
import "ui.dart";

const String baseUrl = "https://htmafia.nl";
// const String BASE_URL = 'http://localhost:3000';

class ApiCalls {
  ApiCalls() : super();

  Future<List<PlayersModel>> getPlayers() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/users"));
      final body = json.decode(response.body) as List;
      if (response.statusCode == 200) {
        return body.map((dynamic json) {
          final map = json as Map<String, dynamic>;
          return PlayersModel(
            id: map["id"] as int,
            nickname: map["nickname"] as String,
          );
        }).toList();
      }
    } on SocketException {
      await Future.delayed(const Duration(milliseconds: 1800));
      throw Exception("No Internet Connection");
    } on TimeoutException {
      throw Exception("");
    }
    throw Exception("error fetching data");
  }

  Future<void> startGame(List<Player> players) async {
    final jsonPlayers = <String, dynamic>{
      "players": [
        for (final player in players)
          {
            "number": player.number,
            "nickname": player.nickname
                , // "nickname": "Игрок ${player.number}
            "role": player.role.jsonName,
          },
      ],
    };
    // players.forEach((player) {
    //   json_players[player.number.toString()] = player.role.toString();
    // });
    try {
      final response = await http.post(Uri.parse("$baseUrl/new_game"),
          body: json.encode(jsonPlayers),
          headers: {"Content-Type": "application/json"},);
      if (response.statusCode == 200) {
        return;
      }
    } on SocketException {
      await Future.delayed(const Duration(milliseconds: 1800));
      throw Exception("No Internet Connection");
    } on TimeoutException {
      throw Exception("");
    }
    throw Exception("error fetching data");
  }

  Future<void> stopGame() async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/stop_game"),
          headers: {"Content-Type": "application/json"},);
      if (response.statusCode == 200) {
        return;
      }
    } on SocketException {
      await Future.delayed(const Duration(milliseconds: 1800));
      throw Exception("No Internet Connection");
    } on TimeoutException {
      throw Exception("");
    }
    throw Exception("error fetching data");
  }

  Future<void> updateStatus(Map<String, dynamic> status) async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/update_status"),
          body: json.encode(status),
          headers: {"Content-Type": "application/json"},);
      if (response.statusCode == 200) {
        return;
      }
    } on SocketException {
      await Future.delayed(const Duration(milliseconds: 1800));
      throw Exception("No Internet Connection");
    } on TimeoutException {
      throw Exception("");
    }
  }

  Future<void> updatePlayers(List<Player> players) async {
    try {
      final jsonPlayers = <String, dynamic>{
        "players": [
          for (final player in players)
            {
              "number": player.number,
              "nickname": player.nickname,
              "alive": player.isAlive,
            },
        ],
      };
      final response = await http.post(
          Uri.parse("$baseUrl/update_status"),
          body: json.encode(jsonPlayers),
          headers: {"Content-Type": "application/json"},);
      if (response.statusCode == 200) {
        return;
      }
    } on SocketException {
      await Future.delayed(const Duration(milliseconds: 1800));
      throw Exception("No Internet Connection");
    } on TimeoutException {
      throw Exception("");
    }
  }

  Future<void> updateLog(Game game) async {
    try {
      final jsonData = <String, dynamic>{};
      final state0 = game.state;

      if (state0.stage == GameStage.speaking)
      {
        final state = state0 as GameStateSpeaking;
        jsonData["stage"] = "speaking";
        jsonData["day"] = state.day;
        jsonData["speaker"] = state.currentPlayerNumber;
        jsonData["speaker_accusation"] = state.accusations[state.currentPlayerNumber];
      }

      if (state0.stage == GameStage.nightKill)
      {
        final state = state0 as GameStateNightKill;
        jsonData["stage"] = "nightKill";
        jsonData["day"] = state.day;
        jsonData["killed"] = state.thisNightKilledPlayerNumber;
      }

      if (state0.stage == GameStage.nightCheck)
      {
        final state = state0 as GameStateNightCheck;
        jsonData["stage"] = "nightCheck";
        jsonData["day"] = state.day;
        jsonData["checked"] = state.activePlayerNumber;
      }

      if (state0.stage == GameStage.preVoting)
      {
        final state = state0 as GameStateWithPlayers;
        jsonData["stage"] = "preVoting";
        jsonData["day"] = state.day;
        jsonData["accused_players"] = state.playerNumbers;
      }

      if (state0.stage == GameStage.voting)
      {
        final state = state0 as GameStateVoting;
        jsonData["stage"] = "voting";
        jsonData["day"] = state.day;
        jsonData["votes_for"] = state.currentPlayerNumber;
        jsonData["votes"] = state.currentPlayerVotes ?? 0;
      }

      final response = await http.post(
          Uri.parse("$baseUrl/update_log"),
          body: json.encode(jsonData),
          headers: {"Content-Type": "application/json"},);
      if (response.statusCode == 200) {
        return;
      }
    } on SocketException {
      await Future.delayed(const Duration(milliseconds: 1800));
      throw Exception("No Internet Connection");
    } on TimeoutException {
      throw Exception("");
    }
  }

  Future<void> updateVoteCandidates(List<int> players) async {
    try {
      final jsonPlayers = <String, dynamic>{"vote_candidates": players};

      final response = await http.post(
          Uri.parse("$baseUrl/update_votes"),
          body: json.encode(jsonPlayers),
          headers: {"Content-Type": "application/json"},);
      if (response.statusCode == 200) {
        return;
      }
    } on SocketException {
      await Future.delayed(const Duration(milliseconds: 1800));
      throw Exception("No Internet Connection");
    } on TimeoutException {
      throw Exception("");
    }
  }
}
