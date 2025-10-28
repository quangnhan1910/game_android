/// CIELAB Color Space Converter
/// 
/// Triển khai thuật toán chuyển đổi RGB → XYZ → CIELAB như web mẫu
/// https://rubiks-cube-solver.com/scan/
/// 
/// CIELAB là không gian màu perceptual (dựa trên cảm nhận con người),
/// tốt hơn HSV cho việc nhận diện màu Rubik's Cube

import 'dart:math' as math;

/// Chuyển đổi sRGB (0-255) sang Linear RGB (0-1)
/// 
/// sRGB sử dụng gamma correction, cần chuyển về linear trước khi tính toán
double _srgbToLinear(int c) {
  final v = c / 255.0;
  if (v <= 0.04045) {
    return v / 12.92;
  } else {
    return math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }
}

/// Chuyển RGB (0-255) sang XYZ
/// 
/// XYZ là không gian màu trung gian, dựa trên cách con người cảm nhận ánh sáng
/// 
/// Sử dụng ma trận chuyển đổi chuẩn sRGB D65
List<double> rgbToXyz(int r, int g, int b) {
  final R = _srgbToLinear(r);
  final G = _srgbToLinear(g);
  final B = _srgbToLinear(b);
  
  // Ma trận chuyển đổi sRGB → XYZ (D65 illuminant)
  final x = R * 0.4124564 + G * 0.3575761 + B * 0.1804375;
  final y = R * 0.2126729 + G * 0.7151522 + B * 0.0721750;
  final z = R * 0.0193339 + G * 0.1191920 + B * 0.9503041;
  
  return [x, y, z];
}

/// Chuyển XYZ sang CIELAB
/// 
/// CIELAB gồm 3 thành phần:
/// - L: Lightness (độ sáng) 0-100
/// - a: green (-) → red (+)
/// - b: blue (-) → yellow (+)
/// 
/// Khoảng cách Euclidean trong CIELAB (Delta E) tương ứng với sự khác biệt
/// màu sắc mà con người cảm nhận được
List<double> xyzToLab(double x, double y, double z) {
  // Illuminant D65 (ánh sáng ban ngày chuẩn)
  const Xr = 0.95047;
  const Yr = 1.00000;
  const Zr = 1.08883;
  
  double fx = x / Xr;
  double fy = y / Yr;
  double fz = z / Zr;
  
  // Hằng số của phép chuyển đổi
  const e = 216 / 24389; // 0.008856
  const k = 24389 / 27;   // 903.3
  
  // Hàm phi tuyến
  double f(double t) {
    if (t > e) {
      return math.pow(t, 1 / 3).toDouble();
    } else {
      return (k * t + 16) / 116;
    }
  }
  
  fx = f(fx);
  fy = f(fy);
  fz = f(fz);
  
  final L = 116 * fy - 16;
  final a = 500 * (fx - fy);
  final b = 200 * (fy - fz);
  
  return [L, a, b];
}

/// Chuyển RGB trực tiếp sang CIELAB
/// 
/// Đây là hàm chính để sử dụng trong app
List<double> rgbToLab(int r, int g, int b) {
  final xyz = rgbToXyz(r, g, b);
  return xyzToLab(xyz[0], xyz[1], xyz[2]);
}

/// Tính khoảng cách Delta E giữa 2 màu trong không gian CIELAB
/// 
/// Delta E < 1: Khác biệt không nhìn thấy được
/// Delta E 1-2: Khác biệt nhỏ
/// Delta E 2-10: Khác biệt trung bình
/// Delta E > 10: Khác biệt lớn
/// 
/// Công thức: √(ΔL² + Δa² + Δb²)
double labDistance(List<double> lab1, List<double> lab2) {
  final dl = lab1[0] - lab2[0];
  final da = lab1[1] - lab2[1];
  final db = lab1[2] - lab2[2];
  return math.sqrt(dl * dl + da * da + db * db);
}

/// Class đại diện cho một màu trong CIELAB space
class LabColor {
  final double L;
  final double a;
  final double b;
  
  LabColor(this.L, this.a, this.b);
  
  /// Tạo từ RGB
  factory LabColor.fromRgb(int r, int g, int b) {
    final lab = rgbToLab(r, g, b);
    return LabColor(lab[0], lab[1], lab[2]);
  }
  
  /// Tính khoảng cách Delta E đến màu khác
  double distanceTo(LabColor other) {
    return labDistance([L, a, b], [other.L, other.a, other.b]);
  }
  
  List<double> toList() => [L, a, b];
  
  @override
  String toString() => 'Lab(L=${L.toStringAsFixed(1)}, a=${a.toStringAsFixed(1)}, b=${b.toStringAsFixed(1)})';
}

/// Màu chuẩn Rubik's Cube trong không gian CIELAB
/// 
/// Đây là giá trị mặc định từ web mẫu (TUNED_DEFAULTS)
class RubikColorAnchors {
  // Màu chuẩn từ dữ liệu thực tế của người dùng - TỐI ƯU CHO KHỐI RUBIK THỰC TẾ
  static final Map<String, String> defaultHex = {
    'W': '#ADADAD', // Trắng xám (173,173,173) - từ ảnh thực tế
    'G': '#5E9041', // Xanh lá (94,144,65) - từ ảnh thực tế
    'R': '#C85081', // Hồng/Magenta (200,80,129) - từ ảnh thực tế
    'Y': '#B6A73A', // Vàng (182,167,58) - từ ảnh thực tế
    'B': '#458BAE', // Xanh dương (69,139,174) - từ ảnh thực tế
    'O': '#BE5C33', // Cam (190,92,51) - từ ảnh thực tế
  };
  
  /// Chuyển hex sang RGB
  static List<int> hexToRgb(String hex) {
    final n = hex.replaceAll('#', '');
    if (n.length == 3) {
      // #RGB → #RRGGBB
      final r = int.parse(n[0], radix: 16) * 17;
      final g = int.parse(n[1], radix: 16) * 17;
      final b = int.parse(n[2], radix: 16) * 17;
      return [r, g, b];
    } else {
      // #RRGGBB
      final r = int.parse(n.substring(0, 2), radix: 16);
      final g = int.parse(n.substring(2, 4), radix: 16);
      final b = int.parse(n.substring(4, 6), radix: 16);
      return [r, g, b];
    }
  }
  
  /// Lấy màu chuẩn CIELAB cho tất cả các màu
  static Map<String, LabColor> getDefaultAnchors() {
    final anchors = <String, LabColor>{};
    defaultHex.forEach((key, hex) {
      final rgb = hexToRgb(hex);
      anchors[key] = LabColor.fromRgb(rgb[0], rgb[1], rgb[2]);
    });
    return anchors;
  }
}

