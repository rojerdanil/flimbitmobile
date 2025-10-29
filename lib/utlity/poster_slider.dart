import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class PosterSlider extends StatefulWidget {
  const PosterSlider({Key? key}) : super(key: key);

  @override
  State<PosterSlider> createState() => _PosterSliderState();
}

class _PosterSliderState extends State<PosterSlider>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _timer;
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  List<dynamic> posterData = [];
  bool isLoading = true;
  bool hasError = false;

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _flashAnimation = Tween<double>(begin: -1.2, end: 2.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeInOut),
    );

    fetchPosters();
  }

  Future<void> fetchPosters() async {
    try {
      final response = await ApiService.get(ApiEndpoints.posterRead);
      if (response is List && response.isNotEmpty) {
        setState(() {
          posterData = response;
          isLoading = false;
        });
        _startAutoSlide();
      } else {
        throw Exception('No posters found');
      }
    } catch (e) {
      debugPrint('Error fetching posters: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (posterData.isNotEmpty && _pageController.hasClients) {
        final nextPage = (_currentIndex + 1) % posterData.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _pauseAutoSlide() => _timer?.cancel();

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (hasError) return const Center(child: Text("Failed to load posters"));
    if (posterData.isEmpty)
      return const Center(child: Text("No posters found"));

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: posterData.length,
            itemBuilder: (context, index) {
              final poster = posterData[index];
              final movieId = poster['movieId'] ?? 0;
              final imageUrl = poster['imageUrl'] ?? '';
              final title = poster['title'] ?? '';

              return GestureDetector(
                onTapDown: (_) => _pauseAutoSlide(),
                onTapUp: (_) => _startAutoSlide(),
                onTap: () {
                  // Only respond if movieId is not zero
                  if (movieId != 0) {
                    debugPrint('Clicked Movie ID: $movieId');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Movie ID: $movieId'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    // Navigation logic will go here later
                  }
                },
                child: AnimatedScale(
                  scale: index == _currentIndex ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 600),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imageUrl,
                          fit: BoxFit.fill,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                child: Icon(Icons.broken_image, size: 60),
                              ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.6),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (index == _currentIndex)
                          AnimatedBuilder(
                            animation: _flashAnimation,
                            builder: (context, child) {
                              return Transform(
                                transform: Matrix4.rotationZ(-0.35),
                                origin: const Offset(100, 0),
                                child: FractionalTranslation(
                                  translation: Offset(_flashAnimation.value, 0),
                                  child: Container(
                                    width: 140,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white.withOpacity(0.0),
                                          Colors.white.withOpacity(0.15),
                                          Colors.white.withOpacity(0.0),
                                        ],
                                        stops: const [0.0, 0.5, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            posterData.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentIndex == index ? 12 : 8,
              height: _currentIndex == index ? 12 : 8,
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? AppTheme.primaryColor
                    : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
