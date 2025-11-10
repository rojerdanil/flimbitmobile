import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class SelectPaymentGatewayScreen extends StatefulWidget {
  const SelectPaymentGatewayScreen({super.key});

  @override
  State<SelectPaymentGatewayScreen> createState() =>
      _SelectPaymentGatewayScreenState();
}

class _SelectPaymentGatewayScreenState
    extends State<SelectPaymentGatewayScreen> {
  List<Map<String, dynamic>> upiAccounts = [];
  List<Map<String, dynamic>> bankAccounts = [];

  bool isLoading = true;
  String? selectedMethod; // "UPI" or "Bank Account"
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
          // Store actual value in 'value' field
          upiAccounts = (response["userUpiList"] as List)
              .map(
                (e) => {
                  "id": e["id"],
                  "name": e["upiId"], // display
                  "value": e["upiId"], // actual value
                },
              )
              .toList();

          bankAccounts = (response["userBankList"] as List)
              .map(
                (e) => {
                  "id": e["id"],
                  "name":
                      "${e["bankName"] ?? "Bank"} - ${e["accountNumber"] ?? ""}", // display
                  "value": e["accountNumber"], // actual account number
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
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor,
              blurRadius: 3,
              offset: const Offset(1, 2),
            ),
          ],
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Navigate to add $type account")),
                  );
                },
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
            (acc) => GestureDetector(
              onTap: () {
                setState(() {
                  selectedId = acc['id'];
                  selectedName = acc['value']; // ← use actual value here
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      acc['name'], // display string
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textColor,
                      ),
                    ),
                    if (selectedId == acc['id'])
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProceedButton() {
    return ElevatedButton(
      onPressed: (selectedId != null && selectedMethod != null)
          ? () {
              Map<String, dynamic> result = {
                "type": selectedMethod == "UPI" ? "upi" : "bank",
                "id": selectedId,
                "name": selectedName, // now always has actual value
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
}
