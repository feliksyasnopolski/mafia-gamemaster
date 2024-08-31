import "dart:collection";

import "package:flutter/foundation.dart";

import "player.dart";
import "states.dart";

@immutable
abstract class BaseGameLogItem {
  const BaseGameLogItem();

  Map<String, dynamic> toJson() => {};
}

@immutable
class StateChangeGameLogItem extends BaseGameLogItem {
  final BaseGameState oldState;
  final BaseGameState? newState;

  const StateChangeGameLogItem({
    required this.oldState,
    this.newState,
  });
  @override
  Map<String, dynamic> toJson() => {
        "type": "stateChange",
        "oldState": oldState.toJson(),
        "newState": newState?.toJson(),
      };
}

@immutable
class PlayerWarnedGameLogItem extends BaseGameLogItem {
  final int playerNumber;
  final bool playerRemoved;
  final int day;

  const PlayerWarnedGameLogItem({
    required this.playerNumber,
    required this.playerRemoved,
    required this.day,
  });

  @override
  Map<String, dynamic> toJson() => {
        "type": "playerWarned",
        "playerNumber": playerNumber,
        "playerRemoved": playerRemoved,
        "day": day,
      };
}

@immutable
class PlayerCheckedGameLogItem extends BaseGameLogItem {
  final int playerNumber;
  final PlayerRole checkedByRole;

  const PlayerCheckedGameLogItem({
    required this.playerNumber,
    required this.checkedByRole,
  });

  @override
  Map<String, dynamic> toJson() => {
        "type": "playerChecked",
        "playerNumber": playerNumber,
        "checkedByRole": checkedByRole.name,
      };
}

class GameLog with IterableMixin<BaseGameLogItem> {
  final _log = <BaseGameLogItem>[];

  GameLog();

  @override
  Iterator<BaseGameLogItem> get iterator => _log.iterator;

  @override
  int get length => _log.length;

  @override
  BaseGameLogItem get last => _log.last;

  void add(BaseGameLogItem item) => _log.add(item);

  BaseGameLogItem pop() => _log.removeLast();

  void removeLastWhere(bool Function(BaseGameLogItem item) test) {
    final i = _log.lastIndexWhere(test);
    if (i != -1) {
      _log.removeAt(i);
    }
  }
}
