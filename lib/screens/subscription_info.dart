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
    return Scaffold(
      appBar: AppBar(
        title: Text("Subscription Info", style: TextStyle(color: Colors.white70)),
        iconTheme: IconThemeData(color: Colors.white70),
        backgroundColor: Colors.blue.shade700,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    subscribed ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                    color: subscribed ? Colors.green : Colors.red,
                    size: 60,
                  ),
                  SizedBox(height: 16),
                  Text(
                    subscribed ? "Subscription Active" : "No Active Subscription",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: subscribed ? Colors.green : Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  if (subscribed) ...[
                    Text("Type: $type", style: TextStyle(fontSize: 16)),
                    if (nextPaymentDate.isNotEmpty)
                      Text("Next Payment Date: $nextPaymentDate", style: TextStyle(fontSize: 16)),
                    SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                    SizedBox(height: 20),
                  ],

                  // --- Styled note ---
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Note: To manage your subscription, please use our website.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: logout,
                    child: Text(
                      "Log Out",
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
