enum CubeFace { U, R, F, D, L, B } // Singmaster faces
enum Move { U, Up, U2, R, Rp, R2, F, Fp, F2, D, Dp, D2, L, Lp, L2, B, Bp, B2 }

/// Mỗi sticker là 1 ký tự trong: U,R,F,D,L,B (màu tâm: U=trắng, R=đỏ, F=xanh lá, D=vàng, L=cam, B=xanh dương)
class CubeState {
  /// Thứ tự mặt: U(0) R(1) F(2) D(3) L(4) B(5), mỗi mặt 9 sticker => tổng 54.
  List<String> stickers;

  CubeState({List<String>? stickers})
      : stickers = stickers ??
            List<String>.from([
              ...List.generate(9, (i) => 'U'), // U
              ...List.generate(9, (i) => 'R'), // R
              ...List.generate(9, (i) => 'F'), // F
              ...List.generate(9, (i) => 'D'), // D
              ...List.generate(9, (i) => 'L'), // L
              ...List.generate(9, (i) => 'B'), // B
            ]);

  String toSingmasterString() => stickers.join();

  bool isColorCountValid() {
    final counts = <String, int>{};
    for (final s in stickers) {
      counts[s] = (counts[s] ?? 0) + 1;
    }
    const need = ['U','R','F','D','L','B'];
    return need.every((c) => counts[c] == 9);
  }
}

/// Màu hiển thị (có thể đổi)
const faceColorMap = {
  'U': 0xFFFFFFFF, // trắng
  'R': 0xFFFF0000, // đỏ
  'F': 0xFF00C853, // xanh lá
  'D': 0xFFFFD600, // vàng
  'L': 0xFFFF9800, // cam
  'B': 0xFF2979FF, // xanh dương
};

const validColors = ['U','R','F','D','L','B'];
