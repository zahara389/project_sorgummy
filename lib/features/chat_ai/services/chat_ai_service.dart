// lib/features/chat_ai/services/chat_ai_service.dart
// Service extended khusus Chat AI Assessment 3.
// Mengelola pesan dengan isFavorite, replyTo, statistik.
// Menggunakan SharedPreferences dengan key berbeda dari ChatService milik anggota lain.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

class ChatAiService extends ChangeNotifier {
  static const String _msgsKey = 'chat_ai_messages_v2';

  // In-memory store: chatId -> List<ChatMessage>
  final Map<String, List<ChatMessage>> _messagesByChatId = {};
  bool _initialized = false;

  // ─── Init ───────────────────────────────────────────────────────────────────

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    await _loadFromPrefs();
    _initialized = true;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_msgsKey);
    if (raw != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final List<dynamic> list = entry.value as List<dynamic>;
          _messagesByChatId[entry.key] = list
              .map((e) => ChatMessage.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      } catch (e) {
        debugPrint('ChatAiService load error: $e');
      }
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _messagesByChatId.map(
      (k, v) => MapEntry(k, v.map((m) => m.toMap()).toList()),
    );
    await prefs.setString(_msgsKey, jsonEncode(encoded));
  }

  // ─── Messages ───────────────────────────────────────────────────────────────

  List<ChatMessage> getMessages(String chatId) {
    return List.unmodifiable(_messagesByChatId[chatId] ?? []);
  }

  Future<ChatMessage> addMessage({
    required String chatId,
    required String role,
    required String content,
    String? replyToId,
    String? replyToContent,
    String? replyToRole,
  }) async {
    await ensureInitialized();
    _messagesByChatId.putIfAbsent(chatId, () => []);
    final msg = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_${role}_${chatId.hashCode}',
      chatId: chatId,
      content: content,
      role: role,
      timestamp: DateTime.now(),
      isFavorite: false,
      replyToId: replyToId,
      replyToContent: replyToContent,
      replyToRole: replyToRole,
    );
    _messagesByChatId[chatId]!.add(msg);
    await _persist();
    notifyListeners();
    return msg;
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    await ensureInitialized();
    _messagesByChatId[chatId]?.removeWhere((m) => m.id == messageId);
    await _persist();
    notifyListeners();
  }

  Future<void> toggleFavorite(String chatId, String messageId) async {
    await ensureInitialized();
    final list = _messagesByChatId[chatId];
    if (list == null) return;
    final idx = list.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    list[idx] = list[idx].copyWith(isFavorite: !list[idx].isFavorite);
    await _persist();
    notifyListeners();
  }

  Future<void> syncFromChatService(
    String chatId,
    List<Map<String, dynamic>> rawMessages,
  ) async {
    await ensureInitialized();
    // Only sync if we have no local messages for this chat
    if (_messagesByChatId[chatId] == null || _messagesByChatId[chatId]!.isEmpty) {
      final synced = rawMessages.asMap().entries.map((e) {
        final raw = e.value;
        return ChatMessage(
          id: '${(raw['timestamp'] as DateTime).millisecondsSinceEpoch}_${raw['role']}_$chatId',
          chatId: chatId,
          content: raw['content'] as String,
          role: raw['role'] as String,
          timestamp: raw['timestamp'] as DateTime,
        );
      }).toList();
      _messagesByChatId[chatId] = synced;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> clearChat(String chatId) async {
    await ensureInitialized();
    _messagesByChatId.remove(chatId);
    await _persist();
    notifyListeners();
  }

  // ─── Statistics ─────────────────────────────────────────────────────────────

  int getTotalMessages(String chatId) =>
      _messagesByChatId[chatId]?.length ?? 0;

  int getTotalUserMessages(String chatId) =>
      _messagesByChatId[chatId]?.where((m) => m.isUser).length ?? 0;

  int getTotalFavorites(String chatId) =>
      _messagesByChatId[chatId]?.where((m) => m.isFavorite).length ?? 0;

  int getGlobalFavoriteCount() {
    int count = 0;
    for (final list in _messagesByChatId.values) {
      count += list.where((m) => m.isFavorite).length;
    }
    return count;
  }

  // ─── AI Reply Builder ────────────────────────────────────────────────────────

  String buildAiReply(String userMessage, String mode) {
    final lower = userMessage.toLowerCase();

    if (lower.contains('sorgum') || lower.contains('sorghum')) {
      if (mode == 'cepat') {
        return 'Sorgum adalah tanaman serealia yang cocok untuk tanah kering. Tanyakan langsung mengenai budidaya atau produk sorgum.';
      }
      if (mode == 'mendalam') {
        return 'Sorgum adalah tanaman serealia yang cocok untuk tanah kering. Berikut beberapa poin penting:\n\n'
            '1. Sorgum tahan kekeringan dan cocok untuk lahan terbatas.\n'
            '2. Dapat dipakai untuk tepung, pakan ternak, dan industri makanan.\n'
            '3. Mendukung diversifikasi pangan lokal dan peluang UMKM.\n\n'
            'Tanya tentang pemupukan, irigasi, atau panen untuk detail lebih lanjut.';
      }
      return 'Sorgum adalah tanaman serealia yang cocok untuk tanah kering. Jika Anda ingin informasi lebih lanjut, tanyakan tentang pemupukan, irigasi, atau panen.';
    }

    if (lower.contains('panen') || lower.contains('hasil')) {
      if (mode == 'cepat') {
        return 'Panen sorgum terbaik saat tanaman sudah matang dan kondisi tanah stabil.';
      }
      if (mode == 'mendalam') {
        return 'Untuk panen optimal:\n\n'
            '1. Pastikan bulir sorgum kering dan keras.\n'
            '2. Periksa kadar air sebelum panen.\n'
            '3. Lakukan panen pagi hari untuk mengurangi kerusakan.\n'
            '4. Simpan hasil panen di tempat kering.\n\n'
            'Langkah ini membantu menjaga kualitas dan mengurangi risiko jamur.';
      }
      return 'Untuk panen optimal, pastikan tanaman sudah matang sempurna dan kondisi tanah stabil.';
    }

    if (lower.contains('pupuk') || lower.contains('pemupukan')) {
      if (mode == 'cepat') {
        return 'Pemupukan sorgum umumnya dilakukan dengan pupuk NPK seimbang sejak awal pertumbuhan.';
      }
      if (mode == 'mendalam') {
        return 'Pemupukan sorgum:\n\n'
            '1. Gunakan NPK seimbang.\n'
            '2. Berikan pupuk dasar sebelum tanam.\n'
            '3. Tambahkan pupuk susulan saat vegetatif.\n'
            '4. Hindari pemupukan berlebihan agar tidak merusak akar.';
      }
      return 'Pemupukan sorgum biasanya dilakukan pada fase awal pertumbuhan menggunakan pupuk NPK seimbang.';
    }

    if (lower.contains('hama') || lower.contains('penyakit')) {
      if (mode == 'cepat') {
        return 'Kendalikan hama sorgum dengan pestisida nabati atau kimia sesuai dosis anjuran.';
      }
      if (mode == 'mendalam') {
        return 'Pengendalian hama dan penyakit sorgum:\n\n'
            '1. Identifikasi hama yang menyerang (lalat bibit, ulat, dll).\n'
            '2. Gunakan pestisida nabati sebagai langkah awal.\n'
            '3. Jika parah, gunakan pestisida kimia sesuai dosis.\n'
            '4. Lakukan rotasi tanaman untuk mencegah resistensi.';
      }
      return 'Kendalikan hama sorgum dengan pestisida sesuai dosis anjuran dan lakukan rotasi tanaman secara rutin.';
    }

    if (mode == 'cepat') {
      return 'Terima kasih atas pertanyaan Anda: "$userMessage". Silakan tanyakan lebih lanjut tentang budidaya sorgum.';
    }

    if (mode == 'mendalam') {
      return 'Terima kasih atas pertanyaan Anda: "$userMessage".\n\n'
          'Saya siap membantu dengan informasi mendalam tentang:\n'
          '1. Budidaya sorgum\n'
          '2. Pemupukan dan irigasi\n'
          '3. Pengendalian hama\n'
          '4. Panen dan pascapanen\n\n'
          'Silakan spesifikasikan pertanyaan Anda.';
    }

    return 'Saya menerima pertanyaan Anda: "$userMessage". Apa yang ingin Anda ketahui tentang sorgum atau budidaya lainnya?';
  }
}
