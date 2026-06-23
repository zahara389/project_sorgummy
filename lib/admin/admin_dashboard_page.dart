import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sorgummi_ai/core/constants/colors.dart';
import 'package:sorgummi_ai/admin/manage_articles_screen.dart';
import 'package:sorgummi_ai/admin/sorgum_management_screen.dart';
import 'package:sorgummi_ai/admin/gesture_management_screen.dart';
import 'package:sorgummi_ai/presentation/screens/welcome_screen.dart';
import 'package:sorgummi_ai/admin/widgets/activity_line_chart.dart';
import 'package:sorgummi_ai/admin/widgets/category_bar_chart.dart';
// ─────────────────────────────────────────────────────────────────────────────
// Konstanta Layout
// ─────────────────────────────────────────────────────────────────────────────
const double _kBreakpoint  = 800.0;  // lebar min untuk tampilkan sidebar statis
const double _kSidebarWidth = 230.0; // lebar sidebar di web/layar lebar

// ─────────────────────────────────────────────────────────────────────────────
// Model: Item Sidebar
// ─────────────────────────────────────────────────────────────────────────────
class _SidebarItem {
  final IconData icon;
  final String label;
  const _SidebarItem(this.icon, this.label);
}

const List<_SidebarItem> _kMenuItems = [
  _SidebarItem(Icons.dashboard_rounded,         'Dashboard'),
  _SidebarItem(Icons.manage_accounts_rounded,   'Manajemen Pengguna'),
  _SidebarItem(Icons.menu_book_rounded,         'Edukasi & Solusi'),
  _SidebarItem(Icons.agriculture_rounded,       'Pengelolaan'),
  _SidebarItem(Icons.smart_toy_rounded,         'AI Chatbot Monitoring'),
  _SidebarItem(Icons.gesture_rounded,           'Manajemen Gestur'),
  _SidebarItem(Icons.bar_chart_rounded,         'Statistik & Analitik'),
  _SidebarItem(Icons.settings_rounded,          'Settings'),
];

// ─────────────────────────────────────────────────────────────────────────────
// Model: Kartu Ringkasan
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryData {
  final IconData icon;
  final String label;
  final String value;
  final String trend;       // mis. "+12%"
  final bool trendUp;
  final Color accentColor;
  const _SummaryData({
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
    required this.trendUp,
    required this.accentColor,
  });
}

const List<_SummaryData> _kSummary = [
  _SummaryData(
    icon: Icons.people_alt_rounded,
    label: 'Total Pengguna',
    value: '108',
    trend: '+8%',
    trendUp: true,
    accentColor: Color(0xFF2E7D32),
  ),
  _SummaryData(
    icon: Icons.chat_bubble_outline_rounded,
    label: 'Konsultasi AI',
    value: '24',
    trend: '+4',
    trendUp: true,
    accentColor: Color(0xFF1565C0),
  ),
  _SummaryData(
    icon: Icons.article_rounded,
    label: 'Artikel Edukasi',
    value: '21',
    trend: '+2',
    trendUp: true,
    accentColor: Color(0xFF6A1B9A),
  ),
  _SummaryData(
    icon: Icons.help_outline_rounded,
    label: 'Knowledge Gaps',
    value: '0',
    trend: '0',
    trendUp: true,
    accentColor: Color(0xFFE65100),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Halaman Utama: AdminDashboardPage
// ─────────────────────────────────────────────────────────────────────────────
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
  }

  Future<void> _checkAdminRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');
    if (role != 'admin') {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Navigasi ke halaman tertentu (untuk menu yang sudah ada screen-nya)
  Widget? _resolveDestination(int index) {
    switch (index) {
      case 2: return const ManageArticlesScreen();     // Edukasi & Solusi
      case 3: return const SorgumManagementScreen();   // Pengelolaan
      case 5: return const GestureManagementScreen();  // Manajemen Gestur
      default: return null;
    }
  }

  void _onMenuTap(int index) {
    final dest = _resolveDestination(index);
    if (dest != null) {
      // Navigasi ke layar terpisah untuk item yang sudah ada
      Navigator.push(context, MaterialPageRoute(builder: (_) => dest));
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar Akun Admin',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('Apakah Anda yakin ingin keluar dari panel admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textLight)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('user_role');

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= _kBreakpoint;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6F9),
          // ── MOBILE: Drawer sebagai sidebar ──────────────────────────────
          drawer: isWide
              ? null
              : Drawer(
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  child: _SidebarContent(
                    selectedIndex: _selectedIndex,
                    onMenuTap: (i) {
                      Navigator.pop(context);
                      _onMenuTap(i);
                    },
                    onLogout: _logout,
                  ),
                ),
          appBar: isWide
              ? null
              : AppBar(
                  title: Row(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.eco_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Sorgummi Admin',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textCharcoal),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.white,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(height: 1, color: const Color(0xFFEEEEEE)),
                  ),
                ),
          // ── BODY: Row(sidebar + konten) jika lebar, konten saja jika sempit ──
          body: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sidebar statis
                    SizedBox(
                      width: _kSidebarWidth,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            right: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                          ),
                        ),
                        child: _SidebarContent(
                          selectedIndex: _selectedIndex,
                          onMenuTap: _onMenuTap,
                          onLogout: _logout,
                        ),
                      ),
                    ),
                    // Konten utama
                    Expanded(
                      child: _MainContent(selectedIndex: _selectedIndex),
                    ),
                  ],
                )
              // Mobile: hanya konten
              : _MainContent(selectedIndex: _selectedIndex),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Sidebar (dipakai di Drawer dan Panel statis)
// ─────────────────────────────────────────────────────────────────────────────
class _SidebarContent extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onMenuTap;
  final VoidCallback onLogout;

  const _SidebarContent({
    required this.selectedIndex,
    required this.onMenuTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Brand / Logo ──────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF65B713)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.eco_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sorgummi AI',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textCharcoal,
                    ),
                  ),
                  Text(
                    'Admin Panel',
                    style: TextStyle(fontSize: 10, color: AppColors.textLight),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Divider
        Container(height: 1, color: const Color(0xFFF0F0F0), margin: const EdgeInsets.symmetric(horizontal: 16)),
        const SizedBox(height: 12),

        // ── Menu Items ────────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _kMenuItems.length,
            itemBuilder: (context, i) {
              final item = _kMenuItems[i];
              final bool isActive = selectedIndex == i;
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onMenuTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primaryGreen.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 18,
                            color: isActive ? AppColors.primaryGreen : AppColors.textLight,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                color: isActive ? AppColors.primaryGreen : AppColors.textCharcoal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Indikator aktif
                          if (isActive)
                            Container(
                              width: 4, height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // ── Tombol Keluar ─────────────────────────────────────────────────
        Container(height: 1, color: const Color(0xFFF0F0F0), margin: const EdgeInsets.symmetric(horizontal: 16)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onLogout,
              splashColor: Colors.red.withOpacity(0.1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                    SizedBox(width: 12),
                    Text(
                      'Keluar',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Konten Utama (kanan)
// ─────────────────────────────────────────────────────────────────────────────
class _MainContent extends StatelessWidget {
  final int selectedIndex;
  const _MainContent({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    // Semua konten per-index
    if (selectedIndex == 0) return _DashboardView();
    return _ComingSoonView(label: _kMenuItems[selectedIndex].label);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Tampilan Dashboard (index 0) — Summary Cards + Charts
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          _DashboardHeader(),
          const SizedBox(height: 24),

          // ── SISI KANAN ATAS: 4 Summary Cards ────────────────────────────
          const Text(
            'RINGKASAN DATA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textLight,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _SummaryCardsGrid(),
          const SizedBox(height: 28),

          // ── SISI KANAN BAWAH: 2 Chart Area ───────────────────────────────
          const Text(
            'ANALITIK & AKTIVITAS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textLight,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _ChartsRow(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Header Dashboard (Greeting + tanggal)
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agt','Sep','Okt','Nov','Des'];
    final days   = ['Minggu','Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'];
    final dateStr = '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF65B713)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()}, Admin! 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Zahara CRUD Master Panel · $dateStr',
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11),
                ),
              ],
            ),
          ),
          // Badge ADMIN
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: const Text(
              'ADMIN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Grid 4 Kartu Ringkasan (responsif Wrap)
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryCardsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Jika lebar cukup → 4 kolom, jika sempit → 2 kolom
        final int cols = constraints.maxWidth >= 600 ? 4 : 2;
        final double spacing = 12;
        final double cardWidth = (constraints.maxWidth - (spacing * (cols - 1))) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _kSummary.map((s) => SizedBox(
            width: cardWidth,
            child: _SummaryCard(data: s),
          )).toList(),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final _SummaryData data;
  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Ikon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: data.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.accentColor, size: 18),
              ),
              const Spacer(),
              // Trend badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: data.trendUp
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      data.trendUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 11,
                      color: data.trendUp ? Colors.green.shade700 : Colors.red,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      data.trend,
                      style: TextStyle(
                        fontSize: 10,
                        color: data.trendUp ? Colors.green.shade700 : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Nilai
          Text(
            data.value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: data.accentColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: 2-Kolom Chart Placeholder
// ─────────────────────────────────────────────────────────────────────────────
class _ChartsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool side = constraints.maxWidth >= 600;

        // Lebar cukup → berdampingan; sempit → vertikal
        if (side) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _LineChartCard()),
              const SizedBox(width: 16),
              Expanded(child: _BarChartCard()),
            ],
          );
        }

        return Column(
          children: [
            _LineChartCard(),
            const SizedBox(height: 16),
            _BarChartCard(),
          ],
        );
      },
    );
  }
}

// ─── Placeholder Chart: Aktivitas Pengguna (Line) ───────────────────────────
class _LineChartCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
          // Header kartu
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.show_chart_rounded, color: Color(0xFF2E7D32), size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aktivitas Pengguna',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textCharcoal,
                      ),
                    ),
                    Text(
                      '7 hari terakhir',
                      style: TextStyle(fontSize: 10, color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Minggu ini', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Area Chart fl_chart
          SizedBox(
            height: 160,
            child: const ActivityLineChart(),
          ),
        ],
      ),
    );
  }
}

// ─── Placeholder Chart: Kategori Paling Dicari (Bar) ────────────────────────
class _BarChartCard extends StatelessWidget {
  // Data dummy bar
  static const List<Map<String, dynamic>> _bars = [
    {'label': 'Hama',        'pct': 0.85, 'color': Color(0xFF2E7D32)},
    {'label': 'Penyakit',    'pct': 0.68, 'color': Color(0xFF558B2F)},
    {'label': 'Pemupukan',   'pct': 0.55, 'color': Color(0xFF65B713)},
    {'label': 'Panen',       'pct': 0.40, 'color': Color(0xFF8BC34A)},
    {'label': 'Irigasi',     'pct': 0.22, 'color': Color(0xFFC5E1A5)},
  ];

  @override
  Widget build(BuildContext context) {
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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF1565C0), size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kategori Paling Dicari',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textCharcoal,
                      ),
                    ),
                    Text(
                      'Top pertanyaan AI bulan ini',
                      style: TextStyle(fontSize: 10, color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Vertical Bar Chart using fl_chart
          SizedBox(
            height: 180,
            child: const CategoryBarChart(),
          ),
        ],
      ),
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// Widget: Tampilan "Segera Hadir" untuk menu yang belum ada kontennya
// ─────────────────────────────────────────────────────────────────────────────
class _ComingSoonView extends StatelessWidget {
  final String label;
  const _ComingSoonView({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.construction_rounded,
                size: 56,
                color: AppColors.primaryGreen.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textCharcoal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Halaman ini sedang dalam pengembangan.\nSegera hadir pada versi berikutnya.',
              style: TextStyle(fontSize: 13, color: AppColors.textLight, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
