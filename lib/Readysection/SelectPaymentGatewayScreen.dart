import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class SelectPaymentGatewayScreen extends StatefulWidget {
  final bool? hideWallet; // 👈 optional flag

  const SelectPaymentGatewayScreen({super.key, this.hideWallet});

  @override
  State<SelectPaymentGatewayScreen> createState() =>
      _SelectPaymentGatewayScreenState();
}

class _SelectPaymentGatewayScreenState
    extends State<SelectPaymentGatewayScreen> {
  List<Map<String, dynamic>> upiAccounts = [];
  List<Map<String, dynamic>> bankAccounts = [];
  Map<String, dynamic>? walletAccount; // Wallet object with total

  bool isLoading = true;
  String? selectedMethod; // "Wallet", "UPI" or "Bank Account"
  int? selectedId;
  String? selectedName;

  @override
  void initState() {
    super.initState();
    _fetchPaymentAccounts();
  }

  Future<void> _fetchPaymentAccounts() async {
    try {
      final response = await ApiService.get(
        ApiEndpoints.userBankAccountsDetails,
      );
      if (response != null) {
        setState(() {
          // Wallet
          walletAccount = response["walletAmount"];

          // UPI
          upiAccounts = (response["userUpiList"] as List)
              .map(
                (e) => {"id": e["id"], "name": e["upiId"], "value": e["upiId"]},
              )
              .toList();

          // Bank
          bankAccounts = (response["userBankList"] as List)
              .map(
                (e) => {
                  "id": e["id"],
                  "name":
                      "${e["bankName"] ?? "Bank"} - ${_maskAccount(e["accountNumber"] ?? "")}",
                  "value": e["accountNumber"],
                },
              )
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching payment accounts: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _maskAccount(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;
    return "****${accountNumber.substring(accountNumber.length - 4)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Select Payment Method"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Select Payment Gateway", style: AppTheme.headline2),
                  const SizedBox(height: 10),
                  if ((widget.hideWallet != true) && walletAccount != null)
                    _buildWalletOption(walletAccount!),
                  _buildPaymentOption("UPI", Icons.account_balance_wallet),
                  _buildPaymentOption("Bank Account", Icons.account_balance),
                  const SizedBox(height: 20),
                  if (selectedMethod == "UPI")
                    _buildAccountList("upi", upiAccounts)
                  else if (selectedMethod == "Bank Account")
                    _buildAccountList("bank", bankAccounts),
                  const Spacer(),
                  _buildProceedButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildWalletOption(Map<String, dynamic> wallet) {
    bool isSelectable = (wallet["total"] ?? 0) > 0;
    bool isSelected = selectedMethod == "Wallet";
    return GestureDetector(
      onTap: isSelectable
          ? () {
              setState(() {
                selectedMethod = "Wallet";
                selectedId = null;
                selectedName = "Wallet";
              });
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.15)
              : AppTheme.accentColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : isSelectable
                ? Colors.grey.shade300
                : Colors.grey.shade400,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: Colors.orange),
            const SizedBox(width: 10),
            Text(
              "Wallet - ₹${wallet['total'] ?? 0}",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelectable ? AppTheme.textColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String label, IconData icon) {
    bool isSelected = selectedMethod == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMethod = label;
          selectedId = null;
          selectedName = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.15)
              : AppTheme.accentColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountList(String type, List<Map<String, dynamic>> accounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${type.toUpperCase()} Accounts", style: AppTheme.headline2),
            if (accounts.length < 2)
              TextButton.icon(
                onPressed: () => _showAddAccountDialog(type),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Add"),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (accounts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primaryColor),
            ),
            child: Text(
              "No $type accounts found.",
              style: const TextStyle(color: Colors.orange),
            ),
          )
        else
          ...accounts.map(
            (acc) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: selectedId == acc['id']
                    ? AppTheme.primaryColor.withOpacity(0.25)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selectedId == acc['id']
                      ? AppTheme.primaryColor
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _confirmDeleteAccount(type, acc['id']),
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedId = acc['id'];
                          selectedName = acc['value'];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        color: Colors.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              acc['name'],
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppTheme.textColor,
                              ),
                            ),
                            if (selectedId == acc['id'])
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProceedButton() {
    return ElevatedButton(
      onPressed:
          (selectedMethod != null &&
              (selectedMethod == "Wallet" || selectedId != null))
          ? () {
              // Build the return data
              Map<String, dynamic> result = {
                "type": selectedMethod == "Wallet"
                    ? "wallet"
                    : selectedMethod == "UPI"
                    ? "upi"
                    : "bank",
                "id": selectedMethod == "Wallet"
                    ? (walletAccount?['total'] ?? 0)
                    : selectedId,
                "name":
                    selectedName ??
                    (selectedMethod == "Wallet" ? "Wallet" : null),
                "methodType":
                    selectedMethod, // 👈 NEW FIELD ADDED (e.g., "UPI", "Bank Account", "Wallet")
              };

              Navigator.pop(context, result);
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        "Proceed",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ---------------- Animated Add Account Dialog ----------------
  Future<void> _showAddAccountDialog(String type) async {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController upiController = TextEditingController();
    final TextEditingController holderController = TextEditingController();
    final TextEditingController accountController = TextEditingController();
    final TextEditingController reAccountController = TextEditingController();
    final TextEditingController ifscController = TextEditingController();

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Add Account",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: _buildAddAccountDialogContent(
              type,
              _formKey,
              upiController,
              holderController,
              accountController,
              reAccountController,
              ifscController,
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: child,
        );
      },
    );
  }

  Widget _buildAddAccountDialogContent(
    String type,
    GlobalKey<FormState> _formKey,
    TextEditingController upiController,
    TextEditingController holderController,
    TextEditingController accountController,
    TextEditingController reAccountController,
    TextEditingController ifscController,
  ) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Add ${type == "upi" ? "UPI" : "Bank"} Account",
                style: AppTheme.headline2.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 15),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (type == "upi")
                      _buildStyledTextField(
                        controller: upiController,
                        label: "UPI ID",
                        hint: "Enter your UPI ID",
                      )
                    else ...[
                      _buildStyledTextField(
                        controller: holderController,
                        label: "Account Holder Name",
                        hint: "Enter name",
                      ),
                      const SizedBox(height: 12),
                      _buildStyledTextField(
                        controller: accountController,
                        label: "Account Number",
                        hint: "Enter account number",
                        keyboardType: TextInputType.number,
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      _buildStyledTextField(
                        controller: reAccountController,
                        label: "Re-enter Account Number",
                        hint: "Re-enter account number",
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please re-enter account number";
                          } else if (value.trim() !=
                              accountController.text.trim()) {
                            return "Account numbers do not match";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildStyledTextField(
                        controller: ifscController,
                        label: "IFSC Code",
                        hint: "Enter IFSC code",
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        Map<String, dynamic> payload;
                        String apiEndpoint;
                        if (type == "upi") {
                          payload = {"upiId": upiController.text.trim()};
                          apiEndpoint = ApiEndpoints.addUpiAccount;
                        } else {
                          payload = {
                            "accountHolderName": holderController.text.trim(),
                            "accountNumber": accountController.text.trim(),
                            "ifscCode": ifscController.text.trim(),
                          };
                          apiEndpoint = ApiEndpoints.addBankAccount;
                        }
                        try {
                          final response = await ApiService.post(
                            apiEndpoint,
                            body: payload,
                          );
                          if (response != null) {
                            Navigator.pop(context);
                            _fetchPaymentAccounts();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "${type.toUpperCase()} added successfully!",
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  response["message"] ?? "Failed to add",
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint("Error adding account: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Something went wrong"),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text("Save"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Delete Confirmation ----------------
  Future<void> _confirmDeleteAccount(String type, int id) async {
    bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this account?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        String apiEndpoint = type == "upi"
            ? "${ApiEndpoints.deleteUpiAccount}/$id"
            : "${ApiEndpoints.deleteBankAccount}/$id";
        final response = await ApiService.get(apiEndpoint);
        if (response != null && response["success"] == true) {
          _fetchPaymentAccounts();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${type.toUpperCase()} deleted successfully!"),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response?["message"] ?? "Failed to delete")),
          );
        }
      } catch (e) {
        debugPrint("Error deleting account: $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Something went wrong")));
      }
    }
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: AppTheme.textColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppTheme.primaryColor),
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: AppTheme.accentColor.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14.0,
          horizontal: 12.0,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
      ),
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return "Please enter $label";
            }
            return null;
          },
    );
  }
}
