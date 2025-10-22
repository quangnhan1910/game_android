import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/cube_provider.dart';
import '../../models/rubik/cube_solvers.dart';
import 'widgets.dart';

class SolveScreen extends ConsumerStatefulWidget {
  const SolveScreen({super.key});
  @override
  ConsumerState<SolveScreen> createState() => _SolveScreenState();
}

class _SolveScreenState extends ConsumerState<SolveScreen> {
  List<String> _moves = [];
  int _step = 0;
  String? _error;
  bool _loading = false;

  Future<void> _runSolve() async {
    setState(() { _error = null; _loading = true; _moves = []; _step = 0; });
    try {
      final cube = ref.read(cubeProvider);
      // Gọi async trên isolate
      final res = await solveCubeAsync(cube);
      if (!mounted) return;
      setState(() { _moves = res; _step = 0; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _moves.length;
    final cube = ref.watch(cubeProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hướng dẫn giải Rubik'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
            tooltip: 'Về trang chủ',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runSolve, // Recalculate solution
            tooltip: 'Tính lại lời giải',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hiển thị cấu hình khối Rubik
            const Text(
              'Cấu hình khối Rubik hiện tại:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            CubeNet(stickers: cube.stickers),
            const SizedBox(height: 16),
            
            // Trạng thái validation
            Row(
              children: [
                Icon(
                  cube.isColorCountValid() ? Icons.check_circle : Icons.error,
                  color: cube.isColorCountValid() ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  cube.isColorCountValid() ? 'Cấu hình hợp lệ' : 'Cấu hình không hợp lệ',
                  style: TextStyle(
                    color: cube.isColorCountValid() ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Nút hành động
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
                        icon: const Icon(Icons.home),
                        label: const Text('Về trang chủ'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref.read(cubeProvider.notifier).resetSolved();
                          setState(() {
                            _moves = [];
                            _step = 0;
                            _error = null;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã reset về trạng thái ban đầu')),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Làm mới'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: cube.isColorCountValid() && !_loading ? _runSolve : null,
                    icon: _loading 
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_loading ? 'Đang tính toán...' : 'Tính lời giải'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Hiển thị lỗi
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Hiển thị kết quả
            if (!_loading && total > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Hoàn thành! Tìm thấy $total bước giải',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bước hiện tại: ${_step + 1} / $total → ${_moves[_step]}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: _step > 0 ? () => setState(() => _step--) : null,
                          child: const Text('Bước trước'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: _step < total - 1 ? () => setState(() => _step++) : null,
                          child: const Text('Bước tiếp'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Hiển thị tất cả các bước
              const Text(
                'Tất cả các bước:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _moves.asMap().entries.map((entry) {
                  final index = entry.key;
                  final move = entry.value;
                  return Chip(
                    label: Text(move),
                    backgroundColor: _step == index ? Colors.blue.shade100 : null,
                    onDeleted: _step == index ? null : () => setState(() => _step = index),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}