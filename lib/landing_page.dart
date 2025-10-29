import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'category_selection_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade400, Colors.green.shade700],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // آیکون اصلی
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.smart_toy_outlined,
                  size: 80,
                  color: Colors.green.shade700,
                ),
              ),

              const SizedBox(height: 40),

              // عنوان
              Text(
                'به چت میت خوش آمدید',
                style: GoogleFonts.vazirmatn(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // توضیحات
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'با ترکیب دانش تخصصی کسب‌ و کارت و قدرت هوش مصنوعی، هوشمندتر از همیشه عمل کن',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(),

              // دکمه شروع
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategorySelectionPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      'شروع کنید',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
