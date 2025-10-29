import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double walletBalance = 3200;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 2 && transactions.isEmpty) {
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

  void addMoney() {
    final amount = double.tryParse(_addMoneyController.text);
    if (amount != null && amount > 0) {
      setState(() {
        walletBalance += amount;
        transactions.insert(0, {
          "date": DateTime.now().toString().split(' ')[0],
          "type": "Add Money",
          "amount": "₹${amount.toInt()}",
          "status": "Done",
        });
        _addMoneyController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Amount added successfully")),
      );
    }
  }

  void withdrawMoney() {
    final amount = double.tryParse(_withdrawController.text);
    if (amount != null && amount > 0 && amount <= walletBalance) {
      setState(() {
        walletBalance -= amount;
        transactions.insert(0, {
          "date": DateTime.now().toString().split(' ')[0],
          "type": "Withdraw",
          "amount": "₹${amount.toInt()}",
          "status": "Done",
        });
        _withdrawController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Amount withdrawn successfully")),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid amount")));
    }
  }

  Widget paymentOptions(
    String selectedPayment,
    Function(String) onSelect,
    bool showBankDetails,
  ) {
    final options = ["UPI", "Bank"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: options.map((method) {
            final isSelected = selectedPayment == method;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isSelected
                        ? Colors.yellow.shade700
                        : Colors.grey.shade400,
                    width: isSelected ? 2 : 1,
                  ),
                  backgroundColor: isSelected
                      ? Colors.yellow.shade50
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  onSelect(method);
                },
                child: Text(
                  method,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.grey.shade700,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (showBankDetails && selectedPayment == "Bank")
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.account_balance,
                          color: Colors.yellow,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Bank Account",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            getMaskedAccount(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: changeBankAccount,
                    child: Row(
                      children: const [
                        Text(
                          "Change",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.edit, size: 18, color: Colors.red),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
            const Text("Quick Add"),
            Row(
              children: [100, 500, 1000].map((amount) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      _addMoneyController.text = amount.toString();
                    },
                    child: Text(
                      "$amount",
                      style: const TextStyle(color: Colors.black),
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
            const Text("Payment Method"),
            paymentOptions(selectedPaymentWithdraw, (val) {
              setState(() {
                selectedPaymentWithdraw = val;
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
