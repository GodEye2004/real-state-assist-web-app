import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'api_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late ApiService api;
  late String userId;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<ChatMessage> messages = [];
  bool isLoading = false;
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    initializeChat();
    loadMessages();

    _messageController.addListener(() {
      setState(() {});
    });
  }

  Future<void> initializeChat() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id') ?? const Uuid().v4();
    selectedCategory = prefs.getString('selected_category');

    api = ApiService(userId: userId);
    setState(() {});
  }

  Future<void> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMessages = prefs.getString('chat_messages_$userId');

    if (savedMessages != null) {
      final List<dynamic> decoded = jsonDecode(savedMessages);
      setState(() {
        messages = decoded.map((m) => ChatMessage.fromJson(m)).toList();
      });
      scrollToBottom();
    }
  }

  // ذخیره پیام‌ها
  Future<void> saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(messages.map((m) => m.toJson()).toList());
    await prefs.setString('chat_messages_$userId', encoded);
  }

  Future<void> sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      messages.add(
        ChatMessage(text: userMessage, isUser: true, timestamp: DateTime.now()),
      );
      isLoading = true;
    });

    await saveMessages();
    scrollToBottom();

    try {
      final response = await api.askQuestion(userMessage);

      setState(() {
        messages.add(
          ChatMessage(text: response, isUser: false, timestamp: DateTime.now()),
        );
        isLoading = false;
      });

      await saveMessages();
      scrollToBottom();
    } catch (e) {
      setState(() {
        messages.add(
          ChatMessage(
            text: 'متأسفانه خطایی رخ داد. لطفاً دوباره تلاش کنید.',
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ),
        );
        isLoading = false;
      });
      await saveMessages();
    }
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('پاک کردن چت'),
        content: const Text(
          'آیا مطمئن هستید که می‌خواهید تمام پیام‌ها را پاک کنید؟',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('پاک کردن'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => messages.clear());
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_messages_$userId');
    }
  }

  Future<void> resetApp() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خروح از برنامه'),
        content: const Text(
          'تمام اطلاعات شما پاک می‌شود و به صفحه اول برمی‌گردید.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('خروج'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.smart_toy_outlined,
                color: Colors.green.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'دستیار هوشمند',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (selectedCategory != null)
                  Text(
                    getCategoryName(selectedCategory!),
                    style: GoogleFonts.vazirmatn(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: clearChat,
            tooltip: 'پاک کردن چت',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'reset') resetApp();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_backup_restore,
                      color: Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text('خروج'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Divider(height: 1, color: Colors.grey.shade200),
          //main chat area
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    itemCount: messages.length + (isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && isLoading) {
                        return _buildTypingIndicator();
                      }
                      return MessageBubble(message: messages[index]);
                    },
                  ),
          ),

          Container(height: 1, color: Colors.grey.shade200),

          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'چطور می‌تونم کمکتون کنم؟',
            style: GoogleFonts.vazirmatn(
              // ← Choose your favorite font here
              color: Colors.grey.shade700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'سوال خود را بپرسید',
            style: GoogleFonts.vazirmatn(
              // ← Choose your favorite font here
              color: Colors.grey.shade700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('شرایط قرارداد چیست؟'),
                _buildSuggestionChip('جزئیات محصول را بگو'),
                _buildSuggestionChip('قیمت چقدر است؟'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _messageController.text = text;
        _focusNode.requestFocus();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.vazirmatn(
            // ← Choose your favorite font here
            color: Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy,
              color: Colors.green.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, -4 * (value * (index % 2 == 0 ? 1 : -1))),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () => setState(() {}),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        decoration: const InputDecoration(
                          hintText: '',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => sendMessage(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: _messageController.text.isEmpty
                    ? Colors.grey.shade300
                    : Colors.green,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_upward_rounded),
                color: Colors.white,
                onPressed: isLoading || _messageController.text.isEmpty
                    ? null
                    : sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getCategoryName(String category) {
    switch (category) {
      case 'contract':
        return 'قرارداد';
      case 'clothing':
        return 'فروشگاه لباس';
      default:
        return category;
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(() {}); // حذف لیستنر
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'isError': isError,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    text: json['text'],
    isUser: json['isUser'],
    timestamp: DateTime.parse(json['timestamp']),
    isError: json['isError'] ?? false,
  );
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: message.isError
                    ? Colors.red.shade100
                    : Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                message.isError ? Icons.error_outline : Icons.smart_toy,
                color: message.isError
                    ? Colors.red.shade700
                    : Colors.green.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? Colors.green
                        : (message.isError
                              ? Colors.red.shade50
                              : Colors.grey.shade100),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 20),
                    ),
                  ),
                  child: SelectableText(
                    message.text,
                    style: GoogleFonts.vazirmatn(
                      color: message.isUser
                          ? Colors.white
                          : (message.isError
                                ? Colors.red.shade900
                                : Colors.black87),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                  child: Text(
                    '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.vazirmatn(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}
