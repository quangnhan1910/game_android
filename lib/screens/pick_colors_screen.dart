import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cube_models.dart';
import '../providers/cube_provider.dart';
import 'widgets.dart';

class PickColorsScreen extends ConsumerStatefulWidget {
  const PickColorsScreen({super.key});
  @override
  ConsumerState<PickColorsScreen> createState() => _PickColorsScreenState();
}

class _PickColorsScreenState extends ConsumerState<PickColorsScreen> {
  int _face = 0; // 0..5
  List<String> _tmp = [];
  String? _selectedColor; // Màu đã chọn để tô

  @override
  void initState() {
    super.initState();
    final s = ref.read(cubeProvider).stickers;
    _tmp = List<String>.from(s);
  }

  List<String> _getFace9(int face) => _tmp.sublist(face*9, face*9+9);

  void _selectColor(String color) {
    setState(() {
      _selectedColor = color;
    });
  }

  void _paintCell(int globalIndex) {
    if (_selectedColor != null) {
      // Kiểm tra xem có phải ô trung tâm không (ô ở giữa mỗi mặt)
      final faceIndex = globalIndex ~/ 9;
      final positionInFace = globalIndex % 9;
      final isCenterSticker = positionInFace == 4; // Ô trung tâm là vị trí 4 (0-8)
      
      if (isCenterSticker) {
        // Ô trung tâm không thể thay đổi màu
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể thay đổi màu ô trung tâm!'),
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 1500),
          ),
        );
        return;
      }
      
      // Cập nhật ký hiệu của ô với màu đã chọn
      _tmp[globalIndex] = _selectedColor!;
      setState(() {});
      
      // Hiển thị thông báo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã tô màu $_selectedColor vào ô ${globalIndex + 1}'),
          duration: const Duration(milliseconds: 1000),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final names = ['U (Trắng)','R (Đỏ)','F (Xanh lá)','D (Vàng)','L (Cam)','B (Xanh dương)'];
    final start = _face * 9;
    final face9 = _getFace9(_face);
    final isValid = _isValidConfiguration();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập cấu hình Rubik'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hướng dẫn sử dụng
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '1. Chọn màu từ bảng màu bên dưới\n2. Chạm vào ô vuông để tô màu đã chọn\n3. Ô trung tâm (giữa) không thể thay đổi\n4. Mỗi màu phải có đúng 9 sticker',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Chọn mặt
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chọn mặt cần nhập:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _face,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: List.generate(6, (i) => DropdownMenuItem(
                        value: i, 
                        child: Row(
                          children: [
                            Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                color: Color(faceColorMap[validColors[i]]!),
                                border: Border.all(color: Colors.black54),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(names[i]),
                          ],
                        ),
                      )),
                      onChanged: (v) => setState(() => _face = v ?? 0),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Lưới 3x3
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mặt ${names[_face]} (3×3):',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: SizedBox(
                        width: 300,
                        height: 300,
                        child: FaceGrid(
                          face9: face9,
                          onTap: (i) => _paintCell(start + i),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Bảng màu
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Bảng màu:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (_selectedColor != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(faceColorMap[_selectedColor!]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Đã chọn: $_selectedColor',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: validColors.map((c) => GestureDetector(
                        onTap: () => _selectColor(c),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color(faceColorMap[c]!),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedColor == c ? Colors.blue : Colors.black54,
                              width: _selectedColor == c ? 3 : 2,
                            ),
                          ),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedColor != null 
                          ? 'Màu $_selectedColor đã chọn. Chạm vào ô vuông để tô màu này.'
                          : 'Chọn màu từ bảng trên, sau đó chạm vào ô vuông để tô',
                      style: TextStyle(
                        fontSize: 12,
                        color: _selectedColor != null ? Colors.green.shade700 : Colors.grey.shade600,
                        fontWeight: _selectedColor != null ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Trạng thái validation
            Card(
              color: isValid ? Colors.green.shade50 : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      isValid ? Icons.check_circle : Icons.error,
                      color: isValid ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isValid 
                            ? 'Cấu hình hợp lệ - Sẵn sàng để giải!'
                            : 'Cấu hình chưa hợp lệ - Mỗi màu phải có đúng 9 sticker',
                        style: TextStyle(
                          color: isValid ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Nút hành động
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _tmp = List<String>.from([
                        ...List.generate(9, (i) => 'U'),
                        ...List.generate(9, (i) => 'R'),
                        ...List.generate(9, (i) => 'F'),
                        ...List.generate(9, (i) => 'D'),
                        ...List.generate(9, (i) => 'L'),
                        ...List.generate(9, (i) => 'B'),
                      ]);
                      setState(() {});
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      for (int f=0; f<6; f++) {
                        ref.read(cubeProvider.notifier).setFace(f, _tmp.sublist(f*9, f*9+9));
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Đã lưu cấu hình 6 mặt'),
                          action: SnackBarAction(
                            label: 'Xem giải',
                            onPressed: () => Navigator.pushNamed(context, '/solve'),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Lưu & Giải'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  bool _isValidConfiguration() {
    final counts = <String, int>{};
    for (final s in _tmp) {
      counts[s] = (counts[s] ?? 0) + 1;
    }
    const need = ['U','R','F','D','L','B'];
    return need.every((c) => counts[c] == 9);
  }
  
  
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hướng dẫn sử dụng'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Chọn mặt cần nhập từ dropdown'),
              SizedBox(height: 8),
              Text('2. Chọn màu từ bảng màu bên dưới'),
              SizedBox(height: 8),
              Text('3. Chạm vào ô vuông để tô màu đã chọn'),
              SizedBox(height: 8),
              Text('4. Ô trung tâm (giữa) không thể thay đổi'),
              SizedBox(height: 8),
              Text('5. Lặp lại bước 2-3 cho các ô khác'),
              SizedBox(height: 8),
              Text('6. Mỗi màu phải có đúng 9 sticker'),
              SizedBox(height: 8),
              Text('7. Bấm "Lưu & Giải" khi hoàn thành'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
