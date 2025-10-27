import 'package:flutter/material.dart';
import '../../models/tetris_leaderboard_models.dart';
import '../../services/tetris_leaderboard_service.dart';
import '../../routes.dart';

class TetrisLeaderboardScreen extends StatefulWidget {
  const TetrisLeaderboardScreen({super.key});

  @override
  State<TetrisLeaderboardScreen> createState() =>
      _TetrisLeaderboardScreenState();
}

class _TetrisLeaderboardScreenState extends State<TetrisLeaderboardScreen> {
  final TetrisLeaderboardService _leaderboardService =
      TetrisLeaderboardService();

  bool _isLoading = true;
  List<TetrisLeaderboardEntry> _entries = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load leaderboard
      final leaderboard = await _leaderboardService.getLeaderboard(limit: 100);

      setState(() {
        _entries = leaderboard?.entries ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải bảng xếp hạng: $e';
        _isLoading = false;
      });
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade400; // Vàng
      case 2:
        return Colors.grey.shade400; // Bạc
      case 3:
        return Colors.brown.shade400; // Đồng
      default:
        return Colors.blue.shade600;
    }
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events; // Trophy
      case 2:
        return Icons.military_tech;
      case 3:
        return Icons.stars;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng Xếp Hạng Tetris'),
        backgroundColor: Colors.purple.shade400,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.mainMenu),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaderboard,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.shade50, Colors.blue.shade50],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadLeaderboard,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Danh sách xếp hạng
                      Expanded(
                        child: _entries.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.leaderboard,
                                        size: 64, color: Colors.grey.shade400),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Chưa có điểm số nào',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                itemCount: _entries.length,
                                itemBuilder: (context, index) {
                                  final entry = _entries[index];
                                  final rank = index + 1;
                                  final isTopThree = rank <= 3;

                                  return Card(
                                    elevation: isTopThree ? 4 : 2,
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: isTopThree
                                          ? BorderSide(
                                              color: _getRankColor(rank),
                                              width: 2,
                                            )
                                          : BorderSide.none,
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                      leading: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: _getRankColor(rank)
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(25),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              _getRankIcon(rank),
                                              color: _getRankColor(rank),
                                              size: isTopThree ? 24 : 20,
                                            ),
                                            Text(
                                              '#$rank',
                                              style: TextStyle(
                                                color: _getRankColor(rank),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      title: Text(
                                        entry.playerName,
                                        style: TextStyle(
                                          fontWeight: isTopThree
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          fontSize: isTopThree ? 16 : 15,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Level ${entry.level}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${entry.score}',
                                            style: TextStyle(
                                              fontSize: isTopThree ? 20 : 18,
                                              fontWeight: FontWeight.bold,
                                              color: _getRankColor(rank),
                                            ),
                                          ),
                                          Text(
                                            'điểm',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

