import 'package:flutter/material.dart';
import '../models/cube_models.dart';

/// Ô sticker 1×1
class StickerCell extends StatelessWidget {
  final String code;
  final VoidCallback? onTap;
  const StickerCell({super.key, required this.code, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorValue = faceColorMap[code] ?? 0xFFBDBDBD;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Color(colorValue),
          border: Border.all(color: Colors.black54, width: 1.2),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(code,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black)),
      ),
    );
  }
}

/// Lưới 3×3 cho một mặt
class FaceGrid extends StatelessWidget {
  final List<String> face9; // length 9
  final void Function(int idx)? onTap;
  const FaceGrid({super.key, required this.face9, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 9,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6),
      itemBuilder: (_, i) => StickerCell(code: face9[i], onTap: () => onTap?.call(i)),
    );
  }
}

/// Net chữ thập (U ở trên F; trái L, phải R; dưới D; B ở bên phải cùng)
class CubeNet extends StatelessWidget {
  final List<String> stickers; // 54
  const CubeNet({super.key, required this.stickers});

  List<String> face(int f) => stickers.sublist(f*9, f*9+9);

  @override
  Widget build(BuildContext context) {
    final U = face(0), R = face(1), F = face(2), D = face(3), L = face(4), B = face(5);
    
    // Tính toán kích thước phù hợp với màn hình
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 32; // Trừ padding
    final faceSize = (availableWidth - 24) / 4; // 4 mặt ngang, trừ spacing
    
    Widget block(List<String> x) => SizedBox(
      width: faceSize, 
      height: faceSize,
      child: FaceGrid(face9: x),
    );
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [block(U)]),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                block(L), 
                const SizedBox(width: 8), 
                block(F), 
                const SizedBox(width: 8), 
                block(R), 
                const SizedBox(width: 8), 
                block(B)
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [block(D)]),
        ],
      ),
    );
  }
}
