import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/message_provider.dart';
import '../../models/message_models.dart';
import '../../utils/datetime_utils.dart';

class ChatScreen extends StatefulWidget {
  final String friendUsername;
  final String? friendInitials;

  const ChatScreen({
    Key? key,
    required this.friendUsername,
    this.friendInitials,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    
    // Load lịch sử chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MessageProvider>();
      provider.loadChatHistory(widget.friendUsername);
      provider.startMessagePolling(widget.friendUsername);
    });

    // Lắng nghe scroll để load thêm tin nhắn cũ
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    context.read<MessageProvider>().stopMessagePolling();
    super.dispose();
  }

  void _onScroll() {
    // Nếu scroll đến đầu danh sách (tin nhắn cũ nhất)
    if (_scrollController.position.pixels <= 100 && !_isLoadingMore) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    final provider = context.read<MessageProvider>();
    
    if (provider.currentChatHistory?.hasMore == true) {
      setState(() {
        _isLoadingMore = true;
      });
      
      await provider.loadMoreMessages();
      
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    
    if (content.isEmpty) return;

    final provider = context.read<MessageProvider>();
    
    // Clear input ngay lập tức
    _messageController.clear();
    
    // Gửi tin nhắn
    final success = await provider.sendMessage(widget.friendUsername, content);
    
    if (success) {
      // Scroll xuống cuối sau khi gửi
      _scrollToBottom();
    } else {
      // Hiển thị lỗi nếu có
      if (provider.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        provider.clearError();
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  String _formatMessageTime(DateTime dateTime) {
    // Sử dụng DateTimeUtils để tự động convert UTC -> Local và format
    return DateTimeUtils.formatMessageTime(dateTime);
  }

  Widget _buildMessageBubble(MessageDto message) {
    final isMe = message.isMine;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 60 : 8,
          right: isMe ? 8 : 60,
          top: 4,
          bottom: 4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue.shade600 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.senderUsername,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            Text(
              message.content,
              style: TextStyle(
                fontSize: 16,
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatMessageTime(message.sentAt),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          // Sử dụng DateTimeUtils để format date separator
          DateTimeUtils.formatDateSeparator(date),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMessageListWithSeparators(List<MessageDto> messages) {
    List<Widget> widgets = [];
    DateTime? lastDate;

    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final messageDate = message.sentAt;

      // Thêm separator nếu ngày khác với tin nhắn trước
      if (lastDate == null || !DateTimeUtils.isSameDay(lastDate, messageDate)) {
        widgets.add(_buildDateSeparator(messageDate));
        lastDate = messageDate;
      }

      widgets.add(_buildMessageBubble(message));
    }

    return widgets;
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      backgroundColor: Colors.white,
      child: Text(
        widget.friendInitials ?? widget.friendUsername.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: Colors.blue.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Text(widget.friendUsername),
          ],
        ),
      ),
      body: Column(
        children: [
          // Danh sách tin nhắn
          Expanded(
            child: Consumer<MessageProvider>(
              builder: (context, messageProvider, child) {
                if (messageProvider.isLoading && messageProvider.currentMessages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (messageProvider.currentMessages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chat_outlined,
                              size: 60,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Bắt đầu cuộc trò chuyện',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Đây là lần đầu tiên bạn nhắn tin với ${widget.friendUsername}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hãy gửi lời chào đầu tiên! 👋',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Stack(
                  children: [
                    ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      children: _buildMessageListWithSeparators(
                        messageProvider.currentMessages,
                      ),
                    ),
                    if (_isLoadingMore)
                      Positioned(
                        top: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          
          // Input area
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer<MessageProvider>(
                    builder: (context, messageProvider, child) {
                      return FloatingActionButton(
                        onPressed: messageProvider.isSending ? null : _sendMessage,
                        backgroundColor: Colors.blue.shade700,
                        mini: true,
                        child: messageProvider.isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.send,
                                color: Colors.white,
                              ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

