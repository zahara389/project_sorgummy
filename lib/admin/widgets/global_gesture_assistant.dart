import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../gesture_management_screen.dart';
import '../services/global_gesture_service.dart';

class GlobalGestureAssistant extends StatefulWidget {
  final Widget child;

  const GlobalGestureAssistant({Key? key, required this.child}) : super(key: key);

  @override
  State<GlobalGestureAssistant> createState() => _GlobalGestureAssistantState();
}

class _GlobalGestureAssistantState extends State<GlobalGestureAssistant> {
  bool _isEnabled = true;
  bool _isExpanded = false;
  
  // Floating position variables
  double _posX = 20.0;
  double _posY = 120.0;

  final GlobalGestureService _gestureService = GlobalGestureService();

  // Variabel deteksi geser (Swipe)
  Offset? _dragStartPos;
  DateTime? _dragStartTime;
  Offset? _dragLastPos;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void didUpdateWidget(covariant GlobalGestureAssistant oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isEnabled = prefs.getBool('enable_global_gesture_assistant') ?? true;
      });
    }
  }

  Future<void> _toggleEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_global_gesture_assistant', val);
    if (mounted) {
      setState(() {
        _isEnabled = val;
        if (!val) _isExpanded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEnabled) {
      return widget.child;
    }

    return Scaffold(
      body: Stack(
        children: [
          // The actual application screen with global physical gesture listeners
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTap: () {
              _gestureService.triggerGesture('double_tap', context);
            },
            onLongPress: () {
              _gestureService.triggerGesture('long_press', context);
            },
            onHorizontalDragStart: (details) {
              _dragStartPos = details.localPosition;
              _dragLastPos = details.localPosition;
              _dragStartTime = DateTime.now();
            },
            onHorizontalDragUpdate: (details) {
              _dragLastPos = details.localPosition;
            },
            onHorizontalDragEnd: (details) {
              if (_dragStartPos != null && _dragLastPos != null && _dragStartTime != null) {
                final duration = DateTime.now().difference(_dragStartTime!);
                final dx = _dragLastPos!.dx - _dragStartPos!.dx;
                if (duration.inMilliseconds < 500 && dx.abs() > 60) {
                  if (dx < 0) {
                    _gestureService.triggerGesture('swipe_left', context);
                  } else {
                    _gestureService.triggerGesture('swipe_right', context);
                  }
                }
              }
              _dragStartPos = null;
              _dragLastPos = null;
              _dragStartTime = null;
            },
            child: widget.child,
          ),

          // Dragable Floating Assistant Control Bubble
          Positioned(
            left: _posX,
            top: _posY,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _posX += details.delta.dx;
                  _posY += details.delta.dy;
                  
                  // Clamp bounds to prevent dragging offscreen
                  final size = MediaQuery.of(context).size;
                  _posX = _posX.clamp(10.0, size.width - 70.0);
                  _posY = _posY.clamp(50.0, size.height - 120.0);
                });
              },
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Outer glowing ring
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scaleXY(begin: 0.95, end: 1.05, duration: 1500.ms, curve: Curves.easeInOut),

                  // Floating Action Button
                  Material(
                    elevation: 8,
                    shape: const CircleBorder(),
                    color: Colors.transparent,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF2E7D32), AppColors.primaryGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        child: AnimatedRotation(
                          turns: _isExpanded ? 0.125 : 0.0,
                          duration: 250.ms,
                          child: Icon(
                            _isExpanded ? Icons.close_rounded : Icons.gesture_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Notification Badge for active/simulated gestures
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Colors.yellowAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.flash_on_rounded, size: 10, color: Color(0xFF2E7D32)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Extended Simulation Panel Overlay
          if (_isExpanded)
            Positioned(
              left: _posX + 65.0 > MediaQuery.of(context).size.width - 290.0
                  ? _posX - 290.0
                  : _posX + 65.0,
              top: _posY - 80.0 < 50.0 ? 50.0 : (_posY - 80.0 > MediaQuery.of(context).size.height - 350.0 ? MediaQuery.of(context).size.height - 350.0 : _posY - 80.0),
              child: _buildControlPanel(context),
            ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context) {
    return Container(
      width: 270,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.gesture_rounded, color: AppColors.primaryGreen, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Pintasan Gestur',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textCharcoal),
                    ),
                    Text(
                      'Simulator & Pintasan Global',
                      style: TextStyle(fontSize: 10, color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),

          const Text(
            'Lakukan gestur pada baris di bawah untuk simulasi:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textLight),
          ),
          const SizedBox(height: 10),

          // Simulation gesture practice rows
          _GesturePracticeRow(
            icon: Icons.touch_app_outlined,
            label: 'Ketuk Ganda (Double Tap)',
            gestureKey: 'double_tap',
            color: Colors.blue,
            hintText: '💡 Ketuk ganda (2x) cepat pada baris ini!',
            onGestureTriggered: (key) => _gestureService.triggerGesture(key, context),
          ),
          const SizedBox(height: 6),
          _GesturePracticeRow(
            icon: Icons.timer_outlined,
            label: 'Tekan Lama (Long Press)',
            gestureKey: 'long_press',
            color: Colors.purple,
            hintText: '💡 Tekan dan tahan (1 detik) pada baris ini!',
            onGestureTriggered: (key) => _gestureService.triggerGesture(key, context),
          ),
          const SizedBox(height: 6),
          _GesturePracticeRow(
            icon: Icons.arrow_back_rounded,
            label: 'Geser Kiri (Swipe Left)',
            gestureKey: 'swipe_left',
            color: Colors.amber.shade800,
            hintText: '💡 Geser/swipe kursor ke kiri pada baris ini!',
            onGestureTriggered: (key) => _gestureService.triggerGesture(key, context),
          ),
          const SizedBox(height: 6),
          _GesturePracticeRow(
            icon: Icons.arrow_forward_rounded,
            label: 'Geser Kanan (Swipe Right)',
            gestureKey: 'swipe_right',
            color: Colors.orange,
            hintText: '💡 Geser/swipe kursor ke kanan pada baris ini!',
            onGestureTriggered: (key) => _gestureService.triggerGesture(key, context),
          ),
          const SizedBox(height: 6),
          _GesturePracticeRow(
            icon: Icons.vibration_rounded,
            label: 'Goyang HP (Shake Device)',
            gestureKey: 'shake_device',
            color: Colors.red,
            hintText: '💡 Goyang kursor kiri-kanan cepat di sini (atau ketuk langsung)!',
            onGestureTriggered: (key) => _gestureService.triggerGesture(key, context),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),

          // Action buttons to change settings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () async {
                  setState(() {
                    _isExpanded = false;
                  });
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GestureManagementScreen()),
                  );
                  _loadSettings();
                },
                icon: const Icon(Icons.settings_outlined, size: 14, color: AppColors.primaryGreen),
                label: const Text(
                  'Atur Pemetaan',
                  style: TextStyle(fontSize: 11, color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  _toggleEnabled(false);
                },
                child: const Text(
                  'Sembunyikan',
                  style: TextStyle(fontSize: 11, color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fade(duration: 200.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-Widget: _GesturePracticeRow (Interactive gesture pads for the simulator)
// ─────────────────────────────────────────────────────────────────────────────
class _GesturePracticeRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final String gestureKey;
  final Color color;
  final String hintText;
  final Function(String) onGestureTriggered;

  const _GesturePracticeRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.gestureKey,
    required this.color,
    required this.hintText,
    required this.onGestureTriggered,
  }) : super(key: key);

  @override
  State<_GesturePracticeRow> createState() => _GesturePracticeRowState();
}

class _GesturePracticeRowState extends State<_GesturePracticeRow> {
  bool _showHint = false;
  Timer? _hintTimer;

  // Drag variables
  Offset? _dragStartPos;
  DateTime? _dragStartTime;
  Offset? _dragLastPos;

  // Shake variables
  int _shakeCount = 0;
  double? _lastX;
  bool? _movingRight;
  DateTime? _lastShakeTime;

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _triggerHint() {
    _hintTimer?.cancel();
    setState(() {
      _showHint = true;
    });
    _hintTimer = Timer(const Duration(seconds: 2500 ~/ 1000), () {
      if (mounted) {
        setState(() {
          _showHint = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget rowContent = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _showHint ? widget.color.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(widget.icon, size: 16, color: widget.color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.grey),
            ],
          ),
          if (_showHint)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 26),
              child: Text(
                widget.hintText,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ).animate().fadeIn(duration: 150.ms).slideY(begin: 0.1, end: 0.0),
            ),
        ],
      ),
    );

    if (widget.gestureKey == 'double_tap') {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _triggerHint,
        onDoubleTap: () {
          widget.onGestureTriggered(widget.gestureKey);
        },
        child: rowContent,
      );
    } else if (widget.gestureKey == 'long_press') {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _triggerHint,
        onLongPress: () {
          widget.onGestureTriggered(widget.gestureKey);
        },
        child: rowContent,
      );
    } else if (widget.gestureKey == 'swipe_left') {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _triggerHint,
        onHorizontalDragStart: (details) {
          _dragStartPos = details.localPosition;
          _dragLastPos = details.localPosition;
          _dragStartTime = DateTime.now();
        },
        onHorizontalDragUpdate: (details) {
          _dragLastPos = details.localPosition;
        },
        onHorizontalDragEnd: (details) {
          if (_dragStartPos != null && _dragLastPos != null && _dragStartTime != null) {
            final duration = DateTime.now().difference(_dragStartTime!);
            final dx = _dragLastPos!.dx - _dragStartPos!.dx;
            if (duration.inMilliseconds < 500 && dx < -30) {
              widget.onGestureTriggered(widget.gestureKey);
            }
          }
          _dragStartPos = null;
          _dragLastPos = null;
          _dragStartTime = null;
        },
        child: rowContent,
      );
    } else if (widget.gestureKey == 'swipe_right') {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _triggerHint,
        onHorizontalDragStart: (details) {
          _dragStartPos = details.localPosition;
          _dragLastPos = details.localPosition;
          _dragStartTime = DateTime.now();
        },
        onHorizontalDragUpdate: (details) {
          _dragLastPos = details.localPosition;
        },
        onHorizontalDragEnd: (details) {
          if (_dragStartPos != null && _dragLastPos != null && _dragStartTime != null) {
            final duration = DateTime.now().difference(_dragStartTime!);
            final dx = _dragLastPos!.dx - _dragStartPos!.dx;
            if (duration.inMilliseconds < 500 && dx > 30) {
              widget.onGestureTriggered(widget.gestureKey);
            }
          }
          _dragStartPos = null;
          _dragLastPos = null;
          _dragStartTime = null;
        },
        child: rowContent,
      );
    } else if (widget.gestureKey == 'shake_device') {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _triggerHint();
          widget.onGestureTriggered(widget.gestureKey);
        },
        onPanUpdate: (details) {
          final currentX = details.localPosition.dx;
          final now = DateTime.now();
          if (_lastShakeTime != null && now.difference(_lastShakeTime!).inMilliseconds > 800) {
            _shakeCount = 0;
          }
          if (_lastX != null) {
            bool movingRightNow = currentX > _lastX!;
            if (_movingRight != null && _movingRight != movingRightNow) {
              _shakeCount++;
              _lastShakeTime = now;
              if (_shakeCount >= 4) {
                widget.onGestureTriggered(widget.gestureKey);
                _shakeCount = 0;
              }
            }
            _movingRight = movingRightNow;
          }
          _lastX = currentX;
        },
        child: rowContent,
      );
    }

    return rowContent;
  }
}
