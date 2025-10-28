class SudokuLeaderboardEntry {
  final String playerName;
  final int time; // Thời gian tính bằng giây
  final String difficulty;
  final DateTime createdAt;
  final int? rank;

  SudokuLeaderboardEntry({
    required this.playerName,
    required this.time,
    required this.difficulty,
    required this.createdAt,
    this.rank,
  });

  factory SudokuLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return SudokuLeaderboardEntry(
      playerName: json['userName'] ?? json['playerName'] ?? json['player_name'] ?? 'Unknown',
      time: json['time'] ?? json['bestTime'] ?? 0,
      difficulty: json['difficulty'] ?? 'easy',
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
      'time': time,
      'difficulty': difficulty,
      'createdAt': createdAt.toIso8601String(),
      if (rank != null) 'rank': rank,
    };
  }

  // Format thời gian thành mm:ss
  String get formattedTime {
    final minutes = time ~/ 60;
    final seconds = time % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class SudokuLeaderboardResponse {
  final List<SudokuLeaderboardEntry> entries;
  final int totalCount;

  SudokuLeaderboardResponse({
    required this.entries,
    required this.totalCount,
  });

  factory SudokuLeaderboardResponse.fromJson(Map<String, dynamic> json) {
    final entriesList = json['entries'] ?? json['data'] ?? [];
    return SudokuLeaderboardResponse(
      entries: (entriesList as List)
          .map((entry) => SudokuLeaderboardEntry.fromJson(entry))
          .toList(),
      totalCount: json['totalCount'] ?? json['total'] ?? 0,
    );
  }
}

class SubmitSudokuTimeRequest {
  final int time;
  final String difficulty;

  SubmitSudokuTimeRequest({
    required this.time,
    required this.difficulty,
  });

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'difficulty': difficulty,
    };
  }
}

