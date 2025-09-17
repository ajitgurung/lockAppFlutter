import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../login_page.dart';
import 'subscription_info.dart';

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
      return Text("No information available.");
    }

    List<Widget> sections = [];

    info!['sections'].forEach((sectionTitle, items) {
      final mapItems = Map<String, dynamic>.from(items);
      sections.add(
        Card(
          margin: EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sectionTitle.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                SizedBox(height: 8),
                ...mapItems.entries.map(
                  (e) => Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          e.key.replaceAll('_', ' '),
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(flex: 5, child: Text(e.value.toString())),
                    ],
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
          child: Image.network(info!['image_url']),
        ),
      );
    }

    if (info!['video'] != null) {
      sections.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text("Video available: ${info!['video']}"),
        ),
      );
    }

    return Column(children: sections);
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
        title: Text("Vehicle Info"),
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SubscriptionInfoScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdowns + info are now scrollable together
            DropdownButtonFormField<int>(
              value: selectedMake,
              items: makes.map<DropdownMenuItem<int>>((m) {
                return DropdownMenuItem<int>(
                  value: int.tryParse(m['id'].toString()),
                  child: Text(m['name'].toString()),
                );
              }).where((e) => e.value != null).cast<DropdownMenuItem<int>>().toList(),
              hint: Text("Choose Make"),
              onChanged: (val) {
                setState(() {
                  selectedMake = val;
                  if (val != null) fetchModels(val);
                });
              },
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: selectedModel,
              items: models.map<DropdownMenuItem<int>>((m) {
                return DropdownMenuItem<int>(
                  value: int.tryParse(m['id'].toString()),
                  child: Text(m['name'].toString()),
                );
              }).where((e) => e.value != null).cast<DropdownMenuItem<int>>().toList(),
              hint: Text("Choose Model"),
              onChanged: loadingModels
                  ? null
                  : (val) {
                      setState(() {
                        selectedModel = val;
                        if (val != null) fetchYears(val);
                      });
                    },
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: selectedYear,
              items: years.map<DropdownMenuItem<int>>((y) {
                return DropdownMenuItem<int>(
                  value: int.tryParse(y['id'].toString()),
                  child: Text(y['year'].toString()),
                );
              }).where((e) => e.value != null).cast<DropdownMenuItem<int>>().toList(),
              hint: Text("Choose Year"),
              onChanged: loadingYears
                  ? null
                  : (val) {
                      setState(() {
                        selectedYear = val;
                        if (val != null) fetchInfo(val);
                      });
                    },
            ),
            SizedBox(height: 20),
            buildInfoSection(),
          ],
        ),
      ),
    );
  }
}
