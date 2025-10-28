# Hướng dẫn Tính năng Tự động Đăng nhập

## Tổng quan
Ứng dụng hiện đã có tính năng tự động đăng nhập khi người dùng thoát và quay lại ứng dụng, nếu token đã được lưu và còn hiệu lực.

## Cách hoạt động

### 1. Lưu Token khi Đăng nhập
Khi người dùng đăng nhập thành công:
- Token JWT được lưu vào `SharedPreferences` với key `jwt_token`
- Token này được sử dụng để xác thực các API request sau này
- Được thực hiện tự động trong `AuthService.login()`

### 2. Kiểm tra Token khi Khởi động
Khi ứng dụng được mở:
- **SplashScreen** được hiển thị đầu tiên
- Tự động gọi `AuthService.autoLogin()` để kiểm tra token
- Quá trình kiểm tra:
  - ✅ Kiểm tra token có tồn tại trong SharedPreferences không
  - ✅ Kiểm tra token có hết hạn không (sử dụng `JwtDecoder.isExpired()`)
  - ✅ Decode token để lấy thông tin người dùng

### 3. Điều hướng Tự động

#### Token hợp lệ
- ✅ Tự động chuyển đến `MainNavigationScreen`
- ✅ Người dùng không cần đăng nhập lại
- ✅ Tiết kiệm thời gian và cải thiện trải nghiệm người dùng

#### Token không hợp lệ hoặc hết hạn
- ❌ Token hết hạn được tự động xóa
- ❌ Chuyển đến `LoginScreen`
- ❌ Yêu cầu người dùng đăng nhập lại

### 4. Đăng xuất
Khi người dùng đăng xuất:
- Token được xóa khỏi SharedPreferences
- Chuyển về màn hình đăng nhập
- Lần khởi động tiếp theo sẽ yêu cầu đăng nhập lại

## Cấu trúc Code

### Files liên quan

#### 1. `lib/services/auth_service.dart`
Các phương thức quan trọng:
```dart
// Lấy token đã lưu
Future<String?> getStoredToken()

// Kiểm tra token có hợp lệ không
bool isTokenValid(String token)

// Tự động đăng nhập
Future<Map<String, dynamic>> autoLogin()

// Đăng xuất và xóa token
Future<bool> logout()
```

#### 2. `lib/screens/splash_screen.dart`
- Màn hình hiển thị khi khởi động app
- Gọi `autoLogin()` và điều hướng dựa trên kết quả
- Hiển thị loading indicator trong khi kiểm tra

#### 3. `lib/routes.dart`
- `home: (context) => const SplashScreen()` - Route khởi động
- SplashScreen là màn hình đầu tiên được hiển thị

#### 4. `lib/main.dart`
- `initialRoute: AppRoutes.home` - Bắt đầu từ SplashScreen

## Flow Chart

```
App Start
    ↓
SplashScreen
    ↓
AutoLogin Check
    ↓
    ├─→ Token exists? ─→ No ─→ LoginScreen
    ↓                     
   Yes
    ↓
    ├─→ Token valid? ─→ No ─→ Clear token → LoginScreen
    ↓                     
   Yes
    ↓
MainNavigationScreen
```

## Thời gian Hiệu lực Token

Token JWT có thời gian hết hạn được set từ server. Khi token hết hạn:
- `JwtDecoder.isExpired(token)` sẽ trả về `true`
- Token sẽ được tự động xóa
- Người dùng cần đăng nhập lại

## Testing

### Test Case 1: Đăng nhập lần đầu
1. Mở app → Thấy SplashScreen → Chuyển đến LoginScreen
2. Đăng nhập thành công → Chuyển đến MainNavigationScreen
3. Token được lưu vào SharedPreferences

### Test Case 2: Quay lại app (Token còn hạn)
1. Thoát app (không logout)
2. Mở lại app → Thấy SplashScreen
3. **Tự động đăng nhập** → Chuyển đến MainNavigationScreen
4. Không cần nhập thông tin đăng nhập

### Test Case 3: Quay lại app (Token hết hạn)
1. Đợi token hết hạn
2. Mở lại app → Thấy SplashScreen
3. Token hết hạn được phát hiện và xóa
4. Chuyển đến LoginScreen
5. Yêu cầu đăng nhập lại

### Test Case 4: Đăng xuất
1. Click nút logout trong MainMenuScreen
2. Xác nhận đăng xuất
3. Token được xóa
4. Chuyển về LoginScreen
5. Lần mở app tiếp theo yêu cầu đăng nhập

## Bảo mật

### ✅ Các biện pháp bảo mật
- Token được lưu an toàn trong SharedPreferences (encrypted on Android)
- Token tự động bị xóa khi hết hạn
- Không lưu password
- Kiểm tra token validity trước mỗi auto-login

### ⚠️ Lưu ý
- SharedPreferences trên Android tự động mã hóa
- Trên iOS, sử dụng Keychain thông qua SharedPreferences
- Token không nên có thời hạn quá dài (khuyến nghị < 30 ngày)

## Debug

### Enable debug logs
Các phương thức trong `AuthService` đã có debug prints:
```
[AuthService] ===== AUTO LOGIN START =====
[AuthService] No stored token found / Token expired / Auto login SUCCESS
[AuthService] ===== AUTO LOGIN END =====
```

Xem console logs để debug:
- Token có tồn tại không
- Token có hết hạn không
- Auto-login thành công hay thất bại

## Changelog

### Version 1.0 - Tính năng mới
- ✅ Thêm auto-login với token đã lưu
- ✅ Kiểm tra token validity
- ✅ SplashScreen với loading indicator
- ✅ Tự động điều hướng dựa trên token status
- ✅ Debug logging đầy đủ

