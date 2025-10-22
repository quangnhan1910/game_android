import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rubik/cube_models.dart';

final cubeProvider = StateNotifierProvider<CubeNotifier, CubeState>((ref) {
  return CubeNotifier();
});

class CubeNotifier extends StateNotifier<CubeState> {
  CubeNotifier() : super(CubeState());

  void setSticker(int index, String color) {
    if (index < 0 || index >= 54) return;
    if (!validColors.contains(color)) return;
    final list = List<String>.from(state.stickers);
    list[index] = color;
    state = CubeState(stickers: list);
  }

  /// Gán cả 1 mặt (face: 0..5) với 9 ký tự hợp lệ
  void setFace(int face, List<String> nine) {
    if (face < 0 || face > 5 || nine.length != 9) return;
    final list = List<String>.from(state.stickers);
    final start = face * 9;
    for (int i = 0; i < 9; i++) {
      final c = nine[i];
      if (validColors.contains(c)) list[start + i] = c;
    }
    state = CubeState(stickers: list);
  }

  void resetSolved() => state = CubeState();
}
