import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';

class TopVisualSection extends StatefulWidget {
  final double height;
  final double logoHeight;

  const TopVisualSection({
    super.key,
    required this.height,
    this.logoHeight = 110,
  });

  @override
  State<TopVisualSection> createState() => _TopVisualSectionState();
}

class _TopVisualSectionState extends State<TopVisualSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late PageController _pageController;
  int currentFeature = 0;

  final List<Map<String, String>> features = [
    {
      'title': 'Invest in Movies',
      'subtitle': 'Own a part of upcoming blockbuster films.',
    },
    {
      'title': 'Exclusive Rewards',
      'subtitle': 'Meet actors, premiers, special events.',
    },
    {
      'title': 'Profit From Success',
      'subtitle': 'Earn when the movie performs well.',
    },
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _pageController = PageController(viewportFraction: 0.82);

    _autoSlide();
  }

  void _autoSlide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      currentFeature = (currentFeature + 1) % features.length;

      _pageController.animateToPage(
        currentFeature,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      setState(() {});

      _autoSlide();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Widget _dotIndicator(bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: active ? 10 : 6,
      height: active ? 10 : 6,
      decoration: BoxDecoration(
        color: active ? AppTheme.primaryColor : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, Colors.yellow.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: _buildFlashSparks()),
          Positioned.fill(child: _buildFloatingIcons()),

          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // const SizedBox(height: 50),
                SizedBox(height: widget.height * 0.10),

                Image.asset(
                  'assets/logo.png',
                  height: widget.logoHeight,
                  fit: BoxFit.contain,
                ),

                SizedBox(
                  height: 90,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: features.length,
                    onPageChanged: (i) {
                      setState(() => currentFeature = i);
                    },
                    itemBuilder: (context, index) {
                      final f = features[index];
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double value = 1;
                          if (_pageController.position.haveDimensions) {
                            value = _pageController.page! - index;
                            value = (1 - (value.abs() * 0.3)).clamp(0.85, 1.0);
                          }
                          return Transform.scale(scale: value, child: child);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                f['title']!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                f['subtitle']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    features.length,
                    (i) => _dotIndicator(i == currentFeature),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ CAMERA FLASH EFFECT ------------------
  Widget _buildFlashSparks() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (_, __) {
        return CustomPaint(
          painter: _UltraBrightFlashPainter(
            progress: _animationController.value,
            width: MediaQuery.of(context).size.width,
            height: widget.height,
          ),
        );
      },
    );
  }

  Widget _buildFloatingIcons() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        double screenWidth = MediaQuery.of(context).size.width;

        final colors = [
          Colors.white70,
          Colors.yellowAccent,
          Colors.pinkAccent,
          Colors.cyanAccent,
          Colors.orangeAccent,
          Colors.greenAccent,
          Colors.deepPurpleAccent,
        ];

        final icons = [
          Icons.movie_creation_outlined,
          Icons.videocam,
          Icons.camera_alt,
          Icons.movie_filter,
          Icons.star,
          Icons.slideshow,
          Icons.local_movies,
        ];

        final random = Random();

        return Stack(
          children: List.generate(25, (index) {
            double offset = index * 0.06;
            double progress = (_animationController.value + offset) % 1.0;

            double y = -40 + (progress * 300); // higher vertical spread
            double swayAmplitude = 20 + index * 2;
            double x =
                (screenWidth / 25) * (index + 1) +
                sin(progress * 2 * pi + index) * swayAmplitude;

            double scale = 1.0 + (progress * 0.7); // slightly bigger scale
            double rotation = progress * pi * 2 * (index.isEven ? 1 : -1);
            double blink =
                0.5 + 0.5 * sin(progress * 10 * pi + random.nextDouble() * pi);
            double fade = ((1 - progress) * blink).clamp(0.2, 1.0);

            return Positioned(
              top: y,
              left: x,
              child: Opacity(
                opacity: fade,
                child: Transform.rotate(
                  angle: rotation,
                  child: Transform.scale(
                    scale: scale,
                    child: Icon(
                      icons[index % icons.length],
                      size: 32 + (progress * 16), // bigger icons
                      color: colors[index % colors.length].withOpacity(fade),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _UltraBrightFlashPainter extends CustomPainter {
  final double progress;
  final double width;
  final double height;
  final Random random = Random();

  _UltraBrightFlashPainter({
    required this.progress,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    int flashesCount = 15;
    double maxTopHeight = height;

    for (int i = 0; i < flashesCount; i++) {
      double xBase = random.nextDouble() * width;
      double yBase = random.nextDouble() * maxTopHeight * 0.5;

      double x = xBase + (random.nextDouble() * 20 - 10);
      double y = yBase + (random.nextDouble() * 15 - 7.5);

      double baseSize = 20 + random.nextDouble() * 30;

      double flashProgress = (progress + i * 0.07) % 1.0;
      double opacity = (1 - flashProgress).clamp(0, 1);

      Paint core = Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawCircle(Offset(x, y), baseSize * 0.25, core);

      Paint glow = Paint()
        ..color = Colors.yellow.shade200.withOpacity(opacity * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 25);
      canvas.drawCircle(Offset(x, y), baseSize * 0.5, glow);

      int rays = 4 + random.nextInt(3);
      for (int r = 0; r < rays; r++) {
        double angle = (2 * pi / rays) * r + flashProgress * pi;
        Paint rayPaint = Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..strokeWidth = 1.5 + random.nextDouble();
        canvas.drawLine(
          Offset(x, y),
          Offset(
            x + cos(angle) * baseSize * (0.5 + random.nextDouble() * 0.5),
            y + sin(angle) * baseSize * (0.5 + random.nextDouble() * 0.5),
          ),
          rayPaint,
        );
      }

      for (int s = 0; s < 2; s++) {
        double dx = x + random.nextDouble() * 20 - 10;
        double dy = y + random.nextDouble() * 20 - 10;
        Paint sparkle = Paint()
          ..color = Colors.white.withOpacity(opacity * 0.5)
          ..strokeWidth = 1;
        canvas.drawCircle(Offset(dx, dy), 1.5, sparkle);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _UltraBrightFlashPainter oldDelegate) => true;
}
