import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'register_page.dart';
import 'screens/dashboard.dart';
import 'otp_verification_page.dart';
import 'forgot_password_page.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  bool checkingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkExistingLogin();
  }

  /// ✅ AUTO LOGIN CHECK
  Future<void> _checkExistingLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token != null && token.isNotEmpty) {
      // User already logged in, redirect to Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen()),
      );
    } else {
      setState(() => checkingAuth = false); // Show login page
    }
  }

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse("https://bikebible.ca/api/login"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": emailController.text.trim(),
          "password": passwordController.text.trim(),
        }),
      );

      setState(() => loading = false);

      print("Login Status Code: ${response.statusCode}");
      print("Login Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString("token", data["access_token"]);
        await prefs.setBool("logged_in", true);

        if (data.containsKey("subscribed")) {
          await prefs.setBool("subscribed", data["subscribed"]);
        }
        if (data.containsKey("user")) {
          await prefs.setString("user", json.encode(data["user"]));
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen()),
        );
      } else if (response.statusCode == 403) {
        final data = json.decode(response.body);

        if (data['needs_verification'] == true && data['user_id'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? "Please verify your email"),
              backgroundColor: Colors.orange,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OtpVerificationPage(
                userId: data['user_id'].toString(),
                email: emailController.text.trim(),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? "Verification required"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        final data = json.decode(response.body);
        String errorMsg = "Invalid email or password";

        if (data['message'] != null) {
          errorMsg = data['message'];
        } else if (data['errors'] != null) {
          if (data['errors'] is Map) {
            errorMsg = (data['errors'] as Map).values
                .expand((e) => e is List ? e : [e])
                .join("\n");
          } else if (data['errors'] is String) {
            errorMsg = data['errors'];
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      print("Login error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Network error. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (checkingAuth) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isDesktop = size.width > 900;

    final primaryColor = Theme.of(context).scaffoldBackgroundColor;
    final primaryColorLight =
        Color.alphaBlend(Colors.white.withOpacity(0.1), primaryColor);
    final primaryColorDark =
        Color.alphaBlend(Colors.black.withOpacity(0.2), primaryColor);

    // Responsive sizing
    final titleFontSize = isDesktop
        ? 48.0
        : isTablet
            ? 40.0
            : 32.0;
    final subtitleFontSize = isDesktop
        ? 22.0
        : isTablet
            ? 20.0
            : 16.0;
    final buttonFontSize = isDesktop
        ? 20.0
        : isTablet
            ? 18.0
            : 16.0;
    final fieldPadding = isDesktop
        ? 24.0
        : isTablet
            ? 22.0
            : 18.0;
    final buttonPadding = isDesktop
        ? 22.0
        : isTablet
            ? 20.0
            : 18.0;
    final horizontalPadding = isDesktop
        ? 120.0
        : isTablet
            ? 80.0
            : 24.0;

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isDesktop
                      ? 80
                      : isTablet
                          ? 60
                          : 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header Icon/Logo
                    Container(
                      width: isDesktop
                          ? 120
                          : isTablet
                              ? 100
                              : 80,
                      height: isDesktop
                          ? 120
                          : isTablet
                              ? 100
                              : 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.login_rounded,
                        size: isDesktop
                            ? 50
                            : isTablet
                                ? 45
                                : 40,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 40 : isTablet ? 32 : 24),

                    // Title
                    Text(
                      "Welcome Back",
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        shadows: const [
                          Shadow(
                            blurRadius: 15,
                            color: Colors.black45,
                            offset: Offset(3, 3),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isDesktop ? 16 : isTablet ? 12 : 8),

                    // Subtitle
                    Text(
                      "Log in to access your Bike Bible account",
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isDesktop ? 50 : isTablet ? 40 : 32),

                    // Login Form
                    Container(
                      padding: EdgeInsets.all(
                          isDesktop ? 40 : isTablet ? 32 : 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Email Field
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "Email Address",
                                hintStyle: const TextStyle(color: Colors.white70),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: fieldPadding,
                                  horizontal: 16,
                                ),
                                prefixIcon: const Icon(
                                  Icons.email_rounded,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: passwordController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "Password",
                                hintStyle: const TextStyle(color: Colors.white70),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: fieldPadding,
                                  horizontal: 16,
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock_rounded,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ForgotPasswordPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: loading ? null : login,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    vertical: buttonPadding),
                                backgroundColor: Colors.white,
                                foregroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: loading
                                  ? SizedBox(
                                      height: isDesktop
                                          ? 28
                                          : isTablet
                                              ? 26
                                              : 24,
                                      width: isDesktop
                                          ? 28
                                          : isTablet
                                              ? 26
                                              : 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: primaryColor,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.login_rounded,
                                            size: buttonFontSize + 4),
                                        const SizedBox(width: 12),
                                        const Text(
                                          "Login to Account",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Register Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account?",
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RegisterPage(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Sign Up",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Additional Help
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.parse('https://bikebible.ca/support');
                        try {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Could not open support link"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Text(
                        "Having trouble logging in? Contact support",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isDesktop ? 14 : 12,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
