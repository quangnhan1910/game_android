import 'dart:async';
import 'dart:math';
import 'dart:ui' show Offset;
import 'package:camera/camera.dart';
import 'color_space_converter.dart';

class CapturedFace {
  final List<int> rgb9; // 9 RGB 0xRRGGBB theo hàng trái→phải
  CapturedFace(this.rgb9);
}

typedef OnPreviewSample = void Function(List<int> rgb9);

class CameraScanner {
  final CameraDescription camera;
  CameraController? _c;
  bool _isStreaming = false;
  DateTime _lastEmit = DateTime.fromMillisecondsSinceEpoch(0);
  
  /// Color anchors cho CIELAB color matching
  /// Ban đầu dùng giá trị mặc định, sau đó có thể calibrate
  Map<String, LabColor> colorAnchors = RubikColorAnchors.getDefaultAnchors();

  CameraScanner(this.camera);

  Future<void> start() async {
    _c = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await _c!.initialize();
    try {
      await _c!.setFocusMode(FocusMode.auto);
      await _c!.setFocusPoint(Offset(0.5, 0.5));
      await _c!.setExposurePoint(Offset(0.5, 0.5));
    } catch (_) {}
  }

  CameraController? get controller => _c;

  Future<void> dispose() async {
    await stopPreviewStream();
    await _c?.dispose();
  }
  
  /// Calibrate một màu cụ thể bằng cách lấy RGB từ center sticker
  /// 
  /// Giống như tính năng "Tune Colors" của web mẫu
  /// colorKey: 'W', 'G', 'R', 'Y', 'B', 'O'
  void calibrateColor(String colorKey, int r, int g, int b) {
    final lab = LabColor.fromRgb(r, g, b);
    colorAnchors[colorKey] = lab;
    print('🎯 [Calibration] $colorKey set to RGB($r,$g,$b) → $lab');
  }
  
  /// Auto-calibration: Tự động học màu từ center sticker
  /// 
  /// Khi người dùng scan một mặt, tự động cập nhật màu anchor
  /// Sử dụng thuật toán thông minh: tìm màu gần nhất và cập nhật
  void autoCalibrateFromCenter(int centerR, int centerG, int centerB, String faceName) {
    final centerLab = LabColor.fromRgb(centerR, centerG, centerB);
    
    // Map face name to color key
    const faceToColor = {
      'U': 'W', // Up = White
      'D': 'Y', // Down = Yellow  
      'F': 'G', // Front = Green
      'B': 'B', // Back = Blue
      'L': 'O', // Left = Orange
      'R': 'R', // Right = Red
    };
    
    final expectedColorKey = faceToColor[faceName];
    if (expectedColorKey == null) return;
    
    // Tìm màu anchor gần nhất
    String closestKey = expectedColorKey;
    double minDistance = centerLab.distanceTo(colorAnchors[expectedColorKey]!);
    
    colorAnchors.forEach((key, anchorLab) {
      final distance = centerLab.distanceTo(anchorLab);
      if (distance < minDistance) {
        minDistance = distance;
        closestKey = key;
      }
    });
    
    // Chỉ cập nhật nếu:
    // 1. Màu gần nhất là màu mong đợi, HOẶC
    // 2. Delta E < 40 (màu tương đối gần)
    if (closestKey == expectedColorKey || minDistance < 40.0) {
      calibrateColor(expectedColorKey, centerR, centerG, centerB);
      print('🤖 [Auto-Calibration] $faceName face → $expectedColorKey color learned (ΔE=${minDistance.toStringAsFixed(1)})');
    } else {
      print('⚠️ [Auto-Calibration] $faceName face color too far from expected $expectedColorKey (ΔE=${minDistance.toStringAsFixed(1)})');
    }
  }
  
  /// Reset về màu mặc định
  void resetCalibration() {
    colorAnchors = RubikColorAnchors.getDefaultAnchors();
    print('🔄 [Calibration] Reset to default colors');
  }

  // ---------- Live preview (YUV420 -> RGB sampling) ----------
  Future<void> startPreviewStream(OnPreviewSample onSample,
      {Duration interval = const Duration(milliseconds: 300)}) async {
    if (_isStreaming) return;
    
    _isStreaming = true;
    await _c!.startImageStream((CameraImage img) {
      final now = DateTime.now();
      if (now.difference(_lastEmit) < interval) return;
      _lastEmit = now;
      final rgb9 = _sample9FromYuv(img);
      onSample(rgb9);
    });
  }

  Future<void> stopPreviewStream() async {
    if (!_isStreaming) return;
    _isStreaming = false;
    if (_c?.value.isStreamingImages == true) {
      try {
        await _c?.stopImageStream();
      } catch (_) {
        // Ignore errors when stopping image stream
      }
    }
  }

  /// Lấy 9 mẫu từ khung trung tâm ảnh YUV (tránh viền ngoài 15% + viền trong mỗi cell 35%)
  List<int> _sample9FromYuv(CameraImage img) {
    final w = img.width, h = img.height;
    final side = w < h ? w : h;
    final pad = (side * 0.15).toInt(); // TĂNG từ 10% -> 15% để tránh viền khung
    final size = side - 2 * pad;
    final cell = (size / 3).floor();

    int yuvAt(int px, int py) {
      // Y plane
      final yPlane = img.planes[0];
      final uvPlane = img.planes[1]; // UV interleaved
      final vuPlane = img.planes[2];

      final uvRowStride = uvPlane.bytesPerRow;
      final yRowStride = yPlane.bytesPerRow;
      final yPixelStride = yPlane.bytesPerPixel ?? 1;
      final uvPixelStride = uvPlane.bytesPerPixel ?? 2;

      final yp = yPlane.bytes[py * yRowStride + px * yPixelStride];

      final uvx = (px / 2).floor();
      final uvy = (py / 2).floor();

      final u = uvPlane.bytes[uvy * uvRowStride + uvx * uvPixelStride];
      final v = vuPlane.bytes[uvy * vuPlane.bytesPerRow + uvx * (vuPlane.bytesPerPixel ?? 2)];

      return (yp & 0xFF) | ((u & 0xFF) << 8) | ((v & 0xFF) << 16);
    }

    int yuv2rgb(int y, int u, int v) {
      // BT.709 (HD standard) + gamma correction để màu chính xác hơn
      final yf = (y.toDouble() - 16.0) * 1.164;
      final uf = u.toDouble() - 128.0;
      final vf = v.toDouble() - 128.0;
      
      // BT.709 matrix
      int r = (yf + 1.793 * vf).round();
      int g = (yf - 0.213 * uf - 0.533 * vf).round();
      int b = (yf + 2.112 * uf).round();
      
      r = r.clamp(0, 255);
      g = g.clamp(0, 255);
      b = b.clamp(0, 255);
      return (r << 16) | (g << 8) | b;
    }

    /// Snap RGB về 1 trong 6 màu Rubik chuẩn (dùng CIELAB Delta E - như web mẫu)
    /// 
    /// Thuật toán: Tìm màu gần nhất trong colorAnchors bằng khoảng cách CIELAB (Delta E)
    /// - Perceptual color space (dựa trên cảm nhận con người)
    /// - Chính xác hơn HSV rất nhiều!
    /// - ADAPTIVE THRESHOLD: Tự động điều chỉnh ngưỡng dựa trên độ sáng
    int _snapToRubikColor(int r, int g, int b) {
      // Chuyển RGB sang CIELAB
      final testLab = LabColor.fromRgb(r, g, b);
      
      // Tính độ sáng để adaptive threshold
      final brightness = (r + g + b) / 3.0;
      
      // ADAPTIVE THRESHOLD: Điều chỉnh ngưỡng dựa trên dữ liệu thực tế
      double maxDeltaE;
      if (brightness > 180) {
        maxDeltaE = 45.0; // Màu rất sáng (trắng/vàng) - ngưỡng cao
      } else if (brightness > 140) {
        maxDeltaE = 40.0; // Màu sáng (cam/vàng nhạt) - ngưỡng trung bình
      } else if (brightness > 100) {
        maxDeltaE = 35.0; // Màu trung bình (xanh lá/đỏ) - ngưỡng thấp
      } else if (brightness > 80) {
        maxDeltaE = 50.0; // Màu tối vừa - TĂNG ngưỡng để nhận diện tốt hơn
      } else if (brightness > 60) {
        maxDeltaE = 70.0; // Màu tối - TĂNG ngưỡng để nhận diện tốt hơn
      } else if (brightness > 40) {
        maxDeltaE = 100.0; // Màu rất tối - TĂNG ngưỡng để nhận diện tốt hơn
      } else {
        maxDeltaE = 130.0; // Màu cực tối - TĂNG ngưỡng để nhận diện tốt hơn
      }
      
      // DYNAMIC THRESHOLD: Điều chỉnh ngưỡng dựa trên dữ liệu thực tế
      // Nếu màu cam (RGB có R>G>B và R>150) thì tăng ngưỡng
      if (r > 150 && r > g && g > b && (r - g) > 20) {
        maxDeltaE = 55.0; // Màu cam cần ngưỡng rất cao
      }
      
      // Nếu màu xanh lá (RGB có G>R và G>B) thì tăng ngưỡng
      if (g > r && g > b && g > 80) {
        maxDeltaE = 60.0; // Màu xanh lá cần ngưỡng rất cao
      }
      
      // Nếu màu trắng/xám (RGB gần bằng nhau và sáng) thì tăng ngưỡng
      if (r > 160 && g > 160 && b > 160 && 
          (r - g).abs() < 10 && (g - b).abs() < 10 && (r - b).abs() < 10) {
        maxDeltaE = 65.0; // Màu trắng/xám cần ngưỡng rất cao
      }
      
      // Nếu màu hồng/magenta (RGB có R>B và G<B) thì tăng ngưỡng
      if (r > 150 && r > b && g < b && (r - g) > 30) {
        maxDeltaE = 60.0; // Màu hồng/magenta cần ngưỡng rất cao
      }
      
      // Tìm màu gần nhất trong colorAnchors
      String bestKey = 'W';
      double bestDist = double.infinity;
      
      colorAnchors.forEach((key, anchorLab) {
        final dist = testLab.distanceTo(anchorLab);
        if (dist < bestDist) {
          bestDist = dist;
          bestKey = key;
        }
      });
      
             // Nếu Delta E quá cao, thử fallback logic
             if (bestDist > maxDeltaE) {
               // ENHANCED FALLBACK LOGIC: Dựa trên RGB pattern + CIELAB
               if (r > 150 && r > g && g > b && (r - g) > 20) {
                 bestKey = 'O'; // Màu cam rõ ràng
               } else if (g > 100 && g > r && g > b) {
                 bestKey = 'G'; // Màu xanh lá rõ ràng
               } else if (b > 100 && b > r && b > g) {
                 bestKey = 'B'; // Màu xanh dương rõ ràng
               } else if (r > 100 && r > g && r > b) {
                 bestKey = 'R'; // Màu đỏ rõ ràng
               } else if (r > 200 && g > 200 && b < 100) {
                 bestKey = 'Y'; // Màu vàng rõ ràng
               } else if (g > 80 && g > r && g > b && (g - r) > 10) {
                 // Xanh lá nhạt - cần ngưỡng thấp hơn
                 bestKey = 'G';
               } else if (r > 160 && g > 160 && b > 160 && 
                          (r - g).abs() < 15 && (g - b).abs() < 15 && (r - b).abs() < 15) {
                 // Trắng/xám - cần ngưỡng thấp hơn
                 bestKey = 'W';
               } else if (r > 150 && r > b && g < b && (r - g) > 30) {
                 // Hồng/magenta - cần ngưỡng thấp hơn
                 bestKey = 'R';
               } else if (r > 150 && r > g && g > b && (r - g) > 20) {
                 // Cam nhạt - cần ngưỡng thấp hơn
                 bestKey = 'O';
               } else if (brightness < 80) {
                 // Màu tối - ưu tiên màu gần nhất dựa trên hue và RGB pattern
                 final hue = atan2(b - g, r - g) * 180 / pi;
                 
                 // Kiểm tra RGB pattern trước
                 if (r > g && r > b && (r - g) > 10) {
                   bestKey = 'R'; // Đỏ/Cam
                 } else if (g > r && g > b && (g - r) > 10) {
                   bestKey = 'G'; // Xanh lá
                 } else if (b > r && b > g && (b - r) > 10) {
                   bestKey = 'B'; // Xanh dương
                 } else if (r > 100 && g > 100 && b < 80) {
                   bestKey = 'Y'; // Vàng
                 } else if (r > 120 && g > 80 && b < 80) {
                   bestKey = 'O'; // Cam
                 } else {
                   // Fallback dựa trên hue
                   if (hue >= -30 && hue <= 30) {
                     bestKey = 'R'; // Đỏ/Cam
                   } else if (hue >= 30 && hue <= 90) {
                     bestKey = 'Y'; // Vàng
                   } else if (hue >= 90 && hue <= 150) {
                     bestKey = 'G'; // Xanh lá
                   } else if (hue >= 150 || hue <= -150) {
                     bestKey = 'B'; // Xanh dương
                   } else {
                     bestKey = 'W'; // Trắng/Xám
                   }
                 }
               } else {
                 bestKey = 'W'; // Fallback về trắng
               }
             }
      
      // Map key → RGB output (sử dụng màu thực tế từ dữ liệu)
      const colorMap = {
        'W': 0xADADAD, // Trắng xám (173,173,173)
        'G': 0x5E9041, // Xanh lá (94,144,65)
        'R': 0xC85081, // Hồng/Magenta (200,80,129)
        'Y': 0xB6A73A, // Vàng (182,167,58)
        'B': 0x458BAE, // Xanh dương (69,139,174)
        'O': 0xBE5C33, // Cam (190,92,51)
      };
      
      return colorMap[bestKey] ?? 0xFFFFFF;
    }
    
    int donutMedian(int x0, int y0, int x1, int y1, int cellIdx) {
      // TĂNG từ 25% -> 35% để CHỈ lấy tâm sticker, tránh viền đen hoàn toàn
      final dx = ((x1 - x0) * 0.35).toInt();
      final dy = ((y1 - y0) * 0.35).toInt();
      x0 += dx;
      y0 += dy;
      x1 -= dx;
      y1 -= dy;

      final rs = <int>[], gs = <int>[], bs = <int>[];
      // Giảm sampling để tăng tốc (từ +=1 -> +=2)
      for (int y = y0; y < y1; y += 2) {
        for (int x = x0; x < x1; x += 2) {
          try {
            final packed = yuvAt(x, y);
            final yy = packed & 0xFF;
            final uu = (packed >> 8) & 0xFF;
            final vv = (packed >> 16) & 0xFF;
            final rgb = yuv2rgb(yy, uu, vv);
            
            final r = (rgb >> 16) & 0xFF;
            final g = (rgb >> 8) & 0xFF;
            final b = rgb & 0xFF;
            
            // FILTER DUY NHẤT: Loại bỏ pixel ĐEN THUẦN (không phải màu Rubik)
            // Brightness = max(R,G,B), chỉ loại bỏ pixel CỰC TỐI (< 30)
            final brightness = r > g ? (r > b ? r : b) : (g > b ? g : b);
            if (brightness < 30) continue; // ĐEN THUẦN -> bỏ
            
            // ✅ ĐÃ BỎ Saturation filter - chấp nhận TẤT CẢ màu nhạt
            // Lý do: Snap color sẽ lo việc phân loại chính xác sau
            
            rs.add(r);
            gs.add(g);
            bs.add(b);
          } catch (_) {
            // Skip invalid pixels
          }
        }
      }
      
              if (rs.isEmpty) {
                // CHỈ log cho center cell (4) để tránh spam
                if (cellIdx == 4) {
                  print('⚠️ [CameraScanner] Center cell: NO valid pixels (lighting too poor)');
                }
                return 0x808080; // gray fallback
              }
      
      // Dùng MEDIAN thay vì mean để chống nhiễu tốt hơn
      rs.sort();
      gs.sort();
      bs.sort();
      int m(List<int> a) => a[a.length >> 1];
      
      int r = m(rs);
      int g = m(gs);
      int b = m(bs);
      
      // ========== SNAP TO 6 RUBIK COLORS ==========
      // Force snap màu về 6 màu Rubik chuẩn (loại bỏ nâu/xám/đen)
      final snapped = _snapToRubikColor(r, g, b);
      
      // Debug log cho ô tâm (index 4) - SHOW CIELAB + ADAPTIVE THRESHOLD
      if (cellIdx == 4) {
        final lab = LabColor.fromRgb(r, g, b);
        final brightness = (r + g + b) / 3.0;
        
        // Tính adaptive threshold
        double maxDeltaE;
        if (brightness > 200) {
          maxDeltaE = 40.0;
        } else if (brightness > 150) {
          maxDeltaE = 35.0;
        } else if (brightness > 100) {
          maxDeltaE = 30.0;
        } else {
          maxDeltaE = 25.0;
        }
        
        // Tìm key màu đã snap
        String snappedKey = 'W';
        final snappedLab = LabColor.fromRgb((snapped>>16)&0xFF, (snapped>>8)&0xFF, snapped&0xFF);
        double minDist = double.infinity;
        colorAnchors.forEach((key, anchorLab) {
          final d = snappedLab.distanceTo(anchorLab);
          if (d < minDist) {
            minDist = d;
            snappedKey = key;
          }
        });
        
        // Tính Delta E đến màu đã chọn
        final deltaE = lab.distanceTo(colorAnchors[snappedKey]!);
        final threshold = deltaE > maxDeltaE ? '❌' : '✅';
        final fallback = deltaE > maxDeltaE ? ' (FALLBACK)' : '';
        
        print('🎨 [CIELAB] RGB($r,$g,$b) → $lab → [$snappedKey] ΔE=${deltaE.toStringAsFixed(1)}/${maxDeltaE.toStringAsFixed(0)} $threshold$fallback → RGB(${(snapped>>16)&0xFF},${(snapped>>8)&0xFF},${snapped&0xFF})');
      }
      
      return snapped;
    }

    final out = <int>[];
    int cellIdx = 0;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final x0 = pad + c * cell;
        final y0 = pad + r * cell;
        final x1 = x0 + cell;
        final y1 = y0 + cell;
        out.add(donutMedian(x0, y0, x1, y1, cellIdx));
        cellIdx++;
      }
    }
    return out;
  }

  // Ảnh chụp final (dùng khi người dùng ấn CHỤP)
  Future<CapturedFace> captureOnce() async {
    // Lấy 3 khung liên tiếp từ stream cho ổn định
    final accum = <List<int>>[];
    for (int i = 0; i < 3; i++) {
      final completer = Completer<List<int>>();
      await startPreviewStream((rgb9) {
        if (!completer.isCompleted) completer.complete(rgb9);
      }, interval: const Duration(milliseconds: 1));
      final rgb = await completer.future;
      await stopPreviewStream();
      accum.add(rgb);
      await Future.delayed(const Duration(milliseconds: 40));
    }
    final out = <int>[];
    for (int i = 0; i < 9; i++) {
      final xs = [accum[0][i], accum[1][i], accum[2][i]]..sort();
      out.add(xs[1]);
    }
    return CapturedFace(out);
  }
}

