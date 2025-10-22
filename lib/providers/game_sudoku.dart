import 'package:flutter/material.dart';
import 'dart:async';
import '../models/sudoku_board.dart';
import '../screens/sudoku_grid.dart';
import '../screens/number_pad.dart';
import '../screens/action_buttons.dart';

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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Chúc mừng!'),
        content: Text(
          'Bạn đã hoàn thành Sudoku mức ${widget.difficulty}!\n\nThời gian: ${_formatTime(seconds)}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Quay lại'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _onNewGamePressed();
            },
            child: const Text('Chơi lại'),
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