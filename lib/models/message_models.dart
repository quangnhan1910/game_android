import '../utils/datetime_utils.dart';

class MessageDto {
  final int id;
  final int conversationId;
  final String senderId;
  final String senderUsername;
  final String? senderInitials;
  final String content;
  final DateTime sentAt;  // Lưu ở dạng UTC từ server
  final bool isMine;

  MessageDto({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderUsername,
    this.senderInitials,
    required this.content,
    required this.sentAt,
    required this.isMine,
  });

  factory MessageDto.fromJson(Map<String, dynamic> json) {
    return MessageDto(
      id: json['id'] ?? 0,
      conversationId: json['conversationId'] ?? 0,
      senderId: json['senderId'] ?? '',
      senderUsername: json['senderUsername'] ?? '',
      senderInitials: json['senderInitials'],
      content: json['content'] ?? '',
      // Parse UTC time từ server (ISO 8601 format)
      sentAt: DateTimeUtils.parseUtcFromServer(json['sentAt']),
      isMine: json['isMine'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderUsername': senderUsername,
      'senderInitials': senderInitials,
      'content': content,
      // Convert sang UTC ISO 8601 string khi gửi lên server
      'sentAt': DateTimeUtils.toUtcIsoString(sentAt),
      'isMine': isMine,
    };
  }
}

class ConversationDto {
  final int id;
  final String friendUsername;
  final String? friendInitials;
  final String? lastMessage;
  final DateTime? lastMessageAt;  // Lưu ở dạng UTC từ server

  ConversationDto({
    required this.id,
    required this.friendUsername,
    this.friendInitials,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory ConversationDto.fromJson(Map<String, dynamic> json) {
    return ConversationDto(
      id: json['id'] ?? 0,
      friendUsername: json['friendUsername'] ?? '',
      friendInitials: json['friendInitials'],
      lastMessage: json['lastMessage'],
      // Parse UTC time từ server (ISO 8601 format)
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTimeUtils.parseUtcFromServer(json['lastMessageAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'friendUsername': friendUsername,
      'friendInitials': friendInitials,
      'lastMessage': lastMessage,
      // Convert sang UTC ISO 8601 string khi gửi lên server
      'lastMessageAt': lastMessageAt != null 
          ? DateTimeUtils.toUtcIsoString(lastMessageAt!)
          : null,
    };
  }
}

class ChatHistoryDto {
  final int conversationId;
  final String friendUsername;
  final String? friendInitials;
  final List<MessageDto> messages;
  final bool hasMore;

  ChatHistoryDto({
    required this.conversationId,
    required this.friendUsername,
    this.friendInitials,
    required this.messages,
    required this.hasMore,
  });

  factory ChatHistoryDto.fromJson(Map<String, dynamic> json) {
    return ChatHistoryDto(
      conversationId: json['conversationId'] ?? 0,
      friendUsername: json['friendUsername'] ?? '',
      friendInitials: json['friendInitials'],
      messages: (json['messages'] as List<dynamic>?)
              ?.map((msg) => MessageDto.fromJson(msg))
              .toList() ??
          [],
      hasMore: json['hasMore'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'friendUsername': friendUsername,
      'friendInitials': friendInitials,
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'hasMore': hasMore,
    };
  }
}

class SendMessageDto {
  final String receiverUsername;
  final String content;

  SendMessageDto({
    required this.receiverUsername,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'receiverUsername': receiverUsername,
      'content': content,
    };
  }
}

