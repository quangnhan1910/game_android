# 🕐 Timezone Handling Guide

## Tổng quan

Dự án này implement **timezone handling chuẩn** để đảm bảo thời gian hiển thị chính xác cho người dùng ở các múi giờ khác nhau.

## Flow chuẩn

### 1️⃣ **Backend (Server)** ✅ ĐÃ HOÀN THÀNH
- ✅ Lưu tất cả thời gian vào database dưới dạng **UTC**
- ✅ Trả về cho client dưới dạng **ISO 8601 UTC** (ví dụ: `"2024-10-26T15:30:45.123Z"`)

### 2️⃣ **Client (Flutter App)** ✅ ĐÃ HOÀN THÀNH
- ✅ Parse **UTC time** từ server
- ✅ Tự động convert sang **local time** của thiết bị khi hiển thị
- ✅ Convert sang **UTC** khi gửi lên server

## Implementation

### 📁 Files đã tạo/cập nhật

#### 1. `lib/utils/datetime_utils.dart` - Utility Helper
File này cung cấp các helper methods để xử lý timezone:

**Các methods chính:**
- `parseUtcFromServer(String)` - Parse ISO 8601 UTC string từ server
- `toLocal(DateTime)` - Convert UTC sang local time
- `formatMessageTime(DateTime)` - Format thời gian cho tin nhắn chat
- `formatConversationTime(DateTime)` - Format thời gian cho danh sách hội thoại
- `formatTimeAgo(DateTime)` - Format kiểu "5 phút trước", "1 giờ trước"
- `formatDateSeparator(DateTime)` - Format cho date separator
- `toUtcIsoString(DateTime)` - Convert sang UTC ISO 8601 để gửi server
- `isSameDay(DateTime, DateTime)` - So sánh 2 ngày

#### 2. `lib/models/message_models.dart` - Models
**Cập nhật:**
- `MessageDto.fromJson()`: Sử dụng `DateTimeUtils.parseUtcFromServer()` để parse UTC
- `MessageDto.toJson()`: Sử dụng `DateTimeUtils.toUtcIsoString()` để serialize
- `ConversationDto.fromJson()`: Parse UTC từ server
- `ConversationDto.toJson()`: Convert sang UTC khi serialize

#### 3. `lib/screens/messages/chat_screen.dart` - Chat UI
**Cập nhật:**
- Sử dụng `DateTimeUtils.formatMessageTime()` cho timestamp tin nhắn
- Sử dụng `DateTimeUtils.formatDateSeparator()` cho date separator
- Sử dụng `DateTimeUtils.isSameDay()` để group tin nhắn theo ngày

#### 4. `lib/screens/messages/conversations_list_screen.dart` - Conversations List UI
**Cập nhật:**
- Sử dụng `DateTimeUtils.formatConversationTime()` cho timestamp cuộc hội thoại

#### 5. `pubspec.yaml` - Dependencies
**Đã thêm:**
```yaml
timeago: ^3.6.1  # Format "X phút trước", "hôm qua"
```

## Cách sử dụng

### 📥 Parse thời gian từ Server (UTC → Local)

```dart
// Server trả về: "2024-10-26T15:30:45.123Z"
final utcDateTime = DateTimeUtils.parseUtcFromServer(json['sentAt']);

// utcDateTime giờ là DateTime object ở UTC timezone
// Để hiển thị, sử dụng các format methods (chúng tự động convert sang local)
```

### 🎨 Format thời gian để hiển thị

```dart
// 1. Format cho tin nhắn chat
final timeStr = DateTimeUtils.formatMessageTime(message.sentAt);
// Output: "15:30" (hôm nay) hoặc "Hôm qua 15:30" hoặc "26/10/2024 15:30"

// 2. Format cho danh sách hội thoại
final timeStr = DateTimeUtils.formatConversationTime(conversation.lastMessageAt);
// Output: "15:30" (hôm nay) hoặc "Hôm qua" hoặc "T2" (thứ 2) hoặc "26/10/2024"

// 3. Format kiểu "time ago"
final timeStr = DateTimeUtils.formatTimeAgo(message.sentAt);
// Output: "5 phút trước", "1 giờ trước", "2 ngày trước"

// 4. Format date separator
final dateStr = DateTimeUtils.formatDateSeparator(date);
// Output: "Hôm nay, 26/10/2024" hoặc "Hôm qua, 25/10/2024" hoặc "26/10/2024"
```

### 📤 Gửi thời gian lên Server (Local → UTC)

```dart
// Client tạo DateTime local
final now = DateTime.now();

// Convert sang UTC ISO 8601 string để gửi server
final utcString = DateTimeUtils.toUtcIsoString(now);
// Output: "2024-10-26T08:30:45.123Z" (UTC)
```

### 🔍 So sánh ngày

```dart
// So sánh 2 DateTime có cùng ngày không (dựa trên local time)
final isSame = DateTimeUtils.isSameDay(date1, date2);
```

## Lưu ý quan trọng

### ⚠️ DateTime trong Models
- **Luôn lưu DateTime ở dạng UTC** trong models
- Chỉ convert sang local time **khi hiển thị** (trong UI layer)
- **Không** lưu local time trong models

### ✅ Best Practices

```dart
// ✅ ĐÚNG: Parse UTC từ server
final message = MessageDto.fromJson(json);
// message.sentAt là UTC DateTime

// ✅ ĐÚNG: Convert sang local khi hiển thị
final displayTime = DateTimeUtils.formatMessageTime(message.sentAt);

// ❌ SAI: Không convert sang local trong model
// sentAt: DateTime.parse(json['sentAt']).toLocal() // SAI!
```

### 🧪 Testing với nhiều timezone

Để test app với timezone khác:
1. Thay đổi timezone của device/emulator
2. Kiểm tra xem thời gian hiển thị có đúng với timezone local không
3. Kiểm tra xem thời gian gửi lên server có đúng UTC không

## Format Outputs

### formatMessageTime()
| Thời gian | Output |
|-----------|--------|
| Hôm nay 15:30 | "15:30" |
| Hôm qua 15:30 | "Hôm qua 15:30" |
| 24/10/2024 15:30 | "24/10/2024 15:30" |

### formatConversationTime()
| Thời gian | Output |
|-----------|--------|
| Hôm nay 15:30 | "15:30" |
| Hôm qua | "Hôm qua" |
| Thứ 2 tuần này | "T2" |
| 20/10/2024 | "20/10/2024" |

### formatTimeAgo()
| Thời gian | Output |
|-----------|--------|
| 5 phút trước | "5 phút trước" |
| 1 giờ trước | "1 giờ trước" |
| 2 ngày trước | "2 ngày trước" |
| 1 tuần trước | "1 tuần trước" |

### formatDateSeparator()
| Thời gian | Output |
|-----------|--------|
| Hôm nay | "Hôm nay, 26/10/2024" |
| Hôm qua | "Hôm qua, 25/10/2024" |
| Cũ hơn | "24/10/2024" |

## Troubleshooting

### Vấn đề: Thời gian hiển thị sai múi giờ
**Giải pháp:** Đảm bảo backend đang trả về UTC time với 'Z' ở cuối (ISO 8601)

### Vấn đề: Server nhận được thời gian sai
**Giải pháp:** Sử dụng `DateTimeUtils.toUtcIsoString()` để convert sang UTC trước khi gửi

### Vấn đề: Date separator không group đúng
**Giải pháp:** Sử dụng `DateTimeUtils.isSameDay()` thay vì so sánh trực tiếp

## Tài liệu tham khảo

- [ISO 8601 Format](https://en.wikipedia.org/wiki/ISO_8601)
- [Flutter DateTime Documentation](https://api.flutter.dev/flutter/dart-core/DateTime-class.html)
- [Package timeago](https://pub.dev/packages/timeago)
- [Package intl](https://pub.dev/packages/intl)

---

**Ngày cập nhật:** 26/10/2024
**Trạng thái:** ✅ Đã hoàn thành và test thành công

