import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../screens/PhoneVerificationScreen.dart';
import '../screens/home-screen.dart'; // after login
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../securityScreen/pin_verification_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setString("deviceType", "phone");

    // Fetch existing deviceId safely
    String deviceId = prefs.getString('deviceId') ?? '';

    // --------------------------
    // 1️⃣ SET DEVICE ID PROPERLY
    // --------------------------
    if (kIsWeb) {
      // Web (testing mode)
      prefs.setString("deviceId", "12234");
      prefs.setString("phoneNumber", "9626814334");
      deviceId = "12234"; // update local variable also
    } else if (deviceId.isEmpty) {
      // Mobile (Android / iOS)
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final id = androidInfo.id ?? "";

        if (id.isNotEmpty) {
          prefs.setString("deviceId", id);
          deviceId = id;
        }
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        final id = iosInfo.identifierForVendor ?? "";

        if (id.isNotEmpty) {
          prefs.setString("deviceId", id);
          deviceId = id;
        }
      }
    }

    // -------------------------
    // 2️⃣ CHECK TOKEN & PHONE
    // -------------------------
    final token = prefs.getString('auth_token') ?? '';
    final phone = prefs.getString('phoneNumber') ?? '';

    if (token.isEmpty || phone.isEmpty || deviceId.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PhoneVerificationScreen()),
      );
      return;
    }

    // -----------------------------------
    // 3️⃣ VALIDATE TOKEN + DEVICE ON API
    // -----------------------------------
    final response = await ApiService.get(
      ApiEndpoints.validateUser,
      context: context,
    );

    if (response != null) {
      final data = response;
      final code = data['code'] ?? 200;

      if (code == 200) {
        // VALID USER — ask PIN
        final rootContext = Navigator.of(context).context;

        final accessKey = await showPinVerificationDialog(
          rootContext,
          isLoginScreen: true,
        );

        if (accessKey.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else if (code == 101) {
        // Blocked by server
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const PhoneVerificationScreen(isUserBlocked: true),
          ),
        );
      } else if (code == 102) {
        // Token expired or device mismatch → restart login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PhoneVerificationScreen()),
        );
      }
    } else {
      // API failed → force login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PhoneVerificationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
