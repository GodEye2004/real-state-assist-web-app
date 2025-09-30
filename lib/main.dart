import 'package:flutter/material.dart';
import 'chat_screen.dart';

void main() {
  runApp(RealEstateChatbotApp());
}

class RealEstateChatbotApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'contract assist',
      theme: ThemeData(
        fontFamily: 'Vazir', 
        primarySwatch: Colors.indigo,
      ),
      home: ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}