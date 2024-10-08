import "package:flutter/foundation.dart";

import "../utils/extensions.dart";

enum PlayerRole {
  mafia,
  don,
  sheriff,
  citizen,
  ;

  /// Returns true if this role is one of [PlayerRole.mafia] or [PlayerRole.don]
  bool get isMafia => isAnyOf(const [PlayerRole.mafia, PlayerRole.don]);

  /// Returns true if this role is one of [PlayerRole.citizen] or [PlayerRole.sheriff]
  bool get isCitizen => isAnyOf(const [PlayerRole.citizen, PlayerRole.sheriff]);
}

const roles = {
  PlayerRole.citizen: 6,
  PlayerRole.mafia: 2,
  PlayerRole.sheriff: 1,
  PlayerRole.don: 1,
};

@immutable
class Player {
  final PlayerRole role;
  final int number;
  final bool isAlive;
  final String nickname;

  const Player({
    required this.role,
    required this.number,
    required this.nickname,
    this.isAlive = true,
  });

  Player copyWith({
    PlayerRole? role,
    int? number,
    bool? isAlive,
    String? nickname,
  }) =>
      Player(
        isAlive: isAlive ?? this.isAlive,
        role: role ?? this.role,
        number: number ?? this.number,
        nickname: nickname ?? this.nickname,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player &&
          runtimeType == other.runtimeType &&
          role == other.role &&
          number == other.number &&
          isAlive == other.isAlive;

  @override
  int get hashCode => Object.hash(role, number, isAlive);

  Map<String, dynamic> toJson() => {
        "role": role.toString().split(".").last,
        "number": number,
        "isAlive": isAlive,
        "nickname": nickname,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        role: PlayerRole.values.firstWhere(
          (role) => role.toString().split(".").last == json["role"],
        ),
        number: json["number"] as int,
        isAlive: json["isAlive"] as bool,
        nickname: json["nickname"] as String,
      );
}

List<Player> generatePlayers({
  Map<PlayerRole, int> roles = const {
    PlayerRole.citizen: 6,
    PlayerRole.mafia: 2,
    PlayerRole.sheriff: 1,
    PlayerRole.don: 1,
  },
}) {
  for (final role in PlayerRole.values) {
    if (!roles.containsKey(role)) {
      throw ArgumentError("Role $role is not defined in the role map");
    }
  }
  if (roles[PlayerRole.sheriff]! != 1) {
    throw ArgumentError("Only one sheriff is allowed");
  }
  if (roles[PlayerRole.don]! != 1) {
    throw ArgumentError("Only one don is allowed");
  }
  if (roles[PlayerRole.mafia]! >= roles[PlayerRole.citizen]!) {
    throw ArgumentError("Too many mafia");
  }
  final playerRoles = roles.entries
      .expand((entry) => List.filled(entry.value, entry.key))
      .toList(growable: false)
    ..shuffle();
  return playerRoles
      .asMap()
      .entries
      .map(
        (entry) => Player(
          role: entry.value,
          number: entry.key + 1,
          nickname: "Игрок ${entry.key + 1}",
        ),
      )
      .toList(growable: false)
    ..sort((a, b) => a.number.compareTo(b.number))
    ..toUnmodifiableList();
}
