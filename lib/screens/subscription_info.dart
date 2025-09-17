import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    await prefs.remove('access_token'); // keep consistent with getToken()
    Navigator.pushReplacementNamed(context, '/login'); // ensure this route exists
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Subscription Info")),
      body: Center(
        child: loading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    subscribed ? "Subscription Active" : "No Active Subscription",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: subscribed ? Colors.green : Colors.red,
                    ),
                  ),
                  SizedBox(height: 8),
                  if (subscribed) ...[
                    Text("Type: $type"),
                    SizedBox(height: 8),
                    if (nextPaymentDate.isNotEmpty)
                      Text("Next Payment Date: $nextPaymentDate"),
                    SizedBox(height: 8),
                    Text(message),
                  ],
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: logout,
                    child: Text("Log Out"),
                  ),
                ],
              ),
      ),
    );
  }
}
