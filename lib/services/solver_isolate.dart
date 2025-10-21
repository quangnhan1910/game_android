import 'dart:isolate';
import '../models/kociemba.dart';

class SolverIsolate {
  SolverIsolate._();
  static final SolverIsolate instance = SolverIsolate._();

  Isolate? _iso;
  SendPort? _send;

  /// Kill isolate cũ và tạo mới (dùng khi hot reload)
  void restart() {
    print('🔄 [DEBUG] Restarting SolverIsolate...');
    _iso?.kill(priority: Isolate.immediate);
    _iso = null;
    _send = null;
  }

  Future<void> _ensureStarted() async {
    if (_iso != null && _send != null) return;
    final rp = ReceivePort();
    _iso = await Isolate.spawn(_solverMain, rp.sendPort);
    _send = await rp.first as SendPort;
  }

  Future<List<String>> solve(String facelets, {SolverOptions opts = const SolverOptions()}) async {
    print('🔍 [DEBUG] SolverIsolate.solve called');
    await _ensureStarted();
    print('✅ [DEBUG] SolverIsolate started');
    final rp = ReceivePort();
    print('🔍 [DEBUG] Sending request to isolate...');
    _send!.send(_IsoReq(facelets, opts, rp.sendPort));
    print('🔍 [DEBUG] Waiting for response...');
    final msg = await rp.first as _IsoRes;
    print('🔍 [DEBUG] Received response: ${msg.error != null ? 'ERROR' : 'SUCCESS'}');
    if (msg.error != null) throw Exception(msg.error);
    return msg.moves!;
  }
}

class _IsoReq {
  final String facelets; final SolverOptions opts; final SendPort reply;
  _IsoReq(this.facelets, this.opts, this.reply);
}
class _IsoRes { final List<String>? moves; final String? error; _IsoRes(this.moves, this.error); }

void _solverMain(SendPort initPort) async {
  print('🔍 [DEBUG] SolverIsolate _solverMain started');
  final rp = ReceivePort(); initPort.send(rp.sendPort);
  print('✅ [DEBUG] SolverIsolate _solverMain ready');
  await for (final msg in rp) {
    if (msg is _IsoReq) {
      print('🔍 [DEBUG] Received solve request in isolate');
      try {
        print('🔍 [DEBUG] Calling Kociemba.solve...');
        final r = Kociemba.solve(msg.facelets, opts: msg.opts);
        print('✅ [DEBUG] Kociemba.solve completed with ${r.length} moves');
        msg.reply.send(_IsoRes(r, null));
      } catch (e) {
        print('❌ [DEBUG] Kociemba.solve error: $e');
        msg.reply.send(_IsoRes(null, e.toString()));
      }
    }
  }
}