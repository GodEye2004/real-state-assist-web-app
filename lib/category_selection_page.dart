import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'file_upload_page.dart';
import 'api_service.dart';

class CategorySelectionPage extends StatefulWidget {
  const CategorySelectionPage({super.key});

  @override
  State<CategorySelectionPage> createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {
  String? selectedCategory;
  bool isLoading = false;
  late String userId;
  late ApiService api;

  @override
  void initState() {
    super.initState();
    initUserId();
  }

  Future<void> initUserId() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id') ?? const Uuid().v4();
    await prefs.setString('user_id', userId);
    api = ApiService(userId: userId);
    setState(() {});
  }

  Future<void> selectAndContinue() async {
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً یک دسته‌بندی انتخاب کنید')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final msg = await api.selectCategory(selectedCategory!);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_category', selectedCategory!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FileUploadPage(
            category: selectedCategory!,
            userId: userId,
            api: api,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('انتخاب دسته‌بندی'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // عنوان
               Text(
                'دسته‌بندی خود را انتخاب کنید',
                style: GoogleFonts.vazirmatn(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              Text(
                'لطفاً نوع اسناد خود را مشخص کنید',
                style: GoogleFonts.vazirmatn(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // کارت قرارداد
              CategoryCard(
                title: 'قرارداد',
                description: 'برای اسناد و قراردادهای حقوقی',
                icon: Icons.description,
                isSelected: selectedCategory == 'contract',
                onTap: () {
                  setState(() => selectedCategory = 'contract');
                },
              ),

              const SizedBox(height: 20),

              // کارت فروشگاه لباس
              CategoryCard(
                title: 'فروشگاه لباس',
                description: 'برای کاتالوگ و اطلاعات محصولات',
                icon: Icons.shopping_bag,
                isSelected: selectedCategory == 'clothing',
                onTap: () {
                  setState(() => selectedCategory = 'clothing');
                },
              ),

              const Spacer(),

              // دکمه ادامه
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : selectAndContinue,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'ادامه',
                          style: GoogleFonts.vazirmatn(fontSize: 18),
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

// ویجت کارت دسته‌بندی
class CategoryCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.vazirmatn(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.green : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.vazirmatn(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}