import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../login_page.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final deletePasswordController = TextEditingController();

  bool loading = true;
  bool updating = false;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchProfile() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('https://bikebible.ca/api/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          nameController.text = data['user']['name'] ?? '';
          emailController.text = data['user']['email'] ?? '';
          loading = false;
        });
      } else {
        setState(() => loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to fetch profile")));
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error fetching profile")));
    }
  }

  Future<void> updateProfile() async {
    final token = await _getToken();
    if (token == null) return;

    if (newPasswordController.text.isNotEmpty &&
        currentPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Please enter your current password to change it.")),
      );
      return;
    }

    setState(() => updating = true);

    final body = {
      'name': nameController.text,
      'email': emailController.text,
    };

    if (currentPasswordController.text.isNotEmpty &&
        newPasswordController.text.isNotEmpty) {
      body['current_password'] = currentPasswordController.text;
      body['password'] = newPasswordController.text;
      body['password_confirmation'] = newPasswordController.text;
    }

    try {
      final response = await http.patch(
        Uri.parse('https://bikebible.ca/api/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      );

      setState(() => updating = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile updated successfully")),
        );
        currentPasswordController.clear();
        newPasswordController.clear();
      } else {
        String errorMsg = "Failed to update profile";
        final data = json.decode(response.body);
        if (data['message'] != null) errorMsg = data['message'];
        if (data['errors'] != null) {
          errorMsg = data['errors'].values.expand((e) => e).join("\n");
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    } catch (e) {
      setState(() => updating = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error updating profile")));
    }
  }

  Future<void> deleteAccount(String password) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('https://bikebible.ca/api/profile/delete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'password': password}),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
          (route) => false,
        );
      } else {
        String errorMsg = "Failed to delete account";
        final data = json.decode(response.body);
        if (data['message'] != null) errorMsg = data['message'];
        if (data['errors'] != null) {
          errorMsg = data['errors'].values.expand((e) => e).join("\n");
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error deleting account")));
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirm Delete"),
        content: TextField(
          controller: deletePasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: "Enter Password",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteAccount(deletePasswordController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : Center(
              child: Container(
                width: isTablet ? 600 : double.infinity,
                padding: EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: _inputDecoration("Name"),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        decoration: _inputDecoration("Email"),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: currentPasswordController,
                        obscureText: true,
                        decoration: _inputDecoration("Current Password"),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: newPasswordController,
                        obscureText: true,
                        decoration:
                            _inputDecoration("New Password (optional)"),
                      ),
                      SizedBox(height: 24),
                      updating
                          ? CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: updateProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF24455E),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      vertical: 16),
                                ),
                                child: Text(
                                  "Update Profile",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              ),
                            ),
                      SizedBox(height: 24),
                      Divider(),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _showDeleteDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            "Delete Account",
                            style: TextStyle(
                                color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
