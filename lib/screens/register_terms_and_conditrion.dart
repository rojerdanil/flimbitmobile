import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../screens/register_security_pin.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  bool isTermsChecked = false;
  bool isPrivacyChecked = false;

  bool get isButtonEnabled => isTermsChecked && isPrivacyChecked;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double logoSize = screenWidth * 0.3;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Logo
              Center(
                child: Image.asset(
                  'assets/logo.png',
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Center(
                child: Text(
                  "Terms & Conditions",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // Scrollable Terms
              Expanded(
                child: SingleChildScrollView(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: "1. Investment Risk\n",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black, // highlighted heading
                          ),
                        ),
                        const TextSpan(
                          text:
                              "All investments are subject to market and industry risks. Returns are not guaranteed, and users should invest responsibly.\n\n",
                        ),
                        TextSpan(
                          text: "2. Profit Distribution\n",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const TextSpan(
                          text:
                              "Profit sharing will start 45 days after the movie’s official release. The amount depends on actual movie earnings and platform policies.\n\n",
                        ),
                        TextSpan(
                          text: "3. Movie Cancellation / Delay\n",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const TextSpan(
                          text:
                              "If a movie is canceled or delayed, the company will take steps as per government guidelines to recover funds. Refund timelines may vary.\n\n",
                        ),
                        TextSpan(
                          text: "4. Compliance & Verification\n",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const TextSpan(
                          text:
                              "Users must complete Video KYC verification to unlock higher investment limits and comply with regulatory norms.\n\n",
                        ),
                        TextSpan(
                          text: "5. Withdrawal & Payouts\n",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const TextSpan(
                          text:
                              "Withdrawals and payouts will be processed via the user’s linked bank account within 7-15 business days after profit distribution.\n\n",
                        ),
                        TextSpan(
                          text: "6. Platform Fee\n",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const TextSpan(
                          text:
                              "A platform commission may apply to investments and profits, as per current policies.\n\n",
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Checkboxes
              Row(
                children: [
                  Checkbox(
                    value: isTermsChecked,
                    onChanged: (value) {
                      setState(() {
                        isTermsChecked = value ?? false;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      "I have read and agree to the Terms & Conditions",
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: isPrivacyChecked,
                    onChanged: (value) {
                      setState(() {
                        isPrivacyChecked = value ?? false;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      "I agree to the Privacy Policy",
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Accept & Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isButtonEnabled
                      ? () {
                          print("Terms Accepted, Continue");
                          // TODO: Navigate to next screen

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SetSecurityPinScreen(),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text("Accept & Continue"),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
