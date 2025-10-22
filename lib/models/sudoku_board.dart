import 'dart:math';

class SudokuBoard {
  late List<List<int>> board;
  late List<List<int>> solution;
  late List<List<bool>> editable;

  SudokuBoard() {
    board = List.generate(9, (_) => List.filled(9, 0));
    solution = List.generate(9, (_) => List.filled(9, 0));
    editable = List.generate(9, (_) => List.filled(9, true));
  }

  void generateNewGame(int emptyCells) {
    board = List.generate(9, (_) => List.filled(9, 0));
    solution = List.generate(9, (_) => List.filled(9, 0));
    editable = List.generate(9, (_) => List.filled(9, true));

    _fillBoard(0, 0);

    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        solution[i][j] = board[i][j];
      }
    }

    _removeNumbers(emptyCells);
  }

  bool _fillBoard(int row, int col) {
    if (row == 9) return true;
    if (col == 9) return _fillBoard(row + 1, 0);

    List<int> numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    numbers.shuffle(Random());

    for (int num in numbers) {
      if (_isValid(row, col, num)) {
        board[row][col] = num;
        if (_fillBoard(row, col + 1)) return true;
        board[row][col] = 0;
      }
    }
    return false;
  }

  bool _isValid(int row, int col, int num) {
    for (int i = 0; i < 9; i++) {
      if (board[row][i] == num || board[i][col] == num) return false;
    }

    int boxRow = (row ~/ 3) * 3;
    int boxCol = (col ~/ 3) * 3;
    for (int i = boxRow; i < boxRow + 3; i++) {
      for (int j = boxCol; j < boxCol + 3; j++) {
        if (board[i][j] == num) return false;
      }
    }
    return true;
  }

  void _removeNumbers(int count) {
    Random random = Random();
    int removed = 0;

    while (removed < count) {
      int row = random.nextInt(9);
      int col = random.nextInt(9);

      if (board[row][col] != 0) {
        board[row][col] = 0;
        removed++;
      }
    }

    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        editable[i][j] = board[i][j] == 0;
      }
    }
  }

  bool hasConflict(int row, int col) {
    if (board[row][col] == 0) return false;
    int num = board[row][col];

    for (int i = 0; i < 9; i++) {
      if (i != col && board[row][i] == num) return true;
      if (i != row && board[i][col] == num) return true;
    }

    int boxRow = (row ~/ 3) * 3;
    int boxCol = (col ~/ 3) * 3;
    for (int i = boxRow; i < boxRow + 3; i++) {
      for (int j = boxCol; j < boxCol + 3; j++) {
        if ((i != row || j != col) && board[i][j] == num) return true;
      }
    }
    return false;
  }

  bool isComplete() {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (board[i][j] != solution[i][j]) return false;
      }
    }
    return true;
  }

  void placeNumber(int row, int col, int number) {
    if (editable[row][col]) {
      board[row][col] = number;
    }
  }

  void clearCell(int row, int col) {
    if (editable[row][col]) {
      board[row][col] = 0;
    }
  }

  void giveHint(int row, int col) {
    if (editable[row][col]) {
      board[row][col] = solution[row][col];
      editable[row][col] = false;
    }
  }
}