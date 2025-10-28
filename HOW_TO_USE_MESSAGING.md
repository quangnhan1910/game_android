# Hướng Dẫn Sử Dụng Chức Năng Nhắn Tin

## 📱 Tổng Quan

Chức năng nhắn tin đã được tích hợp hoàn toàn vào ứng dụng của bạn, cho phép người dùng:
- Xem danh sách cuộc hội thoại
- Chat với bạn bè
- Gửi và nhận tin nhắn real-time (tự động cập nhật mỗi 3 giây)
- Xem lịch sử tin nhắn với pagination

## 🎯 Cách Truy Cập Chức Năng

### Cách 1: Từ Bottom Navigation Bar
1. Mở ứng dụng
2. Nhìn xuống thanh navigation ở dưới cùng
3. Chọn tab **"Tin nhắn"** (icon chat)
4. Bạn sẽ thấy danh sách các cuộc hội thoại

### Cách 2: Từ Màn Hình Bạn Bè
1. Mở tab **"Bạn bè"** từ bottom navigation
2. Tìm bạn bè muốn nhắn tin
3. Nhấn vào **icon chat** (💬) bên cạnh tên bạn bè
4. Sẽ mở màn hình chat ngay lập tức

## 📋 Các Màn Hình

### 1. Danh Sách Cuộc Hội Thoại (Conversations List)

**Hiển thị:**
- Avatar với chữ cái đầu của tên (initials)
- Tên người bạn
- Tin nhắn cuối cùng
- Thời gian tin nhắn cuối (hôm nay hiển thị giờ, hôm qua, hoặc ngày/tháng/năm)

**Thao tác:**
- **Tap vào cuộc hội thoại**: Mở chat với người đó
- **Pull down**: Refresh danh sách
- **Nút refresh**: Cập nhật danh sách thủ công

**Trạng thái:**
- Nếu chưa có cuộc hội thoại: Hiển thị "Chưa có cuộc hội thoại nào"
- Nếu có lỗi: Hiển thị thông báo lỗi với nút "Thử lại"

### 2. Màn Hình Chat

**Hiển thị:**
- Tin nhắn của bạn: Bên phải, màu xanh
- Tin nhắn của người khác: Bên trái, màu xám
- Ngày tháng phân cách giữa các tin nhắn
- Thời gian gửi mỗi tin nhắn

**Thao tác:**
- **Nhập tin nhắn**: Gõ vào ô text ở dưới cùng
- **Gửi tin nhắn**: 
  - Nhấn nút Send (icon máy bay giấy)
  - Hoặc nhấn Enter trên bàn phím
- **Xem tin nhắn cũ**: Scroll lên đầu, hệ thống tự động load thêm tin nhắn cũ
- **Xem tin nhắn mới**: Tự động cập nhật mỗi 3 giây

**Tính năng đặc biệt:**
- Loading indicator khi đang gửi tin nhắn
- Loading indicator khi đang load tin nhắn cũ
- Tự động scroll xuống khi gửi tin nhắn mới
- Tự động dừng polling khi rời khỏi màn hình (tiết kiệm pin và data)

## 🔐 Yêu Cầu

### Để sử dụng chức năng nhắn tin:
1. **Đã đăng nhập**: Phải có tài khoản và đã đăng nhập
2. **Đã kết bạn**: Chỉ có thể nhắn tin với người đã là bạn bè
3. **Có kết nối internet**: Cần mạng để gửi và nhận tin nhắn

### Backend API
- Backend phải đang chạy và có thể truy cập
- API endpoints:
  - POST `/api/Message/send`
  - GET `/api/Message/history/{friendUsername}`
  - GET `/api/Message/conversations`
  - GET `/api/Message/new/{friendUsername}`

## 🚀 Cách Test Chức Năng

### Test Cơ Bản:
1. Đăng nhập với 2 tài khoản khác nhau (trên 2 thiết bị hoặc emulator)
2. Kết bạn với nhau
3. Từ tài khoản 1: Vào tab "Bạn bè" → Nhấn icon chat của tài khoản 2
4. Gửi tin nhắn "Hello"
5. Từ tài khoản 2: Vào tab "Tin nhắn" → Thấy cuộc hội thoại mới
6. Mở cuộc hội thoại → Thấy tin nhắn "Hello"
7. Reply lại → Tài khoản 1 tự động nhận được (sau tối đa 3 giây)

### Test Pagination:
1. Gửi hơn 50 tin nhắn
2. Mở lại cuộc hội thoại
3. Scroll lên đầu → Tin nhắn cũ sẽ tự động load

### Test UI States:
1. **Loading**: Mở ứng dụng lần đầu → Thấy loading spinner
2. **Empty**: Xóa hết cuộc hội thoại → Thấy "Chưa có cuộc hội thoại nào"
3. **Error**: Tắt backend → Thấy thông báo lỗi
4. **Sending**: Gửi tin nhắn → Thấy loading ở nút Send

## ⚙️ Cấu Hình

### API URL
Cấu hình trong file `.env`:
```
BASE_URL=https://your-api-url.com/api
```

### Polling Interval
Hiện tại: 3 giây (có thể thay đổi trong `message_provider.dart`):
```dart
Timer.periodic(const Duration(seconds: 3), (timer) {
  _checkForNewMessages(friendUsername);
});
```

### Page Size
Hiện tại: 50 tin nhắn mỗi lần (có thể thay đổi trong `message_service.dart`):
```dart
int pageSize = 50
```

## ❗ Xử Lý Lỗi

### Lỗi "Vui lòng đăng nhập lại"
**Nguyên nhân**: Token hết hạn hoặc không hợp lệ
**Giải pháp**: Đăng xuất và đăng nhập lại

### Lỗi "Chỉ có thể nhắn tin với bạn bè"
**Nguyên nhân**: Chưa kết bạn với người nhận
**Giải pháp**: Gửi lời mời kết bạn và đợi chấp nhận

### Lỗi "Không thể gửi tin nhắn"
**Nguyên nhân**: 
- Mất kết nối internet
- Backend không hoạt động
- Nội dung tin nhắn không hợp lệ

**Giải pháp**:
1. Kiểm tra kết nối internet
2. Kiểm tra backend có chạy không
3. Thử gửi lại

### Tin nhắn không tự động cập nhật
**Nguyên nhân**:
- Đang ở ngoài màn hình chat
- Polling bị dừng

**Giải pháp**:
- Quay lại màn hình chat
- Pull to refresh
- Mở lại màn hình

## 📊 Luồng Dữ Liệu

```
User Action → UI Screen → Provider → Service → Backend API
                ↓            ↓          ↓
              Update    Manage State  HTTP Request
                UI
```

### Khi gửi tin nhắn:
1. User nhập và nhấn Send
2. ChatScreen gọi `provider.sendMessage()`
3. MessageProvider gọi `service.sendMessage()`
4. MessageService gửi POST request đến backend
5. Backend trả về MessageDto
6. Provider cập nhật `_currentMessages`
7. Provider notify listeners
8. UI tự động rebuild và hiển thị tin nhắn mới

### Khi nhận tin nhắn (polling):
1. Timer chạy mỗi 3 giây
2. Provider gọi `service.getNewMessages()`
3. MessageService gửi GET request với lastMessageId
4. Backend trả về danh sách tin nhắn mới (nếu có)
5. Provider thêm tin nhắn mới vào `_currentMessages`
6. Provider notify listeners
7. UI tự động rebuild và hiển thị tin nhắn mới

## 🎨 Customization

### Thay đổi màu sắc:
**File**: `lib/screens/messages/chat_screen.dart`

Tin nhắn của mình:
```dart
color: Colors.blue.shade600  // Đổi màu tại đây
```

Tin nhắn người khác:
```dart
color: Colors.grey.shade300  // Đổi màu tại đây
```

### Thay đổi avatar:
**File**: `lib/screens/messages/conversations_list_screen.dart`

```dart
CircleAvatar(
  radius: 28,  // Đổi kích thước
  backgroundColor: Colors.blue.shade700,  // Đổi màu nền
  child: Text(
    initials ?? username.substring(0, 1).toUpperCase(),
    style: const TextStyle(
      color: Colors.white,  // Đổi màu chữ
      fontSize: 20,  // Đổi cỡ chữ
    ),
  ),
)
```

### Thay đổi format thời gian:
**File**: `lib/screens/messages/chat_screen.dart`

```dart
String _formatMessageTime(DateTime dateTime) {
  // Custom format tại đây
  return DateFormat('HH:mm').format(dateTime);
}
```

## 📝 Code Examples

### Mở chat programmatically:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ChatScreen(
      friendUsername: 'john_doe',
      friendInitials: 'JD',
    ),
  ),
);
```

### Gửi tin nhắn programmatically:
```dart
final provider = context.read<MessageProvider>();
bool success = await provider.sendMessage('john_doe', 'Hello!');
if (success) {
  print('Tin nhắn đã gửi thành công');
}
```

### Refresh danh sách cuộc hội thoại:
```dart
final provider = context.read<MessageProvider>();
await provider.loadConversations();
```

## 🔍 Debug Tips

### Bật debug logs:
Thêm print statements vào các phương thức trong MessageProvider:
```dart
Future<void> loadConversations() async {
  print('📱 Loading conversations...');
  // ... code ...
  print('✅ Conversations loaded: ${_conversations.length}');
}
```

### Kiểm tra API response:
Trong MessageService, print response:
```dart
print('API Response: ${response.body}');
```

### Kiểm tra token:
```dart
final token = await _getToken();
print('Current token: $token');
```

## 🎓 Best Practices

1. **Luôn kiểm tra mounted trước khi setState**
2. **Dispose timer và controller đúng cách**
3. **Handle loading và error states**
4. **Validate input trước khi gửi**
5. **Sử dụng const constructors khi có thể**
6. **Tránh rebuild không cần thiết**

## 📞 Hỗ Trợ

Nếu gặp vấn đề:
1. Kiểm tra console logs
2. Kiểm tra backend logs
3. Kiểm tra network requests (DevTools)
4. Đọc lại documentation này
5. Kiểm tra code trong các file đã tạo

---

**Chúc bạn thành công với chức năng nhắn tin! 🎉**

