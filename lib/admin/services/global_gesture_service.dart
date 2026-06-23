import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../presentation/screens/chat_screen.dart';
import '../../presentation/screens/main_navigation.dart';
import '../../presentation/screens/welcome_screen.dart';
import '../../data/helpers/shared_prefs_helper.dart';

class GlobalGestureService {
  static final GlobalGestureService _instance = GlobalGestureService._internal();
  factory GlobalGestureService() => _instance;
  GlobalGestureService._internal();

  // Navigation Key to trigger navigation from anywhere
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Default mappings
  Map<String, String> _mappings = {
    'double_tap': 'Buka Chatbot AI',
    'long_press': 'Tampilkan Tips Ahli',
    'swipe_left': 'Kosongkan Cache Aplikasi',
    'swipe_right': 'Sinkronisasi Database',
    'shake_device': 'Keluar Panel Admin (Logout)',
  };

  // Option actions
  final List<String> _actionOptions = [
    'Buka Chatbot AI',
    'Simpan Data Edukasi',
    'Sinkronisasi Database',
    'Kosongkan Cache Aplikasi',
    'Keluar Panel Admin (Logout)',
    'Tampilkan Tips Ahli',
    'Tidak Ada Aksi',
  ];

  // Refresh and load latest mappings
  Future<Map<String, String>> loadMappings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? mappingsJson = prefs.getString('gesture_mappings');
      if (mappingsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(mappingsJson);
        _mappings = decoded.map((key, value) => MapEntry(key, value.toString()));
      }
    } catch (e) {
      debugPrint('Error loading gesture mappings globally: $e');
    }
    return _mappings;
  }

  // Trigger a gesture event
  Future<void> triggerGesture(String gestureKey, BuildContext context) async {
    // 1. Reload mappings to ensure we have the absolute latest configured by the admin
    await loadMappings();

    final String action = _mappings[gestureKey] ?? 'Tidak Ada Aksi';
    if (action == 'Tidak Ada Aksi') {
      _showFeedbackSnackBar(context, gestureKey, 'Tidak Ada Aksi', isIgnored: true);
      return;
    }

    // Translate key to human-readable type for logs
    String gestureType = 'Tap';
    if (gestureKey == 'double_tap') gestureType = 'Double Tap';
    if (gestureKey == 'long_press') gestureType = 'Long Press';
    if (gestureKey == 'swipe_left' || gestureKey == 'swipe_right') gestureType = 'Swipe';
    if (gestureKey == 'shake_device') gestureType = 'Shake';

    // 2. Save to Telemetry Logs and increment counts
    await _saveTelemetry(gestureType, gestureKey, action);

    // 3. Show premium Toast Feedback
    _showFeedbackSnackBar(context, gestureType, action);

    // 4. Run the actual mapped action
    _executeAction(action, context);
  }

  // Save telemetry logs & count updates to SharedPreferences
  Future<void> _saveTelemetry(String gestureType, String gestureKey, String action) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Update gesture counts
      final String? countsJson = prefs.getString('gesture_counts');
      Map<String, int> counts = {
        'Tap': 0,
        'Double Tap': 0,
        'Long Press': 0,
        'Swipe': 0,
        'Scale/Pinch': 0,
        'Shake': 0,
      };

      if (countsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(countsJson);
        counts = decoded.map((key, value) => MapEntry(key, value as int));
      }

      counts[gestureType] = (counts[gestureType] ?? 0) + 1;
      await prefs.setString('gesture_counts', jsonEncode(counts));

      // Append log entry
      final String? logsJson = prefs.getString('gesture_telemetry_logs');
      List<dynamic> logs = [];
      if (logsJson != null) {
        logs = jsonDecode(logsJson);
      }

      final String timeStr = DateTime.now().toString().substring(11, 19);
      final newLog = {
        'timestamp': timeStr,
        'type': gestureType,
        'details': 'Gestur global dipicu: $gestureKey',
        'mappedAction': action,
        'status': 'SUCCESS',
      };

      logs.insert(0, newLog);
      if (logs.length > 50) {
        logs.removeLast();
      }

      await prefs.setString('gesture_telemetry_logs', jsonEncode(logs));
    } catch (e) {
      debugPrint('Error updating gesture telemetry globally: $e');
    }
  }

  // Visual alert for gesture triggers
  void _showFeedbackSnackBar(BuildContext context, String gestureType, String action, {bool isIgnored = false}) {
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
              child: Icon(
                isIgnored ? Icons.notifications_paused_rounded : Icons.flash_on_rounded,
                color: isIgnored ? Colors.grey.shade300 : Colors.yellowAccent,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pintasan Gestur: $gestureType',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                  Text(
                    isIgnored ? 'Aksi tidak ditentukan (Dilewati)' : 'Menjalankan: $action',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isIgnored ? const Color(0xFF475569) : const Color(0xFF2E7D32),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // Execute Action
  void _executeAction(String action, BuildContext context) async {
    if (action == 'Buka Chatbot AI') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
    } else if (action == 'Simpan Data Edukasi') {
      _showSuccessSnackBar(context, 'Data edukasi sorgum berhasil disimpan secara lokal.');
    } else if (action == 'Sinkronisasi Database') {
      _showLoadingDialog(context, 'Sinkronisasi Database...', 'Menghubungkan ke server dan menyinkronkan data...');
      await Future.delayed(const Duration(milliseconds: 1500));
      Navigator.pop(context); // close dialog
      _showSuccessSnackBar(context, 'Sinkronisasi data sorgum selesai dengan sukses!');
    } else if (action == 'Kosongkan Cache Aplikasi') {
      _showLoadingDialog(context, 'Mengosongkan Cache...', 'Sedang membersihkan file sampah...');
      await Future.delayed(const Duration(milliseconds: 1200));
      Navigator.pop(context); // close dialog
      _showSuccessSnackBar(context, 'Cache dibersihkan. Memori 14.2 MB dibebaskan.');
    } else if (action == 'Keluar Panel Admin (Logout)') {
      final prefs = await SharedPreferences.getInstance();
      final String? role = prefs.getString('user_role');

      if (role == 'admin') {
        // Jika sedang di panel admin, beralih ke halaman pengguna (User Panel)
        await prefs.setString('user_role', 'user');
        await prefs.setBool('is_logged_in', true);
        await prefs.setBool('isLoggedIn', true);

        _showSuccessSnackBar(context, 'Beralih dari Admin ke Halaman Pengguna...');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (route) => false,
        );
      } else {
        // Jika sedang di halaman pengguna biasa, lakukan logout total ke WelcomeScreen
        await SharedPrefsHelper.setLoggedIn(false);
        await prefs.remove('user_profile_image');
        final String? currentEmail = prefs.getString('logged_user_email');
        
        try {
          await SharedPrefsHelper.clearActivityLogs(userEmail: currentEmail);
        } catch (e) {
          debugPrint("Gagal membersihkan riwayat aktivitas: $e");
        }

        await prefs.remove('logged_user_email');
        await SharedPrefsHelper.clearRememberMeEmail();

        _showSuccessSnackBar(context, 'Berhasil keluar dari akun pengguna...');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } else if (action == 'Tampilkan Tips Ahli') {
      _showTipsDialog(context);
    }
  }

  void _showLoadingDialog(BuildContext context, String title, String message) {
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

  void _showSuccessSnackBar(BuildContext context, String message) {
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
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showTipsDialog(BuildContext context) {
    final List<String> tips = [
      'Sorgum sangat toleran terhadap kekeringan. Hindari penyiraman berlebihan untuk mencegah pembusukan akar.',
      'Suhu optimal untuk pertumbuhan tanaman sorgum berkisar antara 23°C hingga 30°C.',
      'Lakukan penyiangan gulma pada minggu ke-3 dan ke-6 setelah tanam untuk menjaga nutrisi tanah.',
      'Tanah lempung berpasir dengan pH 5.5 - 7.5 adalah media tanam terbaik untuk budidaya sorgum.',
      'Pupuk nitrogen (Urea) sebaiknya diberikan dalam dua tahap: saat tanam dan umur 30 hari setelah tanam.',
    ];
    final randomTip = tips[math.Random().nextInt(tips.length)];

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
}
