import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ApiService {
  final String baseUrl = "http://192.168.100.244:8000";
  late String userId;
  bool _initialized = false;

  ApiService({required String userId});

  // --------- مقداردهی userId داینامیک ----------
  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id') ?? const Uuid().v4();
    await prefs.setString('user_id', userId);
    _initialized = true;
  }

  // --------- انتخاب کتگوری ----------
  Future<String> selectCategory(String category) async {
    await init();
    final response = await http.post(
      Uri.parse('$baseUrl/select_category'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "category": category}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["message"];
    } else {
      throw Exception("خطا در انتخاب کتگوری");
    }
  }

  // --------- آپلود دیتا ----------
  Future<String> uploadData(Map<String, dynamic> jsonData) async {
    await init();
    final response = await http.post(
      Uri.parse('$baseUrl/upload_data'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "data": jsonData}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["message"];
    } else {
      throw Exception("خطا در آپلود فایل JSON");
    }
  }

  // --------- پرسش سؤال ----------
  Future<String> askQuestion(String question) async {
    await init();
    final response = await http.post(
      Uri.parse('$baseUrl/ask'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "question": question}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["answer"];
    } else {
      throw Exception("خطا در دریافت پاسخ");
    }
  }
}
