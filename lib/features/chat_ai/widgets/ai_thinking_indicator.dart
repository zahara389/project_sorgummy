// lib/features/chat_ai/widgets/ai_thinking_indicator.dart
// Widget yang menampilkan animasi AI sedang berpikir menggunakan CustomPainter.
// Muncul di bawah daftar pesan saat isThinking = true.

import 'package:flutter/material.dart';
import '../painters/ai_thinking_painter.dart';

class AIThinkingIndicator extends StatefulWidget {
  final bool isVisible;

  const AIThinkingIndicator({Key? key, required this.isVisible}) : super(key: key);

  @override
  State<AIThinkingIndicator> createState() => _AIThinkingIndicatorState();
}

class _AIThinkingIndicatorState extends State<AIThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: widget.isVisible
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // AI avatar
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
                  // CustomPainter canvas
                  Container(
                    width: 100,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF65B713).withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF65B713).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (_, __) => CustomPaint(
                          painter: AIThinkingPainter(
                            animationValue: _animation.value,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'AI sedang berpikir...',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF65B713).withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
