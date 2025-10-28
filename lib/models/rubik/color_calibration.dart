import 'dart:math';
import 'package:vector_math/vector_math.dart' as vm;

/// Thuật toán phân loại màu tối ưu cho 6 màu Rubik:
/// Trắng (U), Đỏ/Hồng (R), Xanh lá (F), Vàng (D), Cam (L), Xanh dương (B)
/// 
/// Cải tiến:
/// 1. White Balance tự động dựa trên mặt trắng
/// 2. Enhanced CIELAB với ΔE2000
/// 3. Adaptive confidence thresholds cho từng màu
class ColorCalibration {
  final Map<String, vm.Vector3> labByFace;
  final Map<String, int> rgbByFace; // Lưu RGB sau white balance
  
  const ColorCalibration(this.labByFace, this.rgbByFace);

  factory ColorCalibration.fromCenters({
    required int up,    // U - Trắng
    required int right, // R - Đỏ/Hồng
    required int front, // F - Xanh lá
    required int down,  // D - Vàng
    required int left,  // L - Cam
    required int back,  // B - Xanh dương
  }) {
    // ========== BƯỚC 1: WHITE BALANCE ==========
    // Dùng mặt trắng (U) làm reference để cân bằng màu toàn bộ hệ thống
    final whiteRgb = up;
    final whiteR = ((whiteRgb >> 16) & 0xFF).toDouble();
    final whiteG = ((whiteRgb >> 8) & 0xFF).toDouble();
    final whiteB = (whiteRgb & 0xFF).toDouble();
    
    // Tính hệ số cân bằng (giả định trắng lý tưởng là 255,255,255)
    final maxWhite = max(whiteR, max(whiteG, whiteB));
    final wbR = maxWhite / max(whiteR, 1.0);
    final wbG = maxWhite / max(whiteG, 1.0);
    final wbB = maxWhite / max(whiteB, 1.0);
    
    // Apply white balance cho tất cả các màu
    int applyWB(int rgb) {
      int r = ((((rgb >> 16) & 0xFF) * wbR).clamp(0, 255)).toInt();
      int g = ((((rgb >> 8) & 0xFF) * wbG).clamp(0, 255)).toInt();
      int b = (((rgb & 0xFF) * wbB).clamp(0, 255)).toInt();
      return (r << 16) | (g << 8) | b;
    }
    
    final upWB = applyWB(up);
    final rightWB = applyWB(right);
    final frontWB = applyWB(front);
    final downWB = applyWB(down);
    final leftWB = applyWB(left);
    final backWB = applyWB(back);
    
    // Debug log
    print('🎨 [ColorCalibration] White Balance (WB ratio: R=${wbR.toStringAsFixed(2)}, G=${wbG.toStringAsFixed(2)}, B=${wbB.toStringAsFixed(2)}):');
    print('  U (White):  ${_rgbToHex(up)} -> ${_rgbToHex(upWB)}');
    print('  R (Red):    ${_rgbToHex(right)} -> ${_rgbToHex(rightWB)}');
    print('  F (Green):  ${_rgbToHex(front)} -> ${_rgbToHex(frontWB)}');
    print('  D (Yellow): ${_rgbToHex(down)} -> ${_rgbToHex(downWB)}');
    print('  L (Orange): ${_rgbToHex(left)} -> ${_rgbToHex(leftWB)}');
    print('  B (Blue):   ${_rgbToHex(back)} -> ${_rgbToHex(backWB)}');
    
    // ========== BƯỚC 2: CONVERT TO CIELAB ==========
    final labMap = {
      'U': _rgbToLab(upWB),
      'R': _rgbToLab(rightWB),
      'F': _rgbToLab(frontWB),
      'D': _rgbToLab(downWB),
      'L': _rgbToLab(leftWB),
      'B': _rgbToLab(backWB),
    };
    
    final rgbMap = {
      'U': upWB,
      'R': rightWB,
      'F': frontWB,
      'D': downWB,
      'L': leftWB,
      'B': backWB,
    };
    
    // Debug: In LAB values
    print('🔬 [ColorCalibration] LAB values:');
    labMap.forEach((k, lab) {
      print('  $k: L=${lab.x.toStringAsFixed(1)}, a=${lab.y.toStringAsFixed(1)}, b=${lab.z.toStringAsFixed(1)}');
    });
    
    return ColorCalibration(labMap, rgbMap);
  }
  
  /// Trả về (label, confidence 0..1)
  (String, double) classifyWithConfidence(int rgb) {
    // Apply white balance trước khi phân loại (dùng RGB reference của U)
    final whiteRef = rgbByFace['U']!;
    final whiteR = ((whiteRef >> 16) & 0xFF).toDouble();
    final whiteG = ((whiteRef >> 8) & 0xFF).toDouble();
    final whiteB = (whiteRef & 0xFF).toDouble();
    final maxWhite = max(whiteR, max(whiteG, whiteB));
    final wbR = maxWhite / max(whiteR, 1.0);
    final wbG = maxWhite / max(whiteG, 1.0);
    final wbB = maxWhite / max(whiteB, 1.0);
    
    int r = ((((rgb >> 16) & 0xFF) * wbR).clamp(0, 255)).toInt();
    int g = ((((rgb >> 8) & 0xFF) * wbG).clamp(0, 255)).toInt();
    int b = (((rgb & 0xFF) * wbB).clamp(0, 255)).toInt();
    final rgbWB = (r << 16) | (g << 8) | b;
    
    // Convert to LAB
    final x = _rgbToLab(rgbWB);
    String best = 'U';
    double bestDe = 1e9, secondDe = 1e9;
    
    // Tìm 2 màu gần nhất
    labByFace.forEach((k, ref) {
      final de = _deltaE2000(x, ref);
      if (de < bestDe) {
        secondDe = bestDe;
        bestDe = de;
        best = k;
      } else if (de < secondDe) {
        secondDe = de;
      }
    });
    
    // ========== BƯỚC 3: ADAPTIVE CONFIDENCE ==========
    // Confidence dựa vào:
    // 1. Độ chênh lệch giữa 2 ứng viên tốt nhất (separation)
    // 2. Độ gần với màu reference (absolute distance)
    // 3. Điều chỉnh ngưỡng riêng cho từng màu
    
    // Ngưỡng ΔE cho các màu khác nhau:
    // - Trắng/Vàng: dễ phân biệt -> ngưỡng thấp (15)
    // - Đỏ/Cam: khó phân biệt -> ngưỡng cao (25)
    // - Xanh lá/Xanh dương: trung bình (20)
    final threshold = _getThreshold(best);
    
    final sep = (secondDe - bestDe).clamp(0.0, threshold);
    final abs = (threshold - bestDe).clamp(0.0, threshold);
    final conf = (0.6 * (sep / threshold) + 0.4 * (abs / threshold)).clamp(0.0, 1.0).toDouble();
    
    return (best, conf);
  }
  
  /// Ngưỡng ΔE2000 tối ưu cho từng màu Rubik
  static double _getThreshold(String face) {
    switch (face) {
      case 'U': // Trắng - dễ nhận diện
        return 15.0;
      case 'D': // Vàng - dễ nhận diện
        return 15.0;
      case 'B': // Xanh dương - khá dễ
        return 18.0;
      case 'F': // Xanh lá - khá dễ
        return 18.0;
      case 'R': // Đỏ/Hồng - dễ nhầm với cam
        return 25.0;
      case 'L': // Cam - dễ nhầm với đỏ/vàng
        return 25.0;
      default:
        return 20.0;
    }
  }

  String classify(int rgb) => classifyWithConfidence(rgb).$1;

  // ========== HELPERS ==========
  
  static String _rgbToHex(int rgb) {
    final r = (rgb >> 16) & 0xFF;
    final g = (rgb >> 8) & 0xFF;
    final b = rgb & 0xFF;
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
  }
  
  /// RGB -> CIELAB (D65 illuminant)
  static vm.Vector3 _rgbToLab(int rgb) {
    final r = ((rgb >> 16) & 0xFF) / 255.0;
    final g = ((rgb >> 8) & 0xFF) / 255.0;
    final b = (rgb & 0xFF) / 255.0;

    // sRGB to Linear RGB
    double lin(double c) =>
        c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
    final rl = lin(r), gl = lin(g), bl = lin(b);

    // Linear RGB to XYZ (D65)
    final x = rl * 0.4124564 + gl * 0.3575761 + bl * 0.1804375;
    final y = rl * 0.2126729 + gl * 0.7151522 + bl * 0.0721750;
    final z = rl * 0.0193339 + gl * 0.1191920 + bl * 0.9503041;

    // XYZ to LAB
    final xr = x / 0.95047, yr = y / 1.00000, zr = z / 1.08883;
    double f(double t) =>
        t > 0.008856 ? pow(t, 1 / 3).toDouble() : (7.787 * t + 16 / 116);

    final fx = f(xr), fy = f(yr), fz = f(zr);
    return vm.Vector3(116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz));
  }

  /// ΔE2000: Công thức tính độ khác biệt màu chuẩn CIE2000
  /// Tham khảo: https://en.wikipedia.org/wiki/Color_difference#CIEDE2000
  static double _deltaE2000(vm.Vector3 a, vm.Vector3 b) {
    final L1 = a.x, a1 = a.y, b1 = a.z;
    final L2 = b.x, a2 = b.y, b2 = b.z;

    final avgLp = (L1 + L2) / 2.0;
    final C1 = sqrt(a1 * a1 + b1 * b1);
    final C2 = sqrt(a2 * a2 + b2 * b2);
    final avgC = (C1 + C2) / 2.0;

    final G = 0.5 * (1 - sqrt(pow(avgC, 7) / (pow(avgC, 7) + pow(25.0, 7))));
    final a1p = (1 + G) * a1;
    final a2p = (1 + G) * a2;
    final C1p = sqrt(a1p * a1p + b1 * b1);
    final C2p = sqrt(a2p * a2p + b2 * b2);
    double h1p = atan2(b1, a1p);
    if (h1p < 0) h1p += 2 * pi;
    double h2p = atan2(b2, a2p);
    if (h2p < 0) h2p += 2 * pi;

    final dLp = L2 - L1;
    final dCp = C2p - C1p;
    double dhp;
    final dh = h2p - h1p;
    if (C1p * C2p == 0) {
      dhp = 0;
    } else if (dh.abs() <= pi) {
      dhp = dh;
    } else if (dh > pi) {
      dhp = dh - 2 * pi;
    } else {
      dhp = dh + 2 * pi;
    }
    final dHp = 2 * sqrt(C1p * C2p) * sin(dhp / 2);

    final avgLp2 = (L1 + L2) / 2;
    double avgHp;
    if (C1p * C2p == 0) {
      avgHp = h1p + h2p;
    } else if ((h1p - h2p).abs() <= pi) {
      avgHp = (h1p + h2p) / 2;
    } else {
      avgHp = (h1p + h2p + 2 * pi) / 2;
    }
    final T = 1 -
        0.17 * cos(avgHp - pi / 6) +
        0.24 * cos(2 * avgHp) +
        0.32 * cos(3 * avgHp + pi / 30) -
        0.20 * cos(4 * avgHp - 63 * pi / 180);

    final dRo =
        30 * pi / 180 * exp(-pow((avgHp * 180 / pi - 275) / 25, 2));
    final RC = 2 * sqrt(pow(avgC, 7) / (pow(avgC, 7) + pow(25.0, 7)));
    final SL =
        1 + (0.015 * pow(avgLp2 - 50, 2)) / sqrt(20 + pow(avgLp2 - 50, 2));
    final SC = 1 + 0.045 * avgC;
    final SH = 1 + 0.015 * avgC * T;
    final RT = -sin(2 * dRo) * RC;

    final dE = sqrt(pow(dLp / SL, 2) +
        pow(dCp / SC, 2) +
        pow(dHp / SH, 2) +
        RT * (dCp / SC) * (dHp / SH));
    return dE.abs();
  }
}
