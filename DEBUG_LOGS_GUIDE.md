# Hướng dẫn Debug Lỗi 404 - Tab Tin nhắn

## Các Log đã được thêm vào

Tôi đã thêm các log chi tiết vào các file sau để giúp bạn debug lỗi 404:

### 1. `lib/config/config_url.dart`
- Log BASE_URL đang được sử dụng
- Log xem có đọc được từ file .env hay không

### 2. `lib/services/message_service.dart`
- **GET CONVERSATIONS**: Log URL đầy đủ, headers, response status và body
- **GET CHAT HISTORY**: Log URL, friend username, parameters, headers, response
- **SEND MESSAGE**: Log URL, headers, body, response
- **GET NEW MESSAGES**: Log URL, parameters, headers, response

### 3. `lib/providers/message_provider.dart`
- Log khi bắt đầu/kết thúc các operations
- Log kết quả success/error
- Log số lượng conversations/messages được load

### 4. `lib/screens/messages/conversations_list_screen.dart`
- Log khi màn hình được khởi tạo
- Log khi loadConversations được gọi

## Cách xem log

### Trên Android Studio / IntelliJ:
1. Chạy app ở chế độ Debug
2. Mở tab "Run" hoặc "Debug Console" ở dưới cùng
3. Chuyển sang tab **Tin nhắn** trong app
4. Xem các log in ra theo format:
   ```
   ===== GET CONVERSATIONS =====
   Base URL: https://...
   Full URL: https://.../Message/conversations
   Headers: {Content-Type: application/json, Authorization: Bearer ...}
   Response Status: 404
   Response Body: ...
   =============================
   ```

### Trên VS Code:
1. Chạy app với F5 hoặc "Run > Start Debugging"
2. Xem Debug Console
3. Tương tự như trên

### Trên Terminal:
```bash
flutter run
# hoặc
flutter run --verbose
```

## Các thông tin quan trọng cần chú ý trong log

Khi gặp lỗi 404, hãy chú ý:

1. **Base URL**: Kiểm tra xem base URL có đúng không
   ```
   📍 BASE_URL from .env: https://...
   hoặc
   ⚠️ BASE_URL is not set in the .env file. Using default URL.
   ```

2. **Full URL**: URL đầy đủ được gọi
   ```
   Full URL: https://smallgreensled97.conveyor.cloud/api/Message/conversations
   ```
   - Kiểm tra xem endpoint có đúng không
   - Có thừa hoặc thiếu dấu `/` không
   - Path có đúng case (chữ hoa/thường) không

3. **Headers**: Đảm bảo có Authorization token
   ```
   Headers: {Content-Type: application/json, Authorization: Bearer eyJhbG...}
   ```

4. **Response Status và Body**:
   ```
   Response Status: 404
   Response Body: {"message": "Not Found"}
   ```

## Các lỗi phổ biến gây 404

1. **Endpoint không tồn tại trên server**
   - Backend chưa implement endpoint `/Message/conversations`
   - Path không đúng (ví dụ: `/message` thay vì `/Message`)

2. **Base URL không đúng**
   - File .env chưa cấu hình đúng
   - Server không chạy hoặc URL đã thay đổi

3. **API version không đúng**
   - Backend có thể sử dụng versioning (ví dụ: `/api/v1/Message/conversations`)

## Bước tiếp theo

Sau khi chạy app và xem log, hãy:

1. **Copy toàn bộ log** từ lúc mở tab Tin nhắn đến khi gặp lỗi
2. **Kiểm tra URL** được gọi trong log
3. **So sánh với API backend** để xem endpoint có đúng không
4. **Kiểm tra backend logs** (nếu có quyền truy cập) để xem request có đến server không

## Ví dụ log mẫu khi gặp lỗi 404

```
[ConversationsListScreen] ===== INIT STATE =====
[ConversationsListScreen] Screen initialized, will load conversations
[ConversationsListScreen] PostFrameCallback - Loading conversations...

[MessageProvider] ===== LOAD CONVERSATIONS START =====
📍 BASE_URL from .env: https://smallgreensled97.conveyor.cloud/api/

===== GET CONVERSATIONS =====
Base URL: https://smallgreensled97.conveyor.cloud/api/Message
Full URL: https://smallgreensled97.conveyor.cloud/api/Message/conversations
Headers: {Content-Type: application/json, Authorization: Bearer eyJhbGc...}
Response Status: 404
Response Body: {"message":"Endpoint not found"}
=============================

[MessageProvider] Result success: false
[MessageProvider] Error: Không thể tải danh sách hội thoại (404)
[MessageProvider] ===== LOAD CONVERSATIONS END =====
```

## Giải pháp tạm thời

Nếu URL không đúng, bạn có thể sửa trong file `lib/services/message_service.dart`:
```dart
MessageService({String? baseUrl})
    : baseUrl = baseUrl ?? '${Config_URL.baseUrl}/Message';
    // Thay đổi '/Message' thành path đúng của backend
```

