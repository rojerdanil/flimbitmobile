import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../Readysection/wallet_payment_summary_dialog.dart';
import '../Readysection/SelectPaymentGatewayScreen.dart';
import '../securityScreen/pin_verification_dialog.dart';

class WalletScreen extends StatefulWidget {
  final String? activeTab;
  const WalletScreen({super.key, this.activeTab});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double walletBalance = 0;

  List<Map<String, dynamic>> gatewayFees = [];
  bool isLoadingFees = false;

  final TextEditingController _addMoneyController = TextEditingController();
  final TextEditingController _withdrawController = TextEditingController();

  String selectedPaymentAdd = "UPI";
  String selectedPaymentWithdraw = "UPI";
  String bankAccount = "1234567890123456";

  String ifsc = ""; // add this

  List<Map<String, dynamic>> transactions = [];
  bool isLoadingTx = false;
  bool hasMoreTx = true;
  int offset = 0;
  final int limit = 10;
  late ScrollController _txScrollController;
  int? selectedQuickAdd;
  Map<String, dynamic>? selectedPaymentWithdrawObj;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    // 🔥 Set active tab based on parameter
    if (widget.activeTab != null) {
      switch (widget.activeTab!.toLowerCase()) {
        case "add":
        case "addmoney":
          _tabController.index = 0;
          break;
        case "withdraw":
        case "withdrawmoney":
          _tabController.index = 1;
          break;
        case "transactions":
        case "transection":
          _tabController.index = 2;
          break;
      }
    }

    fetchWalletBalance();
    fetchGatewayFees();
    if (widget.activeTab != null &&
        widget.activeTab!.toLowerCase() == "transactions") {
      fetchTransactions(reset: true);
    }
    _tabController.addListener(() {
      if (_tabController.index == 2) {
        fetchTransactions(reset: true);
      }
    });

    _txScrollController = ScrollController();
    _txScrollController.addListener(() {
      if (_txScrollController.position.pixels >=
              _txScrollController.position.maxScrollExtent - 100 &&
          !isLoadingTx &&
          hasMoreTx) {
        fetchTransactions();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _txScrollController.dispose();
    _addMoneyController.dispose();
    _withdrawController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tabController.index == 2) {
      fetchTransactions(reset: true);
    }
  }

  Future<void> fetchWalletBalance() async {
    try {
      final response = await ApiService.get(ApiEndpoints.userWalletBalance);
      if (response != null) {
        setState(() {
          walletBalance = double.tryParse(response['value'].toString()) ?? 0.0;
        });
      }
    } catch (e) {
      debugPrint("Error fetching wallet balance: $e");
    }
  }

  Future<void> fetchGatewayFees() async {
    setState(() => isLoadingFees = true);

    try {
      final response = await ApiService.get(ApiEndpoints.gatewayFees);
      if (response != null) {
        final List<dynamic> result = response;
        // Remove GST from list; we will handle separately if needed
        gatewayFees = result
            .where((e) => e['method'] != 'GST')
            .map(
              (e) => {
                'method': e['method'],
                'feePercentage': e['feePercentage'].toDouble(),
              },
            )
            .toList();
      }
    } catch (e) {
      debugPrint("Error fetching gateway fees: $e");
    }

    setState(() => isLoadingFees = false);
  }

  Future<void> fetchTransactions({bool reset = false}) async {
    if (isLoadingTx) return;
    setState(() => isLoadingTx = true);

    if (reset) {
      offset = 0;
      hasMoreTx = true;
    }

    final requestBody = {
      "offset": offset.toString(),
      "limit": limit.toString(),
    };

    try {
      final response = await ApiService.post(
        ApiEndpoints.walletTransactions,
        body: requestBody,
      );

      if (response != null) {
        List<dynamic> result = response;
        if (reset) {
          transactions = [];
        }
        transactions.addAll(result.map((e) => e as Map<String, dynamic>));

        if (result.length < limit) {
          hasMoreTx = false; // No more data
        } else {
          offset += limit;
        }
      }
    } catch (e) {
      debugPrint("Error fetching transactions: $e");
    }

    setState(() => isLoadingTx = false);
  }

  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.yellow.shade700, width: 2),
      ),
    );
  }

  String getMaskedAccount() {
    if (bankAccount.length >= 4) {
      return "**** **** **** ${bankAccount.substring(bankAccount.length - 4)}";
    }
    return bankAccount;
  }

  void changeBankAccount() {
    final TextEditingController accountController = TextEditingController(
      text: bankAccount,
    );
    final TextEditingController ifscController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 5,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Verify Bank Account",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: accountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Account Number",
                    hintText: "Enter your bank account number",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ifscController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: "IFSC Code",
                    hintText: "Enter your bank IFSC",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final newAccount = accountController.text.trim();
                          final newIfsc = ifscController.text
                              .trim()
                              .toUpperCase();

                          if (newAccount.length < 9 || newIfsc.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please enter valid account and IFSC",
                                ),
                              ),
                            );
                            return;
                          }

                          // Integrate Razorpay ₹1 verification here

                          setState(() {
                            bankAccount = newAccount;
                            ifsc = newIfsc; // now valid
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Bank account submitted. ₹1 verification will be done via Razorpay",
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Verify",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void addMoney() async {
    final amountText = _addMoneyController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter amount")));
      return;
    }

    final amount = double.tryParse(amountText) ?? 0;
    if (amount < 10) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Minimum amount is ₹10")));
      return;
    }

    if (selectedPaymentAdd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a payment method")),
      );
      return;
    }

    // ✅ Open Summary Dialog and wait for result
    final paymentSuccess = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WalletPaymentSummaryDialog(
        amount: amount,
        paymentOption: selectedPaymentAdd!,
      ),
    );

    // If payment was successful, refresh wallet balance
    if (paymentSuccess == true) {
      await fetchWalletBalance();

      // Optionally clear the amount input
      _addMoneyController.clear();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wallet balance updated successfully!")),
      );
    }
  }

  void withdrawMoney() async {
    final amountText = _withdrawController.text.trim();
    final amount = double.tryParse(amountText);

    // --- Validation: Amount ---
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount")),
      );
      return;
    }

    // --- Minimum limit ---
    if (amount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Minimum withdrawal amount is ₹100")),
      );
      return;
    }

    // --- Payment method check ---
    if (selectedPaymentWithdrawObj == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a payment method")),
      );
      return;
    }

    // --- Wallet balance check ---
    if (amount > walletBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient wallet balance")),
      );
      return;
    }

    // --- Ask user PIN for verification ---
    final rootContext = Navigator.of(context).context;
    final accessKey = await showPinVerificationDialog(rootContext);

    if (accessKey.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("PIN verification failed")));
      return;
    }

    try {
      // --- Show loading indicator ---
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // --- Prepare API payload ---
      final payload = {
        "amount": amount,
        "typeId": selectedPaymentWithdrawObj!['id'],
        "type": selectedPaymentWithdrawObj!['type'],
        "accessKey": accessKey, // 🔐 for backend verification
      };

      // --- Call backend API ---
      final response = await ApiService.post(
        ApiEndpoints.withdrawMoney,
        body: payload,
      );

      Navigator.pop(context); // close loader

      if (response != null) {
        await fetchWalletBalance(); // refresh wallet after success

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Withdrawal successful")));

        _withdrawController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? "Withdrawal failed")),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  Widget paymentOptions(
    String selectedPayment,
    Function(String) onSelect,
    bool showBankDetails,
  ) {
    final options = [
      {'id': 'UPI', 'label': 'UPI'},
      {'id': 'CARD', 'label': 'Card'},
      {'id': 'NETBANKING', 'label': 'Net Banking'},
    ];

    // Helper to get fee from gatewayFees list
    String getFeeText(String method) {
      final fee = gatewayFees.firstWhere(
        (e) => e['method'].toString().toLowerCase() == method.toLowerCase(),
        orElse: () => {'feePercentage': 0},
      )['feePercentage'];
      return " - ${fee == 0 ? '0%' : '$fee%'}";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...options.map((opt) {
          final method = opt['id']!;
          final label = opt['label']!;
          final isSelected = selectedPayment == method;
          final feeText = getFeeText(method);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: GestureDetector(
              onTap: () => onSelect(method),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? Colors.yellow.shade700
                        : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  color: isSelected ? Colors.yellow.shade50 : Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          method == 'UPI'
                              ? Icons.phone_android
                              : method == 'CARD'
                              ? Icons.credit_card
                              : Icons.account_balance,
                          color: Colors.black87,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "$label$feeText",
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget addMoneyTab() {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Amount"),
            const SizedBox(height: 8),
            TextField(
              controller: _addMoneyController,
              keyboardType: TextInputType.number,
              decoration: inputDecoration("Enter amount"),
            ),
            const SizedBox(height: 16),

            const Text(
              "Quick Add",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [100, 500, 1000].map((amount) {
                final isSelected = selectedQuickAdd == amount;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedQuickAdd = amount;
                          _addMoneyController.text = amount.toString();
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.yellow.shade50
                              : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? Colors.yellow.shade700
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "₹$amount",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            if (isSelected)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            const Text("Payment Method"),
            paymentOptions(selectedPaymentAdd, (val) {
              setState(() {
                selectedPaymentAdd = val;
              });
            }, true),
            const SizedBox(height: 16),

            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow.shade700,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 50,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: addMoney,
                child: const Text(
                  "Add Money",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> openPaymentSelection(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const SelectPaymentGatewayScreen(hideWallet: true),
      ),
    );

    if (result != null) {
      debugPrint("Selected Payment: $result");
      setState(() {
        selectedPaymentWithdrawObj = result; // Store selected payment method
      });
    }
  }

  Widget withdrawTab() {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Amount"),
            const SizedBox(height: 8),
            TextField(
              controller: _withdrawController,
              keyboardType: TextInputType.number,
              decoration: inputDecoration("Enter amount"),
            ),
            const SizedBox(height: 16),

            const Text(
              "Payment Method",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // 🔽 This replaces your old ElevatedButton 🔽
            if (selectedPaymentWithdrawObj == null)
              ElevatedButton.icon(
                onPressed: () => openPaymentSelection(context),
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text("Select Payment Option"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow.shade100,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.yellow.shade700, width: 1.2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_balance, color: Colors.black87),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedPaymentWithdrawObj!['name'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "Type: ${selectedPaymentWithdrawObj!['type'] ?? 'Unknown'}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 28,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orangeAccent),
                      onPressed: () => openPaymentSelection(context),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow.shade700,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 50,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: withdrawMoney,
                child: const Text(
                  "Withdraw",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget transactionsTab() {
    if (isLoadingTx && transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async => fetchTransactions(reset: true),
      child: ListView.builder(
        controller: _txScrollController,
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length + (hasMoreTx ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == transactions.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final tx = transactions[index];
          final isCredit = tx['type'] == "CREDIT";

          return Card(
            color: Colors.white,
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Icon(
                isCredit ? Icons.add_circle : Icons.remove_circle,
                color: isCredit ? Colors.green : Colors.red,
              ),
              title: Text(
                "${tx['type']} - ₹${tx['amount'].toStringAsFixed(2)}",
              ),
              subtitle: Text(tx['createdDate'].toString().split('T')[0]),
              trailing: Text(
                tx['source'] ?? "",
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            children: [
              // AppBar imitation
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Wallet Balance",
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          "₹${walletBalance.toInt()}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tab Bar with underline for active tab
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.yellow.shade700,
                  indicatorWeight: 3,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey.shade600,
                  tabs: const [
                    Tab(text: "Add Money"),
                    Tab(text: "Withdraw"),
                    Tab(text: "Transactions"),
                  ],
                ),
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [addMoneyTab(), withdrawTab(), transactionsTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
