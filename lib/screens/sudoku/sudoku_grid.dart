import 'package:flutter/material.dart';
import '../../models/sudoku_board.dart';

class SudokuGrid extends StatelessWidget {
  final SudokuBoard board;
  final int? selectedRow;
  final int? selectedCol;
  final Function(int, int) onCellSelected;

  const SudokuGrid({
    Key? key,
    required this.board,
    required this.selectedRow,
    required this.selectedCol,
    required this.onCellSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 9,
        childAspectRatio: 1,
      ),
      itemCount: 81,
      itemBuilder: (context, index) {
        int row = index ~/ 9;
        int col = index % 9;
        bool isSelected = row == selectedRow && col == selectedCol;
        bool hasConflict = board.hasConflict(row, col);

        return GestureDetector(
          onTap: () => onCellSelected(row, col),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue[100]
                  : hasConflict
                  ? Colors.red[100]
                  : Colors.white,
              border: Border(
                top: BorderSide(
                  color: row % 3 == 0 ? Colors.black : Colors.grey[300]!,
                  width: row % 3 == 0 ? 2 : 0.5,
                ),
                left: BorderSide(
                  color: col % 3 == 0 ? Colors.black : Colors.grey[300]!,
                  width: col % 3 == 0 ? 2 : 0.5,
                ),
                right: BorderSide(
                  color: col == 8 ? Colors.black : Colors.transparent,
                  width: 2,
                ),
                bottom: BorderSide(
                  color: row == 8 ? Colors.black : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Center(
              child: Text(
                board.board[row][col] == 0 ? '' : board.board[row][col].toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: board.editable[row][col]
                      ? Colors.blue[700]
                      : Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}