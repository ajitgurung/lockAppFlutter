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

  @override
  void initState() {
    super.initState();
    checkSubscription();
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

  String fixUrl(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'https://$url';
    }
    return url;
  }

  Widget buildInfoSection(double width) {
    if (loadingInfo) return Center(child: CircularProgressIndicator());

    if (info == null || info!['sections'] == null || info!['sections'].isEmpty) {
      return Center(
        child: Text(
          "No information available.",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
      );
    }

    final List<Widget> items = [];

    info!['sections'].forEach((sectionTitle, itemsMap) {
      final mapItems = Map<String, dynamic>.from(itemsMap);
      items.add(
        Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sectionTitle.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    fontSize: width > 600 ? 18 : 16, // larger font on tablets
                  ),
                ),
                SizedBox(height: 6),
                ...mapItems.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            e.key.replaceAll('_', ' '),
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: width > 600 ? 16 : 14,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: Text(
                            e.value.toString(),
                            style: TextStyle(fontSize: width > 600 ? 16 : 14),
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
    });

    if (info!['product'] != null && info!['product'].toString().isNotEmpty) {
      final productUrl = fixUrl(info!['product'].toString());
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: ElevatedButton.icon(
            icon: Icon(Icons.link),
            label: Text("View Product"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () async {
              final uri = Uri.parse(productUrl);
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Could not open product link.")),
                );
              }
            },
          ),
        ),
      );
    }

    if (info!['image_url'] != null) {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: info!['image_url'],
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) =>
                  Center(child: Icon(Icons.broken_image, size: 40)),
            ),
          ),
        ),
      );
    }

    if (info!['playback_id'] != null && info!['playback_token'] != null) {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: ElevatedButton.icon(
            icon: Icon(Icons.play_arrow),
            label: Text("Play Video"),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: MuxVideoPlayer(
                      playbackId: info!['playback_id'],
                      token: info!['playback_token'],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;

    if (checkingSubscription) {
      return Scaffold(
        appBar: AppBar(title: Text("Vehicle Info")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Vehicle Info", style: TextStyle(color: Colors.white70)),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SettingsScreen()),
            ),
          ),
          IconButton(
            icon: Icon(Icons.info, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SubscriptionInfoScreen()),
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
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
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Colors.blue.shade50
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: subscribed
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomDropdown<int>(
                      hint: "Choose Make",
                      value: selectedMake,
                      items: makes
                          .map((m) => DropdownMenuItem<int>(
                                value: int.tryParse(m['id'].toString()),
                                child: Text(m['name'].toString(),
                                    style: TextStyle(
                                        fontSize: isTablet ? 18 : 14)),
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
                    CustomDropdown<int>(
                      hint: "Choose Model",
                      value: selectedModel,
                      items: models
                          .map((m) => DropdownMenuItem<int>(
                                value: int.tryParse(m['id'].toString()),
                                child: Text(m['name'].toString(),
                                    style: TextStyle(
                                        fontSize: isTablet ? 18 : 14)),
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
                    CustomDropdown<int>(
                      hint: "Choose Year",
                      value: selectedYear,
                      items: years
                          .map((y) => DropdownMenuItem<int>(
                                value: int.tryParse(y['id'].toString()),
                                child: Text(y['year'].toString(),
                                    style: TextStyle(
                                        fontSize: isTablet ? 18 : 14)),
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
                    SizedBox(height: isTablet ? 30 : 20),
                    buildInfoSection(width),
                  ],
                ),
              )
            : Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 48 : 24),
                  child: Text(
                    "No active subscription.\nPlease use our website to manage your account.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 16,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
