import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/message_models.dart';
import '../services/message_service.dart';

class MessageProvider extends ChangeNotifier {
  final MessageService _messageService = MessageService();

  // Danh sách cuộc hội thoại
  List<ConversationDto> _conversations = [];
  List<ConversationDto> get conversations => _conversations;

  // Lịch sử chat hiện tại
  ChatHistoryDto? _currentChatHistory;
  ChatHistoryDto? get currentChatHistory => _currentChatHistory;

  // Tin nhắn của cuộc hội thoại hiện tại
  List<MessageDto> _currentMessages = [];
  List<MessageDto> get currentMessages => _currentMessages;

  // Tên người bạn hiện tại đang chat
  String? _currentFriendUsername;
  String? get currentFriendUsername => _currentFriendUsername;

  // Trạng thái loading
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Trạng thái sending
  bool _isSending = false;
  bool get isSending => _isSending;

  // Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Timer để tự động cập nhật tin nhắn mới
  Timer? _messagePollingTimer;

  // Tải danh sách cuộc hội thoại
  Future<void> loadConversations() async {
    print('\n[MessageProvider] ===== LOAD CONVERSATIONS START =====');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _messageService.getConversations();
    
    print('[MessageProvider] Result success: ${result['success']}');

    if (result['success']) {
      _conversations = result['conversations'] as List<ConversationDto>;
      print('[MessageProvider] Loaded ${_conversations.length} conversations');
    } else {
      _errorMessage = result['message'];
      print('[MessageProvider] Error: $_errorMessage');
    }

    _isLoading = false;
    notifyListeners();
    print('[MessageProvider] ===== LOAD CONVERSATIONS END =====\n');
  }

  // Tải lịch sử chat với một người bạn
  Future<void> loadChatHistory(String friendUsername, {int lastMessageId = 0}) async {
    print('\n[MessageProvider] ===== LOAD CHAT HISTORY START =====');
    print('[MessageProvider] Friend Username: $friendUsername');
    print('[MessageProvider] Last Message ID: $lastMessageId');
    
    _isLoading = true;
    _errorMessage = null;
    _currentFriendUsername = friendUsername;
    notifyListeners();

    final result = await _messageService.getChatHistory(
      friendUsername: friendUsername,
      lastMessageId: lastMessageId,
    );

    print('[MessageProvider] Result success: ${result['success']}');

    if (result['success']) {
      _currentChatHistory = result['chatHistory'] as ChatHistoryDto;
      
      if (lastMessageId == 0) {
        // Nếu là lần đầu load, thay thế toàn bộ
        _currentMessages = _currentChatHistory!.messages;
        print('[MessageProvider] Loaded ${_currentMessages.length} messages');
      } else {
        // Nếu là load thêm (pagination), thêm vào đầu danh sách
        _currentMessages.insertAll(0, _currentChatHistory!.messages);
        print('[MessageProvider] Added ${_currentChatHistory!.messages.length} more messages');
      }
    } else {
      _errorMessage = result['message'];
      print('[MessageProvider] Error: $_errorMessage');
    }

    _isLoading = false;
    notifyListeners();
    print('[MessageProvider] ===== LOAD CHAT HISTORY END =====\n');
  }

  // Gửi tin nhắn
  Future<bool> sendMessage(String receiverUsername, String content) async {
    print('\n[MessageProvider] ===== SEND MESSAGE START =====');
    print('[MessageProvider] Receiver: $receiverUsername');
    print('[MessageProvider] Content length: ${content.trim().length}');
    
    if (content.trim().isEmpty) {
      _errorMessage = 'Nội dung tin nhắn không được để trống';
      print('[MessageProvider] Error: Empty content');
      notifyListeners();
      return false;
    }

    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    final dto = SendMessageDto(
      receiverUsername: receiverUsername,
      content: content.trim(),
    );

    final result = await _messageService.sendMessage(dto);
    
    print('[MessageProvider] Result success: ${result['success']}');

    if (result['success']) {
      final newMessage = result['message'] as MessageDto;
      
      // Thêm tin nhắn mới vào cuối danh sách
      _currentMessages.add(newMessage);
      print('[MessageProvider] Added message to list');
      
      // Cập nhật danh sách cuộc hội thoại
      _updateConversationList(newMessage);
      
      _isSending = false;
      notifyListeners();
      print('[MessageProvider] ===== SEND MESSAGE SUCCESS =====\n');
      return true;
    } else {
      _errorMessage = result['message'];
      _isSending = false;
      notifyListeners();
      print('[MessageProvider] Error: $_errorMessage');
      print('[MessageProvider] ===== SEND MESSAGE FAILED =====\n');
      return false;
    }
  }

  // Cập nhật danh sách cuộc hội thoại sau khi gửi tin nhắn
  void _updateConversationList(MessageDto newMessage) {
    final conversationIndex = _conversations.indexWhere(
      (conv) => conv.friendUsername == _currentFriendUsername,
    );

    if (conversationIndex != -1) {
      // Cập nhật cuộc hội thoại hiện có
      final updatedConv = ConversationDto(
        id: _conversations[conversationIndex].id,
        friendUsername: _conversations[conversationIndex].friendUsername,
        friendInitials: _conversations[conversationIndex].friendInitials,
        lastMessage: newMessage.content,
        lastMessageAt: newMessage.sentAt,
      );
      
      _conversations[conversationIndex] = updatedConv;
      
      // Di chuyển lên đầu danh sách
      _conversations.removeAt(conversationIndex);
      _conversations.insert(0, updatedConv);
    } else {
      // Thêm cuộc hội thoại mới
      final newConv = ConversationDto(
        id: newMessage.conversationId,
        friendUsername: _currentFriendUsername!,
        friendInitials: newMessage.senderInitials,
        lastMessage: newMessage.content,
        lastMessageAt: newMessage.sentAt,
      );
      _conversations.insert(0, newConv);
    }
  }

  // Bắt đầu polling tin nhắn mới
  void startMessagePolling(String friendUsername) {
    stopMessagePolling(); // Dừng timer cũ nếu có
    
    _messagePollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkForNewMessages(friendUsername);
    });
  }

  // Dừng polling
  void stopMessagePolling() {
    _messagePollingTimer?.cancel();
    _messagePollingTimer = null;
  }

  // Kiểm tra tin nhắn mới
  Future<void> _checkForNewMessages(String friendUsername) async {
    if (_currentMessages.isEmpty) return;
    
    final lastMessageId = _currentMessages.last.id;
    
    // Chỉ log khi có tin nhắn mới (comment out để giảm log spam)
    // print('[MessageProvider] Checking new messages for $friendUsername, lastMessageId: $lastMessageId');
    
    final result = await _messageService.getNewMessages(
      friendUsername: friendUsername,
      lastMessageId: lastMessageId,
    );

    if (result['success']) {
      final newMessages = result['messages'] as List<MessageDto>;
      
      if (newMessages.isNotEmpty) {
        print('[MessageProvider] ✅ Found ${newMessages.length} new messages');
        _currentMessages.addAll(newMessages);
        
        // Cập nhật conversation list với tin nhắn mới nhất
        final latestMessage = newMessages.last;
        _updateConversationList(latestMessage);
        
        notifyListeners();
      }
    } else {
      print('[MessageProvider] ❌ Check new messages error: ${result['message']}');
    }
  }

  // Load thêm tin nhắn cũ (pagination)
  Future<void> loadMoreMessages() async {
    if (_currentChatHistory == null || !_currentChatHistory!.hasMore) return;
    if (_currentMessages.isEmpty) return;

    final oldestMessageId = _currentMessages.first.id;
    await loadChatHistory(_currentFriendUsername!, lastMessageId: oldestMessageId);
  }

  // Clear current chat
  void clearCurrentChat() {
    _currentChatHistory = null;
    _currentMessages = [];
    _currentFriendUsername = null;
    stopMessagePolling();
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopMessagePolling();
    super.dispose();
  }
}

