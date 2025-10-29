import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../screens/register_pan_verify.dart';
import '../screens/register_email_otp.dart';

class EnterEmailScreen extends StatefulWidget {
  const EnterEmailScreen({super.key});

  @override
  State<EnterEmailScreen> createState() => _EnterEmailScreenState();
}

class _EnterEmailScreenState extends State<EnterEmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool isButtonEnabled = false;

  void _checkField() {
    setState(() {
      isButtonEnabled = _emailController.text.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_checkField);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onVerify() {
    String email = _emailController.text.trim();
    print("Email: $email");

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EnterEmailOtpScreen()),
    );
  }

  void _onSkip() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PanVerificationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double logoSize = screenWidth * 0.3;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/logo.png',
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                "What is your email address?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle
              const Text(
                "This helps us send you important updates,\n"
                "share documents and verify your identity.",
                style: TextStyle(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Email input
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "test@gmail.com",
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Verify button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isButtonEnabled ? _onVerify : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text("Verify"),
                ),
              ),
              const SizedBox(height: 10),

              // Skip button
              TextButton(onPressed: _onSkip, child: const Text("Skip")),
              const SizedBox(height: 20),

              // Terms and privacy
              const Text(
                "By continuing you agree to our Terms and Privacy Policy.",
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
