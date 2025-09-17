import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "https://test.ajitgurung.ca/api";

  // Get auth token from SharedPreferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Helper GET request with token
  static Future<http.Response> get(String endpoint) async {
    final token = await getToken();
    return http.get(
      Uri.parse("$baseUrl/$endpoint"),
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    );
  }

  // Get makes
  static Future<Map<String, dynamic>> getMakes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final response = await http.get(
      Uri.parse("$baseUrl/makes"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to fetch makes");
    }
  }

  // Get models for a make
 static Future<Map<String, dynamic>> getModels(int makeId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final response = await http.get(
      Uri.parse("$baseUrl/models/$makeId"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to fetch models");
    }
  }

  // Get years for a model
static Future<Map<String, dynamic>> getYears(int modelId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final response = await http.get(
      Uri.parse("$baseUrl/years/$modelId"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to fetch years");
    }
  }

  // Get vehicle info for a year
 static Future<Map<String, dynamic>> getInfo(int yearId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final response = await http.get(
      Uri.parse("$baseUrl/infos/$yearId"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to fetch info");
    }
  }

 static Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final res = await http.get(
      Uri.parse("$baseUrl/subscription-status"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // IMPORTANT
      },
    );

    print("Subscription API response: ${res.body}"); // debug

    if (res.statusCode == 200) {
      return json.decode(res.body);
    }
    throw Exception("Failed to load subscription status: ${res.statusCode}");
  }
}
