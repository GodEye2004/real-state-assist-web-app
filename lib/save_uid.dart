import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> getUserId() async {
  final prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('user_id');

  if (userId == null) {
    userId = const Uuid().v4(); // تولید UUID جدید
    await prefs.setString('user_id', userId);
  }

  return userId;
}
