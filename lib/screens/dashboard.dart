import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../login_page.dart';
import 'subscription_info.dart';
import 'settings_screen.dart';
import 'mux_video_player.dart';
import 'custom_dropdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> makes = [];
  List<Map<String, dynamic>> models = [];
  List<Map<String, dynamic>> years = [];

  int? selectedMake;
  int? selectedModel;
  int? selectedYear;

  Map<String, dynamic>? info;

  bool loadingMakes = true;
  bool loadingModels = false;
  bool loadingYears = false;
  bool loadingInfo = false;
  bool checkingSubscription = true;
  bool subscribed = false;

  // Suggestion box variables
  final TextEditingController _suggestionController = TextEditingController();
  bool _isSubmittingSuggestion = false;
  bool _showSuggestionBox = false;

  @override
  void initState() {
    super.initState();
    checkSubscription();
  }

  @override
  void dispose() {
    _suggestionController.dispose();
    super.dispose();
  }

  Future<void> checkSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final isSubscribed = prefs.getBool("subscribed") ?? false;

    setState(() {
      subscribed = isSubscribed;
      checkingSubscription = false;
    });

    if (isSubscribed) fetchMakes();
  }

  Future<void> fetchMakes() async {
    setState(() => loadingMakes = true);
    try {
      final response = await ApiService.getMakes();
      final newMakes = List<Map<String, dynamic>>.from(response['makes']);
      setState(() {
        makes = newMakes;
        loadingMakes = false;
      });
    } catch (e) {
      setState(() => loadingMakes = false);
    }
  }

  Future<void> fetchModels(int makeId) async {
    setState(() {
      loadingModels = true;
      models = [];
      selectedModel = null;
      years = [];
      selectedYear = null;
      info = null;
    });

    try {
      final response = await ApiService.getModels(makeId);
      final newModels = List<Map<String, dynamic>>.from(response['models']);
      setState(() {
        models = newModels;
        loadingModels = false;
      });
    } catch (e) {
      setState(() => loadingModels = false);
    }
  }

  Future<void> fetchYears(int modelId) async {
    setState(() {
      loadingYears = true;
      years = [];
      selectedYear = null;
      info = null;
    });

    try {
      final response = await ApiService.getYears(modelId);
      final newYears = List<Map<String, dynamic>>.from(response['years']);
      setState(() {
        years = newYears;
        loadingYears = false;
      });
    } catch (e) {
      setState(() => loadingYears = false);
    }
  }

  Future<void> fetchInfo(int yearId) async {
    setState(() {
      loadingInfo = true;
      info = null;
    });

    try {
      final response = await ApiService.getInfo(yearId);
      setState(() {
        info = Map<String, dynamic>.from(response);
        loadingInfo = false;
      });
    } catch (e) {
      setState(() => loadingInfo = false);
    }
  }

  Future<void> _submitSuggestion() async {
    if (_suggestionController.text.trim().isEmpty || selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select a vehicle year and enter your suggestion"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingSuggestion = true;
    });

    try {
      final response = await ApiService.submitSuggestion(
        yearId: selectedYear!,
        message: _suggestionController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? "Suggestion submitted successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      _suggestionController.clear();
      setState(() {
        _showSuggestionBox = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to submit suggestion. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmittingSuggestion = false;
      });
    }
  }

  String fixUrl(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'https://$url';
    }
    return url;
  }

  Widget buildInfoSection(double width) {
    if (loadingInfo) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            SizedBox(height: 16),
            Text(
              "Loading vehicle information...",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: width > 600 ? 18 : 14,
              ),
            ),
          ],
        ),
      );
    }

    if (info == null || info!['sections'] == null || info!['sections'].isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.car_repair,
              size: 64,
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              "No information available for this selection",
              style: TextStyle(
                color: Colors.white,
                fontSize: width > 600 ? 18 : 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final List<Widget> items = [];

    info!['sections'].forEach((sectionTitle, itemsMap) {
      if (itemsMap is Map<String, dynamic> && itemsMap.isNotEmpty) {
        final mapItems = Map<String, dynamic>.from(itemsMap);
        items.add(
          Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      sectionTitle.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).scaffoldBackgroundColor,
                        fontSize: width > 600 ? 16 : 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  ...mapItems.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  e.key.replaceAll('_', ' '),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: width > 600 ? 16 : 14,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 6,
                                child: Text(
                                  e.value.toString(),
                                  style: TextStyle(
                                    fontSize: width > 600 ? 16 : 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
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
    });

    if (info!['product'] != null && info!['product'].toString().isNotEmpty) {
      final productUrl = fixUrl(info!['product'].toString());
      items.add(
        Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ElevatedButton.icon(
            icon: Icon(Icons.shopping_cart_rounded, size: 20),
            label: Text(
              "View Product Details",
              style: TextStyle(fontSize: width > 600 ? 16 : 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: Colors.black26,
            ),
            onPressed: () async {
              final uri = Uri.parse(productUrl);
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Could not open product link."),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ),
      );
    }

    if (info!['image_url'] != null) {
      items.add(
        Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: info!['image_url'],
              fit: BoxFit.cover,
              width: double.infinity,
              height: width > 600 ? 300 : 200,
              placeholder: (context, url) => Container(
                height: width > 600 ? 300 : 200,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: width > 600 ? 300 : 200,
                color: Colors.grey.shade200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 48, color: Colors.grey.shade400),
                    SizedBox(height: 8),
                    Text(
                      "Image not available",
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (info!['playback_id'] != null && info!['playback_token'] != null) {
      items.add(
        Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ElevatedButton.icon(
            icon: Icon(Icons.play_circle_fill_rounded, size: 20),
            label: Text(
              "Watch Video Guide",
              style: TextStyle(fontSize: width > 600 ? 16 : 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: Colors.black26,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: EdgeInsets.all(20),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: MuxVideoPlayer(
                        playbackId: info!['playback_id'],
                        token: info!['playback_token'],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) => items[index],
        ),
        
        // Suggestion Box - Now positioned right after the info content
        if (info != null && !loadingInfo) _buildSuggestionBox(width),
      ],
    );
  }

  Widget _buildSuggestionBox(double width) {
    final isTablet = width > 600;
    
    return Container(
      margin: EdgeInsets.only(top: 20),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_showSuggestionBox) ...[
            Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text(
                  "Have a suggestion?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              "Found something missing or have ideas to improve our vehicle information?",
              style: TextStyle(
                color: Colors.white70,
                fontSize: isTablet ? 16 : 14,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showSuggestionBox = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Share Your Suggestion",
                style: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Icon(Icons.edit_rounded, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text(
                  "Your Suggestion",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: _suggestionController,
              maxLines: 4,
              style: TextStyle(color: Colors.white, fontSize: isTablet ? 16 : 14),
              decoration: InputDecoration(
                hintText: "Type your suggestion here...",
                hintStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white30),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.amber),
                ),
                contentPadding: EdgeInsets.all(16),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _showSuggestionBox = false;
                        _suggestionController.clear();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white30),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(fontSize: isTablet ? 16 : 14),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmittingSuggestion ? null : _submitSuggestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmittingSuggestion
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            "Submit",
                            style: TextStyle(fontSize: isTablet ? 16 : 14),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;
    final isDesktop = width > 900;

    if (checkingSubscription) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                "Checking subscription...",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        bool? exit = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Exit App?'),
            content: Text('Do you want to exit the application?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Yes'),
              ),
            ],
          ),
        );
        return exit ?? false;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            "Vehicle Information",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: isTablet ? 22 : 18,
            ),
          ),
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.settings_rounded, size: isTablet ? 28 : 24),
              color: Colors.white,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen()),
              ),
            ),
            IconButton(
              icon: Icon(Icons.info_outline_rounded, size: isTablet ? 28 : 24),
              color: Colors.white,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SubscriptionInfoScreen()),
              ),
            ),
            IconButton(
              icon: Icon(Icons.logout_rounded, size: isTablet ? 28 : 24),
              color: Colors.white,
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('access_token');
                await prefs.remove('subscribed');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage()),
                );
              },
            ),
          ],
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                Color.alphaBlend(Colors.white.withOpacity(0.1), Theme.of(context).scaffoldBackgroundColor),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: subscribed
              ? SingleChildScrollView(
                  padding: EdgeInsets.all(isTablet ? 24 : 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Selection Section
                        Container(
                          padding: EdgeInsets.all(isTablet ? 24 : 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            children: [
                              CustomDropdown<int>(
                                hint: "Choose Vehicle Make",
                                value: selectedMake,
                                items: makes
                                    .map((m) => DropdownMenuItem<int>(
                                          value: int.tryParse(m['id'].toString()),
                                          child: Text(
                                            m['name'].toString(),
                                            style: TextStyle(
                                              fontSize: isTablet ? 18 : 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ))
                                    .where((e) => e.value != null)
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedMake = val;
                                    if (val != null) fetchModels(val);
                                  });
                                },
                                isLoading: loadingMakes,
                              ),
                              SizedBox(height: 16),
                              CustomDropdown<int>(
                                hint: "Choose Model",
                                value: selectedModel,
                                items: models
                                    .map((m) => DropdownMenuItem<int>(
                                          value: int.tryParse(m['id'].toString()),
                                          child: Text(
                                            m['name'].toString(),
                                            style: TextStyle(
                                              fontSize: isTablet ? 18 : 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ))
                                    .where((e) => e.value != null)
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedModel = val;
                                    if (val != null) fetchYears(val);
                                  });
                                },
                                isLoading: loadingModels,
                              ),
                              SizedBox(height: 16),
                              CustomDropdown<int>(
                                hint: "Choose Year",
                                value: selectedYear,
                                items: years
                                    .map((y) => DropdownMenuItem<int>(
                                          value: int.tryParse(y['id'].toString()),
                                          child: Text(
                                            y['year'].toString(),
                                            style: TextStyle(
                                              fontSize: isTablet ? 18 : 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ))
                                    .where((e) => e.value != null)
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedYear = val;
                                    if (val != null) fetchInfo(val);
                                  });
                                },
                                isLoading: loadingYears,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isTablet ? 30 : 20),
                        
                        // Information Section
                        if (selectedYear != null)
                          Text(
                            "Vehicle Details",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 24 : 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        SizedBox(height: isTablet ? 20 : 16),
                        
                        // The buildInfoSection now includes the suggestion box at the end
                        buildInfoSection(width),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isTablet ? 48 : 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.credit_card_off_rounded,
                          size: 80,
                          color: Colors.white54,
                        ),
                        SizedBox(height: 24),
                        Text(
                          "No Active Subscription",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isTablet ? 24 : 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Please visit our website to manage your subscription and access vehicle information.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}