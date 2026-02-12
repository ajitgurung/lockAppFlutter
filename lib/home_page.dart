import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_page.dart';
import 'register_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  // Helper to open links externally
  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isDesktop = size.width > 900;

    // Get theme colors
    final primaryColor = Theme.of(context).scaffoldBackgroundColor;
    final primaryColorLight = Color.alphaBlend(
      Colors.white.withOpacity(0.1),
      primaryColor,
    );
    final primaryColorDark = Color.alphaBlend(
      Colors.black.withOpacity(0.2),
      primaryColor,
    );

    // Responsive sizing
    final titleFontSize = isDesktop
        ? 72.0
        : isTablet
        ? 64.0
        : 48.0;
    final subtitleFontSize = isDesktop
        ? 24.0
        : isTablet
        ? 22.0
        : 18.0;
    final buttonFontSize = isDesktop
        ? 22.0
        : isTablet
        ? 20.0
        : 16.0;
    final paddingHorizontal = isDesktop
        ? 120.0
        : isTablet
        ? 80.0
        : 32.0;
    final buttonVerticalPadding = isDesktop
        ? 24.0
        : isTablet
        ? 20.0
        : 16.0;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColorDark, primaryColor, primaryColorLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background decorative elements
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -80,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.03),
                  ),
                ),
              ),

              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 800 : 700),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // App Logo
                      // App Logo
                      Container(
                        width: isDesktop
                            ? 140
                            : isTablet
                            ? 120
                            : 100,
                        height: isDesktop
                            ? 140
                            : isTablet
                            ? 120
                            : 100,
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
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo/app_icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Try different paths
                              return Image.asset(
                                'assets/images/app_icon.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.two_wheeler,
                                    size: isDesktop
                                        ? 50
                                        : isTablet
                                        ? 45
                                        : 40,
                                    color: Colors.white,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        height: isDesktop
                            ? 40
                            : isTablet
                            ? 32
                            : 24,
                      ),

                      // --- App Title ---
                      Text(
                        "Bike Bible",
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
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
                      SizedBox(
                        height: isDesktop
                            ? 24
                            : isTablet
                            ? 20
                            : 16,
                      ),

                      // Subtitle with better styling
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop
                              ? 60
                              : isTablet
                              ? 40
                              : 24,
                        ),
                        child: Text(
                          "Secure your vehicle information with cutting-edge protection and seamless access",
                          style: TextStyle(
                            fontSize: subtitleFontSize,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.6,
                            fontWeight: FontWeight.w300,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Feature highlights
                      if (isDesktop) _buildFeatureHighlights(primaryColor),

                      const Spacer(flex: 1),

                      // --- Login & Register Buttons ---
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: paddingHorizontal,
                        ),
                        child: Column(
                          children: [
                            // Login Button
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColorDark.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginPage(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    vertical: buttonVerticalPadding,
                                  ),
                                  backgroundColor: Colors.white,
                                  foregroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.login, size: buttonFontSize + 4),
                                    SizedBox(width: 12),
                                    Text(
                                      "Login to Your Account",
                                      style: TextStyle(
                                        fontSize: buttonFontSize,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              height: isDesktop
                                  ? 20
                                  : isTablet
                                  ? 16
                                  : 12,
                            ),

                            // Register Button
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RegisterPage(),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    vertical: buttonVerticalPadding,
                                  ),
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  backgroundColor: Colors.transparent,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_add,
                                      size: buttonFontSize + 4,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      "Create New Account",
                                      style: TextStyle(
                                        fontSize: buttonFontSize,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(flex: 2),

                      // --- Footer Links ---
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(
                          isDesktop
                              ? 32
                              : isTablet
                              ? 24
                              : 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () => _openLink(
                                "https://bikebible.ca/privacy-policy",
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white70,
                              ),
                              child: Text(
                                "Privacy Policy",
                                style: TextStyle(
                                  fontSize: isDesktop ? 16 : 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              width: 6,
                              height: 6,
                              margin: EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _openLink(
                                "https://bikebible.ca/terms-and-conditions",
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white70,
                              ),
                              child: Text(
                                "Terms & Conditions",
                                style: TextStyle(
                                  fontSize: isDesktop ? 16 : 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureHighlights(Color primaryColor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFeatureItem(Icons.security, "Secure Storage", primaryColor),
          _buildFeatureItem(Icons.speed, "Fast Access", primaryColor),
          _buildFeatureItem(
            Icons.phone_iphone,
            "Mobile Friendly",
            primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, Color primaryColor) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
