import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../theme/AppTheme.dart';

class UserBanner extends StatefulWidget {
  const UserBanner({super.key});

  @override
  State<UserBanner> createState() => _UserBannerState();
}

class _UserBannerState extends State<UserBanner> {
  String? bannerMessage;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  Future<void> _loadBanner() async {
    print('calling url ');
    try {
      final result = await ApiService.get(ApiEndpoints.userSpecificRemainder);
      if (result is List && result.isNotEmpty) {
        setState(() {
          // Take the first banner message from result
          bannerMessage = result[0]['message'];
        });
      }
    } catch (e) {
      debugPrint('Error loading banner: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (bannerMessage == null) {
      return Container(
        width: double.infinity,
        color: const Color(0xFFF97316), // Banner background
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: RichText(
          text: TextSpan(
            text: "Welcome to ",
            style: const TextStyle(
              color: Colors.white, // make base text white to match banner
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            children: [
              TextSpan(
                text: "FilmBit",
                style: TextStyle(
                  color: AppTheme.primaryColor, // your theme color for brand
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );

      //return const SizedBox.shrink(); // nothing until API loads
    }

    return Container(
      width: double.infinity,
      color: const Color(0xFFF97316),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Text(
        bannerMessage!,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
