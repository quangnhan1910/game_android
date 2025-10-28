import 'package:flutter/material.dart';
import '../../models/sudoku/sudoku_leaderboard_models.dart';
import '../../services/sudoku_leaderboard_service.dart';
import '../../routes.dart';

class SudokuLeaderboardScreen extends StatefulWidget {
  const SudokuLeaderboardScreen({super.key});

  @override
  State<SudokuLeaderboardScreen> createState() =>
      _SudokuLeaderboardScreenState();
}

class _SudokuLeaderboardScreenState extends State<SudokuLeaderboardScreen> {
  final SudokuLeaderboardService _leaderboardService =
      SudokuLeaderboardService();

  bool _isLoading = true;
  List<SudokuLeaderboardEntry> _entries = [];
  String? _errorMessage;
  String _selectedDifficulty = 'easy';

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
      final leaderboard = await _leaderboardService.getLeaderboard(
        difficulty: _selectedDifficulty,
        limit: 100,
      );

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

  void _changeDifficulty(String difficulty) {
    setState(() {
      _selectedDifficulty = difficulty;
    });
    _loadLeaderboard();
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
        return Colors.green.shade600;
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

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 'Dễ';
      case 'medium':
        return 'Trung Bình';
      case 'hard':
        return 'Khó';
      default:
        return difficulty;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _buildDifficultyChip(String difficulty) {
    final isSelected = _selectedDifficulty == difficulty;
    return Expanded(
      child: GestureDetector(
        onTap: () => _changeDifficulty(difficulty),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? _getDifficultyColor(difficulty)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _getDifficultyLabel(difficulty),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng Xếp Hạng Sudoku'),
        backgroundColor: Colors.green.shade400,
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
            colors: [Colors.green.shade50, Colors.teal.shade50],
          ),
        ),
        child: Column(
          children: [
            // Difficulty selector
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text(
                    'Độ khó:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        _buildDifficultyChip('easy'),
                        const SizedBox(width: 8),
                        _buildDifficultyChip('medium'),
                        const SizedBox(width: 8),
                        _buildDifficultyChip('hard'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.leaderboard,
                                              size: 64,
                                              color: Colors.grey.shade400),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Chưa có thời gian nào',
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
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
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
                                                    horizontal: 16,
                                                    vertical: 8),
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
                                                    size:
                                                        isTopThree ? 24 : 20,
                                                  ),
                                                  Text(
                                                    '#$rank',
                                                    style: TextStyle(
                                                      color:
                                                          _getRankColor(rank),
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                              _getDifficultyLabel(
                                                  entry.difficulty),
                                              style: TextStyle(
                                                color: _getDifficultyColor(
                                                    entry.difficulty),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            trailing: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  entry.formattedTime,
                                                  style: TextStyle(
                                                    fontSize:
                                                        isTopThree ? 20 : 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: _getRankColor(rank),
                                                  ),
                                                ),
                                                Text(
                                                  'mm:ss',
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
          ],
        ),
      ),
    );
  }
}
