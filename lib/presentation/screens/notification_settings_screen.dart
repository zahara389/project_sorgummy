import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // Variabel state penampung status on/off masing-masing switch
  bool _articleNotif = true;
  bool _managementNotif = true;
  bool _aiUpdateNotif = false;

  @override
  void initState() {
    super.initState();
    _loadSettingsData();
  }

  // 1. Memuat data status notifikasi yang tersimpan di memori lokal perangkat
  Future<void> _loadSettingsData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _articleNotif = prefs.getBool('notif_article') ?? true;
      _managementNotif = prefs.getBool('notif_management') ?? true;
      _aiUpdateNotif = prefs.getBool('notif_ai_update') ?? false;
    });
  }

  // 2. Fungsi pembantu untuk menyimpan status baru ke storage secara real-time
  Future<void> _updateSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    
    // Memberikan feedback pop-up kecil yang rapi
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Pengaturan notifikasi berhasil diperbarui'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppColors.textCharcoal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false), // Sembunyikan scrollbar web kaku
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        appBar: AppBar(
          title: const Text(
            'Pengaturan Notifikasi', 
            style: TextStyle(color: AppColors.textCharcoal, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white, 
          centerTitle: true,
          leading: const BackButton(color: AppColors.textCharcoal),
          elevation: 0,
          // Garis pembatas bawah tipis dan estetik khas modul Sorgummi
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(color: AppColors.cardLightGrey, height: 1.0),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: double.infinity),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  // Switch 1: Artikel Baru
                  _buildSwitchTile(
                    title: 'Notifikasi Artikel Baru',
                    subtitle: 'Dapatkan info edukasi sorgum paling update.',
                    value: _articleNotif,
                    onChanged: (val) {
                      setState(() => _articleNotif = val);
                      _updateSetting('notif_article', val);
                    },
                  ),
                  const SizedBox(height: 8),

                  // Switch 2: Pengingat Budidaya
                  _buildSwitchTile(
                    title: 'Pengingat Pengelolaan (Pupuk/Air)',
                    subtitle: 'Notifikasi jadwal siram dan pemupukan lahan.',
                    value: _managementNotif,
                    onChanged: (val) {
                      setState(() => _managementNotif = val);
                      _updateSetting('notif_management', val);
                    },
                  ),
                  const SizedBox(height: 8),

                  // Switch 3: Update AI
                  _buildSwitchTile(
                    title: 'Pembaruan Sorgummi AI',
                    subtitle: 'Info fitur baru dan tips berkala dari AI.',
                    value: _aiUpdateNotif,
                    onChanged: (val) {
                      setState(() => _aiUpdateNotif = val);
                      _updateSetting('notif_ai_update', val);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Komponen pembangun baris switch yang bersih dan berjarak rapi
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardLightGrey, width: 1),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: SwitchListTile(
          title: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textCharcoal),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
          ),
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: AppColors.primaryGreen,
          inactiveThumbColor: Colors.grey.shade400,
          inactiveTrackColor: AppColors.cardLightGrey,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        ),
      ),
    );
  }
}