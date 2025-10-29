import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_application_1/chatpage.dart';
import 'package:flutter_application_1/new_chat_page_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class FileUploadPage extends StatefulWidget {
  final String category;
  final String userId;
  final ApiService api;

  const FileUploadPage({
    super.key,
    required this.category,
    required this.userId,
    required this.api,
  });

  @override
  State<FileUploadPage> createState() => _FileUploadPageState();
}

class _FileUploadPageState extends State<FileUploadPage> {
  File? selectedFile;
  bool isUploading = false;

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'pdf', 'docx', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> uploadFile() async {
    if (selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً ابتدا یک فایل انتخاب کنید')),
      );
      return;
    }

    setState(() => isUploading = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${widget.api.baseUrl}/upload_json'),
      );

      request.fields['user_id'] = widget.userId;
      request.fields['category'] = widget.category;
      request.files.add(
        await http.MultipartFile.fromPath('file', selectedFile!.path),
      );

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final data = jsonDecode(respStr);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('setup_complete', true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'فایل با موفقیت آپلود شد')),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ChatPage()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'خطا در آپلود فایل')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  Future<void> skipUpload() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_complete', true);

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const ChatPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('آپلود فایل'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: skipUpload,
            child: const Text(
              'رد شدن',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // آیکون
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    size: 80,
                    color: Colors.green.shade700,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // عنوان
              const Text(
                'آپلود فایل',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              const Text(
                'فایل خود را برای شروع چت آپلود کنید',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // کارت فایل انتخاب شده
              if (selectedFile != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.insert_drive_file,
                        color: Colors.green.shade700,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'فایل انتخاب شده:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedFile!.path.split('/').last,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() => selectedFile = null);
                        },
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // دکمه انتخاب فایل
              OutlinedButton.icon(
                onPressed: pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(
                  selectedFile == null ? 'انتخاب فایل' : 'تغییر فایل',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // راهنما
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'فرمت‌های مجاز: JSON, PDF, DOCX, TXT',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // دکمه آپلود
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isUploading ? null : uploadFile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'آپلود و ادامه',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}