import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/rubik/color_calibration.dart';
import '../../services/camera_scanner.dart';
import '../../providers/cube_provider.dart';

const _order = ['U', 'R', 'F', 'D', 'L', 'B'];

class ScanFacesScreen extends ConsumerStatefulWidget {
  const ScanFacesScreen({super.key});
  @override
  ConsumerState<ScanFacesScreen> createState() => _ScanFacesScreenState();
}

class _ScanFacesScreenState extends ConsumerState<ScanFacesScreen> {
  List<CameraDescription>? _cams;
  CameraScanner? _scanner;
  int _idx = 0;
  bool _busy = false;
  bool _permissionDenied = false;

  Map<String, int>? _centerRGB; // U,R,F,D,L,B -> center RGB
  ColorCalibration? _calib; // sau khi đủ 6 tâm
  final Map<String, List<String>> _faces = {}; // face -> 9 nhãn
  final Map<String, List<int>> _facesRGB = {}; // face -> 9 RGB gốc (để phân loại lại sau)
  
  // Realtime preview - NEW
  List<int>? _previewRgb9; // 9 RGB colors từ camera stream
  List<(String, double)>? _previewLabelsWithConf; // (label, confidence) cho mỗi ô

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    print('🟢 [DEBUG] _init() started');
    // Xin quyền camera
    final status = await Permission.camera.request();
    print('🟢 [DEBUG] Camera permission status: ${status.isGranted}');
    if (!status.isGranted) {
      if (mounted) {
        setState(() => _permissionDenied = true);
      }
      return;
    }

    final cams = await availableCameras();
    _cams = cams;
    final back = cams.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cams.first,
    );
    _scanner = CameraScanner(back);
    await _scanner!.start();
    
    // Đợi camera sẵn sàng
    await Future.delayed(const Duration(milliseconds: 500));
    
    // BẬT REALTIME PREVIEW - xem màu trực tiếp từ camera stream
    print('🔵 [DEBUG] Starting preview stream...');
    DateTime _lastLog = DateTime.fromMillisecondsSinceEpoch(0);
    await _scanner!.startPreviewStream((rgb9) {
      if (!mounted) return;
      _previewRgb9 = rgb9;
      
      if (_calib != null) {
        // Phân loại màu với calibration
        final labs = <(String, double)>[];
        for (final rgb in rgb9) {
          labs.add(_calib!.classifyWithConfidence(rgb));
        }
        _previewLabelsWithConf = labs;
        
        // Log 1 lần/giây thôi để tránh spam
        if (DateTime.now().difference(_lastLog).inSeconds >= 1) {
          print('✅ [DEBUG] Preview updated (with calibration): ${labs[4]}');
          _lastLog = DateTime.now();
        }
              } else {
                // Trong giai đoạn calibration: Hiển thị màu đã snap (RGB từ camera đã qua _snapToRubikColor)
                // Dùng confidence = 1.0 để hiển thị màu đã snap
                final labs = <(String, double)>[];
                for (int i = 0; i < 9; i++) {
                  labs.add(('?', 1.0)); // conf = 1.0 -> hiển thị màu đã snap
                }
                _previewLabelsWithConf = labs;
        
        // Log 1 lần/giây thôi để tránh spam
        if (DateTime.now().difference(_lastLog).inSeconds >= 1) {
          print('✅ [DEBUG] Preview (calibration): showing SNAPPED RGB colors');
          _lastLog = DateTime.now();
        }
      }
      
      setState(() {}); // Cập nhật UI realtime
    });
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _scanner?.stopPreviewStream();
    _scanner?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_scanner == null) return;
    setState(() => _busy = true);
    try {
      // Lấy RGB từ preview hoặc chụp
      if (_previewRgb9 == null || _previewRgb9!.length != 9) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ Giữ cố định, đợi camera scan...')),
          );
        }
        setState(() => _busy = false);
        return;
      }

      // 1) Phân loại màu (dùng calibration nếu có, hoặc RGB gốc)
      final labels = <String>[];
      bool lowConfidence = false;
      double avgConfidence = 0.0;

      if (_calib == null) {
        // CHƯA calibrate: Lưu center RGB để calibrate sau khi đủ 6 mặt
        _centerRGB ??= {};
        _centerRGB![_order[_idx]] = _previewRgb9![4]; // ô tâm
        
        // SỬA: Trong giai đoạn calibration, dùng màu đã snap từ camera
        // Thay vì '?', dùng màu thực tế đã được snap
        for (int i = 0; i < 9; i++) {
          final rgb = _previewRgb9![i];
          // Chuyển RGB thành màu Rubik dựa trên màu đã snap
          final snappedColor = _convertRgbToRubikColor(rgb);
          labels.add(snappedColor);
        }
        
        // Ép ô tâm đúng nhãn mặt hiện tại (tránh nhiễu trong calibration)
        labels[4] = _order[_idx];
      } else {
        // ĐÃ calibrate: Phân loại màu chính xác
        for (int i = 0; i < 9; i++) {
          final (lab, conf) = _calib!.classifyWithConfidence(_previewRgb9![i]);
          labels.add(lab);
          avgConfidence += conf;
          if (conf < 0.55) lowConfidence = true; // ngưỡng confidence
        }
        avgConfidence /= 9;
        
        // CHỈ cảnh báo nếu confidence thấp, KHÔNG chặn lưu
        if (lowConfidence) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '⚠️ Ánh sáng chưa ổn (avg ${(avgConfidence * 100).toStringAsFixed(0)}%). Kiểm tra kỹ trước khi giải!',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }

      // Ép ô tâm đúng nhãn mặt hiện tại (tránh nhiễu) - chỉ khi đã calibrate
      if (_calib != null) {
        labels[4] = _order[_idx];
      }

      // 2) Lưu RGB gốc và labels tạm thời
      _facesRGB[_order[_idx]] = List<int>.from(_previewRgb9!);
      _faces[_order[_idx]] = labels;

      // 3) Kiểm tra xem đã scan đủ 6 mặt chưa (để tạo calibration)
      if (_calib == null && _centerRGB!.length == 6 && _facesRGB.length == 6) {
        // Tạo calibration từ 6 centers
        _calib = ColorCalibration.fromCenters(
          up: _centerRGB!['U']!,
          right: _centerRGB!['R']!,
          front: _centerRGB!['F']!,
          down: _centerRGB!['D']!,
          left: _centerRGB!['L']!,
          back: _centerRGB!['B']!,
        );
        
        // QUAN TRỌNG: Phân loại lại TẤT CẢ 6 mặt đã scan với calibration mới
        for (final face in _order) {
          final rgbs = _facesRGB[face]!;
          final newLabels = <String>[];
          
          for (int i = 0; i < 9; i++) {
            final (lab, _) = _calib!.classifyWithConfidence(rgbs[i]);
            newLabels.add(lab);
          }
          
          // Ép tâm đúng
          newLabels[4] = face;
          _faces[face] = newLabels;
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã calibrate và phân loại lại 6 mặt thành công!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        // GOM tất cả 54 stickers và lưu vào cubeProvider
        final stickers = <String>[];
        for (final f in _order) {
          stickers.addAll(_faces[f]!);
        }
        ref.read(cubeProvider.notifier).setStickers(stickers);
        
        // Quay về màn hình trước
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Đã nhập 6 mặt từ camera (URFDLB).')),
          );
        }
        
        setState(() => _busy = false);
        return; // Kết thúc sau khi scan đủ 6 mặt
      }
      
      if (_idx < 5) {
        setState(() {
          _idx++;
          _previewLabelsWithConf = null; // Reset preview
        });
      } else {
        // Hoàn thành 6 mặt
        final stickers = <String>[];
        for (final f in _order) {
          stickers.addAll(_faces[f]!);
        }
        ref.read(cubeProvider.notifier).setStickers(stickers);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã nhập 6 mặt từ camera (URFDLB).')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi chụp: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Chuyển RGB đã snap thành màu Rubik label
  String _convertRgbToRubikColor(int rgb) {
    final r = (rgb >> 16) & 0xFF;
    final g = (rgb >> 8) & 0xFF;
    final b = rgb & 0xFF;
    
    // Map RGB đã snap thành màu Rubik
    // Dựa trên colorMap trong camera_scanner.dart
    if (r == 173 && g == 173 && b == 173) return 'U'; // Trắng xám
    if (r == 94 && g == 144 && b == 65) return 'F';   // Xanh lá
    if (r == 200 && g == 80 && b == 129) return 'R';  // Hồng/Magenta
    if (r == 182 && g == 167 && b == 58) return 'D';  // Vàng
    if (r == 69 && g == 139 && b == 174) return 'B';  // Xanh dương
    if (r == 190 && g == 92 && b == 51) return 'L';   // Cam
    
    // Fallback: Dựa trên độ sáng
    final brightness = (r + g + b) / 3.0;
    if (brightness > 150) return 'U'; // Sáng -> Trắng
    if (brightness < 80) return 'B';  // Tối -> Xanh dương
    
    return 'U'; // Default
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quét 6 mặt Rubik')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Cần quyền Camera để quét Rubik',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  await openAppSettings();
                },
                icon: const Icon(Icons.settings),
                label: const Text('Mở cài đặt'),
              ),
            ],
          ),
        ),
      );
    }

    final cam = _scanner?.controller;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét 6 mặt Rubik'),
        actions: [
          IconButton(
            tooltip: 'Reset',
            onPressed: () => setState(() {
              _idx = 0;
              _busy = false;
              _faces.clear();
              _facesRGB.clear();
              _calib = null;
              _centerRGB = null;
              _previewLabelsWithConf = null;
              _previewRgb9 = null;
            }),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: (cam == null || !cam.value.isInitialized)
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CameraPreview(cam),
                _GridOverlay(
                  faceName: _order[_idx],
                  labels: _previewLabelsWithConf,
                  previewRgb: _previewRgb9, // Truyền RGB thực tế từ camera
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Hint(
                        face: _order[_idx],
                        calib: _calib,
                        avgConf: _previewLabelsWithConf == null
                            ? null
                            : _previewLabelsWithConf!
                                    .map((e) => e.$2)
                                    .reduce((a, b) => a + b) /
                                9,
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _busy ? null : _capture,
                        icon: const Icon(Icons.save),
                        label: Text(_busy
                            ? 'Đang lưu...'
                            : 'Lưu mặt ${_order[_idx]}'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ============ Grid Overlay (CHỈ hiển thị, KHÔNG cho chạm) ============
class _GridOverlay extends StatelessWidget {
  final String faceName;
  final List<(String, double)>? labels;
  final List<int>? previewRgb; // RGB thực tế từ camera (9 giá trị 0xRRGGBB)

  const _GridOverlay({
    required this.faceName,
    this.labels,
    this.previewRgb, // Nhận RGB từ camera
  });

  Color colorForLabel(String l) {
    switch (l) {
      case 'U':
        return Colors.white70;
      case 'R':
        return const Color(0xFFFF3D5F); // đỏ/hồng
      case 'F':
        return Colors.greenAccent.shade400;
      case 'D':
        return Colors.yellow.shade600;
      case 'L':
        return Colors.orange.shade600;
      case 'B':
        return Colors.blue.shade600;
    }
    return Colors.grey;
  }
  
  // Chuyển RGB 0xRRGGBB thành Color
  Color rgbToColor(int rgb) {
    final r = (rgb >> 16) & 0xFF;
    final g = (rgb >> 8) & 0xFF;
    final b = rgb & 0xFF;
    return Color.fromARGB(255, r, g, b);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (_, constraints) {
          final short = min(constraints.maxWidth, constraints.maxHeight);
          final pad = short * 0.12;
          final side = short - 2 * pad;
          final left = (constraints.maxWidth - side) / 2;
          final top = (constraints.maxHeight - side) / 2;
          final cell = side / 3;

          return Stack(
            children: [
              // Grid lines
              CustomPaint(
                painter: _GridPainter(faceName),
                size: Size.infinite,
              ),
              // Display-only cells (KHÔNG có GestureDetector)
              for (int r = 0; r < 3; r++)
                for (int cc = 0; cc < 3; cc++)
                  Positioned(
                    left: left + cc * cell,
                    top: top + r * cell,
                    width: cell,
                    height: cell,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3), // Nền mờ để thấy camera
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // VÒNG TRÒN hiển thị màu thực tế
                          Container(
                            width: cell * 0.5, // 50% kích thước ô
                            height: cell * 0.5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: () {
                                final idx = r * 3 + cc;
                                if (labels == null) {
                                  return Colors.grey.withOpacity(0.5);
                                }
                                final label = labels![idx].$1;
                                
                                // LUÔN dùng màu đã snap từ camera (đã qua _snapToRubikColor)
                                if (previewRgb != null && previewRgb!.length == 9) {
                                  final color = rgbToColor(previewRgb![idx]);
                                  return color;
                                }
                                
                                // Fallback: Dùng màu theo nhãn
                                return colorForLabel(label);
                              }(),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                          // Nhãn và confidence
                          () {
                        final idx = r * 3 + cc;
                        String txt = labels == null ? '' : labels![idx].$1;
                        String conf = labels == null ? '' : '${(labels![idx].$2 * 100).toStringAsFixed(0)}%';
                        
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              txt,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            if (conf.isNotEmpty)
                              Text(
                                conf,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        );
                      }(),
                        ],
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final String faceName;

  _GridPainter(this.faceName);

  @override
  void paint(Canvas canvas, Size size) {
    final short = size.shortestSide;
    final pad = short * 0.12;
    final side = short - 2 * pad;
    final left = (size.width - side) / 2;
    final top = (size.height - side) / 2;
    final cell = side / 3;

    // Grid lines
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFFFFFFF).withOpacity(0.9);

    for (int i = 0; i <= 3; i++) {
      canvas.drawLine(
          Offset(left, top + i * cell), Offset(left + side, top + i * cell), paint);
      canvas.drawLine(
          Offset(left + i * cell, top), Offset(left + i * cell, top + side), paint);
    }

    // Border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.white.withOpacity(0.9);

    canvas.drawRect(
      Rect.fromLTWH(left, top, side, side),
      borderPaint,
    );

    // Title
    final tp = TextPainter(
      text: TextSpan(
        text: 'Mặt $faceName',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          shadows: [
            Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 3),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(left, top - 32));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Hint extends StatelessWidget {
  final String face;
  final ColorCalibration? calib;
  final double? avgConf;

  const _Hint({required this.face, this.calib, this.avgConf});

  @override
  Widget build(BuildContext context) {
    const mapVN = {
      'U': 'Trên (U)',
      'R': 'Phải (R)',
      'F': 'Trước (F)',
      'D': 'Dưới (D)',
      'L': 'Trái (L)',
      'B': 'Sau (B)'
    };
    
    final confValue = avgConf;
    final status = calib == null
        ? '🔵 Đang calibrate màu...'
        : confValue != null
            ? confValue >= 0.70
                ? '🟢 Ánh sáng tốt (${(confValue * 100).toStringAsFixed(0)}%)'
                : '🟡 Cần chỉnh ánh sáng (${(confValue * 100).toStringAsFixed(0)}%)'
            : '⚪ Đang quét...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.50),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            'Bước ${_order.indexOf(face) + 1}/6 • ${mapVN[face]}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          Text(
            status,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
