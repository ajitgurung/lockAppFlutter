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

    final response = await http.get(
      Uri.parse('https://test.ajitgurung.ca/api/profile'),
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

    final response = await http.patch(
      Uri.parse('https://test.ajitgurung.ca/api/profile'),
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
      try {
        final data = json.decode(response.body);
        if (data['message'] != null) errorMsg = data['message'];
        if (data['errors'] != null) {
          errorMsg =
              data['errors'].values.expand((e) => e).join("\n");
        }
      } catch (_) {}
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMsg)));
    }
  }

  Future<void> deleteAccount(String password) async {
    final token = await _getToken();
    if (token == null) return;

    final response = await http.post(
  Uri.parse('https://test.ajitgurung.ca/api/profile/delete'),
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
      try {
        final data = json.decode(response.body);
        if (data['message'] != null) errorMsg = data['message'];
        if (data['errors'] != null) {
          errorMsg = data['errors'].values.expand((e) => e).join("\n");
        }
      } catch (_) {}
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMsg)));
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
          decoration: InputDecoration(labelText: "Enter Password"),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: currentPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Current Password",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "New Password (optional)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  updating
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: updateProfile,
                          child: Text("Update Profile"),
                        ),
                  SizedBox(height: 20),
                  Divider(),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _showDeleteDialog,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red),
                    child: Text("Delete Account"),
                  ),
                ],
              ),
            ),
    );
  }
}
