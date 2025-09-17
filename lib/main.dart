import 'package:flutter/material.dart';
import 'screens/dashboard.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access_token") != null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vehicle Info App',
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: isLoggedIn(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          // If logged in, go directly to Dashboard
          if (snapshot.data!) return DashboardScreen();

          // Otherwise, show HomePage (with Login/Register buttons)
          return HomePage();
        },
      ),
    );
  }
}
