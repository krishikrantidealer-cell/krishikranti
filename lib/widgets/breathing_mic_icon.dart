import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BreathingMicIcon extends StatefulWidget {
  final double size;
  final Color color;
  
  const BreathingMicIcon({
    super.key,
    this.size = 20,
    this.color = Colors.grey,
  });

  @override
  State<BreathingMicIcon> createState() => _BreathingMicIconState();
}

class _BreathingMicIconState extends State<BreathingMicIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_controller.value * 0.1),
          child: Icon(
            CupertinoIcons.mic_fill,
            color: widget.color,
            size: widget.size,
          ),
        );
      },
    );
  }
}
