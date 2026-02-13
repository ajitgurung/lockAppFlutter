import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';
import 'otp_verification_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = false;

  Future<void> register() async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse("https://bikebible.ca/api/register"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "name": nameController.text.trim(),
          "email": emailController.text.trim(),
          "password": passwordController.text,
          "password_confirmation": confirmPasswordController.text,
        }),
      );

      setState(() => loading = false);

      // Debug logging
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print("Parsed Data: $data");
        
        // Handle user_id properly - convert to string
        dynamic userId = data['user_id'];
        String userIdString = userId?.toString() ?? '';
        
        if (userIdString.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Registration successful but user ID not found"),
              backgroundColor: Colors.orange,
            ),
          );
          // Fallback to login page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LoginPage()),
          );
          return;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🎉 Registered successfully. Please verify your email."),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to OTP verification page instead of login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationPage(
              userId: userIdString, // Use the converted string
              email: emailController.text.trim(),
            ),
          ),
        );
      } else {
        final data = json.decode(response.body);
        String errorMsg = "Registration failed";

        if (data['message'] != null) {
          errorMsg = data['message'];
        } else if (data['errors'] != null) {
          // Handle different error formats
          if (data['errors'] is Map) {
            errorMsg = (data['errors'] as Map)
                .values
                .expand((e) => e is List ? e : [e])
                .join("\n");
          } else if (data['errors'] is String) {
            errorMsg = data['errors'];
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      print("Error during registration: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ Network error. Please check your connection and try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isDesktop = size.width > 900;
    
    // Get theme colors
    final primaryColor = Theme.of(context).scaffoldBackgroundColor;
    final primaryColorLight = Color.alphaBlend(Colors.white.withOpacity(0.1), primaryColor);
    final primaryColorDark = Color.alphaBlend(Colors.black.withOpacity(0.2), primaryColor);
    
    // Responsive sizing
    final titleFontSize = isDesktop ? 48.0 : isTablet ? 40.0 : 32.0;
    final subtitleFontSize = isDesktop ? 22.0 : isTablet ? 20.0 : 16.0;
    final buttonFontSize = isDesktop ? 20.0 : isTablet ? 18.0 : 16.0;
    final fieldPadding = isDesktop ? 24.0 : isTablet ? 22.0 : 18.0;
    final buttonPadding = isDesktop ? 22.0 : isTablet ? 20.0 : 18.0;
    final horizontalPadding = isDesktop ? 120.0 : isTablet ? 80.0 : 24.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColorDark,
                primaryColor,
                primaryColorLight,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.6, 1.0],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isDesktop ? 80 : isTablet ? 60 : 40,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header Icon
                      Container(
                        width: isDesktop ? 120 : isTablet ? 100 : 80,
                        height: isDesktop ? 120 : isTablet ? 100 : 80,
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
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person_add_rounded,
                          size: isDesktop ? 50 : isTablet ? 45 : 40,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 40 : isTablet ? 32 : 24),

                      // Title
                      Text(
                        "Create Account",
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
                        "Join Bike Bible to secure your vehicle information",
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w300,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isDesktop ? 50 : isTablet ? 40 : 32),

                      // Registration Form Container
                      Container(
                        padding: EdgeInsets.all(isDesktop ? 40 : isTablet ? 32 : 24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Name Field
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: nameController,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Full Name",
                                  hintStyle: TextStyle(color: Colors.white70),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: fieldPadding,
                                    horizontal: 16,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_rounded,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),

                            // Email Field
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Email Address",
                                  hintStyle: TextStyle(color: Colors.white70),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: fieldPadding,
                                    horizontal: 16,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_rounded,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),

                            // Password Field
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: passwordController,
                                obscureText: true,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Password",
                                  hintStyle: TextStyle(color: Colors.white70),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: fieldPadding,
                                    horizontal: 16,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_rounded,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),

                            // Confirm Password Field
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: confirmPasswordController,
                                obscureText: true,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Confirm Password",
                                  hintStyle: TextStyle(color: Colors.white70),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: fieldPadding,
                                    horizontal: 16,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 30),

                            // Register Button
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColorDark.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: loading ? null : register,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: buttonPadding),
                                  backgroundColor: Colors.white,
                                  foregroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: loading
                                    ? SizedBox(
                                        height: isDesktop ? 28 : isTablet ? 26 : 24,
                                        width: isDesktop ? 28 : isTablet ? 26 : 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: primaryColor,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.person_add_alt_1_rounded, size: buttonFontSize + 4),
                                          SizedBox(width: 12),
                                          Text(
                                            "Create Account",
                                            style: TextStyle(
                                              fontSize: buttonFontSize,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            SizedBox(height: 20),

                            // Login Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account?",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
                                  ),
                                ),
                                SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (_) => LoginPage()),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size(50, 30),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    "Login",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isDesktop ? 40 : isTablet ? 32 : 24),

                      // Additional Info Text
                      Text(
                        "By creating an account, you agree to our Terms of Service",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: isDesktop ? 14 : 12,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}