import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../routes.dart';

class TetrisScreen extends StatefulWidget {
  const TetrisScreen({super.key});

  @override
  State<TetrisScreen> createState() => _TetrisScreenState();
}

class _TetrisScreenState extends State<TetrisScreen> {
  static const int boardWidth = 10;
  static const int boardHeight = 20;

  List<List<Color?>> board = List.generate(
    boardHeight,
    (i) => List.generate(boardWidth, (j) => null),
  );

  Timer? gameTimer;
  int score = 0;
  int level = 1;
  bool isGameOver = false;
  bool isPaused = false;

  // Tetris pieces
  final List<List<List<int>>> pieces = [
    // I piece
    [
      [1, 1, 1, 1],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ],
    // O piece
    [
      [1, 1],
      [1, 1],
    ],
    // T piece
    [
      [0, 1, 0],
      [1, 1, 1],
      [0, 0, 0],
    ],
    // S piece
    [
      [0, 1, 1],
      [1, 1, 0],
      [0, 0, 0],
    ],
    // Z piece
    [
      [1, 1, 0],
      [0, 1, 1],
      [0, 0, 0],
    ],
    // J piece
    [
      [1, 0, 0],
      [1, 1, 1],
      [0, 0, 0],
    ],
    // L piece
    [
      [0, 0, 1],
      [1, 1, 1],
      [0, 0, 0],
    ],
  ];

  final List<Color> pieceColors = [
    Colors.cyan,
    Colors.yellow,
    Colors.purple,
    Colors.green,
    Colors.red,
    Colors.blue,
    Colors.orange,
  ];

  List<List<int>>? currentPiece;
  Color? currentPieceColor;
  int currentX = 0;
  int currentY = 0;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    _spawnNewPiece();
    _startTimer();
  }

  void _startTimer() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(
      Duration(milliseconds: max(100, 500 - (level * 50))),
      (timer) {
        if (!isPaused && !isGameOver) {
          _movePieceDown();
        }
      },
    );
  }

  void _spawnNewPiece() {
    final random = Random();
    final pieceIndex = random.nextInt(pieces.length);
    currentPiece = pieces[pieceIndex];
    currentPieceColor = pieceColors[random.nextInt(pieceColors.length)];
    currentX = boardWidth ~/ 2 - currentPiece![0].length ~/ 2;
    currentY = 0;

    if (_checkCollision(currentPiece!, currentX, currentY)) {
      setState(() {
        isGameOver = true;
      });
      gameTimer?.cancel();
    }
  }

  bool _checkCollision(List<List<int>> piece, int x, int y) {
    for (int i = 0; i < piece.length; i++) {
      for (int j = 0; j < piece[i].length; j++) {
        if (piece[i][j] == 1) {
          int newX = x + j;
          int newY = y + i;

          if (newX < 0 || newX >= boardWidth || newY >= boardHeight) {
            return true;
          }

          if (newY >= 0 && board[newY][newX] != null) {
            return true;
          }
        }
      }
    }
    return false;
  }

  void _movePieceDown() {
    if (currentPiece != null) {
      if (!_checkCollision(currentPiece!, currentX, currentY + 1)) {
        setState(() {
          currentY++;
        });
      } else {
        _placePiece();
        _clearLines();
        _spawnNewPiece();
      }
    }
  }

  void _movePieceLeft() {
    if (currentPiece != null &&
        !_checkCollision(currentPiece!, currentX - 1, currentY)) {
      setState(() {
        currentX--;
      });
    }
  }

  void _movePieceRight() {
    if (currentPiece != null &&
        !_checkCollision(currentPiece!, currentX + 1, currentY)) {
      setState(() {
        currentX++;
      });
    }
  }

  void _rotatePiece() {
    if (currentPiece != null) {
      List<List<int>> rotated = List.generate(
        currentPiece![0].length,
        (i) => List.generate(
          currentPiece!.length,
          (j) => currentPiece![currentPiece!.length - 1 - j][i],
        ),
      );

      if (!_checkCollision(rotated, currentX, currentY)) {
        setState(() {
          currentPiece = rotated;
        });
      }
    }
  }

  void _placePiece() {
    if (currentPiece != null) {
      for (int i = 0; i < currentPiece!.length; i++) {
        for (int j = 0; j < currentPiece![i].length; j++) {
          if (currentPiece![i][j] == 1) {
            int x = currentX + j;
            int y = currentY + i;
            if (y >= 0 && y < boardHeight && x >= 0 && x < boardWidth) {
              board[y][x] = currentPieceColor;
            }
          }
        }
      }
    }
  }

  void _clearLines() {
    int linesCleared = 0;
    for (int y = boardHeight - 1; y >= 0; y--) {
      bool isLineFull = true;
      for (int x = 0; x < boardWidth; x++) {
        if (board[y][x] == null) {
          isLineFull = false;
          break;
        }
      }

      if (isLineFull) {
        board.removeAt(y);
        board.insert(0, List.generate(boardWidth, (i) => null));
        linesCleared++;
        y++; // Check the same line again
      }
    }

    if (linesCleared > 0) {
      setState(() {
        score += linesCleared * 100 * level;
        level = (score ~/ 1000) + 1;
      });
      _startTimer(); // Restart timer with new speed
    }
  }

  void _resetGame() {
    setState(() {
      board = List.generate(
        boardHeight,
        (i) => List.generate(boardWidth, (j) => null),
      );
      score = 0;
      level = 1;
      isGameOver = false;
      isPaused = false;
      currentPiece = null;
    });
    gameTimer?.cancel();
    _startGame();
  }

  void _togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
    if (!isPaused) {
      _startTimer();
    } else {
      gameTimer?.cancel();
    }
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tetris'),
        backgroundColor: Colors.blue.shade100,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.mainMenu),
        ),
        actions: [
          IconButton(
            icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: _togglePause,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetGame),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.purple.shade50],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Game Board
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                    color: Colors.black,
                  ),
                  child: AspectRatio(
                    aspectRatio: boardWidth / boardHeight,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: boardWidth,
                          ),
                      itemCount: boardWidth * boardHeight,
                      itemBuilder: (context, index) {
                        int x = index % boardWidth;
                        int y = index ~/ boardWidth;

                        // Check if current piece occupies this cell
                        Color? cellColor = board[y][x];
                        if (currentPiece != null) {
                          int pieceX = x - currentX;
                          int pieceY = y - currentY;
                          if (pieceX >= 0 &&
                              pieceX < currentPiece![0].length &&
                              pieceY >= 0 &&
                              pieceY < currentPiece!.length &&
                              currentPiece![pieceY][pieceX] == 1) {
                            cellColor = currentPieceColor;
                          }
                        }

                        return Container(
                          decoration: BoxDecoration(
                            color: cellColor ?? Colors.grey.shade800,
                            border: Border.all(
                              color: Colors.grey.shade600,
                              width: 0.5,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Game Info and Controls
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Score and Level Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Score: $score',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Level: $level',
                              style: const TextStyle(fontSize: 14),
                            ),
                            if (isGameOver) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Game Over!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            if (isPaused) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Paused',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // New Game Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _resetGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text(
                          'New Game',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Control Buttons
                    const Text(
                      'Controls:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Movement Controls
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _movePieceLeft,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Icon(Icons.arrow_back, size: 20),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _movePieceRight,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Icon(Icons.arrow_forward, size: 20),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _movePieceDown,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Icon(Icons.arrow_downward, size: 20),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _rotatePiece,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Icon(Icons.rotate_right, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
