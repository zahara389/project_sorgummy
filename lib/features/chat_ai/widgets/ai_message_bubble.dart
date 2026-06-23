// lib/features/chat_ai/widgets/ai_message_bubble.dart
// Custom widget AIMessageBubble untuk pesan dari AI.
// Fitur: TTS, Share, LongPress menu, Swipe gesture via flutter_slidable.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import '../models/chat_message.dart';

class AIMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onDelete;
  final VoidCallback? onFavorite;
  final VoidCallback? onReply;

  const AIMessageBubble({
    Key? key,
    required this.message,
    this.onDelete,
    this.onFavorite,
    this.onReply,
  }) : super(key: key);

  @override
  State<AIMessageBubble> createState() => _AIMessageBubbleState();
}

class _AIMessageBubbleState extends State<AIMessageBubble> {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _toggleTts() async {
    if (_isSpeaking) {
      await _tts.stop();
      if (mounted) setState(() => _isSpeaking = false);
    } else {
      // Set Bahasa Indonesia dengan fallback
      final languages = await _tts.getLanguages;
      final langList = List<dynamic>.from(languages ?? []);
      final hasId = langList.any((l) => l.toString().toLowerCase().contains('id'));
      if (hasId) {
        for (final lang in ['id-ID', 'id_ID', 'id', 'in-ID']) {
          final res = await _tts.setLanguage(lang);
          if (res == 1) break;
        }
      } else {
        await _tts.setLanguage('en-US');
      }
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.speak(widget.message.content);
      if (mounted) setState(() => _isSpeaking = true);
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
    }
  }

  void _copyMessage() {
    Clipboard.setData(ClipboardData(text: widget.message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pesan disalin'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareMessage() {
    Share.share(
      widget.message.content,
      subject: 'Jawaban Sorgummi AI',
    );
  }

  void _showContextMenu() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: Color(0xFF65B713)),
              title: const Text('Salin Pesan'),
              onTap: () {
                Navigator.pop(ctx);
                _copyMessage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.reply_rounded, color: Color(0xFF65B713)),
              title: const Text('Balas Pesan'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onReply?.call();
              },
            ),
            ListTile(
              leading: Icon(
                widget.message.isFavorite ? Icons.star : Icons.star_outline,
                color: const Color(0xFFFFC107),
              ),
              title: Text(widget.message.isFavorite ? 'Hapus Favorit' : 'Favorit'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onFavorite?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded, color: Color(0xFF65B713)),
              title: const Text('Bagikan Pesan'),
              onTap: () {
                Navigator.pop(ctx);
                _shareMessage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Hapus Pesan', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                widget.onDelete?.call();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(widget.message.id),
      startActionPane: ActionPane(
        // Swipe kanan → Reply
        motion: const DrawerMotion(),
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (_) => widget.onReply?.call(),
            backgroundColor: const Color(0xFF65B713),
            foregroundColor: Colors.white,
            icon: Icons.reply_rounded,
            label: 'Balas',
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ],
      ),
      endActionPane: ActionPane(
        // Swipe kiri → Favorite
        motion: const DrawerMotion(),
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (_) => widget.onFavorite?.call(),
            backgroundColor: const Color(0xFFFFC107),
            foregroundColor: Colors.white,
            icon: widget.message.isFavorite ? Icons.star : Icons.star_outline,
            label: widget.message.isFavorite ? 'Unfav' : 'Favorit',
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: GestureDetector(
        onLongPress: _showContextMenu,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Avatar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF65B713).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Color(0xFF65B713),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reply preview
                    if (widget.message.hasReply)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF65B713).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: const Border(
                            left: BorderSide(color: Color(0xFF65B713), width: 3),
                          ),
                        ),
                        child: Text(
                          widget.message.replyToContent ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF65B713),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    // Bubble
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFE8F7E6),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.message.content,
                        style: const TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Action bar bawah bubble
                    Row(
                      children: [
                        Text(
                          _formatTime(widget.message.timestamp),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // TTS button
                        GestureDetector(
                          onTap: _toggleTts,
                          child: Icon(
                            _isSpeaking
                                ? Icons.volume_up_rounded   // sedang ngomong → speaker aktif
                                : Icons.volume_off_rounded, // diam → muted (default)
                            size: 14,
                            color: _isSpeaking
                                ? const Color(0xFF65B713)  // hijau saat aktif
                                : const Color(0xFF9E9E9E), // abu saat muted
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Share button
                        GestureDetector(
                          onTap: _shareMessage,
                          child: const Icon(
                            Icons.share_rounded,
                            size: 14,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Favorite badge
                        if (widget.message.isFavorite)
                          const Icon(
                            Icons.star,
                            size: 13,
                            color: Color(0xFFFFC107),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
