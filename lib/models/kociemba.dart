// Kociemba "ultra-lite" (mobile-friendly, offline)
// - Phase-1: slice–twist & slice–flip pruning (Uint8List, nhỏ ~2MB)
// - Phase-2: DFS/IDA* on-the-fly với heuristic nhẹ
// BỔ SUNG: giới hạn độ sâu từng pha + timeout + nodeCap để chạy nhanh trên máy ảo.

import 'dart:typed_data';

class SolverOptions {
  final int maxLength;        // tổng bước tối đa
  final int p1MaxDepthCap;    // trần độ sâu Pha-1
  final int p2StartDepth;     // độ sâu Pha-2 khởi điểm (IDA*)
  final int p2MaxDepthCap;    // trần độ sâu Pha-2
  final int nodeCap;          // giới hạn số node duyệt ở Pha-2
  final int timeoutMs;        // thời gian tối đa cho cả lời giải
  const SolverOptions({
    this.maxLength = 30,
    this.p1MaxDepthCap = 14,
    this.p2StartDepth = 10,
    this.p2MaxDepthCap = 20,
    this.nodeCap = 800000,
    this.timeoutMs = 8000,
  });
}

class Kociemba {
  /// Giải từ chuỗi 54 ký tự facelets (URFDLB).
  static List<String> solve(String facelets, {SolverOptions opts = const SolverOptions()}) {
    print('🔍 [DEBUG] Kociemba.solve started with opts: maxLength=${opts.maxLength}, nodeCap=${opts.nodeCap}');
    final c = _CubieCube.fromFacelets(facelets);
    print('✅ [DEBUG] CubieCube created');
    if (!_CubeValidator.isValid(c)) {
      print('❌ [DEBUG] Cube validation failed');
      throw Exception('Cấu hình không hợp lệ (orientation/parity). Kiểm tra lại khi nhập màu.');
    }
    print('✅ [DEBUG] Cube validation passed');
    final s = _Search(opts: opts);
    print('🔍 [DEBUG] Starting search...');
    final res = s.solution(c);
    if (res == null) {
      print('❌ [DEBUG] No solution found');
      throw Exception('Không tìm được lời giải trong giới hạn (tăng p1/p2 depth, nodeCap hoặc timeoutMs).');
    }
    print('✅ [DEBUG] Solution found: ${res.length} moves');
    return res;
  }
}

// ======= Cube representation & moves =======
class _CubieCube {
  final List<int> cp = List.filled(8, 0);
  final List<int> co = List.filled(8, 0);
  final List<int> ep = List.filled(12, 0);
  final List<int> eo = List.filled(12, 0);
  _CubieCube(){ for (int i=0;i<8;i++) cp[i]=i; for (int i=0;i<12;i++) ep[i]=i; }

  static const _cornerFacelet = [
    [8,9,20],[6,18,38],[0,36,47],[2,45,11],
    [29,26,15],[27,44,24],[33,53,42],[35,17,51],
  ];
  static const _cornerColor = [
    ['U','R','F'],['U','F','L'],['U','L','B'],['U','B','R'],
    ['D','F','R'],['D','L','F'],['D','B','L'],['D','R','B'],
  ];
  static const _edgeFacelet = [
    [5,10],[7,19],[3,37],[1,46],
    [32,21],[30,41],[34,50],[28,12],
    [23,14],[25,43],[39,48],[16,52],
  ];
  static const _edgeColor = [
    ['U','R'],['U','F'],['U','L'],['U','B'],
    ['D','R'],['D','F'],['D','L'],['D','B'],
    ['F','R'],['F','L'],['B','L'],['B','R'],
  ];

  static _CubieCube fromFacelets(String s){
    if (s.length!=54) { throw Exception('Chuỗi facelets phải có 54 ký tự.'); }
    final cc=_CubieCube();
    // corners
    final usedC = List.filled(8,false);
    for (int i=0;i<8;i++){
      for (int ori=0;ori<3;ori++){
        final fc = s[_cornerFacelet[i][ori]];
        if (fc=='U' || fc=='D'){
          final c1 = s[_cornerFacelet[i][(ori+1)%3]];
          final c2 = s[_cornerFacelet[i][(ori+2)%3]];
          for (int j=0;j<8;j++){
            if (!usedC[j] && c1==_cornerColor[j][1] && c2==_cornerColor[j][2]) {
              cc.cp[i]=j; cc.co[i]=ori%3; usedC[j]=true; break;
            }
          }
        }
      }
    }
    // edges
    final usedE = List.filled(12,false);
    for (int i=0;i<12;i++){
      for (int ori=0;ori<2;ori++){
        final fc=s[_edgeFacelet[i][ori]];
        if (fc=='U'||fc=='D'){
          final c1=s[_edgeFacelet[i][(ori+1)%2]];
          for (int j=0;j<12;j++){
            if (!usedE[j] && c1==_edgeColor[j][1]) { cc.ep[i]=j; cc.eo[i]=ori%2; usedE[j]=true; break; }
          }
        }
      }
    }
    return cc;
  }

  _CubieCube clone(){
    final x=_CubieCube();
    for (int i=0;i<8;i++){ x.cp[i]=cp[i]; x.co[i]=co[i]; }
    for (int i=0;i<12;i++){ x.ep[i]=ep[i]; x.eo[i]=eo[i]; }
    return x;
  }

  static final _move = List.generate(18,(i){ final m=_CubieCube(); m._apply(i~/3,(i%3)+1); return m; });

  void _apply(int f,int p){
    const cIdx=[[0,3,7,4],[0,4,5,1],[0,1,2,3],[4,7,6,5],[2,6,7,3],[1,5,6,2]];
    const eIdx=[[0,3,2,1],[8,4,11,0],[9,5,8,1],[4,7,6,5],[10,6,9,2],[11,7,10,3]];
    for (int k=0;k<p;k++){
      final a=cIdx[f];
      _cycle4(cp,a[0],a[1],a[2],a[3]);
      if (f==2||f==5){ _tw(a[0],1); _tw(a[1],2); _tw(a[2],1); _tw(a[3],2); }
      else if (f==1||f==4){ _tw(a[0],2); _tw(a[1],1); _tw(a[2],2); _tw(a[3],1); }
      final b=eIdx[f]; _cycle4(ep,b[0],b[1],b[2],b[3]);
      if (f==2||f==5){ _fl(b[0]); _fl(b[2]); }
    }
  }
  void _tw(int i,int d)=>co[i]=(co[i]+d)%3;
  void _fl(int i)=>eo[i]^=1;

  _CubieCube operator*(_CubieCube a){
    final r=_CubieCube();
    for (int i=0;i<8;i++){ r.cp[i]=cp[a.cp[i]]; r.co[i]=(co[a.cp[i]]+a.co[i])%3; }
    for (int i=0;i<12;i++){ r.ep[i]=ep[a.ep[i]]; r.eo[i]=eo[a.ep[i]]^a.eo[i]; }
    return r;
  }

  // Coordinates
  int get twist { int r=0; for(int i=0;i<7;i++) r=3*r+co[i]; return r; }
  set twist(int v){ int s=0; for(int i=6;i>=0;i--){ co[i]=v%3; s+=co[i]; v~/=3; } co[7]=(3-s%3)%3; }
  int get flip { int r=0; for(int i=0;i<11;i++) r=2*r+eo[i]; return r; }
  set flip(int v){ int s=0; for(int i=10;i>=0;i--){ eo[i]=v&1; s+=eo[i]; v>>=1; } eo[11]=(s&1)==0?0:1; }
  int get slice {
    int a=0,y=0; for(int i=0;i<12;i++) if (4<=ep[i]&&ep[i]<=7){ a|=1<<(11-i); y++; }
    int r=0,x=12,k=4; for(int i=0;i<12;i++){ if((a&(1<<(11-i)))!=0){ r+=_Cnk(x-1,k-1); k--; } x--; if(k==0) break; } return r;
  }
  int get cornerPerm{ int r=0; final a=List<int>.from(cp); for(int j=7;j>0;j--){ int s=0; for(int i=0;i<j;i++){ if(a[i]>a[j]) s++; } r=r*(j+1)+s; } return r; }
  int get udep{
    final list=<int>[]; for(int i=0;i<12;i++) if(ep[i]<=3||ep[i]>=8) list.add(ep[i]);
    int r=0; for(int j=7;j>0;j--){ int s=0; for(int i=0;i<j;i++){ if(list[i]>list[j]) s++; } r=r*(j+1)+s; } return r;
  }
}
bool _cycle4(List<int>a,int i,int j,int k,int l){ final t=a[i]; a[i]=a[j]; a[j]=a[k]; a[k]=a[l]; a[l]=t; return true; }
int _Cnk(int n,int k){ if(k>n) return 0; int r=1; for(int i=1;i<=k;i++){ r=r*(n-(k-i))~/i; } return r; }

class _CubeValidator{
  static bool isValid(_CubieCube c){
    int s=0; for(final x in c.co) s+=x; if (s%3!=0) return false;
    s=0; for(final x in c.eo) s+=x; if (s%2!=0) return false;
    return _par(c.cp)==_par(c.ep);
  }
  static int _par(List<int> p){ int inv=0; for(int i=0;i<p.length-1;i++) for(int j=i+1;j<p.length;j++) if(p[i]>p[j]) inv++; return inv&1; }
}

// ======= Small tables (Phase-1 only) =======
class _Tables{
  static const N_TWIST=2187, N_FLIP=2048, N_SLICE=495;
  static late final List<Uint32List> twistMove;
  static late final List<Uint32List> flipMove;
  static late final List<Uint32List> sliceMove;
  static late final Uint8List prunSliceTwist; // 495*2187 ~1.03MB
  static late final Uint8List prunSliceFlip;  // 495*2048 ~0.97MB
  static bool _inited=false;

  static void init(){
    if(_inited) return; _inited=true;
    twistMove = List.generate(N_TWIST, (_)=>Uint32List(18));
    flipMove  = List.generate(N_FLIP , (_)=>Uint32List(18));
    sliceMove = List.generate(N_SLICE, (_)=>Uint32List(18));

    final cc=_CubieCube();
    for(int i=0;i<N_TWIST;i++){ final x=cc.clone()..twist=i; for(int m=0;m<18;m++){ twistMove[i][m]=(x* _CubieCube._move[m]).twist; } }
    for(int i=0;i<N_FLIP;i++){  final x=cc.clone()..flip=i;  for(int m=0;m<18;m++){ flipMove [i][m]=(x* _CubieCube._move[m]).flip;  } }
    for(int i=0;i<N_SLICE;i++){ final x=_setSlice(cc.clone(), i); for(int m=0;m<18;m++){ sliceMove[i][m]=_getSlice(x* _CubieCube._move[m]); } }

    prunSliceTwist = Uint8List(N_SLICE*N_TWIST);
    prunSliceFlip  = Uint8List(N_SLICE*N_FLIP );
    _fillPrun(prunSliceTwist, N_SLICE, N_TWIST, sliceMove, twistMove);
    _fillPrun(prunSliceFlip , N_SLICE, N_FLIP , sliceMove, flipMove );
  }

  static _CubieCube _setSlice(_CubieCube c,int idx){
    final occ=List.filled(12,0); int x=12,y=4,r=idx;
    for(int i=0;i<12;i++){ if(y==0) break; final cn=_Cnk(x-1,y-1); if(r>=cn){ occ[i]=1; r-=cn; y--; } x--; }
    int j=0,t=0; for(int i=0;i<12;i++){ if(occ[i]==1){ c.ep[i]=4+(j++);} else { while(t<12 && (t>=4 && t<=7)) t++; c.ep[i]=t++; } }
    return c;
  }
  static int _getSlice(_CubieCube c)=>c.slice;

  static void _fillPrun(Uint8List pr,int nA,int nB,List<Uint32List> moveA,List<Uint32List> moveB){
    for(int i=0;i<pr.length;i++) pr[i]=255;
    pr[0]=0; final q=<int>[0];
    while(q.isNotEmpty){
      final x=q.removeAt(0); final d=pr[x]; final a=x~/nB; final b=x%nB;
      for(int m=0;m<18;m++){ final nx=moveA[a][m]*nB + moveB[b][m]; if(pr[nx]==255){ pr[nx]=(d+1); q.add(nx); } }
    }
  }
}

// ======= IDA* two-phase (P2 on-the-fly) + depth caps + timeout =======
class _Search{
  final SolverOptions opts;
  _Search({required this.opts});
  final _moves = List<int>.filled(32,0);
  int _depth1=0, _nodes=0;
  late final int _deadlineMs;

  List<String>? solution(_CubieCube cc){
    _Tables.init();
    _deadlineMs = DateTime.now().millisecondsSinceEpoch + opts.timeoutMs;

    int twist=cc.twist, flip=cc.flip, slice=cc.slice;
    final p1Cap = opts.p1MaxDepthCap.clamp(0, opts.maxLength);
    print('🔍 [DEBUG] Phase-1: Searching depth 0 to $p1Cap...');
    for (int d=0; d<=p1Cap; d++){
      print('🔍 [DEBUG] Phase-1: Trying depth $d...');
      _checkTimeout();
      if (_search1(twist, flip, slice, d, -1)){
        print('✅ [DEBUG] Phase-1: Solution found at depth $d');
        final c1=cc.clone();
        for(int i=0;i<_depth1;i++){ c1._apply(_moves[i]~/3, (_moves[i]%3)+1); }
        final remain = opts.maxLength - _depth1;
        final p2Start = opts.p2StartDepth.clamp(0, remain);
        final p2Cap   = opts.p2MaxDepthCap.clamp(0, remain);
        print('🔍 [DEBUG] Phase-2: Searching depth $p2Start to $p2Cap...');
        for (int d2=p2Start; d2<=p2Cap; d2++){
          print('🔍 [DEBUG] Phase-2: Trying depth $d2...');
          _checkTimeout();
          final res=_search2(c1, d2);
          if (res!=null){ 
            print('✅ [DEBUG] Phase-2: Solution found at depth $d2');
            return _toStrings([..._moves.take(_depth1), ...res]); 
          }
        }
      }
    }
    print('❌ [DEBUG] No solution found within depth limits');
    return null;
  }

  bool _search1(int twist,int flip,int slice,int depth,int last){
    // Check timeout để không đứng đơ
    if (DateTime.now().millisecondsSinceEpoch > _deadlineMs) {
      throw Exception('Timeout khi tính lời giải Phase-1 (tăng timeoutMs).');
    }
    
    if (depth==0){
      final h1=_Tables.prunSliceTwist[slice*_Tables.N_TWIST + twist];
      final h2=_Tables.prunSliceFlip [slice*_Tables.N_FLIP  + flip ];
      return (h1==0 && h2==0);
    }
    final h1=_Tables.prunSliceTwist[slice*_Tables.N_TWIST + twist];
    final h2=_Tables.prunSliceFlip [slice*_Tables.N_FLIP  + flip ];
    if (h1>depth || h2>depth) return false;

    for(int m=0;m<18;m++){
      if (last!=-1 && (m~/3)==(last~/3)) continue; // tránh trùng mặt liên tiếp
      final nt=_Tables.twistMove[twist][m];
      final nf=_Tables.flipMove [flip ][m];
      final ns=_Tables.sliceMove[slice][m];
      _moves[_depth1]=m; _depth1++;
      final ok=_search1(nt,nf,ns,depth-1,m);
      if (ok) return true;
      _depth1--;
    }
    return false;
  }

  int _heurP2(_CubieCube c){
    int misE=0, misC=0;
    for (int i=0;i<12;i++){
      final e=c.ep[i];
      final isUD = (i<=3 || i>=8);
      final shouldUD = (e<=3 || e>=8);
      if (isUD != shouldUD) misE++;
    }
    for (int i=0;i<8;i++){ if (c.cp[i]!=i) misC++; }
    return (misE/4).ceil() + (misC/4).ceil();
  }

  List<int>? _search2(_CubieCube start, int maxDepth){
    _nodes=0;
    return _dfs2(start, maxDepth, -1, const <int>[]);
  }

  List<int>? _dfs2(_CubieCube c, int depth, int last, List<int> acc){
    _checkTimeout();
    _nodes++; if (_nodes>opts.nodeCap) return null;
    final h=_heurP2(c);
    if (h>depth) return null;
    if (depth==0) {
      bool cornersOk=true; for(int i=0;i<8;i++) if (c.cp[i]!=i) { cornersOk=false; break; }
      bool edgesOk=true; for(int i=0;i<12;i++){ final e=c.ep[i]; if ((i<=3||i>=8)!=(e<=3||e>=8)) { edgesOk=false; break; } }
      return (cornersOk && edgesOk) ? acc : null;
    }
    // P2 allowed: U/D bất kỳ; R2 L2 F2 B2
    const faces = [0,3,1,4,2,5]; // U,D,R,L,F,B
    const pw = {
      0:[1,2,3], 3:[1,2,3], // U/D: U U2 U'
      1:[2], 4:[2], 2:[2], 5:[2], // R2 L2 F2 B2
    };
    for (final f in faces){
      if (last!=-1 && f==last) continue;
      for (final p in pw[f]!){
        final m=f*3+(p-1);
        final n=c.clone().._apply(f,p);
        final r=_dfs2(n, depth-1, f, [...acc, m]);
        if (r!=null) return r;
      }
    }
    return null;
  }

  void _checkTimeout(){
    if (DateTime.now().millisecondsSinceEpoch > _deadlineMs) {
      throw Exception('Timeout khi tính lời giải (tăng timeoutMs).');
    }
  }

  List<String> _toStrings(List<int> ms){
    final out=<String>[];
    for(final m in ms){
      final f=['U','R','F','D','L','B'][m~/3];
      final p = m%3;
      out.add(p==0? f : (p==1? '${f}2' : "${f}'"));
    }
    return out;
  }
}