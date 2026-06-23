// lib/features/chat_ai/widgets/chat_history_card.dart
// Custom widget ChatHistoryCard untuk menampilkan item riwayat chat di panel/sidebar.
// Fitur: tap to load, swipe action delete/pin, badge pinned/favorit.

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../models/chat_model.dart';

class ChatHistoryCard extends StatelessWidget {
  final ChatModel chat;
  final bool isSelected;
  final int favoriteCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onPin;
  final VoidCallback onUnpin;

  const ChatHistoryCard({
    Key? key,
    required this.chat,
    required this.onTap,
    required this.onDelete,
    required this.onPin,
    required this.onUnpin,
    this.isSelected = false,
    this.favoriteCount = 0,
  }) : super(key: key);

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return 'Hari ini $h:$m';
    } else if (diff.inDays == 1) {
      return 'Kemarin';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF65B713);

    return Slidable(
      key: ValueKey(chat.chatId),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.35,
        children: [
          SlidableAction(
            onPressed: (_) => chat.isPinned ? onUnpin() : onPin(),
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            icon: chat.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            label: chat.isPinned ? 'Unpin' : 'Pin',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Hapus',
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryGreen.withOpacity(0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? primaryGreen.withOpacity(0.3)
                  : const Color(0xFFEEEEEE),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryGreen.withOpacity(0.15)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  chat.isPinned ? Icons.push_pin : Icons.chat_bubble_outline,
                  size: 18,
                  color: isSelected ? primaryGreen : const Color(0xFF9E9E9E),
                ),
              ),
              const SizedBox(width: 10),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? primaryGreen : const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          _formatDate(chat.updatedAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                        if (favoriteCount > 0) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.star, size: 11, color: Color(0xFFFFC107)),
                          const SizedBox(width: 2),
                          Text(
                            '$favoriteCount',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFFFC107),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Selected indicator
              if (isSelected)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
