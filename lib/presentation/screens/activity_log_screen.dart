import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../data/helpers/shared_prefs_helper.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({Key? key}) : super(key: key);

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  List<Map<String, String>> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivityLogs();
  }

  // LOGIKA PEMBACAAN DATA: Diperkuat casting tipe data agar 100% kebal eror runtime
  Future<void> _loadActivityLogs() async {
    try {
      // Mengambil data mentah secara dinamis untuk menghindari crash tipe data di web/mobile
      final dynamic rawData = await SharedPrefsHelper.getActivityLogs();
      
      final List<Map<String, String>> parsedLogs = [];
      
      if (rawData != null && rawData is List) {
        for (var item in rawData) {
          final Map<String, dynamic> decoded = jsonDecode(item.toString());
          parsedLogs.add({
            'action': decoded['action']?.toString() ?? '',
            'time': decoded['time']?.toString() ?? '',
          });
        }
      }

      setState(() {
        _logs = parsedLogs;
      });
    } catch (e) {
      debugPrint("Gagal memuat log riwayat dari SharedPreferences: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // DIALOG KONFIRMASI: Membersihkan laci penyimpanan riwayat secara permanen
  void _showClearConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Bersihkan Riwayat', 
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textCharcoal, fontSize: 16),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus semua catatan aktivitas?', 
          style: TextStyle(color: AppColors.textLight, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Batal', style: TextStyle(color: AppColors.textLight)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog pop-up terlebih dahulu
              try {
                await SharedPrefsHelper.clearActivityLogs();
              } catch (e) {
                debugPrint("Gagal mengeksekusi clearActivityLogs: $e");
              }
              setState(() {
                _logs.clear(); // Bersihkan list di layar secara instan
              });
            },
            child: const Text('Ya, Bersihkan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Aktivitas Saya', 
          style: TextStyle(color: AppColors.textCharcoal, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textCharcoal),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_logs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 24),
              onPressed: _showClearConfirmDialog,
              tooltip: 'Bersihkan Semua',
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off_rounded, size: 64, color: AppColors.textLight.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada riwayat aktivitas', 
                        style: TextStyle(fontSize: 14, color: AppColors.textLight.withOpacity(0.8), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                          border: Border.all(color: AppColors.cardLightGrey.withOpacity(0.5)),
                        ),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.08), 
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.bolt_rounded, color: AppColors.primaryGreen, size: 20),
                            ),
                            title: Text(
                              log['action']!, 
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textCharcoal),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                log['time']!, 
                                style: TextStyle(fontSize: 11, color: AppColors.textLight.withOpacity(0.6)),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}