import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../login_page.dart';
import 'subscription_info.dart';
import 'settings_screen.dart';

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
    try {
      final prefs = await SharedPreferences.getInstance();
      final isSubscribed = prefs.getBool("subscribed") ?? false;

      setState(() {
        subscribed = isSubscribed;
        checkingSubscription = false;
      });

      if (isSubscribed) {
        fetchMakes();
      }
    } catch (e) {
      print("Subscription check error: $e");
      setState(() {
        subscribed = false;
        checkingSubscription = false;
      });
    }
  }

  Future<void> fetchMakes() async {
    setState(() => loadingMakes = true);
    try {
      final response = await ApiService.getMakes();
      makes = List<Map<String, dynamic>>.from(response['makes']);
      setState(() => loadingMakes = false);
    } catch (e) {
      print("Error fetching makes: $e");
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
      models = List<Map<String, dynamic>>.from(response['models']);
      setState(() => loadingModels = false);
    } catch (e) {
      print("Error fetching models: $e");
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
      years = List<Map<String, dynamic>>.from(response['years']);
      setState(() => loadingYears = false);
    } catch (e) {
      print("Error fetching years: $e");
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
      info = Map<String, dynamic>.from(response);
      setState(() => loadingInfo = false);
    } catch (e) {
      print("Error fetching info: $e");
      setState(() => loadingInfo = false);
    }
  }

  Widget buildInfoSection() {
    if (loadingInfo) return Center(child: CircularProgressIndicator());
    if (info == null || info!['sections'] == null || info!['sections'].isEmpty) {
      return Center(
        child: Text(
          "No information available.",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
      );
    }

    List<Widget> sections = [];

    info!['sections'].forEach((sectionTitle, items) {
      final mapItems = Map<String, dynamic>.from(items);
      sections.add(
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sectionTitle.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700, fontSize: 16),
                ),
                SizedBox(height: 8),
                ...mapItems.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            e.key.replaceAll('_', ' '),
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: Text(e.value.toString()),
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

    if (info!['image_url'] != null) {
      sections.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(info!['image_url']),
          ),
        ),
      );
    }

    if (info!['video'] != null) {
      sections.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Video available: ${info!['video']}",
              style: TextStyle(color: Colors.blue.shade800),
            ),
          ),
        ),
      );
    }

    return Column(children: sections);
  }

  Widget buildDropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        hint: Text(hint),
        onChanged: isLoading ? null : onChanged,
        decoration: InputDecoration(border: InputBorder.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
  backgroundColor: Colors.blue.shade700,
  actions: [
    IconButton(
      icon: Icon(Icons.settings, color: Colors.white),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SettingsScreen()),
        );
      },
    ),
    IconButton(
      icon: Icon(Icons.info, color: Colors.white),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SubscriptionInfoScreen()),
        );
      },
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
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: subscribed
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildDropdown<int>(
                      hint: "Choose Make",
                      value: selectedMake,
                      items: makes
                          .map<DropdownMenuItem<int>>((m) => DropdownMenuItem<int>(
                                value: int.tryParse(m['id'].toString()),
                                child: Text(m['name'].toString()),
                              ))
                          .where((e) => e.value != null)
                          .cast<DropdownMenuItem<int>>()
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedMake = val;
                          if (val != null) fetchModels(val);
                        });
                      },
                      isLoading: loadingMakes,
                    ),
                    SizedBox(height: 12),
                    buildDropdown<int>(
                      hint: "Choose Model",
                      value: selectedModel,
                      items: models
                          .map<DropdownMenuItem<int>>((m) => DropdownMenuItem<int>(
                                value: int.tryParse(m['id'].toString()),
                                child: Text(m['name'].toString()),
                              ))
                          .where((e) => e.value != null)
                          .cast<DropdownMenuItem<int>>()
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedModel = val;
                          if (val != null) fetchYears(val);
                        });
                      },
                      isLoading: loadingModels,
                    ),
                    SizedBox(height: 12),
                    buildDropdown<int>(
                      hint: "Choose Year",
                      value: selectedYear,
                      items: years
                          .map<DropdownMenuItem<int>>((y) => DropdownMenuItem<int>(
                                value: int.tryParse(y['id'].toString()),
                                child: Text(y['year'].toString()),
                              ))
                          .where((e) => e.value != null)
                          .cast<DropdownMenuItem<int>>()
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedYear = val;
                          if (val != null) fetchInfo(val);
                        });
                      },
                      isLoading: loadingYears,
                    ),
                    SizedBox(height: 20),
                    buildInfoSection(),
                  ],
                ),
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    "No active subscription.\nPlease use our website to manage your account.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
      ),
    );
  }
}
