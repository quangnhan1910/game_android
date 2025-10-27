import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/sudoku_board.dart';
import '../../screens/sudoku/sudoku_grid.dart';
import '../../screens/sudoku/number_pad.dart';
import '../../screens/sudoku/action_buttons.dart';
import '../../services/sudoku_leaderboard_service.dart';
import '../../routes.dart';

class GameSudoku extends StatefulWidget {
  final String difficulty;
  final int emptyCells;

  const GameSudoku({
    Key? key,
    required this.difficulty,
    required this.emptyCells,
  }) : super(key: key);

  @override
  State<GameSudoku> createState() => _GameSudokuState();
}

// Helper function to check if hints are allowed
bool _isHintAllowed(String difficulty) {
  return difficulty == 'Dễ';
}

class _GameSudokuState extends State<GameSudoku> {
  late SudokuBoard sudokuBoard;
  int? selectedRow;
  int? selectedCol;
  int seconds = 0;
  Timer? timer;
  bool isGameWon = false;
  final SudokuLeaderboardService _leaderboardService =
      SudokuLeaderboardService();

  @override
  void initState() {
    super.initState();
    sudokuBoard = SudokuBoard();
    sudokuBoard.generateNewGame(widget.emptyCells);
    _startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isGameWon) {
        setState(() {
          seconds++;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _onCellSelected(int row, int col) {
    setState(() {
      selectedRow = row;
      selectedCol = col;
    });
  }

  void _onNumberPressed(int number) {
    if (selectedRow != null && selectedCol != null) {
      setState(() {
        sudokuBoard.placeNumber(selectedRow!, selectedCol!, number);
        if (sudokuBoard.isComplete()) {
          isGameWon = true;
          _showWinDialog();
        }
      });
    }
  }

  void _onClearPressed() {
    if (selectedRow != null && selectedCol != null) {
      setState(() {
        sudokuBoard.clearCell(selectedRow!, selectedCol!);
      });
    }
  }

  void _onHintPressed() {
    if (selectedRow != null && selectedCol != null) {
      setState(() {
        sudokuBoard.giveHint(selectedRow!, selectedCol!);
        if (sudokuBoard.isComplete()) {
          isGameWon = true;
          _showWinDialog();
        }
      });
    }
  }

  void _onNewGamePressed() {
    setState(() {
      seconds = 0;
      isGameWon = false;
      selectedRow = null;
      selectedCol = null;
      sudokuBoard.generateNewGame(widget.emptyCells);
    });
  }

  void _showWinDialog() {
    // Map difficulty từ tiếng Việt sang tiếng Anh
    String difficultyKey = widget.difficulty == 'Dễ'
        ? 'easy'
        : widget.difficulty == 'Trung bình'
            ? 'medium'
            : 'hard';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          '🎉 Chúc mừng!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 64,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              'Bạn đã hoàn thành Sudoku mức ${widget.difficulty}!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'Thời gian: ${_formatTime(seconds)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Gửi thời gian lên server
              final result = await _leaderboardService.submitTime(
                time: seconds,
                difficulty: difficultyKey,
              );

              if (mounted) {
                Navigator.of(context).pop();

                // Hiển thị kết quả
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Đã gửi thời gian'),
                    backgroundColor:
                        result['success'] == true ? Colors.green : Colors.red,
                  ),
                );

                // Chuyển đến bảng xếp hạng
                if (result['success'] == true) {
                  Navigator.pushNamed(context, AppRoutes.sudokuLeaderboard);
                }
              }
            },
            child: const Text('Lưu thời gian & Xem BXH'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, AppRoutes.sudokuLeaderboard);
            },
            child: const Text('Xem BXH'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _onNewGamePressed();
            },
            child: const Text('Chơi lại'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Quay lại'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sudoku - ${widget.difficulty}'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.sudokuLeaderboard),
            tooltip: 'Bảng xếp hạng',
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                _formatTime(seconds),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: SudokuGrid(
                    board: sudokuBoard,
                    selectedRow: selectedRow,
                    selectedCol: selectedCol,
                    onCellSelected: _onCellSelected,
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                NumberPad(onNumberPressed: _onNumberPressed),
                const SizedBox(height: 16),
                ActionButtons(
                  onClearPressed: _onClearPressed,
                  onHintPressed: _onHintPressed,
                  onNewGamePressed: _onNewGamePressed,
                  showHint: _isHintAllowed(widget.difficulty),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}