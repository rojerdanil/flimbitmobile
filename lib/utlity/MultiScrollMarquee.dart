// lib/widgets/multi_scroll_marquee.dart
import 'package:flutter/material.dart';

class MultiScrollMarquee extends StatefulWidget {
  final List<String> messages;
  final double velocity; // pixels per second
  final TextStyle? style;

  const MultiScrollMarquee({
    super.key,
    required this.messages,
    this.velocity = 50,
    this.style,
  });

  @override
  _MultiScrollMarqueeState createState() => _MultiScrollMarqueeState();
}

class _MultiScrollMarqueeState extends State<MultiScrollMarquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _currentIndex;
  late double _textWidth;

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;

    _setTextWidth(widget.messages[_currentIndex]);

    _controller =
        AnimationController(
          vsync: this,
          duration: _getDuration(widget.messages[_currentIndex]),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            // move to next message
            setState(() {
              _currentIndex = (_currentIndex + 1) % widget.messages.length;
              _setTextWidth(widget.messages[_currentIndex]);
              _controller.duration = _getDuration(
                widget.messages[_currentIndex],
              );
            });
            _controller.forward(from: 0); // restart animation
          }
        });

    _controller.forward();
  }

  Duration _getDuration(String text) {
    return Duration(
      milliseconds: (_textWidth / widget.velocity * 1000).toInt(),
    );
  }

  void _setTextWidth(String text) {
    _textWidth = text.length * 10.0; // approx width per char
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.messages[_currentIndex];
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double offset =
                  (1 - _controller.value) * (constraints.maxWidth + _textWidth);
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: Text(
              text,
              style:
                  widget.style ??
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
            ),
          );
        },
      ),
    );
  }
}
