// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:uuid/uuid.dart';
// import 'api_service.dart';

// class ChatPage extends StatefulWidget {
//   const ChatPage({super.key});

//   @override
//   State<ChatPage> createState() => _ChatPageState();
// }

// class _ChatPageState extends State<ChatPage> {
//   late ApiService api;
//   late String userId;
//   String selectedCategory = "contract";
//   String answer = "";
//   bool loading = false;

//   File? selectedFile;
//   final TextEditingController _questionController = TextEditingController();

//   // ---------------- Init UserId & ApiService ----------------
//   @override
//   void initState() {
//     super.initState();
//     initUserId();
//   }

//   Future<void> initUserId() async {
//     final prefs = await SharedPreferences.getInstance();
//     userId = prefs.getString('user_id') ?? const Uuid().v4();
//     await prefs.setString('user_id', userId);

//     api = ApiService(userId: userId); // ApiService با userId داینامیک
//     setState(() {});
//   }

//   // ---------------- Pick & Upload File ----------------
//   Future<void> pickAndUploadFile() async {
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['json', 'pdf', 'docx', 'txt'],
//     );

//     if (result != null && result.files.single.path != null) {
//       final file = File(result.files.single.path!);
//       setState(() => selectedFile = file);

//       final request = http.MultipartRequest(
//         'POST',
//         Uri.parse('${api.baseUrl}/upload_json'),
//       );

//       request.fields['user_id'] = userId;
//       request.fields['category'] = selectedCategory;
//       request.files.add(await http.MultipartFile.fromPath('file', file.path));

//       final response = await request.send();
//       final respStr = await response.stream.bytesToString();
//       final data = jsonDecode(respStr);

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(data['message'] ?? data['error'])),
//       );
//     }
//   }

//   // ---------------- Ask Question ----------------
//   Future<void> ask() async {
//     if (_questionController.text.isEmpty) return;
//     setState(() => loading = true);

//     final res = await api.askQuestion(_questionController.text);
//     setState(() {
//       answer = res;
//       loading = false;
//     });
//   }

//   // ---------------- Select Category ----------------
//   Future<void> setupCategory() async {
//     final msg = await api.selectCategory(selectedCategory);
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//   }

//   // ---------------- Build UI ----------------
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("دستیار هوشمند")),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             DropdownButton<String>(
//               value: selectedCategory,
//               items: const [
//                 DropdownMenuItem(value: "contract", child: Text("قرارداد")),
//                 DropdownMenuItem(value: "clothing", child: Text("فروشگاه لباس")),
//               ],
//               onChanged: (value) {
//                 if (value != null) setState(() => selectedCategory = value);
//               },
//             ),
//             ElevatedButton(
//               onPressed: setupCategory,
//               child: const Text("انتخاب کتگوری"),
//             ),
//             const SizedBox(height: 20),

//             // ---------------- Pick & Upload File ----------------
//             ElevatedButton.icon(
//               onPressed: pickAndUploadFile,
//               icon: const Icon(Icons.attach_file),
//               label: const Text("انتخاب فایل (JSON, PDF, DOCX, TXT)"),
//             ),
//             if (selectedFile != null) ...[
//               const SizedBox(height: 10),
//               Text(
//                 "فایل انتخاب شده: ${selectedFile!.path.split('/').last}",
//                 style: const TextStyle(fontSize: 14),
//               ),
//               const SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: pickAndUploadFile,
//                 child: const Text("ارسال فایل"),
//               ),
//             ],

//             const SizedBox(height: 20),

//             // ---------------- Question Input ----------------
//             TextField(
//               controller: _questionController,
//               decoration: const InputDecoration(
//                 labelText: "سؤال خود را بنویسید...",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: loading ? null : ask,
//               child: loading
//                   ? const CircularProgressIndicator()
//                   : const Text("بپرس"),
//             ),

//             const SizedBox(height: 20),
//             if (answer.isNotEmpty)
//               Text(
//                 "پاسخ: $answer",
//                 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
