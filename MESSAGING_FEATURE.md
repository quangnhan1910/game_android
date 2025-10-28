# Chức năng Nhắn Tin (Messaging Feature)

## Tổng quan

Đã thiết kế và triển khai hoàn chỉnh chức năng nhắn tin cho ứng dụng Flutter, tích hợp với backend API có sẵn.

## Các File Đã Tạo

### 1. Models (`lib/models/message_models.dart`)
Chứa các data models để map với DTOs từ backend:
- **MessageDto**: Đại diện cho một tin nhắn
  - id, conversationId, senderId, senderUsername, senderInitials
  - content, sentAt, isMine
- **ConversationDto**: Đại diện cho một cuộc hội thoại
  - id, friendUsername, friendInitials
  - lastMessage, lastMessageAt
- **ChatHistoryDto**: Lịch sử chat với phân trang
  - conversationId, friendUsername, friendInitials
  - messages, hasMore
- **SendMessageDto**: DTO để gửi tin nhắn
  - receiverUsername, content

### 2. Service (`lib/services/message_service.dart`)
Xử lý các API calls:
- `sendMessage()` - Gửi tin nhắn (POST /api/message/send)
- `getChatHistory()` - Lấy lịch sử chat (GET /api/message/history/{friendUsername})
- `getConversations()` - Lấy danh sách cuộc hội thoại (GET /api/message/conversations)
- `getNewMessages()` - Lấy tin nhắn mới (GET /api/message/new/{friendUsername})

### 3. Provider (`lib/providers/message_provider.dart`)
Quản lý state của messaging feature:
- Quản lý danh sách cuộc hội thoại
- Quản lý tin nhắn của cuộc hội thoại hiện tại
- Tự động polling tin nhắn mới mỗi 3 giây
- Hỗ trợ pagination để load tin nhắn cũ
- Cập nhật danh sách cuộc hội thoại khi có tin nhắn mới

### 4. UI Screens

#### ConversationsListScreen (`lib/screens/messages/conversations_list_screen.dart`)
Màn hình danh sách các cuộc hội thoại:
- Hiển thị danh sách cuộc hội thoại với tin nhắn cuối cùng
- Pull-to-refresh để cập nhật
- Avatar với initials
- Format thời gian thông minh (hôm nay, hôm qua, ngày/tháng/năm)
- Tap vào cuộc hội thoại để mở chat

#### ChatScreen (`lib/screens/messages/chat_screen.dart`)
Màn hình chat với một người bạn:
- Hiển thị lịch sử tin nhắn
- Tự động polling tin nhắn mới mỗi 3 giây
- Phân biệt tin nhắn của mình và người khác
- Date separators để phân chia theo ngày
- Text input với nút gửi
- Loading indicator khi đang gửi
- Scroll lên đầu để load thêm tin nhắn cũ (pagination)
- Tự động scroll xuống khi gửi tin nhắn mới

## Tích hợp với UI

### Main Navigation
Đã thêm tab "Tin nhắn" vào bottom navigation bar:
```dart
// lib/screens/main_navigation_screen.dart
BottomNavigationBarItem(
  icon: Icon(Icons.chat),
  label: 'Tin nhắn',
)
```

### Friends Screen
Đã thêm nút "Nhắn tin" vào mỗi friend tile:
- Nhấn vào icon chat để mở chat với bạn bè đó
- Chuyển trực tiếp đến màn hình chat

## Cấu hình API

API base URL được lấy từ `lib/config/config_url.dart`:
```dart
String baseUrl = Config_URL.baseUrl + '/Message';
```

Các endpoint được sử dụng:
- POST /api/Message/send
- GET /api/Message/history/{friendUsername}?lastMessageId={id}&pageSize={size}
- GET /api/Message/conversations
- GET /api/Message/new/{friendUsername}?lastMessageId={id}

## Authentication

Service tự động lấy JWT token từ SharedPreferences và thêm vào header:
```dart
'Authorization': 'Bearer $token'
```

## Tính năng chính

### 1. Gửi tin nhắn
- Validate nội dung không rỗng
- Hiển thị loading state khi đang gửi
- Cập nhật UI ngay lập tức sau khi gửi thành công
- Hiển thị lỗi nếu gửi thất bại

### 2. Real-time Updates (Polling)
- Tự động kiểm tra tin nhắn mới mỗi 3 giây
- Chỉ hoạt động khi đang mở màn hình chat
- Tự động dừng khi rời khỏi màn hình

### 3. Pagination
- Load 50 tin nhắn mỗi lần
- Scroll lên đầu để load thêm tin nhắn cũ
- Hiển thị loading indicator khi đang load
- Kiểm tra `hasMore` để biết còn tin nhắn cũ không

### 4. UI/UX Features
- Avatar với initials
- Message bubbles (khác màu cho tin nhắn của mình và người khác)
- Date separators
- Format thời gian thông minh
- Pull-to-refresh
- Empty states với icon và text hướng dẫn
- Error handling với thông báo rõ ràng

## Dependencies Đã Thêm

```yaml
provider: ^6.1.1
intl: ^0.18.1
```

## Cách sử dụng

### 1. Từ Bottom Navigation
Người dùng chọn tab "Tin nhắn" → Xem danh sách cuộc hội thoại → Tap vào để mở chat

### 2. Từ Friends Screen
Người dùng mở tab "Bạn bè" → Nhấn icon chat ở bạn bè muốn nhắn tin → Mở chat ngay lập tức

### 3. Trong Chat Screen
- Nhập tin nhắn vào text field
- Nhấn nút Send hoặc Enter để gửi
- Scroll lên đầu để xem tin nhắn cũ hơn
- Tin nhắn mới tự động hiển thị (polling)

## Lưu ý kỹ thuật

1. **Provider Pattern**: Sử dụng ChangeNotifierProvider để quản lý state
2. **Polling**: Timer.periodic chạy mỗi 3 giây để kiểm tra tin nhắn mới
3. **Memory Management**: Timer được dispose đúng cách khi rời khỏi màn hình
4. **Error Handling**: Tất cả API calls đều có error handling và hiển thị thông báo
5. **Loading States**: Hiển thị loading indicators ở tất cả các chỗ cần thiết
6. **Timezone**: Backend sử dụng local time (không phải UTC)

## Cải tiến có thể làm trong tương lai

1. **WebSocket**: Thay thế polling bằng WebSocket để real-time thực sự
2. **Typing Indicator**: Hiển thị khi người khác đang nhập
3. **Message Status**: Đã gửi, đã nhận, đã đọc
4. **Media Support**: Gửi hình ảnh, file
5. **Push Notifications**: Thông báo khi có tin nhắn mới
6. **Message Search**: Tìm kiếm tin nhắn
7. **Message Actions**: Reply, delete, edit
8. **Group Chat**: Nhắn tin nhóm

## Troubleshooting

### Lỗi 401 Unauthorized
- Kiểm tra token có được lưu trong SharedPreferences không
- Kiểm tra token còn hạn không
- Yêu cầu người dùng đăng nhập lại

### Tin nhắn không cập nhật
- Kiểm tra polling có đang chạy không
- Kiểm tra kết nối mạng
- Kiểm tra API có hoạt động không

### Lỗi pagination
- Kiểm tra `lastMessageId` có đúng không
- Kiểm tra `hasMore` flag

## Kết luận

Chức năng nhắn tin đã được triển khai hoàn chỉnh với tất cả các tính năng cơ bản:
- ✅ Gửi và nhận tin nhắn
- ✅ Danh sách cuộc hội thoại
- ✅ Real-time updates (polling)
- ✅ Pagination
- ✅ UI/UX đẹp và thân thiện
- ✅ Error handling
- ✅ Integration với Friends screen
- ✅ Bottom navigation integration

Ứng dụng sẵn sàng để test và sử dụng!

