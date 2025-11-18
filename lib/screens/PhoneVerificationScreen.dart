import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/AppTheme.dart';
import '../screens/verify_otp_screen.dart';
import '../MainScreen/topVisualSection.dart'; // <-- Import the reusable top section
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../securityScreen/pin_verification_dialog.dart';
import '../screens/home-screen.dart'; // after login
import '../Readysection/CustomBottomSheet.dart';
import '../securityScreen/recover_account_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final bool isUserBlocked;

  const PhoneVerificationScreen({super.key, this.isUserBlocked = false});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final TextEditingController phoneController = TextEditingController();
  String errorMessage = '';
  final List<String> verifiedNumbers = ['9876543210', '9123456789'];
  Map<String, String>? companyContact;

  @override
  void initState() {
    super.initState();
    fetchCompanyContact();
  }

  Future<void> fetchCompanyContact() async {
    try {
      final response = await ApiService.get(ApiEndpoints.companyContact);
      if (response != null) {
        setState(() {
          companyContact = {
            "email": response['companyEmail'] ?? "",
            "phone": response['companyPhoneNumber'] ?? "",
            "companyName": response['companyName'] ?? "",
          };
        });
      }
    } catch (e) {
      debugPrint("Error fetching company contact: $e");
    }
  }

  Future<Map<String, dynamic>> fetchAccessTokenAndSet(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phoneNumber');
      Map<String, dynamic> payload = {
        "phoneNumber": phoneNumber,
        "password": token,
      };

      final response = await ApiService.post(
        ApiEndpoints.createToken,
        body: payload,
        isFullBody: true,
      );

      if (response == null) {
        return {
          "success": false,
          "message": "Something went wrong. Please try again.",
        };
      }

      // SUCCESS
      if (response["status"] == "success") {
        ApiService.setUserTokens(response["result"]);
        return {"success": true, "message": response["message"] ?? "Success"};
      }

      // FAILURE → return API message
      return {"success": false, "message": response["message"] ?? "Failed"};
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  void verifyPhone() async {
    String phone = phoneController.text.trim();

    // VALIDATION
    if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      setState(
        () => errorMessage = 'Please enter a valid 10-digit phone number',
      );
      return;
    }

    if (verifiedNumbers.contains(phone)) {
      setState(
        () => errorMessage =
            'Phone number is already verified with another device',
      );
      return;
    }

    setState(() => errorMessage = '');

    try {
      // ------- API REQUEST -------
      final response = await ApiService.post(
        ApiEndpoints.registerSendOtp, // <--- Add correct endpoint here
        body: {"phoneNumber": phone},
        isFullBody: true,
      );

      // NULL response case
      if (response == null) {
        setState(() {
          errorMessage = "Something went wrong. Try again.";
        });
        return;
      }

      // SUCCESS from main API
      if (response["status"] == "success" &&
          response["result"] != null &&
          response["result"]["sessionId"] != null) {
        final sessionId =
            response["result"]["sessionId"]; // <--- STORE SESSION ID

        // also save phone number for later login token step
        //final prefs = await SharedPreferences.getInstance();
        //prefs.setString("phoneNumber", phone);

        // Navigate to OTP screen WITH sessionId
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyOtpScreen(
              phoneNumber: phone,
              sessionId: sessionId!, // <---- PASS SESSION ID
            ),
          ),
        );
        return;
      }

      // FAILURE CASE
      /*  setState(() {
        errorMessage = response["message"] ?? "Failed to send OTP";
      });*/

      //test remove hared coded
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyOtpScreen(
            phoneNumber: phone,
            sessionId:
                "f27c7b2f-4fc0-4765-b093-967472e805fb"!, // <---- PASS SESSION ID
          ),
        ),
      );
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --------------------- REUSABLE TOP VISUAL SECTION ---------------------
            TopVisualSection(height: h * 0.45),

            // --------------------- BOTTOM INPUT SECTION ---------------------
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    // Show blocked message if user is blocked
                    if (widget.isUserBlocked) ...[
                      Text(
                        'Your account is blocked. Please contact support.',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],

                    const Text(
                      'Enter your phone number',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (errorMessage.isNotEmpty)
                      Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        hintText: 'e.g. 9876543210',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) {
                        if (errorMessage.isNotEmpty) {
                          setState(() => errorMessage = '');
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.isUserBlocked ? null : verifyPhone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Verify',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'By continuing you agree to our Terms and Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 40),

                    // --------------------- BOTTOM INFO SECTION ---------------------
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                // ✅ Add async here
                                bool isUser =
                                    await ApiService.isUserDataAvailable();
                                if (isUser) {
                                  final accessKey =
                                      await showPinVerificationDialog(
                                        context,
                                        isLoginScreen: true,
                                      );
                                  print("access key $accessKey");
                                  if (accessKey.isEmpty == false) {
                                    final result = await fetchAccessTokenAndSet(
                                      accessKey,
                                    );

                                    if (result["success"]) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const HomeScreen(),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            result["message"] ??
                                                "Something went wrong",
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                          backgroundColor: Colors.redAccent,
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                } else {
                                  // showModalBottomSheet
                                  CustomBottomSheet.show(
                                    context,
                                    title: "User Phone Number Not Found",
                                    message:
                                        "We are not able to find a user registered with this phone number.\n"
                                        "Please try ‘Recover Account’.",
                                    primaryButtonText: "Recover Account",
                                    onPrimaryPressed: () async {
                                      Navigator.pop(
                                        context,
                                      ); // close bottom sheet

                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const RecoverAccountScreen(),
                                        ),
                                      );

                                      if (result == "REFRESH") {
                                        setState(() {}); // Reload login screen
                                      }
                                    },

                                    secondaryButtonText: "Close",
                                  );
                                }
                              },
                              child: Text(
                                'Login',
                                style: AppTheme.goldTitle.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '?',
                              style: AppTheme.headline2.copyWith(fontSize: 16),
                            ),
                            const SizedBox(width: 5),
                            GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const RecoverAccountScreen(),
                                  ),
                                );

                                if (result == "REFRESH") {
                                  setState(() {}); // Reload login screen
                                }
                              },
                              child: Text(
                                'Recover account',
                                style: AppTheme.goldTitle.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        Text(
                          'Contact Email:  ${companyContact?['email'] ?? 'flimbitorg@gmail.com'}',
                          style: AppTheme.subtitle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contact Phone: ${companyContact?['phone'] ?? '+91 9626814334'}',
                          style: AppTheme.subtitle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '© 2025 ${companyContact?['companyName'] ?? ' Skyion tech'}',
                          style: AppTheme.headline2.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
