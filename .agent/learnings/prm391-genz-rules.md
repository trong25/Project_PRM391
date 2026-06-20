# PRM391_GenZ - Development Rules & Agent Learnings

> **Dự án:** Ứng dụng Quản lý Khách sạn (PRM391_GenZ)
> **Công nghệ:** Flutter (Mobile/Web Frontend) + Spring Boot (Backend REST API)
> **Vai trò của bạn:** Người 5 (Thành) - Admin & Account Management
> **Cập nhật:** 2026

---

## 1. Phân chia Module & Trách nhiệm (Team 5 người)

- **Người 1 (Huy):** Customer Booking - Phụ trách luồng khách hàng (Xem, Search, Filter, Book phòng, Combo).
- **Người 2 (Chang):** Booking Management - Luồng nhân viên (Quản lý Booking, Check-in, Check-out, Trạng thái phòng).
- **Người 3 (Trọng):** Promotion - (Tạo mã giảm giá, Gửi thông báo, Áp dụng mã).
- **Người 4 (Cao):** Feedback - (Khách gửi feedback, Nhân viên/Admin trả lời).
- **Người 5 (Thành):** Admin & Account - (CRUD Room, CRUD User, Tạo tài khoản staff, Quản lý phân quyền ADMIN/STAFF/CUSTOMER).

*Lưu ý: Khi code tính năng của Thành, phải tập trung vào tính bảo mật, phân quyền và khả năng quản lý dữ liệu lớn (phân trang, search user).*

---

## 2. Kiến trúc Hệ thống (Architecture)

### 2.1 Backend (Spring Boot)
- **Cấu trúc:** Áp dụng mô hình chuẩn `Controller` -> `Service` -> `Repository` -> `Entity`.
- **API Standard:** Mọi RESTful API phải trả về một JSON format thống nhất: 
  ```json
  {
    "status": 200,
    "message": "Success",
    "data": { ... }
  }
  ```
- **Security & Auth:** Bắt buộc sử dụng **Spring Security + JWT**. API của Admin (Thành) như tạo User, sửa Room phải yêu cầu có `Authorization: Bearer <token>` và check Role (chỉ `ADMIN` mới được gọi).
- **Database:** Sử dụng Spring Data JPA, quản lý Schema chặt chẽ.

### 2.2 Frontend (Flutter)
- **State Management:** Thống nhất trong nhóm dùng 1 loại (ví dụ: `Provider` hoặc `GetX`).
- **Network:** Sử dụng package `dio` hoặc `http`. Bắt buộc tạo **Interceptor** để tự động gắn JWT Token vào header cho mọi request.
- **Cấu trúc thư mục Flutter:**
  - `lib/screens/`: Giao diện các trang.
  - `lib/widgets/`: Component dùng chung (CustomButton, CustomTextField...).
  - `lib/models/`: Chứa các data class từ API.
  - `lib/services/`: Chứa các hàm gọi API Spring Boot.

---

## 3. Quy tắc UI/UX cho Admin Dashboard (Thành)

- **Phong cách:** Không dùng Dark Neon. Yêu cầu giao diện **Clean, Minimalist, Professional** (dựa trên Material Design 3).
- **Readability:** Text phải dễ đọc (chữ đen/xám đậm trên nền trắng hoặc Dark Mode tiêu chuẩn của Flutter). Bảng danh sách User/Room phải có Padding hợp lý.
- **Components cốt lõi:**
  - **CRUD UI:** Luôn dùng `PaginatedDataTable` (bảng phân trang) hoặc `ListView` có chức năng Pull-to-refresh cho danh sách.
  - **Forms:** Sử dụng `Form` widget với validator đầy đủ (bắt lỗi bỏ trống, sai định dạng email, sai mật khẩu).
  - **Feedback:** Luôn hiển thị `CircularProgressIndicator` khi call API, hiển thị `SnackBar` báo lỗi hoặc thành công.

---

## 4. Common Bugs & Solutions (Dành riêng cho Fullstack)

### 4.1 Lỗi CORS khi Flutter Web gọi API Spring Boot
- **Vấn đề:** Trình duyệt chặn request vì khác domain.
- **Fix:** Ở Spring Boot, thêm Annotation `@CrossOrigin(origins = "*")` trên Controller hoặc config global CORS mapping.

### 4.2 Mất Token JWT khi restart App Flutter
- **Vấn đề:** Biến state bị reset, User bị văng ra màn login.
- **Fix:** Lưu token JWT vào thiết bị bằng package `flutter_secure_storage` hoặc `shared_preferences`. Khi mở app, check token trước khi điều hướng.

### 4.3 Quản lý trạng thái phòng bị lệch giữa Chang và Thành
- **Vấn đề:** Thành sửa tên phòng (CRUD Room), Chang cập nhật trạng thái phòng (Trống/Đã đặt).
- **Fix:** Đảm bảo API dùng chung bảng `Room`, có cơ chế khóa (Lock) hoặc validation cẩn thận: Không cho Thành (Admin) xóa phòng đang có khách ở (status != "AVAILABLE").

---

## 5. Mẫu nhắc việc (Prompt Trigger)
> Khi bạn muốn AI (Antigravity) code tính năng cho bạn, hãy nói: 
> **"@prm391-genz-rules.md Hãy code chức năng CRUD User bằng Flutter dựa theo chuẩn trong file này."**
