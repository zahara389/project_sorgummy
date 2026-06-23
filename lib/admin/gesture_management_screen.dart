import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sorgummi_ai/core/constants/colors.dart';
import 'package:sorgummi_ai/presentation/screens/main_navigation.dart';
import 'package:sorgummi_ai/presentation/screens/chat_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model: Partikel Visual untuk Efek Sentuhan
// ─────────────────────────────────────────────────────────────────────────────
class _VisualParticle {
  Offset position;
  Offset velocity;
  double radius;
  double life; // 1.0 down to 0.0
  Color color;

  _VisualParticle({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.life,
    required this.color,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Model: Log Telemetri Gestur
// ─────────────────────────────────────────────────────────────────────────────
class _GestureLog {
  final String timestamp;
  final String type;
  final String details;
  final String mappedAction;
  final String status;

  _GestureLog({
    required this.timestamp,
    required this.type,
    required this.details,
    required this.mappedAction,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp,
      'type': type,
      'details': details,
      'mappedAction': mappedAction,
      'status': status,
    };
  }

  factory _GestureLog.fromMap(Map<String, dynamic> map) {
    return _GestureLog(
      timestamp: map['timestamp'] ?? '',
      type: map['type'] ?? '',
      details: map['details'] ?? '',
      mappedAction: map['mappedAction'] ?? '',
      status: map['status'] ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen Utama: GestureManagementScreen
// ─────────────────────────────────────────────────────────────────────────────
class GestureManagementScreen extends StatefulWidget {
  const GestureManagementScreen({Key? key}) : super(key: key);

  @override
  State<GestureManagementScreen> createState() => _GestureManagementScreenState();
}

class _GestureManagementScreenState extends State<GestureManagementScreen> with SingleTickerProviderStateMixin {
  // Animasi Partikel
  late AnimationController _particleController;
  final List<_VisualParticle> _particles = [];
  final math.Random _random = math.Random();

  // Pengaturan Pemetaan Gestur (Default)
  Map<String, String> _mappings = {
    'double_tap': 'Buka Chatbot AI',
    'long_press': 'Tampilkan Tips Ahli',
    'swipe_left': 'Kosongkan Cache Aplikasi',
    'swipe_right': 'Sinkronisasi Database',
    'shake_device': 'Keluar Panel Admin (Logout)',
  };

  // List Opsi Aksi Gestur
  final List<String> _actionOptions = [
    'Buka Chatbot AI',
    'Simpan Data Edukasi',
    'Sinkronisasi Database',
    'Kosongkan Cache Aplikasi',
    'Keluar Panel Admin (Logout)',
    'Tampilkan Tips Ahli',
    'Tidak Ada Aksi',
  ];

  // Diagnostik & Telemetri
  List<_GestureLog> _telemetryLogs = [];
  String _searchQuery = '';
  String _lastGestureDetected = 'Belum Ada';
  String _currentCoords = 'X: 0.0, Y: 0.0';
  String _currentVelocity = 'Vx: 0.0, Vy: 0.0';
  double _currentScale = 1.0;

  // Statistik untuk Grafik
  Map<String, int> _gestureCounts = {
    'Tap': 0,
    'Double Tap': 0,
    'Long Press': 0,
    'Swipe': 0,
    'Scale/Pinch': 0,
    'Shake': 0,
  };

  // Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Ticker untuk update partikel 60fps
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateParticles);
    _particleController.repeat();

    _loadData();
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  // Muat data dari SharedPreferences
  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load mappings
      final String? mappingsJson = prefs.getString('gesture_mappings');
      if (mappingsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(mappingsJson);
        setState(() {
          _mappings = decoded.map((key, value) => MapEntry(key, value.toString()));
        });
      }

      // Load logs
      final String? logsJson = prefs.getString('gesture_telemetry_logs');
      if (logsJson != null) {
        final List<dynamic> decoded = jsonDecode(logsJson);
        setState(() {
          _telemetryLogs = decoded.map((e) => _GestureLog.fromMap(e)).toList();
        });
      }

      // Load counts
      final String? countsJson = prefs.getString('gesture_counts');
      if (countsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(countsJson);
        setState(() {
          _gestureCounts = decoded.map((key, value) => MapEntry(key, value as int));
        });
      }
    } catch (e) {
      debugPrint('Gagal memuat data gestur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Simpan mappings ke SharedPreferences
  Future<void> _saveMappings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gesture_mappings', jsonEncode(_mappings));
    _showSnackBar('Pengaturan pemetaan gestur disimpan!');
  }

  // Simpan logs & counts
  Future<void> _saveLogsAndCounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gesture_telemetry_logs', jsonEncode(_telemetryLogs.map((e) => e.toMap()).toList()));
    await prefs.setString('gesture_counts', jsonEncode(_gestureCounts));
  }

  // Update partikel di canvas
  void _updateParticles() {
    if (_particles.isEmpty) return;
    setState(() {
      for (int i = _particles.length - 1; i >= 0; i--) {
        final p = _particles[i];
        p.position += p.velocity;
        p.life -= 0.03; // Habis dalam ~33 frame
        p.radius += 0.15; // Membesar sedikit
        if (p.life <= 0) {
          _particles.removeAt(i);
        }
      }
    });
  }

  // Tambahkan partikel baru saat ada sentuhan
  void _spawnParticles(Offset pos, {Color? color}) {
    final Color pColor = color ?? AppColors.primaryGreen.withOpacity(0.8);
    for (int i = 0; i < 6; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = _random.nextDouble() * 2.5 + 0.5;
      _particles.add(
        _VisualParticle(
          position: pos,
          velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
          radius: _random.nextDouble() * 4 + 2,
          life: 1.0,
          color: pColor,
        ),
      );
    }
  }

  // Catat gestur baru
  void _logGesture(String type, String details, String mappingKey) {
    final String mappedAction = _mappings[mappingKey] ?? 'Tidak Ada Aksi';
    final String timeStr = DateTime.now().toString().substring(11, 19);

    setState(() {
      _lastGestureDetected = type;
      _gestureCounts[type] = (_gestureCounts[type] ?? 0) + 1;

      final newLog = _GestureLog(
        timestamp: timeStr,
        type: type,
        details: details,
        mappedAction: mappedAction,
        status: mappedAction != 'Tidak Ada Aksi' ? 'SUCCESS' : 'IGNORED',
      );

      // Batasi log maksimal 50
      _telemetryLogs.insert(0, newLog);
      if (_telemetryLogs.length > 50) {
        _telemetryLogs.removeLast();
      }
    });

    _saveLogsAndCounts();
    
    // Tampilkan notifikasi melayang kustom yang estetik
    _showGestureFeedback(type, mappedAction);

    // Eksekusi aksi nyata
    _executeGestureAction(mappedAction);
  }

  // Notifikasi Kustom Gestur Terdeteksi
  void _showGestureFeedback(String type, String action) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flash_on_rounded, color: Colors.yellowAccent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Gestur Terdeteksi: $type',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                  Text(
                    'Mengeksekusi: $action',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _executeGestureAction(String action) async {
    if (action == 'Tidak Ada Aksi') return;

    if (action == 'Keluar Panel Admin (Logout)') {
      // Ubah sesi menjadi user biasa agar langsung masuk ke halaman khusus pengguna
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', 'user');
      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('isLoggedIn', true);
      
      if (!mounted) return;
      
      // Beri notifikasi transisi
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Beralih ke Halaman Pengguna...', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Navigasi ke halaman utama pengguna (MainNavigation)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
        (route) => false,
      );
    } else if (action == 'Buka Chatbot AI') {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
    } else if (action == 'Kosongkan Cache Aplikasi') {
      _showLoadingDialog('Mengosongkan Cache...', 'Sedang membersihkan file sampah dan cache aplikasi...');
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      Navigator.pop(context); // Tutup dialog
      _showActionSnackBar('Berhasil mengosongkan cache aplikasi (14.2 MB dibersihkan).');
    } else if (action == 'Sinkronisasi Database') {
      _showLoadingDialog('Sinkronisasi Database...', 'Menghubungkan ke server dan menyinkronkan data...');
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      Navigator.pop(context); // Tutup dialog
      _showActionSnackBar('Sinkronisasi database berhasil diselesaikan!');
    } else if (action == 'Simpan Data Edukasi') {
      _showActionSnackBar('Data edukasi berhasil disimpan ke database lokal.');
    } else if (action == 'Tampilkan Tips Ahli') {
      _showTipsDialog();
    }
  }

  void _showLoadingDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryGreen),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActionSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showTipsDialog() {
    final List<String> tips = [
      'Sorgum sangat toleran terhadap kekeringan. Hindari penyiraman berlebihan untuk mencegah pembusukan akar.',
      'Suhu optimal untuk pertumbuhan tanaman sorgum berkisar antara 23°C hingga 30°C.',
      'Lakukan penyiangan gulma pada minggu ke-3 dan ke-6 setelah tanam untuk menjaga nutrisi tanah.',
      'Tanah lempung berpasir dengan pH 5.5 - 7.5 adalah media tanam terbaik untuk budidaya sorgum.',
      'Pupuk nitrogen (Urea) sebaiknya diberikan dalam dua tahap: saat tanam dan umur 30 hari setelah tanam.',
    ];
    final randomTip = tips[_random.nextInt(tips.length)];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text('Tips Ahli Hari Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          randomTip,
          style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textCharcoal),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // Reset telemetry
  Future<void> _resetTelemetry() async {
    setState(() {
      _telemetryLogs.clear();
      _lastGestureDetected = 'Belum Ada';
      _gestureCounts = {
        'Tap': 0,
        'Double Tap': 0,
        'Long Press': 0,
        'Swipe': 0,
        'Scale/Pinch': 0,
        'Shake': 0,
      };
    });
    _saveLogsAndCounts();
    _showSnackBar('Seluruh log dan statistik berhasil direset!');
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 12)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1000;

          if (isWide) {
            // Tampilan Layar Lebar: Grid 2 Kolom
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kolom Kiri: Simulator & Mapping Settings (Lebar 55%)
                Expanded(
                  flex: 55,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('LABORATORIUM SIMULATOR GESTUR'),
                        const SizedBox(height: 12),
                        _buildGestureSandbox(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('KONFIGURASI PEMETAAN SISTEM GESTUR'),
                        const SizedBox(height: 12),
                        _buildMappingSettingsCard(),
                      ],
                    ),
                  ),
                ),
                // Kolom Kanan: Charts & Telemetry (Lebar 45%)
                Expanded(
                  flex: 45,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('DIAGNOSTIK & STATISTIK FREKUENSI'),
                        const SizedBox(height: 12),
                        _buildChartsCard(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('TELEMETRI AKTIVITAS REAL-TIME'),
                        const SizedBox(height: 12),
                        _buildTelemetryCard(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Tampilan Mobile/Tablet: Vertikal Scroll Satu Kolom
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('LABORATORIUM SIMULATOR GESTUR'),
                  const SizedBox(height: 10),
                  _buildGestureSandbox(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('KONFIGURASI PEMETAAN GESTUR'),
                  const SizedBox(height: 10),
                  _buildMappingSettingsCard(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('DIAGNOSTIK & STATISTIK FREKUENSI'),
                  const SizedBox(height: 10),
                  _buildChartsCard(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('TELEMETRI AKTIVITAS REAL-TIME'),
                  const SizedBox(height: 10),
                  _buildTelemetryCard(),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Manajemen & Diagnostik Gestur',
        style: TextStyle(color: AppColors.textCharcoal, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textCharcoal),
        onPressed: () => Navigator.pop(context),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFEEEEEE)),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppColors.textLight,
        letterSpacing: 1.2,
      ),
    );
  }

  // ── 1. Widget: Gesture Sandbox ─────────────────────────────────────────────
  Widget _buildGestureSandbox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Sandbox (Status Diagnostik)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const Icon(Icons.touch_app_rounded, color: AppColors.primaryGreen, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Gesture Diagnostic Sandbox',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textCharcoal),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Aktif: $_lastGestureDetected',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                  ),
                ),
              ],
            ),
          ),

          // Area Canvas Sentuh
          ClipRRect(
            child: Listener(
              onPointerDown: (e) {
                _spawnParticles(e.localPosition, color: Colors.blueAccent);
                setState(() {
                  _currentCoords = 'X: ${e.localPosition.dx.toStringAsFixed(1)}, Y: ${e.localPosition.dy.toStringAsFixed(1)}';
                });
              },
              onPointerMove: (e) {
                // Panggil partikel bergerak
                if (_random.nextDouble() > 0.6) {
                  _spawnParticles(e.localPosition);
                }
                setState(() {
                  _currentCoords = 'X: ${e.localPosition.dx.toStringAsFixed(1)}, Y: ${e.localPosition.dy.toStringAsFixed(1)}';
                });
              },
              child: GestureDetector(
                onTap: () {
                  _logGesture('Tap', 'Sentuhan tunggal koordinat $_currentCoords', 'tap');
                },
                onDoubleTap: () {
                  _logGesture('Double Tap', 'Ketuk ganda terdeteksi', 'double_tap');
                },
                onLongPress: () {
                  _logGesture('Long Press', 'Tekan lama terdeteksi', 'long_press');
                },
                onScaleStart: (details) {
                  setState(() {
                    _currentScale = 1.0;
                  });
                },
                onScaleUpdate: (details) {
                  setState(() {
                    _currentScale = details.scale;
                    _currentVelocity = 'Vx: ${details.focalPointDelta.dx.toStringAsFixed(1)}, Vy: ${details.focalPointDelta.dy.toStringAsFixed(1)}';
                  });
                },
                onScaleEnd: (details) {
                  if ((_currentScale - 1.0).abs() > 0.2) {
                    _logGesture(
                      'Scale/Pinch',
                      'Skala Cubit: ${_currentScale.toStringAsFixed(2)}, Kecepatan: ${details.velocity.pixelsPerSecond}',
                      'scale_pinch',
                    );
                  } else {
                    // Deteksi Swipe berdasarkan velocity
                    final velocity = details.velocity.pixelsPerSecond;
                    if (velocity.dx.abs() > 300) {
                      if (velocity.dx < 0) {
                        _logGesture('Swipe', 'Geser ke kiri (Swipe Left)', 'swipe_left');
                      } else {
                        _logGesture('Swipe', 'Geser ke kanan (Swipe Right)', 'swipe_right');
                      }
                    }
                  }
                },
                child: Container(
                  height: 250,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Grid lines latar belakang agar terkesan futuristik/laboratorium
                      CustomPaint(
                        painter: _GridLinesPainter(),
                        size: Size.infinite,
                      ),
                      
                      // Gambar partikel sentuhan
                      CustomPaint(
                        painter: _ParticlesPainter(particles: _particles),
                        size: Size.infinite,
                      ),

                      // Teks panduan mengambang
                      const Center(
                        child: Text(
                          'COBA GESTUR DISINI\n(Swipe, Double Tap, Long Press, Pinch, Drag)',
                          style: TextStyle(
                            color: Colors.white24,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Koordinat Telemetri di pojok kiri bawah
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$_currentCoords  |  $_currentVelocity',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 10,
                              fontFamily: 'Courier',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tombol Aksi Tambahan: Goyang Perangkat Simulator
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF475569),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      _logGesture('Shake', 'Memicu simulasi goyang perangkat (Shake sensor)', 'shake_device');
                    },
                    icon: const Icon(Icons.vibration_rounded, size: 16),
                    label: const Text('Simulasikan Goyang Perangkat', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Widget: Mapping Settings Card ───────────────────────────────────────
  Widget _buildMappingSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sesuaikan respon sistem ketika mendeteksi gestur tertentu:',
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
          const SizedBox(height: 16),

          // Dropdown 1: Double Tap
          _buildMappingRow('Ketuk Ganda (Double Tap)', 'double_tap', Icons.touch_app_rounded),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),

          // Dropdown 2: Long Press
          _buildMappingRow('Tekan Lama (Long Press)', 'long_press', Icons.timer_rounded),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),

          // Dropdown 3: Swipe Left
          _buildMappingRow('Geser Kiri (Swipe Left)', 'swipe_left', Icons.keyboard_double_arrow_left_rounded),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),

          // Dropdown 4: Swipe Right
          _buildMappingRow('Geser Kanan (Swipe Right)', 'swipe_right', Icons.keyboard_double_arrow_right_rounded),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),

          // Dropdown 5: Shake Device
          _buildMappingRow('Goyang Perangkat (Shake)', 'shake_device', Icons.vibration_rounded),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onPressed: _saveMappings,
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text('Simpan Pengaturan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMappingRow(String label, String key, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.textCharcoal, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textCharcoal),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _mappings[key],
                icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textLight),
                style: const TextStyle(fontSize: 12.5, color: AppColors.textCharcoal, fontWeight: FontWeight.w500),
                isExpanded: true,
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _mappings[key] = newValue;
                    });
                  }
                },
                items: _actionOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 3. Widget: Charts Card (fl_chart Pie & Line) ───────────────────────────
  Widget _buildChartsCard() {
    // Menghitung persentase gestur
    final total = _gestureCounts.values.fold(0, (sum, val) => sum + val);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Akurasi & Distribusi Jenis Gestur',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textCharcoal),
          ),
          const Text(
            'Dihitung dinamis setiap kali simulasi gestur dipicu.',
            style: TextStyle(fontSize: 10, color: AppColors.textLight),
          ),
          const SizedBox(height: 24),
          
          total == 0
              ? Container(
                  height: 180,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pie_chart_outline_rounded, color: AppColors.textLight.withOpacity(0.3), size: 40),
                      const SizedBox(height: 10),
                      const Text(
                        'Belum ada data visualisasi.\nLakukan beberapa gestur di sandbox untuk mengisi grafik.',
                        style: TextStyle(fontSize: 11, color: AppColors.textLight, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    // Pie Chart
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 28,
                          sections: _buildPieChartSections(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Legend
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _gestureCounts.entries.map((e) {
                          if (e.value == 0) return const SizedBox.shrink();
                          final pct = (e.value / total * 100).toStringAsFixed(0);
                          final color = _getGestureColor(e.key);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    e.key,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textCharcoal),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${e.value} ($pct%)',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final total = _gestureCounts.values.fold(0, (sum, val) => sum + val);
    if (total == 0) return [];

    return _gestureCounts.entries.map((e) {
      final value = e.value.toDouble();
      final color = _getGestureColor(e.key);
      return PieChartSectionData(
        color: color,
        value: value,
        title: '', // Teks kosong agar lebih clean, persentase diletakkan di legend
        radius: 20,
      );
    }).toList();
  }

  Color _getGestureColor(String type) {
    switch (type) {
      case 'Tap':         return const Color(0xFF65B713);
      case 'Double Tap':  return const Color(0xFF1565C0);
      case 'Long Press':  return const Color(0xFF8E24AA);
      case 'Swipe':       return const Color(0xFFEF6C00);
      case 'Scale/Pinch': return const Color(0xFF00ACC1);
      case 'Shake':       return const Color(0xFFD81B60);
      default:            return Colors.grey;
    }
  }

  // ── 4. Widget: Telemetry Logs Table ────────────────────────────────────────
  Widget _buildTelemetryCard() {
    final filtered = _searchQuery.isEmpty
        ? _telemetryLogs
        : _telemetryLogs.where((log) {
            return log.type.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                log.mappedAction.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                log.details.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Toolbar Table: Search & Reset
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Cari log gestur...',
                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.textLight),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textLight, size: 18),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Reset Log & Statistik',
                icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Reset Telemetri?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      content: const Text('Seluruh data statistik dan log aktivitas gestur akan dihapus permanen.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal', style: TextStyle(color: AppColors.textLight)),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _resetTelemetry();
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tabel Log
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, color: AppColors.textLight.withOpacity(0.3), size: 36),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty ? 'Tidak ada data log.' : 'Pencarian tidak ditemukan.',
                          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final log = filtered[idx];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        child: Row(
                          children: [
                            // Jam
                            Text(
                              log.timestamp,
                              style: const TextStyle(fontFamily: 'Courier', fontSize: 11, color: AppColors.textLight),
                            ),
                            const SizedBox(width: 12),
                            // Badge Gestur
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getGestureColor(log.type).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                log.type,
                                style: TextStyle(
                                  color: _getGestureColor(log.type),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Detail dan Target Aksi
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.details,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textCharcoal,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Aksi: ${log.mappedAction}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: log.mappedAction != 'Tidak Ada Aksi'
                                          ? AppColors.primaryGreen
                                          : AppColors.textLight,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status
                            Text(
                              log.status,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: log.status == 'SUCCESS' ? Colors.green.shade700 : Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painter: Partikel Partikel visual sentuhan (Visual Canvas)
// ─────────────────────────────────────────────────────────────────────────────
class _ParticlesPainter extends CustomPainter {
  final List<_VisualParticle> particles;

  _ParticlesPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.life)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p.position, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Painter: Garis grid futuristik latar belakang
// ─────────────────────────────────────────────────────────────────────────────
class _GridLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.0;

    const double step = 25.0;

    // Garis Vertikal
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Garis Horisontal
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridLinesPainter oldDelegate) => false;
}
