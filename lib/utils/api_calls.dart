// ignore_for_file: inference_failure_on_instance_creation

import "dart:async";
import "dart:convert";
import "dart:io";

import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";

import "../game/controller.dart";
import "../game/player.dart";
import "../game/states.dart";
import "./api_models.dart";
import "ui.dart";

const String baseUrl = "https://mafiaarena.org/api/v1/";
// const String baseUrl = "http://localhost:3000/api/v1/";

class ApiCalls {
  final prefs = SharedPreferences.getInstance();
  ApiCalls() : super();

  Future<void> login(String email, String password) async {
    try {
      final body = <String, dynamic>{
        "email": email,
        "password": password,
      };

      final response = await http.post(
        Uri.parse("${baseUrl}auth/sign_in"),
        body: json.encode(body),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        final token =
            response.headers["authorization"]?.replaceAll("Bearer ", "");
        await prefs.then((value) => value.setString("appToken", token ?? ""));

        return;
      }
      throw Exception("Неверный логин или пароль");
      // await prefs.then((value) => value.setString("appToken", token));
    } catch (error) {
      throw Exception("Неверный логин или пароль");
    }
  }

  Future<List<PlayersModel>> getPlayers() async {
    final body = await httpGet("${baseUrl}users");
    final jsonBody = json.decode(body) as List;
    return jsonBody.map((dynamic json) {
      final map = json as Map<String, dynamic>;
      return PlayersModel(
        id: map["id"] as int,
        nickname: map["nickname"] as String,
      );
    }).toList();
  }

  Future<List<TablesModel>> getTables() async {
    final body = await httpGet("${baseUrl}tables");
    final jsonBody = json.decode(body) as List;
    return jsonBody.map((dynamic json) {
      final map = json as Map<String, dynamic>;
      return TablesModel(
        id: map["id"] as int,
        name: "Cтол №${map["number"] as int}",
        token: map["token"] as String,
      );
    }).toList();
  }

  Future<void> startGame(List<Player> players, String tableToken) async {
    final jsonPlayers = <String, dynamic>{
      "players": [
        for (final player in players)
          {
            "number": player.number,
            "nickname": player.nickname, // "nickname": "Игрок ${player.number}
            "role": player.role.jsonName,
          },
      ],
      "table_token": tableToken,
    };

    await httpPost("${baseUrl}new_game", jsonPlayers);
  }

  Future<void> stopGame(String tableToken) async {
    await httpPost("${baseUrl}stop_game", {
      "table_token": tableToken,
    });
  }

  Future<void> updateStatus(Map<String, dynamic> status) async {
    await httpPost("${baseUrl}update_status", status);
  }

  Future<void> updatePlayers(List<Player> players, String tableToken) async {
    final jsonPlayers = <String, dynamic>{
      "players": [
        for (final player in players)
          {
            "number": player.number,
            "nickname": player.nickname,
            "alive": player.isAlive,
          },
      ],
      "table_token": tableToken,
    };

    await httpPost("${baseUrl}update_status", jsonPlayers);
  }

  Future<void> sendNightCheckResult(
    String type,
    int playerNumber,
    String tableToken,
  ) async {
    final jsonData = <String, dynamic>{
      "stage": type,
      "player": playerNumber,
      "table_token": tableToken,
    };
    await httpPost("${baseUrl}update_log", jsonData);
  }

  Future<void> updateLog(Game game, String tableToken) async {
    final jsonData = <String, dynamic>{};
    final state0 = game.state;

    if (state0.stage == GameStage.speaking) {
      final state = state0 as GameStateSpeaking;
      jsonData["stage"] = "speaking";
      jsonData["day"] = state.day;
      jsonData["speaker"] = state.currentPlayerNumber;
      jsonData["speaker_accusation"] =
          state.accusations[state.currentPlayerNumber];
    }

    if (state0.stage == GameStage.nightFirstKilled) {
      final state = state0 as GameStateFirstKilled;
      jsonData["stage"] = "nightFirstKilled";
      jsonData["bestMoves"] = state.bestMoves;
      jsonData["killed"] = state.thisNightKilledPlayerNumber;
    }

    if (state0.stage == GameStage.nightKill) {
      final state = state0 as GameStateNightKill;
      jsonData["stage"] = "nightKill";
      jsonData["day"] = state.day;
      jsonData["killed"] = state.thisNightKilledPlayerNumber;
    }

    // if (state0.stage == GameStage.nightCheck)
    // {
    //   final state = state0 as GameStateNightCheck;
    //   if (state.activePlayerRole == PlayerRole.sheriff)
    //   {
    //     jsonData["stage"] = "sheriffCheck";
    //   } else {
    //     jsonData["stage"] = "donCheck";
    //   }
    //   jsonData["day"] = state.day;
    //   jsonData["checked"] = state.activePlayerNumber;
    // }

    if (state0.stage == GameStage.preVoting) {
      final state = state0 as GameStateWithPlayers;
      jsonData["stage"] = "preVoting";
      jsonData["day"] = state.day;
      jsonData["accused_players"] = state.playerNumbers;
    }

    if (state0.stage == GameStage.excuse) {
      final state = state0 as GameStateWithCurrentPlayer;
      jsonData["stage"] = "excuse";
      jsonData["day"] = state.day;
      jsonData["accused"] = state.currentPlayerNumber;
    }

    if (state0.stage == GameStage.preFinalVoting) {
      final state = state0 as GameStateWithPlayers;
      jsonData["stage"] = "preFinalVoting";
      jsonData["day"] = state.day;
      jsonData["accused_players"] = state.playerNumbers;
    }

    if (state0.stage == GameStage.nightLastWords) {
      final state = state0 as GameStateWithPlayer;
      jsonData["stage"] = "lastWords";
      jsonData["day"] = state.day;
      jsonData["player"] = state.currentPlayerNumber;
    }

    if (state0.stage == GameStage.dayLastWords) {
      final state = state0 as GameStateWithCurrentPlayer;
      jsonData["stage"] = "lastWords";
      jsonData["day"] = state.day;
      jsonData["player"] = state.currentPlayerNumber;
    }

    if (state0.stage == GameStage.dropTableVoting) {
      final state = state0 as GameStateDropTableVoting;
      jsonData["stage"] = "dropTableVoting";
      jsonData["day"] = state.day;
      jsonData["votes"] = state.votesForDropTable;
    }

    if (state0.stage == GameStage.preFinalVoting) {
      final state = state0 as GameStateWithPlayers;
      jsonData["stage"] = "preFinalVoting";
      jsonData["day"] = state.day;
      jsonData["accused_players"] = state.playerNumbers;
    }

    // {
    //   final state = state0 as GameStateWithPlayers;
    //   jsonData["stage"] = "preVoting";
    //   jsonData["day"] = state.day;
    //   jsonData["accused_players"] = state.playerNumbers;
    // }

    if (state0.stage == GameStage.voting) {
      final state = state0 as GameStateVoting;
      jsonData["stage"] = "voting";
      jsonData["day"] = state.day;
      jsonData["votes_for"] = state.currentPlayerNumber;
      jsonData["votes"] = state.currentPlayerVotes ?? 0;
    }

    jsonData["table_token"] = tableToken;

    await httpPost("${baseUrl}update_log", jsonData);
  }

  Future<void> updateVoteCandidates(List<int> players) async {
    final jsonPlayers = <String, dynamic>{"vote_candidates": players};
    await httpPost("${baseUrl}update_votes", jsonPlayers);
  }

  Future<String> httpGet(String url) async {
    try {
      final token =
          await prefs.then((value) => value.getString("appToken") ?? "");
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        return response.body;
      }
    } on SocketException {
      await Future.delayed(const Duration(milliseconds: 1800));
      throw Exception("No Internet Connection");
    } on TimeoutException {
      throw Exception("");
    }
    throw Exception("error fetching data");
  }

  Future<String> httpPost(String url, Map<String, dynamic> body) async {
    try {
      final token =
          await prefs.then((value) => value.getString("appToken") ?? "");
      // body["token"] = token;
      final response = await http.post(
        Uri.parse(url),
        body: json.encode(body),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        return response.body;
      }
    } on SocketException {
      await Future.delayed(const Duration(milliseconds: 1800));
      throw Exception("No Internet Connection");
    } on TimeoutException {
      throw Exception("");
    }
    throw Exception("error fetching data");
  }

  Future<String> loginPost(String url, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        body: json.encode(body),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        return response.body;
      }
    } on SocketException {
      await Future.delayed(const Duration(milliseconds: 1800));
      throw Exception("No Internet Connection");
    } on TimeoutException {
      throw Exception("");
    }
    throw Exception("error fetching data");
  }
}
