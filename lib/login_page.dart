import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'register_page.dart';
import 'screens/dashboard.dart';


class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> login() async {
    final response = await http.post(
      Uri.parse("https://test.ajitgurung.ca/api/login"), // change to your API
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "email": emailController.text,
        "password": passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
  final data = json.decode(response.body);
  final prefs = await SharedPreferences.getInstance();

  // Save token
  await prefs.setString("token", data["access_token"]);

  // Save subscription flag
  if (data.containsKey("subscribed")) {
    await prefs.setBool("subscribed", data["subscribed"]);
  }

  // (Optional: save user info)
  if (data.containsKey("user")) {
    await prefs.setString("user", json.encode(data["user"]));
  }

  // Go to dashboard
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => DashboardScreen()),
  );
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Login failed")),
  );
}

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(onPressed: login, child: Text("Login")),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterPage()));
              },
              child: Text("No account? Register"),
            )
          ],
        ),
      ),
    );
  }
}
