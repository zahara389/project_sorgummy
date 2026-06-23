import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../data/helpers/shared_prefs_helper.dart';
import '../../data/helpers/database_helper.dart'; 
import 'welcome_screen.dart';

import 'edit_profile_screen.dart';
import 'saved_articles_screen.dart';
import 'activity_log_screen.dart'; 
import 'notification_settings_screen.dart';
import 'security_screen.dart';
import 'help_center_screen.dart';
import 'about_screen.dart';

// FIX PATH IMPORT: Sudah disesuaikan rill dengan nama project kelompokmu 'sorgummi_ai'
import 'package:sorgummi_ai/admin/manage_articles_screen.dart';
import 'package:sorgummi_ai/admin/sorgum_management_screen.dart';
import 'package:sorgummi_ai/admin/gesture_management_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  String? _base64Image;

  String _userName = 'Petani Hebat';
  String _userEmail = 'petani@sorgummi.com';
  String _userPhone = '081234567890';
  String _userAddress = 'Bandung, Jawa Barat';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllProfileData();
  }

  Future<void> _loadAllProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // KEY 1: Ambil Foto Profil
      _base64Image = prefs.getString('user_profile_image'); 

      if (kIsWeb) {
        final String? loggedEmail = prefs.getString('logged_user_email');
        if (loggedEmail != null && loggedEmail.isNotEmpty) {
          final storedUsers = prefs.getString('web_users') ?? '{}';
          final Map<String, dynamic> userMap = jsonDecode(storedUsers);
          if (userMap.containsKey(loggedEmail)) {
            final currentUser = Map<String, dynamic>.from(userMap[loggedEmail]);
            setState(() {
              _userName = currentUser['name'] ?? 'Petani Hebat';
              _userEmail = currentUser['email'] ?? 'petani@sorgummi.com';
              _userPhone = currentUser['phone'] ?? '081234567890';
              _userAddress = prefs.getString('web_profile_address') ?? 'Bandung, Jawa Barat';
            });
          } else {
            setState(() {
              _userName = prefs.getString('web_profile_name') ?? 'Petani Hebat';
              _userEmail = prefs.getString('web_profile_email') ?? 'petani@sorgummi.com';
              _userPhone = prefs.getString('web_profile_phone') ?? '081234567890';
              _userAddress = prefs.getString('web_profile_address') ?? 'Bandung, Jawa Barat';
            });
          }
        } else {
          setState(() {
            _userName = prefs.getString('web_profile_name') ?? 'Petani Hebat';
            _userEmail = prefs.getString('web_profile_email') ?? 'petani@sorgummi.com';
            _userPhone = prefs.getString('web_profile_phone') ?? '081234567890';
            _userAddress = prefs.getString('web_profile_address') ?? 'Bandung, Jawa Barat';
          });
        }
      } else {
        final String? loggedEmail = prefs.getString('logged_user_email');
        final profileMap = await DatabaseHelper.instance.getUserProfile();
        if (loggedEmail != null && loggedEmail.isNotEmpty) {
          final currentUser = await DatabaseHelper.instance.getUserByEmail(loggedEmail);
          if (currentUser != null) {
            setState(() {
              _userName = currentUser['name'] ?? 'Petani Hebat';
              _userEmail = currentUser['email'] ?? 'petani@sorgummi.com';
              _userPhone = currentUser['phone'] ?? '081234567890';
              _userAddress = profileMap?['address'] ?? 'Bandung, Jawa Barat';
            });
          } else if (profileMap != null) {
            setState(() {
              _userName = profileMap['name'] ?? 'Petani Hebat';
              _userEmail = profileMap['email'] ?? 'petani@sorgummi.com';
              _userPhone = profileMap['phone'] ?? '081234567890';
              _userAddress = profileMap['address'] ?? 'Bandung, Jawa Barat';
            });
          }
        } else if (profileMap != null) {
          setState(() {
            _userName = profileMap['name'] ?? 'Petani Hebat';
            _userEmail = profileMap['email'] ?? 'petani@sorgummi.com';
            _userPhone = profileMap['phone'] ?? '081234567890';
            _userAddress = profileMap['address'] ?? 'Bandung, Jawa Barat';
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal mengambil data profil: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    Navigator.pop(context);
    final XFile? selectedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (selectedImage != null) {
      final bytes = await selectedImage.readAsBytes();
      final base64String = base64Encode(bytes);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile_image', base64String); 
      
      try {
        await SharedPrefsHelper.saveActivity('Memperbarui foto profil akun');
      } catch (e) {
        debugPrint("Gagal mencatat log aktivitas: $e");
      }

      setState(() {
        _base64Image = base64String;
      });
      _showCompactTopToast('Foto profil diperbarui!');
    }
  }

  Future<void> _deleteImage() async {
    Navigator.pop(context);
    if (_base64Image == null || _base64Image!.isEmpty) {
      _showCompactTopToast('Foto profil memang kosong', isError: true);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_profile_image');
    
    try {
      await SharedPrefsHelper.saveActivity('Menghapus foto profil akun');
    } catch (e) {
      debugPrint("Gagal mencatat log aktivitas: $e");
    }

    setState(() {
      _base64Image = null;
    });
    _showCompactTopToast('Foto profil dihapus!');
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.cardLightGrey, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 24),
              const Text('Foto Profil Saya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textCharcoal)),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.photo_library_rounded, color: AppColors.primaryGreen, size: 20)),
                title: const Text('Pilih dari Galeri HP', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textCharcoal)),
                onTap: _pickImage,
              ),
              Divider(height: 1, color: AppColors.cardLightGrey.withOpacity(0.5)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20)),
                title: const Text('Hapus Foto Saat Ini', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                onTap: _deleteImage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          currentName: _userName,
          currentEmail: _userEmail,
          currentPhone: _userPhone,
          currentAddress: _userAddress,
        ),
      ),
    );
    if (result == true) {
      try {
        await SharedPrefsHelper.saveActivity('Mengubah informasi biodata profil');
      } catch (e) {
        debugPrint("Gagal mencatat log aktivitas: $e");
      }
      _loadAllProfileData(); 
    }
  }

  void _doLogout(BuildContext context) async {
    debugPrint('🚪 Logout process started');
    
    await SharedPrefsHelper.setLoggedIn(false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_profile_image');
    final String? currentEmail = prefs.getString('logged_user_email');

    try {
      await SharedPrefsHelper.clearActivityLogs(userEmail: currentEmail);
      debugPrint('✅ Riwayat aktivitas dibersihkan');
    } catch (e) {
      debugPrint("⚠️ Gagal membersihkan riwayat aktivitas saat logout: $e");
    }

    await prefs.remove('logged_user_email');
    await SharedPrefsHelper.clearRememberMeEmail();
    debugPrint('✅ Session dihapus (email, remember_me)');
    debugPrint('✅ Logout berhasil - Akun tetap tersimpan, user bisa login kembali');

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()), (route) => false);
    }
  }

  void _showCompactTopToast(String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 0,
        right: 0,
        child: Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: isError ? const Color(0xFFFFF2F2) : const Color(0xFFF2FDF5),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: isError ? Colors.red.withOpacity(0.2) : AppColors.primaryGreen.withOpacity(0.2), width: 1),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isError ? Icons.error_rounded : Icons.check_circle_rounded, color: isError ? Colors.redAccent : AppColors.primaryGreen, size: 18),
                  const SizedBox(width: 10),
                  Text(message, style: TextStyle(color: isError ? Colors.red.shade900 : const Color(0xFF1B5E20), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.1)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(milliseconds: 2200), () => overlayEntry.remove());
  }

  Widget _buildAvatarWidget() {
    if (_base64Image != null && _base64Image!.isNotEmpty) {
      return CircleAvatar(radius: 50, backgroundColor: AppColors.cardLightGrey, backgroundImage: MemoryImage(base64Decode(_base64Image!)));
    }
    String initial = _userName.isNotEmpty ? _userName[0].toUpperCase() : 'P';
    return CircleAvatar(
      radius: 50,
      backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
      child: Text(initial, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primaryGreen)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true); 
        return false;
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: Scaffold(
          backgroundColor: AppColors.backgroundWhite,
          appBar: AppBar(
            title: const Text('Profil Saya', style: TextStyle(color: AppColors.textCharcoal, fontSize: 18, fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.backgroundWhite,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textCharcoal), onPressed: () => Navigator.pop(context, true)),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    children: [
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _showAvatarOptions,
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3), width: 2)), child: _buildAvatarWidget()),
                                  Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle), child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(_userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textCharcoal)),
                            const SizedBox(height: 4),
                            Text(_userEmail, style: const TextStyle(fontSize: 14, color: AppColors.textLight)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen.withOpacity(0.1), foregroundColor: AppColors.primaryGreen, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10)),
                              onPressed: _navigateToEditProfile, 
                              child: const Text('Edit Profil', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ==================== COUPLING MENU PANEL ADMIN DINAMIS ====================
                      if (_userEmail.contains('admin')) ...[
                        _buildMenuSection(
                          context: context,
                          title: 'Panel Pengendalian Admin (Zahara CRUD Master)',
                          items: [
                            _MenuData(
                              icon: Icons.article_rounded, 
                              title: 'Kelola Master Artikel Edukasi', 
                              destination: const ManageArticlesScreen()
                            ),
                            _MenuData(
                              icon: Icons.agriculture_rounded, 
                              title: 'Kelola Stok & Hasil Panen', 
                              destination: const SorgumManagementScreen()
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // SECTION: PENGATURAN AKUN (Bawaan Petani)
                      _buildMenuSection(
                        context: context,
                        title: 'Pengaturan Akun',
                        items: [
                          _MenuData(icon: Icons.bookmark_border, title: 'Artikel Tersimpan', destination: const SavedArticlesScreen()),
                          _MenuData(icon: Icons.history_rounded, title: 'Aktivitas Saya', destination: const ActivityLogScreen()),
                          _MenuData(icon: Icons.notifications_none, title: 'Notifikasi', destination: const NotificationSettingsScreen()),
                          _MenuData(icon: Icons.lock_outline, title: 'Keamanan & Password', destination: const SecurityScreen()),
                          _MenuData(icon: Icons.gesture_rounded, title: 'Pengaturan Gestur & Pintasan', destination: const GestureManagementScreen()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildMenuSection(
                        context: context,
                        title: 'Lainnya',
                        items: [
                          _MenuData(icon: Icons.help_outline, title: 'Pusat Bantuan', destination: const HelpCenterScreen()),
                          _MenuData(icon: Icons.info_outline, title: 'Tentang Sorgummi AI', destination: const AboutScreen()),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: TextButton(
                          style: TextButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.05), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                          onPressed: () => _showLogOutDialog(context),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text('Keluar Akun', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildMenuSection({required BuildContext context, required String title, required List<_MenuData> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(left: 8, bottom: 12), child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textCharcoal))),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 4))]),
          child: Column(
            children: items.asMap().entries.map((entry) {
              int index = entry.key;
              _MenuData data = entry.value;
              bool isLast = index == items.length - 1;
              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: _getBorderRadius(index, items.length),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => data.destination)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Icon(data.icon, color: AppColors.textLight, size: 24),
                            const SizedBox(width: 16),
                            Expanded(child: Text(data.title, style: const TextStyle(fontSize: 14, color: AppColors.textCharcoal, fontWeight: FontWeight.w500))),
                            const Icon(Icons.chevron_right, color: AppColors.dividerGrey, size: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!isLast) Divider(height: 1, color: AppColors.dividerGrey.withOpacity(0.5), indent: 60, endIndent: 20),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  BorderRadius _getBorderRadius(int index, int totalItems) {
    if (totalItems == 1) return BorderRadius.circular(20);
    if (index == 0) return const BorderRadius.vertical(top: Radius.circular(20));
    if (index == totalItems - 1) return const BorderRadius.vertical(bottom: Radius.circular(20));
    return BorderRadius.zero;
  }

  void _showLogOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textCharcoal)),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?', style: TextStyle(color: AppColors.textLight)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: AppColors.textLight))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              Navigator.pop(context);
              _doLogout(context);
            },
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
  }
}

class _MenuData {
  final IconData icon;
  final String title;
  final Widget destination;

  _MenuData({required this.icon, required this.title, required this.destination});
}