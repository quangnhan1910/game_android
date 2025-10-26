import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/message_provider.dart';
import '../../models/message_models.dart';
import '../../utils/datetime_utils.dart';
import 'chat_screen.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({Key? key}) : super(key: key);

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  @override
  void initState() {
    super.initState();
    print('\n[ConversationsListScreen] ===== INIT STATE =====');
    print('[ConversationsListScreen] Screen initialized, will load conversations');
    // Load conversations khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[ConversationsListScreen] PostFrameCallback - Loading conversations...');
      context.read<MessageProvider>().loadConversations();
    });
  }

  String _formatDateTime(DateTime? dateTime) {
    // Sử dụng DateTimeUtils để tự động convert UTC -> Local và format
    return DateTimeUtils.formatConversationTime(dateTime);
  }

  Widget _buildAvatar(String? initials, String username) {
    return CircleAvatar(
      backgroundColor: Colors.blue[100],
      child: Text(
        initials ?? username.substring(0, 1).toUpperCase(),
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildConversationItem(ConversationDto conversation) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: _buildAvatar(conversation.friendInitials, conversation.friendUsername),
        title: Text(
          conversation.friendUsername,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          conversation.lastMessage ?? 'Chưa có tin nhắn',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatDateTime(conversation.lastMessageAt),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                friendUsername: conversation.friendUsername,
                friendInitials: conversation.friendInitials,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tin nhắn', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Consumer<MessageProvider>(
        builder: (context, messageProvider, child) {
          if (messageProvider.isLoading && messageProvider.conversations.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (messageProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    messageProvider.errorMessage!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      messageProvider.loadConversations();
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (messageProvider.conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Chưa có cuộc hội thoại nào',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hãy bắt đầu trò chuyện với bạn bè của bạn!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Chuyển sang tab "Bạn bè" để kết bạn',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await messageProvider.loadConversations();
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: messageProvider.conversations.length,
              itemBuilder: (context, index) {
                return _buildConversationItem(messageProvider.conversations[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

