// lib/features/chat_ai/widgets/user_message_bubble.dart
// Custom widget UserMessageBubble untuk pesan dari pengguna.
// Fitur: LongPress menu (Salin/Hapus/Bagikan), Swipe gesture (reply, favorite).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:share_plus/share_plus.dart';
import '../models/chat_message.dart';

class UserMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onDelete;
  final VoidCallback? onFavorite;
  final VoidCallback? onReply;

  const UserMessageBubble({
    Key? key,
    required this.message,
    this.onDelete,
    this.onFavorite,
    this.onReply,
  }) : super(key: key);

  void _copyMessage(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pesan disalin'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareMessage() {
    Share.share(message.content, subject: 'Pesan ke Sorgummi AI');
  }

  void _showContextMenu(BuildContext context) {
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
                _copyMessage(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.reply_rounded, color: Color(0xFF65B713)),
              title: const Text('Balas Pesan'),
              onTap: () {
                Navigator.pop(ctx);
                onReply?.call();
              },
            ),
            ListTile(
              leading: Icon(
                message.isFavorite ? Icons.star : Icons.star_outline,
                color: const Color(0xFFFFC107),
              ),
              title: Text(message.isFavorite ? 'Hapus Favorit' : 'Favorit'),
              onTap: () {
                Navigator.pop(ctx);
                onFavorite?.call();
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
                onDelete?.call();
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
      key: ValueKey(message.id),
      startActionPane: ActionPane(
        // Swipe kanan → Reply
        motion: const DrawerMotion(),
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (_) => onReply?.call(),
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
            onPressed: (_) => onFavorite?.call(),
            backgroundColor: const Color(0xFFFFC107),
            foregroundColor: Colors.white,
            icon: message.isFavorite ? Icons.star : Icons.star_outline,
            label: message.isFavorite ? 'Unfav' : 'Favorit',
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: GestureDetector(
        onLongPress: () => _showContextMenu(context),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Reply preview
              if (message.hasReply)
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: const Border(
                        right: BorderSide(color: Colors.white, width: 3),
                      ),
                    ),
                    child: Text(
                      message.replyToContent ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.9),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              // Bubble
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF65B713),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(4),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF65B713).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        message.content,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (message.isFavorite)
                    const Icon(Icons.star, size: 12, color: Color(0xFFFFC107)),
                  if (message.isFavorite) const SizedBox(width: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
