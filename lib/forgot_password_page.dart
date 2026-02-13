import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();
  bool loading = false;
  bool emailSent = false;

  Future<void> sendResetLink() async {
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter your email address"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse("https://bikebible.ca/api/forgot-password"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": emailController.text.trim(),
        }),
      );

      setState(() => loading = false);

      print("Forgot Password Status Code: ${response.statusCode}");
      print("Forgot Password Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => emailSent = true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Password reset link sent!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final data = json.decode(response.body);
        String errorMsg = "Failed to send reset link";
        
        if (data['message'] != null) {
          errorMsg = data['message'];
        } else if (data['errors'] != null && data['errors']['email'] != null) {
          errorMsg = data['errors']['email'][0];
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
      print("Forgot password error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ Network error. Please try again."),
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
    
    final primaryColor = Theme.of(context).scaffoldBackgroundColor;
    final primaryColorLight = Color.alphaBlend(Colors.white.withOpacity(0.1), primaryColor);
    final primaryColorDark = Color.alphaBlend(Colors.black.withOpacity(0.2), primaryColor);

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
          child: Stack( // Use Stack to position back button absolutely at top
            children: [
              // Back Button - Positioned at top left
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
                  iconSize: isDesktop ? 32 : isTablet ? 28 : 24,
                ),
              ),
              
              // Main Content
              Center(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 120.0 : isTablet ? 80.0 : 24.0,
                      vertical: isDesktop ? 80 : isTablet ? 60 : 40,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Header Icon
                          Container(
                            width: isDesktop ? 100 : isTablet ? 80 : 60,
                            height: isDesktop ? 100 : isTablet ? 80 : 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.lock_reset_rounded,
                              size: isDesktop ? 40 : isTablet ? 35 : 30,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: isDesktop ? 40 : isTablet ? 32 : 24),

                          // Title
                          Text(
                            "Reset Password",
                            style: TextStyle(
                              fontSize: isDesktop ? 36.0 : isTablet ? 32.0 : 28.0,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isDesktop ? 16 : isTablet ? 12 : 8),
                          
                          // Subtitle
                          Text(
                            emailSent
                                ? "Check your email for the password reset link"
                                : "Enter your email and we'll send you a reset link",
                            style: TextStyle(
                              fontSize: isDesktop ? 18.0 : isTablet ? 16.0 : 14.0,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w300,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isDesktop ? 50 : isTablet ? 40 : 32),

                          if (!emailSent) ...[
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
                                  hintText: "Enter your email address",
                                  hintStyle: TextStyle(color: Colors.white70),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: isDesktop ? 24.0 : isTablet ? 22.0 : 18.0,
                                    horizontal: 16,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_rounded,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 30),

                            // Send Reset Link Button
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
                                onPressed: loading ? null : sendResetLink,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isDesktop ? 22.0 : isTablet ? 20.0 : 18.0,
                                  ),
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
                                          Icon(Icons.send_rounded, size: isDesktop ? 20 : isTablet ? 18 : 16),
                                          SizedBox(width: 12),
                                          Text(
                                            "Send Reset Link",
                                            style: TextStyle(
                                              fontSize: isDesktop ? 18.0 : isTablet ? 16.0 : 14.0,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ] else ...[
                            // Success State
                            Container(
                              padding: EdgeInsets.all(isDesktop ? 40 : isTablet ? 32 : 24),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: isDesktop ? 60 : isTablet ? 50 : 40,
                                    color: Colors.green,
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    "Email Sent Successfully!",
                                    style: TextStyle(
                                      fontSize: isDesktop ? 20 : isTablet ? 18 : 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "We've sent a password reset link to your email address. Please check your inbox and follow the instructions.",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 30),

                            // Back to Login Button
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                "Back to Login",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}