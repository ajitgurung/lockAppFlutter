import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login_page.dart';

class SubscriptionInfoScreen extends StatefulWidget {
  @override
  _SubscriptionInfoScreenState createState() => _SubscriptionInfoScreenState();
}

class _SubscriptionInfoScreenState extends State<SubscriptionInfoScreen> {
  bool loading = true;
  bool subscribed = false;
  String type = '';
  String message = '';
  String nextPaymentDate = '';

  @override
  void initState() {
    super.initState();
    fetchSubscription();
  }

  Future<void> fetchSubscription() async {
    try {
      final response = await ApiService.getSubscriptionStatus();
      print("Subscription API response: $response"); // DEBUG

      setState(() {
        subscribed = response['subscribed'] == true;
        type = response['type'] ?? '';
        message = response['message'] ?? '';
        nextPaymentDate = response['next_payment_date'] ?? '';
        loading = false;
      });
    } catch (e) {
      print("Error fetching subscription: $e");
      setState(() => loading = false);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('subscribed');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text("Subscription Info"),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : Center(
              child: Container(
                width: isTablet ? 600 : double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        subscribed
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_outlined,
                        color: subscribed ? Colors.green : Colors.red,
                        size: 80,
                      ),
                      SizedBox(height: 16),
                      Text(
                        subscribed
                            ? "Subscription Active"
                            : "No Active Subscription",
                        style: TextStyle(
                          fontSize: isTablet ? 24 : 20,
                          fontWeight: FontWeight.bold,
                          color: subscribed ? Colors.green : Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      if (subscribed) ...[
                        Text(
                          "Type: $type",
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            color: Colors.white,
                          ),
                        ),
                        if (nextPaymentDate.isNotEmpty)
                          Text(
                            "Next Payment Date: $nextPaymentDate",
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              color: Colors.white,
                            ),
                          ),
                        SizedBox(height: 8),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 20),
                      ],

                      // --- Styled note ---
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          "Note: To manage your subscription, please use our website.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            color: Colors.grey.shade800,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // --- Logout button ---
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF24455E),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: logout,
                          child: Text(
                            "Log Out",
                            style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                color: Colors.white),
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
