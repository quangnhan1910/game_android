# 🎯 HƯỚNG DẪN THUẬT TOÁN AI CARO

## 📋 Tổng quan
Game Caro vs AI sử dụng 3 mức độ khó khác nhau với các thuật toán từ đơn giản đến phức tạp.

---

## 😊 CHẾ ĐỘ DỄ (Easy Mode)

### Thuật toán: **Random với ưu tiên vị trí**
```dart
_nuocDiNgauNhienCoTrongTam()
```

### Chiến lược:
1. **Tìm kiếm**: Chỉ trong phạm vi tâm bàn cờ (bán kính 4)
2. **Lựa chọn**: Ngẫu nhiên từ các ô trống trong phạm vi
3. **Fallback**: Nếu không có ô trống trong tâm → tìm toàn bàn cờ
4. **Đặc điểm**: 
   - Không có logic thông minh
   - Dễ đoán và dễ thắng
   - Tốc độ: ~50ms

### Code logic:
```dart
// Tìm ô trống trong phạm vi tâm
for (int r = tam - 4; r <= tam + 4; r++) {
  for (int c = tam - 4; c <= tam + 4; c++) {
    if (_banCo[r][c] == 0) trong.add(_Cap(r, c));
  }
}
// Chọn ngẫu nhiên
trong.shuffle();
return trong.first;
```

---

## 😐 CHẾ ĐỘ TRUNG BÌNH (Medium Mode)

### Thuật toán: **Heuristic với Pattern Recognition**
```dart
_nuocDiTrungBinhCaiTien()
```

### Chiến lược:
1. **Tìm kiếm**: Phạm vi rộng (bán kính 3)
2. **Ưu tiên thắng ngay**: Tìm nước thắng cho máy
3. **Chặn thắng ngay**: Chặn nước thắng của người chơi
4. **Heuristic**: Đánh giá điểm dựa trên pattern
5. **Đặc điểm**:
   - Thông minh nhưng không quá mạnh
   - Không có minimax sâu
   - Tốc độ: ~200-500ms

### Công thức đánh giá:
```dart
final tong = diemMay * 2 - diemNguoi + thuongTam;
```
- `diemMay`: Điểm tấn công của máy
- `diemNguoi`: Điểm phòng thủ (chặn người chơi)
- `thuongTam`: Ưu tiên vị trí gần tâm

### Pattern Recognition:
- **Open-4**: Chuỗi 4 quân không bị chặn → điểm cao nhất
- **Open-3**: Chuỗi 3 quân không bị chặn → điểm cao
- **Blocked-4**: Chuỗi 4 quân bị chặn 1 đầu → điểm trung bình
- **Open-2**: Chuỗi 2 quân không bị chặn → điểm thấp

---

## 😈 CHẾ ĐỘ KHÓ (Hard Mode)

### Thuật toán: **Trung bình tăng cường + Minimax nông + Double Threat**
```dart
_nuocDiMinimaxKhoCaiTien()
```

### Chiến lược:
1. **Tìm kiếm mở rộng**: Phạm vi bán kính 4 (tăng từ 3)
2. **Thắng/chặn ngay**: Ưu tiên cao nhất
3. **Double Threat**: Chặn/tạo đe dọa kép
4. **Minimax nông**: Depth 2-3 với alpha-beta pruning
5. **Heuristic tăng cường**: Trọng số mạnh hơn trung bình
6. **Fallback thông minh**: Dựa trên thuật toán trung bình đã test

### Công thức đánh giá:
```dart
final tong = diemMay * 4 - diemNguoi * 3 + thuongTam;
```
- Trọng số tấn công: `* 4` (tăng từ `* 2` của trung bình)
- Trọng số phòng thủ: `* 3` (tăng từ `* 1` của trung bình)
- Ưu tiên tâm: `thuongTam` (giống trung bình)

### Minimax Algorithm (Nông nhưng hiệu quả):
```dart
// Depth động dựa trên số ứng viên
final depth = top.length <= 4 ? 3 : 2;

// Alpha-Beta Pruning với Iterative Deepening
int minimaxIterativeDeepening(int nguoiDangXet, int doSau, int alpha, int beta, int soUngVien, int maxDepth) {
  if (doSau >= maxDepth) {
    return danhGiaOTaiViTri(r, c, 2) - danhGiaOTaiViTri(r, c, 1);
  }
  
  if (nguoiDangXet == 2) { // MAX (máy)
    int best = -∞;
    for (move in topCandidates) {
      val = minimaxIterativeDeepening(1, doSau + 1, alpha, beta, soUngVien, maxDepth);
      best = max(best, val);
      alpha = max(alpha, best);
      if (beta <= alpha) break; // Alpha-Beta pruning
    }
    return best;
  } else { // MIN (người chơi)
    int best = +∞;
    for (move in topCandidates) {
      val = minimaxIterativeDeepening(2, doSau + 1, alpha, beta, soUngVien, maxDepth);
      best = min(best, val);
      beta = min(beta, best);
      if (beta <= alpha) break; // Alpha-Beta pruning
    }
    return best;
  }
}
```

### Double Threat Detection:
```dart
// Chặn double threat của người chơi
_timNuocChanDoubleThreat() {
  for (move in candidates) {
    _banCo[r][c] = 1; // Giả định người chơi đi
    if (có_2_cửa_thắng_cùng_lúc) return move;
    _banCo[r][c] = 0;
  }
}

// Tạo double threat cho máy
_timNuocTaoDoubleThreat() {
  for (move in candidates) {
    _banCo[r][c] = 2; // Giả định máy đi
    if (có_2_cửa_thắng_cùng_lúc) return move;
    _banCo[r][c] = 0;
  }
}
```

---

## 🧮 HỆ THỐNG ĐÁNH GIÁ PATTERN

### Score Function (từ Python code):
```dart
int _winningSituation(Map<int, int> sumcol) {
  if (sumcol[5]! > 0) return 5; // Có 5 quân liên tiếp
  
  // Có 2 chuỗi 4 quân hoặc 1 chuỗi 4 quân có >=2 pattern
  if (sumcol[4]! >= 2) return 4;
  
  // Kiểm tra TF34score: có 4 quân và >=2 chuỗi 3 quân
  if (_tf34Score(sumcol[3]!, sumcol[4]!)) return 4;
  
  // Có >=2 chuỗi 3 quân
  if (sumcol[3]! >= 2) return 3;
  
  return 0;
}
```

### Bảng điểm Pattern:
| Pattern | Điểm | Mô tả |
|---------|------|-------|
| 5 quân liên tiếp | 200,000 | Thắng ngay |
| Open-4 | 15,000 | 4 quân không bị chặn |
| Blocked-4 | 4,000 | 4 quân bị chặn 1 đầu |
| Open-3 | 3,000 | 3 quân không bị chặn |
| Blocked-3 | 600 | 3 quân bị chặn 1 đầu |
| Open-2 | 200 | 2 quân không bị chặn |
| Blocked-2 | 50 | 2 quân bị chặn 1 đầu |
| Single | 8 | 1 quân |

---

## ⚡ TỐI ƯU HÓA HIỆU SUẤT

### Async Processing:
```dart
void _nuocDiMay() {
  Future.delayed(const Duration(milliseconds: 100), () async {
    final diem = await _timNuocDiMayAsync(_doKho);
    // Cập nhật UI
  });
}
```

### Timeout Protection:
```dart
return await Future.any([
  Future.delayed(const Duration(seconds: 2), () => null), // timeout
  Future(() => calculateMove()),
]);
```

### Move Ordering (Tăng cường):
```dart
// Sắp xếp ứng viên theo điểm đánh giá tăng cường
ds.sort((a, b) {
  final db = danhGiaOTaiViTri(b.item1, b.item2, 2) * 4 - danhGiaOTaiViTri(b.item1, b.item2, 1) * 3;
  final da = danhGiaOTaiViTri(a.item1, a.item2, 2) * 4 - danhGiaOTaiViTri(a.item1, a.item2, 1) * 3;
  return db.compareTo(da);
});
```

### Candidate Pruning (Tối ưu):
```dart
// Chỉ xét top ứng viên tốt nhất để minimax hiệu quả
final int k = ds.length > 8 ? 8 : ds.length;
final top = ds.take(k).toList();
```

---

## 📊 SO SÁNH HIỆU SUẤT

| Chế độ | Tốc độ | Độ sâu | Pattern | Minimax | Double Threat | Heuristic |
|--------|--------|--------|---------|---------|---------------|-----------|
| Dễ | ~50ms | 0 | Không | Không | Không | Random |
| Trung bình | ~200-500ms | 0 | Cơ bản | Không | Không | 2 vs 1 |
| Khó | ~300-800ms | 2-3 | Nâng cao | Có | Có | 4 vs 3 |

---

## 🎯 KẾT LUẬN

### Điểm mạnh của thuật toán:
- ✅ **Phân cấp rõ ràng**: Dễ < Trung bình < Khó (tăng cường)
- ✅ **Ổn định**: Dựa trên thuật toán đã test
- ✅ **Tối ưu hiệu suất**: Async, timeout, pruning
- ✅ **Pattern recognition**: Nhận dạng đe dọa chính xác
- ✅ **Alpha-Beta pruning**: Cắt tỉa hiệu quả
- ✅ **Move ordering**: Sắp xếp ứng viên thông minh
- ✅ **Double threat detection**: Phát hiện đe dọa kép

### Công nghệ sử dụng:
- **Minimax Algorithm** với Alpha-Beta Pruning (depth 2-3)
- **Heuristic Evaluation** với Pattern Recognition (4 vs 3)
- **Move Ordering** và Candidate Pruning (top 8)
- **Async Processing** để tránh block UI
- **Timeout Protection** để đảm bảo phản hồi
- **Iterative Deepening** cho minimax hiệu quả

---

*Tài liệu này mô tả chi tiết các thuật toán AI được sử dụng trong Game Caro vs AI. Mỗi chế độ có độ phức tạp và hiệu suất khác nhau phù hợp với từng mức độ người chơi.*
