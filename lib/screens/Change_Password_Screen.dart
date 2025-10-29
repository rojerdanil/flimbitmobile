import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with SingleTickerProviderStateMixin {
  bool _obscureCurrent = true;
  String newPassword = '';
  String confirmPassword = '';
  bool newCompleted = false;
  bool confirmCompleted = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  bool get isResetEnabled =>
      newCompleted && confirmCompleted && newPassword == confirmPassword;

  void _onResetPressed() {
    if (!isResetEnabled) {
      _shakeController.forward(from: 0);
    } else {
      // Reset password logic here
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final boxWidth = (screenWidth - 50) / 6;

    final defaultPinTheme = PinTheme(
      width: boxWidth,
      height: 60,
      textStyle: TextStyle(
        fontSize: 22,
        color: Colors.yellow.shade700,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      width: boxWidth + 8,
      height: 64,
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: Colors.yellow.shade700, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.shade200.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    Widget buildPinCard({
      required String label,
      required String helper,
      required bool obscure,
      required Function(String) onCompleted,
      required String currentValue,
      required bool showTick,
      bool eyeButton = false,
      Function()? toggleEye,
      Widget? shakeWrapper,
    }) {
      Widget pinWidget = Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Pinput(
            length: 6,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: focusedPinTheme,
            obscureText: obscure,
            obscuringCharacter: '*',
            animationDuration: const Duration(milliseconds: 200),
            keyboardType: TextInputType.number,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            enableInteractiveSelection: false,
            onCompleted: onCompleted,
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
      );

      if (shakeWrapper != null) {
        pinWidget = AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            double offset = _shakeAnimation.value;
            return Transform.translate(
              offset: Offset(
                offset *
                    (_shakeController.status == AnimationStatus.forward
                        ? 1
                        : -1),
                0,
              ),
              child: child,
            );
          },
          child: pinWidget,
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (eyeButton)
                IconButton(
                  icon: Icon(
                    _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: toggleEye,
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            helper,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Center(
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                pinWidget,
                if (showTick)
                  Positioned(
                    right: 8,
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 24,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
        ],
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.yellow.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: screenHeight * 0.03,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AppBar imitation
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Reset Password",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03),

                // Current Password
                buildPinCard(
                  label: "Current Password",
                  helper: "Enter your 6-digit numeric password",
                  obscure: _obscureCurrent,
                  showTick: false,
                  eyeButton: true,
                  toggleEye: () {
                    setState(() {
                      _obscureCurrent = !_obscureCurrent;
                    });
                  },
                  currentValue: '',
                  onCompleted: (pin) {},
                ),

                // New Password
                buildPinCard(
                  label: "New Password",
                  helper: "Enter your new 6-digit numeric password",
                  obscure: true,
                  showTick: newCompleted,
                  eyeButton: false,
                  currentValue: newPassword,
                  onCompleted: (pin) {
                    setState(() {
                      newPassword = pin;
                      newCompleted = pin.length == 6;
                    });
                  },
                ),

                // Confirm Password with shake wrapper
                buildPinCard(
                  label: "Confirm Password",
                  helper: "Re-enter your new password",
                  obscure: true,
                  showTick: confirmCompleted && confirmPassword == newPassword,
                  eyeButton: false,
                  currentValue: confirmPassword,
                  onCompleted: (pin) {
                    setState(() {
                      confirmPassword = pin;
                      confirmCompleted = pin.length == 6;
                    });
                  },
                  shakeWrapper: Container(), // marker to enable shake
                ),

                SizedBox(height: screenHeight * 0.05),

                // Reset Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isResetEnabled
                          ? Colors.yellow.shade700
                          : Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    onPressed: _onResetPressed,
                    child: const Text(
                      "Reset Password",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
