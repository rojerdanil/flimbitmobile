import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../screens/home-screen.dart';

class SetSecurityPinScreen extends StatefulWidget {
  const SetSecurityPinScreen({super.key});

  @override
  State<SetSecurityPinScreen> createState() => _SetSecurityPinScreenState();
}

class _SetSecurityPinScreenState extends State<SetSecurityPinScreen> {
  final List<TextEditingController> _pinControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _pinFocus = List.generate(6, (index) => FocusNode());

  final List<TextEditingController> _confirmControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _confirmFocus = List.generate(
    6,
    (index) => FocusNode(),
  );

  bool isButtonEnabled = false;
  bool _isPinVisible = false; // toggle for pin
  bool _isConfirmPinVisible = false; // toggle for confirm pin
  String errorMessage = "";

  void _checkPinsFilled() {
    String pin = _pinControllers.map((c) => c.text).join();
    String confirm = _confirmControllers.map((c) => c.text).join();

    setState(() {
      isButtonEnabled = (pin.length == 6 && confirm.length == 6);
      errorMessage = "";
    });
  }

  @override
  void initState() {
    super.initState();
    for (var c in _pinControllers) {
      c.addListener(_checkPinsFilled);
    }
    for (var c in _confirmControllers) {
      c.addListener(_checkPinsFilled);
    }
  }

  @override
  void dispose() {
    for (var c in _pinControllers) {
      c.dispose();
    }
    for (var c in _confirmControllers) {
      c.dispose();
    }
    for (var f in _pinFocus) {
      f.dispose();
    }
    for (var f in _confirmFocus) {
      f.dispose();
    }
    super.dispose();
  }

  void _onConfirm() {
    String pin = _pinControllers.map((c) => c.text).join();
    String confirm = _confirmControllers.map((c) => c.text).join();

    if (pin != confirm) {
      setState(() {
        errorMessage = "Pin is not matched";
      });
    } else {
      setState(() {
        errorMessage = "";
      });
      print("Security PIN Set: $pin");

      // TODO: Save PIN securely and navigate
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Security PIN set successfully")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  Widget _buildPinBox(
    int index,
    List<TextEditingController> controllers,
    List<FocusNode> focusNodes,
    bool isVisible,
  ) {
    return SizedBox(
      width: 50,
      child: TextField(
        controller: controllers[index],
        focusNode: focusNodes[index],
        keyboardType: TextInputType.number,
        obscureText: !isVisible,
        obscuringCharacter: "*",
        textAlign: TextAlign.center,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: "",
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            focusNodes[index + 1].requestFocus();
          }
          if (value.isEmpty && index > 0) {
            focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  Widget _buildPinRow(
    List<TextEditingController> controllers,
    List<FocusNode> focusNodes,
    bool isVisible,
    VoidCallback onToggle,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            6,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: _buildPinBox(index, controllers, focusNodes, isVisible),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggle,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double logoSize = screenWidth * 0.3;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                "Set your security pin",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle
              const Text(
                "This pin helps you to secure your account",
                style: TextStyle(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // PIN Row with toggle
              _buildPinRow(_pinControllers, _pinFocus, _isPinVisible, () {
                setState(() {
                  _isPinVisible = !_isPinVisible;
                });
              }),
              const SizedBox(height: 20),

              // Confirm PIN Row with toggle
              _buildPinRow(
                _confirmControllers,
                _confirmFocus,
                _isConfirmPinVisible,
                () {
                  setState(() {
                    _isConfirmPinVisible = !_isConfirmPinVisible;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Error Message
              if (errorMessage.isNotEmpty)
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              const SizedBox(height: 20),

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isButtonEnabled ? _onConfirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text("Confirm"),
                ),
              ),
              const SizedBox(height: 20),

              // Note
              const Text(
                "Do not share your pin with anyone",
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
