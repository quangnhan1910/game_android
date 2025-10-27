class TetrisLeaderboardEntry {
  final String playerName;
  final int score;
  final int level;
  final DateTime createdAt;
  final int? rank;

  TetrisLeaderboardEntry({
    required this.playerName,
    required this.score,
    required this.level,
    required this.createdAt,
    this.rank,
  });

  factory TetrisLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return TetrisLeaderboardEntry(
      playerName: json['userName'] ?? json['playerName'] ?? json['player_name'] ?? 'Unknown',
      score: json['score'] ?? json['bestScore'] ?? 0,
      level: json['level'] ?? json['bestLevel'] ?? 1,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : (json['achievedAt'] != null
                  ? DateTime.parse(json['achievedAt'])
                  : DateTime.now())),
      rank: json['rank'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerName': playerName,
      'score': score,
      'level': level,
      'createdAt': createdAt.toIso8601String(),
      if (rank != null) 'rank': rank,
    };
  }
}

class TetrisLeaderboardResponse {
  final List<TetrisLeaderboardEntry> entries;
  final int totalCount;

  TetrisLeaderboardResponse({
    required this.entries,
    required this.totalCount,
  });

  factory TetrisLeaderboardResponse.fromJson(Map<String, dynamic> json) {
    final entriesList = json['entries'] ?? json['data'] ?? [];
    return TetrisLeaderboardResponse(
      entries: (entriesList as List)
          .map((entry) => TetrisLeaderboardEntry.fromJson(entry))
          .toList(),
      totalCount: json['totalCount'] ?? json['total'] ?? 0,
    );
  }
}

class SubmitTetrisScoreRequest {
  final int score;
  final int level;

  SubmitTetrisScoreRequest({
    required this.score,
    required this.level,
  });

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'level': level,
    };
  }
}

