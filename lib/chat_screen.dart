import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": message});
      _isLoading = true;
      _controller.clear(); 
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    try {
      final response = await http.post(
        Uri.parse("https://real-state-assist-new.onrender.com/ask"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"question": message}),
      );

      if (response.statusCode == 200) {
        final answer = jsonDecode(response.body)["answer"];
        setState(() {
          _messages.add({"role": "bot", "text": answer});
        });
      } else {
        setState(() {
          _messages.add({"role": "bot", "text": "خطا در دریافت پاسخ از سرور."});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({"role": "bot", "text": "خطا در اتصال به سرور."});
      });
    }

    setState(() {
      _isLoading = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'متن کپی شد',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Vazir'),
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildMessage(Map<String, String> msg, int index) {
    final isUser = msg["role"] == "user";

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: isUser ? 60 : 16,
        right: isUser ? 16 : 60,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) _buildAvatar(isBot: true),
              if (!isUser) SizedBox(width: 8),
              Flexible(
                child: GestureDetector(
                  onLongPress: () => _copyToClipboard(msg["text"] ?? ""),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isUser
                          ? LinearGradient(
                              colors: [Colors.green.shade500, Colors.green.shade600],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isUser ? null : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(isUser ? 20 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isUser
                              ? Colors.green.withOpacity(0.3)
                              : Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                      border: isUser
                          ? null
                          : Border.all(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Text(
                      msg["text"] ?? "",
                      style: TextStyle(
                        fontSize: 15,
                        color: isUser ? Colors.white : Colors.grey.shade800,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ),
              ),
              if (isUser) SizedBox(width: 8),
              if (isUser) _buildAvatar(isBot: false),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              left: isUser ? 0 : 44,
              right: isUser ? 44 : 0,
            ),
            child: InkWell(
              onTap: () => _copyToClipboard(msg["text"] ?? ""),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.content_copy,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'کپی',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar({required bool isBot}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: isBot
            ? LinearGradient(
                colors: [Colors.grey.shade300, Colors.grey.shade400],
              )
            : LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isBot
                ? Colors.black.withOpacity(0.1)
                : Colors.green.withOpacity(0.3),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isBot ? Icons.smart_toy_rounded : Icons.person_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      margin: EdgeInsets.only(left: 60, right: 16, top: 8, bottom: 8),
      child: Row(
        children: [
          _buildAvatar(isBot: true),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: SizedBox(
              width: 50,
              height: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  3,
                  (index) => TweenAnimationBuilder(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 600),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(
                          0,
                          -4 *
                              (0.5 -
                                  (0.5 -
                                          ((value +
                                                      index * 0.33) %
                                                  1.0 -
                                              0.5)
                                              .abs())
                                      .abs()),
                        ),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.green.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                    onEnd: () {
                      setState(() {});
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _controller,
                  textDirection: TextDirection.rtl,
                  maxLines: null,
                  style: TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: "پیام خود را بنویسید...",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (text) {
                    sendMessage(text);
                  },
                ),
              ),
            ),
            SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade500, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.send_rounded, color: Colors.white, size: 22),
                onPressed: _isLoading ? null : () => sendMessage(_controller.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chat_rounded, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              "دستیار قرارداد",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade200,
                  Colors.green.shade400,
                  Colors.green.shade200,
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade100,
                                Colors.green.shade50,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 50,
                            color: Colors.green.shade400,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          "سلام! چگونه می‌توانم کمکتان کنم؟",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        SizedBox(height: 12),
                        Text(
                          "سوال خود را در مورد قراردادها بپرسید",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade500,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        SizedBox(height: 8),
                        Text(
                          "برای کپی کردن، پیام را لمس طولانی کنید",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.only(top: 16, bottom: 16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return _buildLoadingIndicator();
                      }
                      return _buildMessage(_messages[index], index);
                    },
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}