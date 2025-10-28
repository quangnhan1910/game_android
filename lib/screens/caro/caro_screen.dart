import 'dart:async';
import 'package:flutter/material.dart';

// Man hinh chinh cua tro choi Caro voi may (AI)
class ManHinhGameCaro extends StatefulWidget {
  const ManHinhGameCaro({super.key});

  @override
  State<ManHinhGameCaro> createState() => _ManHinhGameCaroState();
}

class _ManHinhGameCaroState extends State<ManHinhGameCaro> {
  static const int _kichThuoc = 15; // kich thuoc ban co 15x15 (kich thuoc chuan)
  static const int _soQuanDeThang = 5; // 5 quan lien tiep se thang

  // 0 = rong, 1 = nguoi, 2 = may
  late List<List<int>> _banCo;
  String _doKho = 'de';
  bool _daKetThuc = false;
  String _thongBao = '';
  bool _luotNguoi = true;
  bool _daBatDau = false; // chi choi sau khi chon che do va bam Bat dau

  // Timer cho giới hạn thời gian
  Timer? _timer;
  int _thoiGianConLai = 0; // thời gian còn lại (giây)

  @override
  void initState() {
    super.initState();
    khoiTaoBanCo();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // khoiTaoBanCo: tao ban co rong va reset trang thai tran dau
  // Giai tich: Ham nay khoi tao ma tran 2 chieu kich thuoc _kichThuoc x _kichThuoc voi gia tri 0 (o trong).
  // Dong thoi reset cac co bao trang thai tran dau nhu _daKetThuc, _thongBao va dat luot nguoi choi truoc.
  void khoiTaoBanCo() {
    _timer?.cancel();
    _banCo = List.generate(
      _kichThuoc,
          (_) => List.generate(_kichThuoc, (_) => 0),
    );
    _daKetThuc = false;
    _thongBao = '';
    _luotNguoi = true;
    _thoiGianConLai = 0;
    setState(() {});
  }

  // batDauSauKhiChonCheDo: bat dau van dau sau khi chon do kho
  // Giai tich: Reset ban co va cho phep tuong tac voi ban co (_daBatDau = true).
  void batDauSauKhiChonCheDo() {
    khoiTaoBanCo();
    _daBatDau = true;
    _batDauTimer(); // Bắt đầu timer cho lượt đầu tiên
    setState(() {});
  }

  // batDauTimer: bat dau dem nguoc thoi gian cho luot nguoi choi
  void _batDauTimer() {
    _timer?.cancel();

    // Chỉ bắt đầu timer nếu là lượt người chơi và chế độ khó/trung bình
    if (!_luotNguoi || _daKetThuc) return;

    if (_doKho == 'trung binh') {
      _thoiGianConLai = 30;
    } else if (_doKho == 'kho') {
      _thoiGianConLai = 15;
    } else {
      _thoiGianConLai = 0;
      return; // Chế độ dễ không có giới hạn thời gian
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_thoiGianConLai > 0) {
        setState(() {
          _thoiGianConLai--;
        });
      } else {
        // Hết thời gian - người chơi thua
        timer.cancel();
        setState(() {
          _daKetThuc = true;
          _thongBao = 'Hết giờ! Bạn Thua!';
        });
      }
    });
  }

  // dungTimer: dung timer
  void _dungTimer() {
    _timer?.cancel();
    _thoiGianConLai = 0;
  }

  // hienThiHuongDan: hien thi dialog huong dan choi
  void _hienThiHuongDan() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue.shade700, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Hướng dẫn chơi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHuongDanSection(
                '🎯 Luật chơi cơ bản',
                [
                  'Bạn (X) chơi với Máy (O)',
                  'Người chơi đi trước',
                  'Đặt 5 quân liên tiếp (ngang/dọc/chéo) để thắng',
                  'Nếu hết ô mà không ai thắng → Hòa',
                ],
              ),
              const SizedBox(height: 16),
              _buildHuongDanSection(
                '😊 Chế độ Dễ',
                [
                  'Máy đi ngẫu nhiên',
                  'Không giới hạn thời gian',
                  'Phù hợp để làm quen',
                ],
              ),
              const SizedBox(height: 16),
              _buildHuongDanSection(
                '😐 Chế độ Trung bình',
                [
                  'Máy sử dụng AI thông minh',
                  'Giới hạn thời gian: 30 giây/lượt',
                  'Hết giờ → Bạn thua',
                ],
              ),
              const SizedBox(height: 16),
              _buildHuongDanSection(
                '😈 Chế độ Khó',
                [
                  'Máy sử dụng AI siêu mạnh',
                  'Giới hạn thời gian: 15 giây/lượt',
                  'Hết giờ → Bạn thua',
                  'Thử thách cao nhất!',
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Mẹo: Tập trung vào trung tâm bàn cờ và luôn chú ý chặn đối thủ!',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Đã hiểu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // buildHuongDanSection: xay dung mot section trong huong dan
  Widget _buildHuongDanSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  // datNuocDi: dat nuoc di len ban co neu o do con trong
  // Giai tich: Nhan vao toa do (r, c) va nguoi choi (1=nguoi, 2=may). Neu o trong thi gan gia tri,
  // sau do kiem tra thang thua va chuyen luot. Tra ve true neu dat duoc nuoc di, nguoc lai false.
  bool datNuocDi(int r, int c, int nguoi) {
    if (_daKetThuc) return false;
    if (r < 0 || r >= _kichThuoc || c < 0 || c >= _kichThuoc) return false;
    if (_banCo[r][c] != 0) return false;
    _banCo[r][c] = nguoi;
    if (kiemTraThangThua(r, c, nguoi)) {
      _daKetThuc = true;
      _thongBao = nguoi == 1 ? 'Bạn Thắng!' : 'Máy Thắng!';
    } else if (kiemTraHoa()) {
      _daKetThuc = true;
      _thongBao = 'Hòa!';
    }
    return true;
  }

  // kiemTraThangThua: kiem tra nguoi vua di co thang khong
  // Giai tich: Kiem tra 4 huong chinh (ngang, doc, cheo chinh, cheo phu) xung quanh nuoc vua di.
  // Dem so quan lien tiep cua cung mot ben. Neu tong >= _soQuanDeThang thi chien thang.
  bool kiemTraThangThua(int r, int c, int nguoi) {
    const List<List<int>> huong = [
      [0, 1], // ngang
      [1, 0], // doc
      [1, 1], // cheo chinh
      [1, -1], // cheo phu
    ];
    for (final h in huong) {
      int dem = 1;
      dem += _demHuong(r, c, h[0], h[1], nguoi);
      dem += _demHuong(r, c, -h[0], -h[1], nguoi);
      if (dem >= _soQuanDeThang) return true;
    }
    return false;
  }

  // kiemTraHoa: kiem tra ban co da day chua (hoa)
  // Giai tich: Kiem tra xem con o trong nao khong. Neu khong con o trong thi hoa.
  bool kiemTraHoa() {
    for (int r = 0; r < _kichThuoc; r++) {
      for (int c = 0; c < _kichThuoc; c++) {
        if (_banCo[r][c] == 0) return false;
      }
    }
    return true;
  }

  // _demHuong: dem so quan lien tiep theo mot huong tu vi tri (r,c)
  // Giai tich: Di chuyen theo vector (dr, dc) cho den khi ra ngoai ban co hoac gap quan khac.
  int _demHuong(int r, int c, int dr, int dc, int nguoi) {
    int dem = 0;
    int i = r + dr, j = c + dc;
    while (i >= 0 && i < _kichThuoc && j >= 0 && j < _kichThuoc && _banCo[i][j] == nguoi) {
      dem++;
      i += dr;
      j += dc;
    }
    return dem;
  }

  // xuLyNguoiChoi: su kien khi nguoi choi cham vao o tren ban co
  // Giai tich: Neu den luot nguoi va o trong thi dat nuoc di, kiem tra ket thuc.
  // Neu chua ket thuc thi den luot may (AI) thuc hien tim nuoc di.
  void xuLyNguoiChoi(int r, int c) {
    if (!_daBatDau || _daKetThuc || !_luotNguoi) return;
    if (datNuocDi(r, c, 1)) {
      _dungTimer(); // Dừng timer khi người chơi đã đánh
      setState(() {});
      if (!_daKetThuc) {
        _luotNguoi = false;
        Future.delayed(const Duration(milliseconds: 150), () {
          _nuocDiMay();
        });
      }
    }
  }

  // _nuocDiMay: goi AI tim nuoc di va cap nhat ban co
  // Giai tich: Dua tren muc do kho _doKho, su dung chien luoc AI tuong ung
  // (de: ngau nhien co trong tam ban co; trung binh: heuristic chan/thang; kho: minimax gioi han).
  void _nuocDiMay() {
    if (!_daBatDau || _daKetThuc) return;

    // Chạy AI trong isolate để tránh block main thread
    Future.delayed(const Duration(milliseconds: 100), () async {
      final diem = await _timNuocDiMayAsync(_doKho);
      if (diem != null && !_daKetThuc) {
        datNuocDi(diem.item1, diem.item2, 2);
        _luotNguoi = true;
        setState(() {});
        // Bắt đầu timer cho lượt người chơi tiếp theo
        if (!_daKetThuc) {
          _batDauTimer();
        }
      }
    });
  }

  // _timNuocDiMayAsync: chạy AI trong Future để tránh block UI
  Future<_Cap?> _timNuocDiMayAsync(String doKho) async {
    try {
      // Timeout 5 giây để tránh AI tính quá lâu
      return await Future.any([
        Future.delayed(const Duration(seconds: 5), () => null), // timeout
        Future(() {
          switch (doKho) {
            case 'de':
              return _nuocDiNgauNhienCoTrongTam();
            case 'trung binh':
              return _nuocDiTrungBinhCaiTien();
            case 'kho':
              return _nuocDiMinimaxKhoCaiTien();
            default:
              return _nuocDiNgauNhienCoTrongTam();
          }
        }),
      ]);
    } catch (e) {
      // Nếu có lỗi thì dùng AI trung bình
      return _nuocDiTrungBinhCaiTien();
    }
  }

  // timNuocDiMay: chon nuoc di cho may theo do kho
  // Giai tich: Tra ve cap toa do (r,c). Cac chien luoc:
  // - de: chon o trong gan tam, uu tien o xung quanh quan da co
  // - trung binh: danh gia diem theo mau 2,3,4 lien, uu tien chan thang/tao 4
  // - kho: minimax voi do sau nho (2-3), dung ham danh gia heuristic.
  _Cap? timNuocDiMay(String doKho) {
    switch (doKho) {
      case 'de':
        return _nuocDiNgauNhienCoTrongTam();
      case 'trung binh':
        return _nuocDiTrungBinhCaiTien();
      case 'kho':
        return _nuocDiMinimaxKhoCaiTien();
      default:
        return _nuocDiNgauNhienCoTrongTam();
    }
  }

  // _nuocDiNgauNhienCoTrongTam: chon ngau nhien 1 o trong gan khu vuc tam
  // Giai tich: Lap qua cac o trong trong pham vi tam+ban kinh va chon ngau nhien tu danh sach do.
  _Cap? _nuocDiNgauNhienCoTrongTam() {
    final List<_Cap> trong = [];
    final int tam = _kichThuoc ~/ 2;
    for (int r = tam - 6; r <= tam + 6; r++) {
      for (int c = tam - 6; c <= tam + 6; c++) {
        if (r >= 0 && c >= 0 && r < _kichThuoc && c < _kichThuoc && _banCo[r][c] == 0) {
          trong.add(_Cap(r, c));
        }
      }
    }
    if (trong.isEmpty) {
      for (int r = 0; r < _kichThuoc; r++) {
        for (int c = 0; c < _kichThuoc; c++) {
          if (_banCo[r][c] == 0) trong.add(_Cap(r, c));
        }
      }
    }
    if (trong.isEmpty) return null;
    trong.shuffle();
    return trong.first;
  }

  // _nuocDiTrungBinhCaiTien: AI trung bình - tăng cường một chút
  // Giai tich: Có heuristic tốt hơn, tìm kiếm rộng hơn, nhưng vẫn không có minimax sâu
  _Cap? _nuocDiTrungBinhCaiTien() {
    final ds = _lietKeOViTienMoRong(3); // tăng bán kính từ 2 lên 3

    // 1) Tìm thắng ngay trong phạm vi rộng hơn
    for (final o in ds) {
      _banCo[o.item1][o.item2] = 2;
      final thang = kiemTraThangThua(o.item1, o.item2, 2);
      _banCo[o.item1][o.item2] = 0;
      if (thang) return o;
    }

    // 2) Chặn thắng ngay trong phạm vi rộng hơn
    for (final o in ds) {
      _banCo[o.item1][o.item2] = 1;
      final thang = kiemTraThangThua(o.item1, o.item2, 1);
      _banCo[o.item1][o.item2] = 0;
      if (thang) return o;
    }

    // 3) Heuristic tốt hơn: dùng danhGiaOTaiViTri thay vì cơ bản
    int diemTotNhat = -0x3f3f3f3f;
    _Cap? nuocTotNhat;
    final tam = _kichThuoc ~/ 2;
    for (final o in ds) {
      final diemMay = danhGiaOTaiViTri(o.item1, o.item2, 2);
      final diemNguoi = danhGiaOTaiViTri(o.item1, o.item2, 1);

      final khoangCachTam = (o.item1 - tam).abs() + (o.item2 - tam).abs();
      final thuongTam = (_kichThuoc - khoangCachTam);
      final tong = diemMay * 2 - diemNguoi + thuongTam; // tăng trọng số từ 1.5 lên 2

      if (tong > diemTotNhat) {
        diemTotNhat = tong;
        nuocTotNhat = o;
      }
    }
    return nuocTotNhat ?? _nuocDiNgauNhienCoTrongTam();
  }

  // _nuocDiMinimaxKhoCaiTien: KHÓ TĂNG CƯỜNG - Dựa trên thuật toán trung bình nhưng mạnh hơn
  // Giai tich: Thuật toán trung bình + tăng cường heuristic + mở rộng tìm kiếm
  _Cap? _nuocDiMinimaxKhoCaiTien() {
    final ds = _lietKeOViTienMoRong(4); // Tăng bán kính từ 3 lên 4

    // 1) Thắng ngay cho máy (ưu tiên cao nhất)
    for (final o in ds) {
      _banCo[o.item1][o.item2] = 2;
      final thang = kiemTraThangThua(o.item1, o.item2, 2);
      _banCo[o.item1][o.item2] = 0;
      if (thang) return o;
    }

    // 2) Chặn thắng ngay của người chơi (ưu tiên cao)
    for (final o in ds) {
      _banCo[o.item1][o.item2] = 1;
      final thang = kiemTraThangThua(o.item1, o.item2, 1);
      _banCo[o.item1][o.item2] = 0;
      if (thang) return o;
    }

    // 3) Chặn double threat (tạo 2 cửa thắng)
    final doubleThreat = _timNuocChanDoubleThreat();
    if (doubleThreat != null) return doubleThreat;

    // 4) Tạo double threat cho máy
    final taoDoubleThreat = _timNuocTaoDoubleThreat();
    if (taoDoubleThreat != null) return taoDoubleThreat;

    // 5) Minimax nông với heuristic mạnh
    final dsSorted = [...ds];
    dsSorted.sort((a, b) {
      final db = danhGiaOTaiViTri(b.item1, b.item2, 2) * 4 - danhGiaOTaiViTri(b.item1, b.item2, 1) * 3;
      final da = danhGiaOTaiViTri(a.item1, a.item2, 2) * 4 - danhGiaOTaiViTri(a.item1, a.item2, 1) * 3;
      return db.compareTo(da);
    });

    // Chỉ xét top ứng viên tốt nhất
    final int k = dsSorted.length > 8 ? 8 : dsSorted.length;
    final top = dsSorted.take(k).toList();

    int diemTotNhat = -0x3f3f3f3f;
    _Cap? nuocTotNhat;
    int alpha = -0x3f3f3f3f;
    int beta = 0x3f3f3f3f;

    for (final o in top) {
      _banCo[o.item1][o.item2] = 2;
      // Minimax nông: depth 2-3
      final depth = top.length <= 4 ? 3 : 2;
      final diem = minimaxIterativeDeepening(2, 0, alpha, beta, top.length, depth);
      _banCo[o.item1][o.item2] = 0;
      if (diem > diemTotNhat) {
        diemTotNhat = diem;
        nuocTotNhat = o;
      }
      if (diemTotNhat > alpha) alpha = diemTotNhat;
    }

    // Fallback về heuristic tăng cường
    if (nuocTotNhat == null) {
      int diemTotNhat2 = -0x3f3f3f3f;
      _Cap? nuocTotNhat2;
      final tam = _kichThuoc ~/ 2;
      for (final o in ds) {
        final diemMay = danhGiaOTaiViTri(o.item1, o.item2, 2);
        final diemNguoi = danhGiaOTaiViTri(o.item1, o.item2, 1);

        final khoangCachTam = (o.item1 - tam).abs() + (o.item2 - tam).abs();
        final thuongTam = (_kichThuoc - khoangCachTam);
        final tong = diemMay * 4 - diemNguoi * 3 + thuongTam; // TĂNG CƯỜNG: 4 vs 3

        if (tong > diemTotNhat2) {
          diemTotNhat2 = tong;
          nuocTotNhat2 = o;
        }
      }
      return nuocTotNhat2 ?? dsSorted.first;
    }

    return nuocTotNhat;
  }

  // minimaxIterativeDeepening: iterative deepening nhu KSH-AI với depth tối đa
  // Giai tich: Bat dau tu depth 2, tang dan len maxDepth. Dung alpha-beta pruning va transposition table simulation.
  int minimaxIterativeDeepening(int nguoiDangXet, int doSau, int alpha, int beta, int soUngVien, int maxDepth) {
    int bestScore = nguoiDangXet == 2 ? -0x3f3f3f3f : 0x3f3f3f3f;

    // iterative deepening: bat dau tu depth 2, tang dan len maxDepth
    for (int depth = 2; depth <= maxDepth; depth++) {
      final score = minimaxGioiHan(nguoiDangXet, doSau, depth, alpha, beta);
      if (nguoiDangXet == 2) {
        if (score > bestScore) bestScore = score;
        if (bestScore > alpha) alpha = bestScore;
      } else {
        if (score < bestScore) bestScore = score;
        if (bestScore < beta) beta = bestScore;
      }
      // neu tim thay nuoc tot thi dung lai
      if (bestScore >= beta || bestScore <= alpha) break;
    }
    return bestScore;
  }





  // Badge thời gian nhỏ đặt cạnh nút hướng dẫn
  Widget _buildSmallTimerBadge() {
    final Color bgColor = _thoiGianConLai <= 5
        ? Colors.red.shade600
        : _thoiGianConLai <= 10
        ? Colors.orange.shade600
        : Colors.blue.shade600;

    final Color shadowColor = _thoiGianConLai <= 5
        ? Colors.red
        : _thoiGianConLai <= 10
        ? Colors.orange
        : Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            '$_thoiGianConLai s',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // minimaxGioiHan: danh gia nut theo minimax voi alpha-beta
  // Giai tich: Neu den do sau hoac ket thuc tran, tra ve diem heuristic. Nguoi (1) la minimize, May (2) la maximize.
  int minimaxGioiHan(int nguoiDangXet, int doSau, int doSauToiDa, int alpha, int beta) {
    if (_daKetThuc) {
      // neu co ket thuc: uu tien thang nhanh hoac thua cham
      return _thongBao == 'Máy Thắng!'
          ? 100000 - doSau
          : _thongBao == 'Bạn Thắng!'
          ? -100000 + doSau
          : 0;
    }
    if (doSau >= doSauToiDa) {
      // dung heuristic nang cao o la
      return danhGiaBanCoNangCao(2) - danhGiaBanCoNangCao(1);
    }

    final oUngVien = _lietKeOViTien();
    if (oUngVien.isEmpty) return 0;

    if (nguoiDangXet == 2) {
      int best = -0x3f3f3f3f;
      for (final o in oUngVien) {
        _banCo[o.item1][o.item2] = 2;
        final kt = _kiemTraKetThucNhanh(o.item1, o.item2, 2);
        final val = kt ?? minimaxGioiHan(1, doSau + 1, doSauToiDa, alpha, beta);
        _banCo[o.item1][o.item2] = 0;
        if (val > best) best = val;
        if (best > alpha) alpha = best;
        if (beta <= alpha) break;
      }
      return best;
    } else {
      int best = 0x3f3f3f3f;
      for (final o in oUngVien) {
        _banCo[o.item1][o.item2] = 1;
        final kt = _kiemTraKetThucNhanh(o.item1, o.item2, 1);
        final val = kt ?? minimaxGioiHan(2, doSau + 1, doSauToiDa, alpha, beta);
        _banCo[o.item1][o.item2] = 0;
        if (val < best) best = val;
        if (best < beta) beta = best;
        if (beta <= alpha) break;
      }
      return best;
    }
  }

  // _kiemTraKetThucNhanh: neu nuoc vua dat da thang/ua the ro net thi tra ve diem lon/nhan
  // Giai tich: Toi uu hoa minimax, neu co thang thua ngay lap tuc thi tra ve diem cuc lon, giam nhanh nhanh canh.
  int? _kiemTraKetThucNhanh(int r, int c, int nguoi) {
    if (kiemTraThangThua(r, c, nguoi)) {
      return nguoi == 2 ? 100000 : -100000;
    }
    return null;
  }

  // danhGiaBanCo: tinh diem heuristic cho mot ben
  // Giai tich: Cong diem theo so day lien tiep mo (khong bi chan hai dau) 2,3,4 quan. Day 4 mo duoc cong cao.
  int danhGiaBanCo(int nguoi) {
    int diem = 0;
    const List<List<int>> huong = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];
    for (int r = 0; r < _kichThuoc; r++) {
      for (int c = 0; c < _kichThuoc; c++) {
        if (_banCo[r][c] != nguoi) continue;
        for (final h in huong) {
          diem += _diemChuoi(r, c, h[0], h[1], nguoi);
        }
      }
    }
    return diem;
  }

  // danhGiaBanCoNangCao: heuristic manh hon voi trong so cao cho 4 mo, uu tien 3 mo gan thang
  // Giai tich: giong danhGiaBanCo nhung bang diem chi tiet hon de phan biet muc kho.
  int danhGiaBanCoNangCao(int nguoi) {
    int diem = 0;
    const List<List<int>> huong = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];
    for (int r = 0; r < _kichThuoc; r++) {
      for (int c = 0; c < _kichThuoc; c++) {
        if (_banCo[r][c] != nguoi) continue;
        for (final h in huong) {
          diem += _diemChuoiNangCao(r, c, h[0], h[1], nguoi);
        }
      }
    }
    return diem;
  }

  // _diemChuoiNangCao: bang diem chi tiet, khac _diemChuoi de phan biet kho hon
  int _diemChuoiNangCao(int r, int c, int dr, int dc, int nguoi) {
    int dai = 0;
    int i = r, j = c;
    while (i >= 0 && i < _kichThuoc && j >= 0 && j < _kichThuoc && _banCo[i][j] == nguoi) {
      dai++;
      i += dr;
      j += dc;
    }
    final int r1 = r - dr, c1 = c - dc;
    final int r2 = i, c2 = j;
    bool chanDau = !(r1 >= 0 && r1 < _kichThuoc && c1 >= 0 && c1 < _kichThuoc && _banCo[r1][c1] == 0);
    bool chanCuoi = !(r2 >= 0 && r2 < _kichThuoc && c2 >= 0 && c2 < _kichThuoc && _banCo[r2][c2] == 0);

    if (dai >= _soQuanDeThang) return 200000;
    if (chanDau && chanCuoi) return 0;
    if (dai == 4) return chanDau || chanCuoi ? 4000 : 15000;
    if (dai == 3) return chanDau || chanCuoi ? 600 : 3000;
    if (dai == 2) return chanDau || chanCuoi ? 50 : 200;
    return 8;
  }

  // danhGiaOTaiViTri: danh gia nuoc di neu dat quan 'nguoi' tai (r,c) theo cac mau de doa
  // Giai tich: tam thoi dat quan, tinh diem bang heuristic nang cao theo cac huong, bo ra
  int danhGiaOTaiViTri(int r, int c, int nguoi) {
    if (_banCo[r][c] != 0) return -0x3f3f3f3f;

    final anticol = nguoi == 1 ? 2 : 1;
    int res = 0;
    const int M = 1000;

    // tan cong: dat quan cua minh
    _banCo[r][c] = nguoi;
    final sumcol = _scoreOfColOne(nguoi, r, c);
    final a = _winningSituation(sumcol);
    res += a * M;
    res += (sumcol[-1] ?? 0) + (sumcol[1] ?? 0) + 4 * (sumcol[2] ?? 0) + 8 * (sumcol[3] ?? 0) + 16 * (sumcol[4] ?? 0);

    // phong thu: dat quan cua doi thu
    _banCo[r][c] = anticol;
    final sumanticol = _scoreOfColOne(anticol, r, c);
    final d = _winningSituation(sumanticol);
    res += d * (M - 100);
    res += (sumanticol[-1] ?? 0) + (sumanticol[1] ?? 0) + 4 * (sumanticol[2] ?? 0) + 8 * (sumanticol[3] ?? 0) + 16 * (sumanticol[4] ?? 0);

    _banCo[r][c] = 0;
    return res;
  }

  // _scoreOfColOne: tinh diem cua mot vi tri theo 4 huong (tu Python code)
  // Giai tich: Tra ve Map voi key la so quan lien tiep, value la so luong pattern do.
  Map<int, int> _scoreOfColOne(int nguoi, int r, int c) {
    final scores = <int, Map<String, int>>{
      0: {},
      1: {},
      2: {},
      3: {},
      4: {},
      5: {},
      -1: {},
    };

    const List<List<int>> huong = [
      [0, 1],   // ngang
      [1, 0],   // doc
      [1, 1],   // cheo chinh
      [-1, 1],  // cheo phu
    ];

    for (final h in huong) {
      final dr = h[0], dc = h[1];
      final row = _rowToList(r, c, dr, dc);
      final colscores = _scoreOfRow(row, nguoi);

      for (int i = 0; i < colscores.length; i++) {
        final score = colscores[i];
        final key = '$dr,$dc,$i';
        if (scores[score]!.containsKey(key)) {
          scores[score]![key] = scores[score]![key]! + 1;
        } else {
          scores[score]![key] = 1;
        }
      }
    }

    // hop nhat diem cua moi huong
    final result = <int, int>{};
    for (final key in scores.keys) {
      if (key == 5) {
        result[key] = scores[key]!.values.contains(1) ? 1 : 0;
      } else {
        result[key] = scores[key]!.values.fold(0, (sum, val) => sum + val);
      }
    }

    return result;
  }

  // _rowToList: lay danh sach quan theo huong tu vi tri (r,c)
  List<int> _rowToList(int r, int c, int dr, int dc) {
    final row = <int>[];
    final startR = r - 4 * dr;
    final startC = c - 4 * dc;
    final endR = r + 4 * dr;
    final endC = c + 4 * dc;

    int i = startR, j = startC;
    while (i != endR + dr || j != endC + dc) {
      if (i >= 0 && i < _kichThuoc && j >= 0 && j < _kichThuoc) {
        row.add(_banCo[i][j]);
      } else {
        row.add(-1); // ngoai ban co
      }
      i += dr;
      j += dc;
    }
    return row;
  }

  // _scoreOfRow: tinh diem cua mot hang 5 quan
  List<int> _scoreOfRow(List<int> row, int nguoi) {
    final colscores = <int>[];
    for (int start = 0; start <= row.length - 5; start++) {
      final subrow = row.sublist(start, start + 5);
      colscores.add(_scoreOfList(subrow, nguoi));
    }
    return colscores;
  }

  // _scoreOfList: tinh diem cua mot chuoi 5 quan
  int _scoreOfList(List<int> lis, int nguoi) {
    int blank = 0, filled = 0;
    for (final item in lis) {
      if (item == 0) {
        blank++;
      } else if (item == nguoi) {
        filled++;
      }
    }

    if (blank + filled < 5) return -1;
    if (blank == 5) return 0;
    return filled;
  }

  // _winningSituation: danh gia tinh huong chien thang (tu Python code)
  // Giai tich: Tra ve muc do nguy hiem: 5=thang ngay, 4=de doa cao, 3=de doa trung binh
  int _winningSituation(Map<int, int> sumcol) {
    if ((sumcol[5] ?? 0) > 0) return 5; // co 5 quan lien tiep

    // co 2 chuoi 4 quan hoac 1 chuoi 4 quan co >=2 pattern
    if ((sumcol[4] ?? 0) >= 2 || ((sumcol[4] ?? 0) >= 1 && (sumcol[4] ?? 0) >= 2)) {
      return 4;
    }

    // kiem tra TF34score: co 4 quan va >=2 chuoi 3 quan
    if (_tf34Score(sumcol[3] ?? 0, sumcol[4] ?? 0)) {
      return 4;
    }

    // co >=2 chuoi 3 quan
    if ((sumcol[3] ?? 0) >= 2) {
      return 3;
    }

    return 0;
  }

  // _tf34Score: kiem tra truong hop chac chan co the thang (tu Python code)
  bool _tf34Score(int score3, int score4) {
    if (score4 >= 1 && score3 >= 2) {
      return true;
    }
    return false;
  }


  // _timNuocChanDoubleThreat: chặn double threat của người chơi
  // Giai tich: Tìm nước đi mà nếu người chơi đi sẽ tạo ra 2 cửa thắng cùng lúc
  _Cap? _timNuocChanDoubleThreat() {
    final ds = _lietKeOViTienMoRong(3);
    for (final o in ds) {
      _banCo[o.item1][o.item2] = 1;
      final sumcol = _scoreOfColOne(1, o.item1, o.item2);
      _banCo[o.item1][o.item2] = 0;

      // Kiểm tra có tạo ra double threat không (>=2 chuỗi 4 hoặc >=2 chuỗi 3)
      if ((sumcol[4] ?? 0) >= 2 || ((sumcol[3] ?? 0) >= 2 && (sumcol[4] ?? 0) >= 1)) {
        return o;
      }
    }
    return null;
  }

  // _timNuocTaoDoubleThreat: tạo double threat cho máy
  // Giai tich: Tìm nước đi mà máy có thể tạo ra 2 cửa thắng cùng lúc
  _Cap? _timNuocTaoDoubleThreat() {
    final ds = _lietKeOViTienMoRong(3);
    for (final o in ds) {
      _banCo[o.item1][o.item2] = 2;
      final sumcol = _scoreOfColOne(2, o.item1, o.item2);
      _banCo[o.item1][o.item2] = 0;

      // Kiểm tra có tạo ra double threat không
      if ((sumcol[4] ?? 0) >= 2 || ((sumcol[3] ?? 0) >= 2 && (sumcol[4] ?? 0) >= 1)) {
        return o;
      }
    }
    return null;
  }

  // _diemChuoi: danh gia diem cho chuoi lien ke bat dau tu (r,c) theo huong (dr,dc)
  // Giai tich: Dem do dai chuoi, kiem tra bi chan dau nao, cong diem theo bang tuong doi.
  int _diemChuoi(int r, int c, int dr, int dc, int nguoi) {
    int dai = 0;
    int i = r, j = c;
    while (i >= 0 && i < _kichThuoc && j >= 0 && j < _kichThuoc && _banCo[i][j] == nguoi) {
      dai++;
      i += dr;
      j += dc;
    }
    final int r1 = r - dr, c1 = c - dc;
    final int r2 = i, c2 = j;
    bool chanDau = !(r1 >= 0 && r1 < _kichThuoc && c1 >= 0 && c1 < _kichThuoc && _banCo[r1][c1] == 0);
    bool chanCuoi = !(r2 >= 0 && r2 < _kichThuoc && c2 >= 0 && c2 < _kichThuoc && _banCo[r2][c2] == 0);

    if (dai >= _soQuanDeThang) return 100000;
    if (chanDau && chanCuoi) return 0;
    switch (dai) {
      case 4:
        return chanDau || chanCuoi ? 1000 : 5000;
      case 3:
        return chanDau || chanCuoi ? 200 : 800;
      case 2:
        return chanDau || chanCuoi ? 30 : 100;
      default:
        return 5;
    }
  }

  // _lietKeOViTien: liet ke cac o trong xung quanh khu vuc co quan (~ban kinh 2)
  // Giai tich: Giam nhanh khong gian tim kiem, chi xem xet o trong gan cac quan da co tren ban co.
  List<_Cap> _lietKeOViTien() {
    final Set<String> tap = {};
    for (int r = 0; r < _kichThuoc; r++) {
      for (int c = 0; c < _kichThuoc; c++) {
        if (_banCo[r][c] == 0) continue;
        for (int dr = -2; dr <= 2; dr++) {
          for (int dc = -2; dc <= 2; dc++) {
            final int rr = r + dr, cc = c + dc;
            if (rr >= 0 && cc >= 0 && rr < _kichThuoc && cc < _kichThuoc && _banCo[rr][cc] == 0) {
              tap.add('$rr,$cc');
            }
          }
        }
      }
    }
    final ds = tap.map((s) {
      final p = s.split(',');
      return _Cap(int.parse(p[0]), int.parse(p[1]));
    }).toList();
    if (ds.isEmpty) {
      // neu ban co rong, uu tien tam
      return [_Cap(_kichThuoc ~/ 2, _kichThuoc ~/ 2)];
    }
    return ds;
  }

  // _lietKeOViTienMoRong: giong _lietKeOViTien nhung ban kinh lon hon (mac dinh 3)
  List<_Cap> _lietKeOViTienMoRong(int banKinh) {
    final Set<String> tap = {};
    for (int r = 0; r < _kichThuoc; r++) {
      for (int c = 0; c < _kichThuoc; c++) {
        if (_banCo[r][c] == 0) continue;
        for (int dr = -banKinh; dr <= banKinh; dr++) {
          for (int dc = -banKinh; dc <= banKinh; dc++) {
            final int rr = r + dr, cc = c + dc;
            if (rr >= 0 && cc >= 0 && rr < _kichThuoc && cc < _kichThuoc && _banCo[rr][cc] == 0) {
              tap.add('$rr,$cc');
            }
          }
        }
      }
    }
    final ds = tap.map((s) {
      final p = s.split(',');
      return _Cap(int.parse(p[0]), int.parse(p[1]));
    }).toList();
    if (ds.isEmpty) {
      return [_Cap(_kichThuoc ~/ 2, _kichThuoc ~/ 2)];
    }
    return ds;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header với title đẹp
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      '🎯 CARO vs AI 🎯',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(2, 2),
                            blurRadius: 4,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Trí tuệ nhân tạo siêu mạnh',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              // Panel điều khiển đẹp
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Dropdown độ khó đẹp
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.settings, size: 16, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              const Text('Độ khó: ', style: TextStyle(fontWeight: FontWeight.w600)),
                              DropdownButton<String>(
                                value: _doKho,
                                underline: const SizedBox(),
                                style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                                items: const [
                                  DropdownMenuItem(value: 'de', child: Text('😊 Dễ')),
                                  DropdownMenuItem(value: 'trung binh', child: Text('😐 Trung bình')),
                                  DropdownMenuItem(value: 'kho', child: Text('😈 Khó')),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() {
                                    _doKho = v;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Nút bắt đầu, chơi lại và hướng dẫn
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildButton(
                          '🚀 Bắt đầu',
                          Colors.green,
                          batDauSauKhiChonCheDo,
                        ),
                        _buildButton(
                          '🔄 Chơi lại',
                          Colors.orange,
                              () {
                            final dangChoi = _daBatDau;
                            khoiTaoBanCo();
                            _daBatDau = dangChoi;
                            setState(() {});
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Nút hướng dẫn chơi + badge thời gian nhỏ cạnh bên
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildButton(
                          '❓ Hướng dẫn chơi',
                          Colors.blue,
                          _hienThiHuongDan,
                        ),
                        if (_daBatDau && !_daKetThuc && _thoiGianConLai > 0 && _luotNguoi) ...[
                          const SizedBox(width: 8),
                          _buildSmallTimerBadge(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // (Đã dời đồng hồ đếm ngược lên góc trên của bàn cờ)

              // Thông báo kết quả đẹp
              if (_thongBao.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _thongBao == 'Hòa!'
                          ? [Colors.amber.shade400, Colors.orange.shade600]
                          : _thongBao.contains('Thắng')
                          ? [Colors.green.shade400, Colors.green.shade600]
                          : [Colors.red.shade400, Colors.red.shade600],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: (_thongBao == 'Hòa!'
                            ? Colors.orange
                            : _thongBao.contains('Thắng') ? Colors.green : Colors.red).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    _thongBao,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Bàn cờ
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        _xayDungBanCoWidget(),
                        // Timer badge đã dời lên cạnh nút hướng dẫn
                        if (!_daBatDau)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.play_circle_outline,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Chọn độ khó và bấm "Bắt đầu" để chơi',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget tạo nút đẹp
  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    List<Color> gradientColors;
    Color shadowColor;

    if (color == Colors.green) {
      gradientColors = [const Color(0xFF4CAF50), const Color(0xFF2E7D32)];
      shadowColor = Colors.green;
    } else if (color == Colors.orange) {
      gradientColors = [const Color(0xFFFF9800), const Color(0xFFE65100)];
      shadowColor = Colors.orange;
    } else if (color == Colors.blue) {
      gradientColors = [const Color(0xFF2196F3), const Color(0xFF1565C0)];
      shadowColor = Colors.blue;
    } else {
      gradientColors = [color, color];
      shadowColor = color;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // _xayDungBanCoWidget: render luoi o vuong the hien ban co Caro với giao diện đẹp
  // Giai tich: Dung GridView voi 10 cot, moi o co border dep, hien ky hieu X cho nguoi va O cho may.
  Widget _xayDungBanCoWidget() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _kichThuoc,
      ),
      itemCount: _kichThuoc * _kichThuoc,
      itemBuilder: (_, idx) {
        final r = idx ~/ _kichThuoc;
        final c = idx % _kichThuoc;
        final val = _banCo[r][c];
        final isCenter = r == _kichThuoc ~/ 2 && c == _kichThuoc ~/ 2;

        return Container(
          margin: const EdgeInsets.all(0.5),
          child: InkWell(
            onTap: _daBatDau ? () => xuLyNguoiChoi(r, c) : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: isCenter
                    ? Colors.amber.shade100
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCenter
                      ? Colors.amber.shade300
                      : Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: val != 0 ? [
                  BoxShadow(
                    color: (val == 1 ? Colors.red : Colors.blue).withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Center(
                child: val == 1
                    ? Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFff6b6b), Color(0xFFee5a52)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'X',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
                    : val == 2
                    ? Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4ecdc4), Color(0xFF44a08d)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'O',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Lop _Cap: luu cap toa do (row, col)
class _Cap {
  final int item1;
  final int item2;
  const _Cap(this.item1, this.item2);
}


