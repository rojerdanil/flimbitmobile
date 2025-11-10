import 'package:flutter/material.dart';

/// ⚡ FINAL: One-time Lazy Loader (zero re-fetch + smooth scroll)
/// ✅ Loads each section only once when first visible.
/// ✅ Keeps it in memory (AutomaticKeepAlive).
/// ✅ Never refetches or flickers on scroll up/down.
class LazySectionLoader extends StatefulWidget {
  final Widget Function(BuildContext) builder;
  final EdgeInsetsGeometry? margin;
  final double preloadOffset;

  const LazySectionLoader({
    super.key,
    required this.builder,
    this.margin,
    this.preloadOffset = 300,
  });

  @override
  State<LazySectionLoader> createState() => _LazySectionLoaderState();
}

class _LazySectionLoaderState extends State<LazySectionLoader>
    with AutomaticKeepAliveClientMixin {
  bool _isVisible = false;
  bool _hasLoaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  void _checkVisibility() {
    if (!mounted || _hasLoaded) return;
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
      return;
    }

    final position = box.localToGlobal(Offset.zero).dy;
    final screenHeight = MediaQuery.of(context).size.height;
    final bool visible =
        position < screenHeight + widget.preloadOffset && position > -200;

    if (visible) {
      setState(() {
        _isVisible = true;
        _hasLoaded = true; // ✅ Load only once
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());

    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 6),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _hasLoaded
            ? widget.builder(context)
            : _isVisible
            ? widget.builder(context)
            : const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
      ),
    );
  }
}
