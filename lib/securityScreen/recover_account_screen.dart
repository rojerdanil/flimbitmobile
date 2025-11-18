import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../MainScreen/topVisualSection.dart';
import '../theme/AppTheme.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../screens/home-screen.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class RecoverAccountScreen extends StatefulWidget {
  const RecoverAccountScreen({super.key});

  @override
  State<RecoverAccountScreen> createState() => _RecoverAccountScreenState();
}

class _RecoverAccountScreenState extends State<RecoverAccountScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController pinController = TextEditingController();

  bool isOTPSent = false;
  bool isOtpVerified = false;
  bool loading = false;
  String sessionId = "";
  String shortToken = "";

  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  late final PinTheme defaultPinTheme;
  int otpSeconds = 60;
  Timer? otpTimer;
  bool canResend = false;
  int otpAttempts = 0;
  final int maxOtpAttempts = 3;
  @override
  void initState() {
    super.initState();

    defaultPinTheme = PinTheme(
      width: 50,
      height: 56,
      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor),
      ),
    );

    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 60,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    Future.delayed(const Duration(milliseconds: 300), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    _controller.dispose();
    otpTimer?.cancel();

    super.dispose();
  }

  Future<void> sendOtp() async {
    if (phoneController.text.trim().length != 10) {
      _showError("Enter valid 10 digit phone number");
      return;
    }

    setState(() => loading = true);

    final response = await ApiService.post(
      ApiEndpoints.sendRecoverOtp,
      body: {"phoneNumber": phoneController.text.trim()},
      context: context,
      isFullBody: true,
    );

    setState(() => loading = false);

    if (response["status"] == "success" && response["result"] != null) {
      final data = response["result"];

      setState(() {
        isOTPSent = true;
        sessionId = data['sessionId'];
      });
      startOTPTimer();
    } else {
      //testing code
      /* setState(() {
        isOTPSent = true;
        sessionId = "test";
      });
      startOTPTimer();  */

      //testing code

      setState(() => isOTPSent = false);
      _showError(response["message"] ?? "Failed to send OTP");
      return;
    }
  }

  void startOTPTimer() {
    otpTimer?.cancel();
    setState(() {
      otpSeconds = 40;
      canResend = false;
    });

    otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpSeconds == 0) {
        timer.cancel();
        setState(() => canResend = true);
      } else {
        setState(() => otpSeconds--);
      }
    });
  }

  Future<void> verifyOtp() async {
    if (otpController.text.length != 6) {
      _showError("Enter valid 6 digit OTP");
      return;
    }
    print(sessionId);
    // 🔴 Check if sessionId is missing
    if (sessionId == null || sessionId!.isEmpty) {
      _showError("Session expired. Please resend OTP.");
      setState(() {
        isOTPSent = false; // reset
        isOtpVerified = false;
        otpController.clear();
      });
      return;
    }

    setState(() => loading = true);

    final res = await ApiService.post(
      ApiEndpoints.verifyRecoverOtp,
      body: {
        "phoneNumber": phoneController.text.trim(),
        "otp": otpController.text.trim(),
        "sessionId": sessionId,
      },
      context: context,
      isFullBody: true,
    );

    setState(() => loading = false);

    if (res["status"] != "success") {
      otpAttempts++;

      if (otpAttempts >= maxOtpAttempts) {
        // Reset full flow
        setState(() {
          isOTPSent = false;
          isOtpVerified = false;
          otpController.clear();
          sessionId = "";
          otpAttempts = 0;
          otpTimer?.cancel();
        });

        _showError(
          "You entered wrong OTP 3 times.\nPlease enter phone number again.",
        );
        return;
      }

      _showError("Invalid OTP. Attempts: $otpAttempts of $maxOtpAttempts");
      return;
    }

    // OTP success
    final data = res["result"];

    setState(() {
      isOtpVerified = true;
      shortToken = data['token'];
    });
  }

  Future<void> recoverWithPin() async {
    if (pinController.text.length != 6) {
      _showError("Enter valid 6 digit PIN");
      return;
    }

    if (shortToken == null || shortToken!.isEmpty) {
      _showError("Session expired. Please resend OTP.");
      return;
    }

    Map<String, dynamic> payload = {
      "pin": pinController.text.trim(),
      "phoneNumber": phoneController.text.trim(),
      "shortToken": shortToken,
    };

    final response = await ApiService.post(
      ApiEndpoints.verifyRecoverPin,
      body: payload,
      context: context,
      isFullBody: true,
    );

    if (response["status"] == "success" && response["result"] != null) {
      // 1️⃣ Read next token from result
      final String nextToken = response["result"]["token"] ?? "";

      if (nextToken.isEmpty) {
        _showError("Invalid token received.");
        return;
      }

      // 2️⃣ Call next API using a separate method
      await _callNextTokenService(nextToken);
    } else {
      _showError(response["message"] ?? "Recovery failed");
    }
  }

  Future<void> _callNextTokenService(String nextToken) async {
    Map<String, dynamic> payload = {
      "phoneNumber": pinController.text.trim(),
      "password": nextToken,
    };
    final res = await ApiService.post(
      ApiEndpoints.createToken, // <-- your next API endpoint
      body: payload,
      context: context,
      isFullBody: true,
    );

    if (res["status"] == "success" && res["result"] != null) {
      // Example final login
      ApiService.setUserTokens(res["result"]);

      // Navigate to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      _showError(res["message"] ?? "Something went wrong");
    }
  }

  Widget stepsIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        stepCircle(1, "OTP Verification", !isOtpVerified),
        stepLine(),
        stepCircle(2, "PIN Verification", isOtpVerified),
      ],
    );
  }

  Widget stepCircle(int step, String title, bool isActive) {
    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: isActive
              ? AppTheme.primaryColor
              : Colors.grey.shade300,
          child: Text(
            "$step",
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 100,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.black : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget stepLine() {
    return Container(
      width: 40,
      height: 2,
      color: Colors.grey.shade400,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  void _showError(String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.red.shade50,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Error",
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Colors.red.shade800, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text("OK", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopVisualSection(height: h * 0.35),

            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Opacity(opacity: _fadeAnimation.value, child: child),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const Text(
                          "Recover Account",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 10),

                        stepsIndicator(),
                        const SizedBox(height: 20),

                        // ---------------- ONLY SHOW BEFORE OTP VERIFIED ----------------
                        if (!isOtpVerified) ...[
                          if (!isOTPSent) // ← SHOW phone field only before send OTP
                            TextField(
                              controller: phoneController,
                              keyboardType: TextInputType.number,
                              maxLength: 10,
                              decoration: InputDecoration(
                                labelText: "Phone Number",
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),

                          if (isOTPSent) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Enter OTP sent to ${phoneController.text}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isOTPSent = false;
                                      isOtpVerified = false;
                                      otpController.clear();
                                      otpTimer?.cancel();
                                    });
                                  },
                                  child: const Text(
                                    "Edit",
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            Pinput(
                              controller: otpController,
                              length: 6,
                              defaultPinTheme: defaultPinTheme,
                              focusedPinTheme: defaultPinTheme.copyWith(
                                decoration: defaultPinTheme.decoration!
                                    .copyWith(
                                      border: Border.all(
                                        color: AppTheme.primaryColor,
                                        width: 2,
                                      ),
                                    ),
                              ),
                              keyboardType: TextInputType.number,
                            ),

                            const SizedBox(height: 8),
                            if (isOTPSent && !isOtpVerified) ...[
                              const SizedBox(height: 8),

                              // TIMER TEXT
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    canResend
                                        ? "Didn't receive the code? "
                                        : "Resend OTP in 00:${otpSeconds.toString().padLeft(2, '0')}",
                                    style: const TextStyle(fontSize: 14),
                                  ),

                                  if (canResend)
                                    TextButton(
                                      onPressed: () {
                                        otpController.clear();
                                        sendOtp();
                                      },
                                      child: const Text(
                                        "Resend OTP",
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                          const SizedBox(height: 8),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: loading
                                  ? null
                                  : (isOTPSent && !isOtpVerified)
                                  ? verifyOtp
                                  : (!isOTPSent)
                                  ? sendOtp
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                loading
                                    ? "Please wait..."
                                    : (!isOTPSent)
                                    ? "Send OTP"
                                    : (!isOtpVerified)
                                    ? "Verify OTP"
                                    : "OTP Verified ✔",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],

                        // ---------------- SHOW ONLY AFTER OTP VERIFIED ----------------
                        if (isOtpVerified) ...[
                          const SizedBox(height: 25),

                          const Text(
                            "Enter PIN",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),

                          Pinput(
                            controller: pinController,
                            length: 6,
                            obscureText: true,
                            defaultPinTheme: defaultPinTheme,
                            focusedPinTheme: defaultPinTheme.copyWith(
                              decoration: defaultPinTheme.decoration!.copyWith(
                                border: Border.all(
                                  color: AppTheme.primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),

                          const SizedBox(height: 25),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: recoverWithPin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Verify PIN",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 30),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, "REFRESH");
                          },
                          child: Text(
                            "Back to Login",
                            style: AppTheme.goldTitle.copyWith(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
