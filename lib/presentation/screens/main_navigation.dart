import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import 'home_screen.dart';
import 'chat_screen.dart';
import 'pengelolaan_screen.dart';
// Import halaman baru agar terbaca di navigasi bawah
import 'edukasi_screen.dart';
import 'profile_screen.dart';

import '../../admin/widgets/global_gesture_assistant.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Daftar layar sudah dihubungkan ke halaman aslinya
  final List<Widget> _screens = [
    const HomeScreen(),
    const EdukasiScreen(),       // Teks placeholder diganti menjadi halaman asli
    const PengelolaanScreen(),
    const ChatScreen(),
    const ProfileScreen(),       // Teks placeholder diganti menjadi halaman asli
  ];

  @override
  Widget build(BuildContext context) {
    return GlobalGestureAssistant(
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        body: _screens[_currentIndex],
        bottomNavigationBar: _buildCustomBottomNav(),
      ),
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 8), 
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(icon: Icons.home, inactiveIcon: Icons.home_outlined, label: 'Beranda', index: 0),
            _buildNavItem(icon: Icons.menu_book, inactiveIcon: Icons.menu_book_outlined, label: 'Edukasi', index: 1),
            _buildNavItem(icon: Icons.eco, inactiveIcon: Icons.eco_outlined, label: 'Pengelolaan', index: 2),
            _buildNavItem(icon: Icons.smart_toy, inactiveIcon: Icons.smart_toy_outlined, label: 'Chat AI', index: 3),
            _buildNavItem(icon: Icons.person, inactiveIcon: Icons.person_outline, label: 'Profil', index: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData inactiveIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? icon : inactiveIcon,
            color: isSelected ? AppColors.primaryGreen : Colors.grey.shade400,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.primaryGreen : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}