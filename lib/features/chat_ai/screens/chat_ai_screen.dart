// lib/features/chat_ai/screens/chat_ai_screen.dart
// Screen utama Chat AI Assessment 3.
// Menggunakan: flutter_tts, speech_to_text, lottie, flutter_slidable, share_plus.
// Gesture: LongPress, Swipe kiri/kanan (slidable), Drag untuk panel riwayat.
// TIDAK mengubah fitur lain — hanya menggunakan ChatProvider dan ChatService yang ada.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants/colors.dart';
import '../../../providers/chat_provider.dart';
import '../../../models/chat_model.dart';
import '../services/chat_ai_service.dart';
import '../models/chat_message.dart';
import '../widgets/ai_message_bubble.dart';
import '../widgets/user_message_bubble.dart';
import '../widgets/ai_thinking_indicator.dart';
import '../widgets/ai_status_card.dart';
import '../widgets/chat_history_card.dart';
import '../widgets/chat_stats_section.dart';

class ChatAiScreen extends StatefulWidget {
  const ChatAiScreen({Key? key}) : super(key: key);

  @override
  State<ChatAiScreen> createState() => _ChatAiScreenState();
}

class _ChatAiScreenState extends State<ChatAiScreen>
    with TickerProviderStateMixin {
  // ─── Controllers ───────────────────────────────────────────────────────────
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // ─── Services ──────────────────────────────────────────────────────────────
  final ChatAiService _aiService = ChatAiService();
  final stt.SpeechToText _stt = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  // ─── State ─────────────────────────────────────────────────────────────────
  bool _isThinking = false;
  bool _isListening = false;
  bool _sttAvailable = false;
  bool _panelOpen = false; // panel riwayat kiri — default tertutup
  double _panelDragStartX = 0;

  // Reply state
  ChatMessage? _replyToMessage;

  // ─── Panel width ───────────────────────────────────────────────────────────
  static const double _panelWidth = 300;

  @override
  void initState() {
    super.initState();
    _initStt();
    _initTts();
  }

  Future<void> _initStt() async {
    try {
      _sttAvailable = await _stt.initialize(
        onStatus: (status) {
          debugPrint('[STT] status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (error) {
          debugPrint('[STT] error: ${error.errorMsg}');
          if (mounted) setState(() => _isListening = false);
        },
        debugLogging: false,
      );
      debugPrint('[STT] available: $_sttAvailable');
    } catch (e) {
      debugPrint('[STT] init exception: $e');
      _sttAvailable = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _initTts() async {
    // Cek bahasa yang tersedia dan set ke Bahasa Indonesia
    final languages = await _tts.getLanguages;
    final langList = List<dynamic>.from(languages ?? []);
    final hasIndonesian = langList.any((l) =>
        l.toString().toLowerCase().contains('id'));

    if (hasIndonesian) {
      // Coba berbagai format kode Bahasa Indonesia
      final candidates = ['id-ID', 'id_ID', 'id', 'in-ID', 'in_ID'];
      for (final lang in candidates) {
        final result = await _tts.setLanguage(lang);
        if (result == 1) break; // berhasil
      }
    } else {
      // Fallback ke bahasa default
      await _tts.setLanguage('en-US');
    }

    await _tts.setSpeechRate(0.45);  // sedikit lebih lambat agar jelas
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);        // pitch natural
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _stt.stop();
    _tts.stop();
    super.dispose();
  }

  // ─── STT toggle ────────────────────────────────────────────────────────────
  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stt.stop();
      setState(() => _isListening = false);
      return;
    }

    // Coba inisialisasi ulang jika belum tersedia
    if (!_sttAvailable) {
      await _initStt();
    }

    if (!_sttAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mikrofon tidak tersedia. Pastikan izin mikrofon sudah diberikan di pengaturan.',
          ),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isListening = true);
    try {
      await _stt.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _controller.text = result.recognizedWords;
              _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length),
              );
            });
          }
        },
        localeId: 'id_ID',
        pauseFor: const Duration(seconds: 4),
        listenFor: const Duration(seconds: 30),
      );
    } catch (e) {
      debugPrint('[STT] listen error: $e');
      if (mounted) setState(() => _isListening = false);
    }
  }


  // ─── Send message ──────────────────────────────────────────────────────────
  Future<void> _handleSend(ChatProvider provider) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    // Pastikan chat tersedia
    if (provider.currentChatId == null) {
      final shortTitle = text.length > 64 ? '${text.substring(0, 61)}...' : text;
      await provider.createChat(title: shortTitle);
    }
    if (provider.currentChatId == null) return;

    final chatId = provider.currentChatId!;
    await _aiService.ensureInitialized();

    // Tambahkan pesan user ke ChatProvider (untuk persistence lama)
    await provider.sendMessage(content: text);

    // Tambahkan ke ChatAiService (extended)
    await _aiService.addMessage(
      chatId: chatId,
      role: 'user',
      content: text,
      replyToId: _replyToMessage?.id,
      replyToContent: _replyToMessage?.content,
      replyToRole: _replyToMessage?.role,
    );

    setState(() {
      _isThinking = true;
      _replyToMessage = null;
    });
    _scrollToBottom();

    // Simulasi AI response delay
    final delay = 600 + math.Random().nextInt(800);
    await Future.delayed(Duration(milliseconds: delay));

    final reply = _aiService.buildAiReply(text, provider.aiModelMode);
    await provider.addAssistantMessage(content: reply);
    await _aiService.addMessage(
      chatId: chatId,
      role: 'assistant',
      content: reply,
    );

    // TTS tidak otomatis — user klik tombol 🔊 di bubble AI untuk mendengarkan
    setState(() => _isThinking = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Sync messages dari ChatProvider ke ChatAiService ──────────────────────
  Future<void> _syncMessagesIfNeeded(ChatProvider provider) async {
    if (provider.currentChatId == null) return;
    final chatId = provider.currentChatId!;
    await _aiService.ensureInitialized();
    final raw = provider.messages.map((m) => {
          'role': m.role,
          'content': m.content,
          'timestamp': m.timestamp,
        }).toList();
    await _aiService.syncFromChatService(chatId, raw);
  }

  // ─── Drag gesture untuk panel ──────────────────────────────────────────────
  void _onHorizontalDragStart(DragStartDetails details) {
    _panelDragStartX = details.globalPosition.dx;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    if (isMobile) return;
    final dx = details.velocity.pixelsPerSecond.dx;
    if (dx > 200) {
      setState(() => _panelOpen = true);
    } else if (dx < -200) {
      setState(() => _panelOpen = false);
    }
  }

  // ─── Delete message ────────────────────────────────────────────────────────
  Future<void> _deleteMessage(ChatProvider provider, ChatMessage msg) async {
    if (provider.currentChatId == null) return;
    await _aiService.deleteMessage(provider.currentChatId!, msg.id);
    setState(() {});
  }

  // ─── Favorite message ──────────────────────────────────────────────────────
  Future<void> _toggleFavorite(ChatProvider provider, ChatMessage msg) async {
    if (provider.currentChatId == null) return;
    await _aiService.toggleFavorite(provider.currentChatId!, msg.id);
    setState(() {});
  }

  // ─── Mode label ────────────────────────────────────────────────────────────
  String _modeLabel(String mode) {
    if (mode == 'cepat') return 'Cepat';
    if (mode == 'mendalam') return 'Mendalam';
    return 'Informatif';
  }

  // ─── AI mode dialog ────────────────────────────────────────────────────────
  void _showAiModeDialog(BuildContext ctx, ChatProvider provider) {
    showDialog<void>(
      context: ctx,
      builder: (dialogCtx) {
        String selected = provider.aiModelMode;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.smart_toy_rounded, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              const Text('Mode Respons AI'),
            ],
          ),
          content: StatefulBuilder(
            builder: (_, setSt) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _modeRadio(dialogCtx, provider, setSt, 'cepat', selected, 'Cepat',
                    'Jawaban singkat dan langsung ke inti.'),
                _modeRadio(dialogCtx, provider, setSt, 'informatif', selected,
                    'Informatif', 'Penjelasan seimbang dan mudah dipahami.'),
                _modeRadio(dialogCtx, provider, setSt, 'mendalam', selected,
                    'Mendalam', 'Jawaban detail, lengkap, dan terstruktur.'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _modeRadio(
    BuildContext ctx,
    ChatProvider provider,
    StateSetter setSt,
    String value,
    String groupValue,
    String label,
    String subtitle,
  ) {
    return RadioListTile<String>(
      title: Text(label),
      subtitle: Text(subtitle),
      value: value,
      groupValue: groupValue,
      activeColor: AppColors.primaryGreen,
      onChanged: (v) async {
        if (v == null) return;
        setSt(() => groupValue = v);
        await provider.setAiModelMode(v);
        if (ctx.mounted) Navigator.of(ctx).pop();
      },
    );
  }

  // ─── Build sidebar panel (riwayat + statistik) ────────────────────────────
  Widget _buildHistoryPanel(ChatProvider provider) {
    final chatId = provider.currentChatId;
    final totalConv = provider.chatHistory.length;
    final totalQ = chatId != null ? _aiService.getTotalUserMessages(chatId) : 0;
    final totalFav = _aiService.getGlobalFavoriteCount();

    return Container(
      width: _panelWidth,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(2, 0)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
            child: Row(
              children: [
                const Text(
                  'Riwayat Chat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Color(0xFF9E9E9E)),
                  onPressed: () => setState(() => _panelOpen = false),
                  tooltip: 'Tutup Panel',
                ),
              ],
            ),
          ),
          // Statistik
          ChatStatsSection(
            totalConversations: totalConv,
            totalQuestions: totalQ,
            totalFavorites: totalFav,
          ),
          const Divider(height: 1),
          // New chat button
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: ElevatedButton.icon(
              onPressed: () => provider.newChat(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Obrolan Baru'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          // Chat list
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.chatHistory.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada riwayat',
                          style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: provider.chatHistory.length,
                        itemBuilder: (ctx, i) {
                          final chat = provider.chatHistory[i];
                          final favCount = _aiService.getTotalFavorites(chat.chatId);
                          return ChatHistoryCard(
                            chat: chat,
                            isSelected: provider.currentChatId == chat.chatId,
                            favoriteCount: favCount,
                            onTap: () async {
                              await _aiService.ensureInitialized();
                              await provider.loadChat(chatId: chat.chatId);
                              await _syncMessagesIfNeeded(provider);
                              setState(() {});
                            },
                            onDelete: () async {
                              final ok = await _confirmDelete(ctx, 'Hapus percakapan ini?');
                              if (ok) {
                                await provider.deleteChat(chatId: chat.chatId);
                                await _aiService.clearChat(chat.chatId);
                                setState(() {});
                              }
                            },
                            onPin: () => provider.pinChat(chatId: chat.chatId),
                            onUnpin: () => provider.unpinChat(chatId: chat.chatId),
                          );
                        },
                      ),
          ),
          // Hapus semua
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton.icon(
              onPressed: () async {
                final ok = await _confirmDelete(context, 'Hapus semua riwayat chat?');
                if (ok) {
                  await provider.deleteAllChats();
                  setState(() {});
                }
              },
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: const Text('Hapus Semua Riwayat'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 36),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext ctx, String message) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  // ─── Build chat area ───────────────────────────────────────────────────────
  Widget _buildChatArea(ChatProvider provider) {
    final chatId = provider.currentChatId;
    final messages = chatId != null ? _aiService.getMessages(chatId) : <ChatMessage>[];

    if (chatId == null || messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: messages.length,
      itemBuilder: (ctx, i) {
        final msg = messages[i];
        if (msg.isUser) {
          return UserMessageBubble(
            message: msg,
            onDelete: () => _deleteMessage(provider, msg),
            onFavorite: () => _toggleFavorite(provider, msg),
            onReply: () => setState(() => _replyToMessage = msg),
          );
        } else {
          return AIMessageBubble(
            message: msg,
            onDelete: () => _deleteMessage(provider, msg),
            onFavorite: () => _toggleFavorite(provider, msg),
            onReply: () => setState(() => _replyToMessage = msg),
          );
        }
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Lottie.asset(
              'assets/lottie/ai_thinking.json',
              repeat: true,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Halo! Saya Sorgummi AI 🌾',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tanyakan apa saja tentang budidaya sorgum,\npemupukan, panen, atau peluang usaha.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E), height: 1.5),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _suggestionChip('Cara budidaya sorgum'),
              _suggestionChip('Kapan waktu panen?'),
              _suggestionChip('Pupuk yang cocok'),
              _suggestionChip('Hama dan penyakit'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _suggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _controller.text = text;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.primaryGreen,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ─── Build reply preview ───────────────────────────────────────────────────
  Widget _buildReplyPreview() {
    if (_replyToMessage == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primaryGreen.withOpacity(0.05),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _replyToMessage!.isUser ? 'Anda' : 'Sorgummi AI',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                Text(
                  _replyToMessage!.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF9E9E9E)),
            onPressed: () => setState(() => _replyToMessage = null),
          ),
        ],
      ),
    );
  }

  // ─── Build input area ──────────────────────────────────────────────────────
  Widget _buildInputArea(BuildContext ctx, ChatProvider provider) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(ctx).padding.bottom + 8,
      ),
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
      child: Row(
        children: [
          // Drag handle for panel (mobile tap)
          IconButton(
            icon: Icon(
              _panelOpen ? Icons.menu_open : Icons.menu,
              color: AppColors.primaryGreen,
              size: 22,
            ),
            onPressed: () => setState(() => _panelOpen = !_panelOpen),
            tooltip: 'Riwayat Chat',
          ),
          // Input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isListening
                      ? AppColors.primaryGreen
                      : const Color(0xFFEEEEEE),
                  width: _isListening ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(provider),
                      maxLines: 4,
                      minLines: 1,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF333333),
                      ),
                      decoration: InputDecoration(
                        hintText: _isListening
                            ? 'Mendengarkan...'
                            : 'Ketik atau tekan mic...',
                        hintStyle: TextStyle(
                          color: _isListening
                              ? AppColors.primaryGreen
                              : const Color(0xFF9E9E9E),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  // Mic button (STT)
                  GestureDetector(
                    onTap: _toggleListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none_rounded,
                        color: _isListening
                            ? AppColors.primaryGreen
                            : const Color(0xFF9E9E9E),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send button
          GestureDetector(
            onTap: () => _handleSend(provider),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isThinking
                    ? AppColors.primaryGreen.withOpacity(0.4)
                    : AppColors.primaryGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final p = ChatProvider();
        p.loadChats().then((_) async {
          await _aiService.ensureInitialized();
          await _syncMessagesIfNeeded(p);
          if (mounted) setState(() {});
        });
        return p;
      },
      child: Consumer<ChatProvider>(
        builder: (ctx, provider, _) {
          final isMobile = MediaQuery.of(ctx).size.width < 750;
          final aiStatus =
              _isThinking ? AIStatus.thinking : AIStatus.ready;

          return Scaffold(
            backgroundColor: const Color(0xFFF8FAF7),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: const BackButton(color: AppColors.textCharcoal),
              titleSpacing: 0,
              title: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Lottie.asset(
                        'assets/lottie/ai_thinking.json',
                        repeat: true,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sorgummi AI',
                        style: TextStyle(
                          color: AppColors.textCharcoal,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Mode: ${_modeLabel(provider.aiModelMode)}',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.smart_toy_outlined,
                      color: AppColors.textCharcoal),
                  tooltip: 'Mode Respons AI',
                  onPressed: () => _showAiModeDialog(ctx, provider),
                ),
                if (isMobile)
                  IconButton(
                    icon: Icon(
                      _panelOpen ? Icons.close : Icons.history,
                      color: AppColors.textCharcoal,
                    ),
                    onPressed: () => setState(() => _panelOpen = !_panelOpen),
                  ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: const Color(0xFFEEEEEE)),
              ),
            ),
            body: GestureDetector(
              // Drag gesture untuk buka/tutup panel riwayat
              onHorizontalDragStart: _onHorizontalDragStart,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: Row(
                children: [
                  // ── Panel Riwayat ──────────────────────────────────────────
                  if (!isMobile || _panelOpen)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      width: _panelOpen ? _panelWidth : 0,
                      child: _panelOpen
                          ? _buildHistoryPanel(provider)
                          : null,
                    ),
                  // ── Chat Area ──────────────────────────────────────────────
                  Expanded(
                    child: Column(
                      children: [
                        // Status card
                        AIStatusCard(
                          status: aiStatus,
                          modeName: _modeLabel(provider.aiModelMode),
                        ),
                        // Messages
                        Expanded(
                          child: _buildChatArea(provider),
                        ),
                        // AI thinking indicator (CustomPainter)
                        AIThinkingIndicator(isVisible: _isThinking),
                        // Reply preview
                        _buildReplyPreview(),
                        // Input area
                        _buildInputArea(ctx, provider),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
