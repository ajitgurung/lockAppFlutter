// otp_verification_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'login_page.dart';

class OtpVerificationPage extends StatefulWidget {
  final String userId;
  final String email;

  const OtpVerificationPage({
    Key? key,
    required this.userId,
    required this.email,
  }) : super(key: key);

  @override
  _OtpVerificationPageState createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());
  bool loading = false;
  bool verifying = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldownTimer();
    _setupFocusNodes();
  }

  void _startCooldownTimer() {
    _resendCooldown = 30; // 30 seconds cooldown
    _cooldownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() {
          _resendCooldown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _setupFocusNodes() {
    for (int i = 0; i < focusNodes.length; i++) {
      focusNodes[i].addListener(() {
        if (!focusNodes[i].hasFocus && i < focusNodes.length - 1) {
          FocusScope.of(context).requestFocus(focusNodes[i + 1]);
        }
      });
    }
  }

  Future<void> verifyOtp() async {
    setState(() => verifying = true);

    String otp = otpControllers.map((controller) => controller.text).join();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter a complete 6-digit code"),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() => verifying = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("https://bikebible.ca/api/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_id": widget.userId,
          "otp": otp,
        }),
      );

      setState(() => verifying = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🎉 Email verified successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
        );
      } else {
        final data = json.decode(response.body);
        String errorMsg = data['message'] ?? "Verification failed";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );

        // Clear OTP fields on failure
        _clearOtpFields();
      }
    } catch (e) {
      setState(() => verifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ Network error. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearOtpFields() {
    for (var controller in otpControllers) {
      controller.clear();
    }
    FocusScope.of(context).requestFocus(focusNodes[0]);
  }

  Future<void> resendOtp() async {
    if (_resendCooldown > 0) return;

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse("https://bikebible.ca/api/resend-otp"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_id": widget.userId,
        }),
      );

      setState(() => loading = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("📧 New verification code sent!"),
            backgroundColor: Colors.green,
          ),
        );
        _startCooldownTimer(); // Restart cooldown
      } else {
        final data = json.decode(response.body);
        String errorMsg = data['message'] ?? "Failed to resend code";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ Failed to resend code. Please try again."),
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
                          Icons.verified_user_rounded,
                          size: isDesktop ? 50 : isTablet ? 45 : 40,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 40 : isTablet ? 32 : 24),

                      // Title
                      Text(
                        "Verify Your Email",
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
                      
                      // Description
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: subtitleFontSize,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.6,
                            fontWeight: FontWeight.w300,
                          ),
                          children: [
                            TextSpan(text: "We sent a 6-digit verification code to\n"),
                            TextSpan(
                              text: widget.email,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                // Removed underline for consistency
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isDesktop ? 50 : isTablet ? 40 : 32),

                      // OTP Input Section
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
                            // OTP Input Fields
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(6, (index) {
                                return Container(
                                  width: isDesktop ? 65 : isTablet ? 60 : 50,
                                  height: isDesktop ? 75 : isTablet ? 70 : 60,
                                  child: TextField(
                                    controller: otpControllers[index],
                                    focusNode: focusNodes[index],
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    maxLength: 1,
                                    style: TextStyle(
                                      fontSize: isDesktop ? 26 : isTablet ? 24 : 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    decoration: InputDecoration(
                                      counterText: "",
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.1),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.white.withOpacity(0.2),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (value) {
                                      if (value.length == 1 && index < 5) {
                                        FocusScope.of(context)
                                            .requestFocus(focusNodes[index + 1]);
                                      }
                                      if (value.isEmpty && index > 0) {
                                        FocusScope.of(context)
                                            .requestFocus(focusNodes[index - 1]);
                                      }
                                      // Auto-submit when all fields are filled
                                      if (index == 5 && value.isNotEmpty) {
                                        bool allFilled = otpControllers
                                            .every((controller) =>
                                                controller.text.isNotEmpty);
                                        if (allFilled) {
                                          verifyOtp();
                                        }
                                      }
                                    },
                                  ),
                                );
                              }),
                            ),
                            SizedBox(height: isDesktop ? 32 : isTablet ? 24 : 20),

                            // Verify Button
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
                                onPressed: verifying ? null : verifyOtp,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: buttonPadding),
                                  backgroundColor: Colors.white,
                                  foregroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: verifying
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
                                          Icon(Icons.verified_rounded, size: buttonFontSize + 4),
                                          SizedBox(width: 12),
                                          Text(
                                            "Verify Email",
                                            style: TextStyle(
                                              fontSize: buttonFontSize,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            SizedBox(height: isDesktop ? 20 : isTablet ? 16 : 12),

                            // Resend Code Section
                            Column(
                              children: [
                                if (_resendCooldown > 0)
                                  Text(
                                    "Resend code in $_resendCooldown seconds",
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
                                    ),
                                  )
                                else
                                  loading
                                      ? CircularProgressIndicator(color: Colors.white)
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Didn't receive the code? ",
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: resendOtp,
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: Size(50, 30),
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: Text(
                                                "Resend",
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
                          ],
                        ),
                      ),
                      SizedBox(height: isDesktop ? 40 : isTablet ? 32 : 24),

                      // Back to login
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => LoginPage()),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back_ios_new, size: 16),
                            SizedBox(width: 8),
                            Text(
                              "Back to Login",
                              style: TextStyle(
                                fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Help Text
                      Padding(
                        padding: EdgeInsets.only(top: isDesktop ? 32 : isTablet ? 24 : 16),
                        child: Text(
                          "Check your spam folder if you don't see the email",
                          style: TextStyle(
                            color: Colors.white54,
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
      ),
    );
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    for (var node in focusNodes) {
      node.dispose();
    }
    for (var controller in otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}