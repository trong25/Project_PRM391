-- =============================================
-- SAMPLE DATA cho GenzCinemaHotel
-- Copy toàn bộ file này vào SSMS và chạy F5
-- =============================================

USE GenzCinemaHotel;
GO

-- =============================================
-- 1. HOTELS (Chi nhánh khách sạn)
-- =============================================
INSERT INTO Hotel (HotelId, name, address, countRoom, phone) VALUES
('HOTEL001', N'GenzCinema Hà Nội', N'123 Hồ Hoàn Kiếm, Hoàn Kiếm, Hà Nội', 20, '024-1234-5678'),
('HOTEL002', N'GenzCinema TP. Hồ Chí Minh', N'456 Nguyễn Huệ, Quận 1, TP.HCM', 30, '028-8765-4321'),
('HOTEL003', N'GenzCinema Đà Nẵng', N'789 Bạch Đằng, Hải Châu, Đà Nẵng', 15, '0236-1122-334');
GO

-- =============================================
-- 2. TYPE ROOMS (Loại phòng)
-- =============================================
INSERT INTO TypeRoom (TypeRoomId, TypeRoom) VALUES
('TYPE001', N'Standard'),
('TYPE002', N'Superior'),
('TYPE003', N'Deluxe'),
('TYPE004', N'Suite'),
('TYPE005', N'Presidential Suite');
GO

-- =============================================
-- 3. TYPE BOOKINGS (Loại hình thuê)
-- =============================================
INSERT INTO TypeBooking (TypeBookingId, TypeName, BookingCode, DurationHours) VALUES
('TB001', N'Thuê theo giờ', 'HOURLY', 1),
('TB002', N'Qua đêm (12h-12h)', 'OVERNIGHT', 12),
('TB003', N'Thuê nguyên ngày', 'DAILY', 24),
('TB004', N'Thuê theo tuần', 'WEEKLY', 168);
GO

-- =============================================
-- 4. PRICE CONFIG (Bảng giá)
-- =============================================
INSERT INTO PriceConfig (TypeRoomId, TypeBookingId, Price) VALUES
-- Standard
('TYPE001', 'TB001', 150000),
('TYPE001', 'TB002', 350000),
('TYPE001', 'TB003', 500000),
('TYPE001', 'TB004', 2800000),
-- Superior
('TYPE002', 'TB001', 200000),
('TYPE002', 'TB002', 450000),
('TYPE002', 'TB003', 650000),
('TYPE002', 'TB004', 3800000),
-- Deluxe
('TYPE003', 'TB001', 280000),
('TYPE003', 'TB002', 600000),
('TYPE003', 'TB003', 900000),
('TYPE003', 'TB004', 5500000),
-- Suite
('TYPE004', 'TB001', 500000),
('TYPE004', 'TB002', 1200000),
('TYPE004', 'TB003', 1800000),
('TYPE004', 'TB004', 10000000),
-- Presidential Suite
('TYPE005', 'TB002', 3000000),
('TYPE005', 'TB003', 5000000);
GO

-- =============================================
-- 5. ROOMS (Phòng - gắn với Hotel & TypeRoom)
-- =============================================
-- Phòng Chi nhánh Hà Nội
INSERT INTO Room (RoomId, nameRoom, TypeRoomId, Status, HotelId) VALUES
('ROOM-HN-101', N'101', 'TYPE001', N'Trống', 'HOTEL001'),
('ROOM-HN-102', N'102', 'TYPE001', N'Đang thuê', 'HOTEL001'),
('ROOM-HN-201', N'201', 'TYPE002', N'Trống', 'HOTEL001'),
('ROOM-HN-202', N'202', 'TYPE002', N'Dọn dẹp', 'HOTEL001'),
('ROOM-HN-301', N'301', 'TYPE003', N'Trống', 'HOTEL001'),
('ROOM-HN-401', N'401', 'TYPE004', N'Trống', 'HOTEL001');

-- Phòng Chi nhánh HCM
INSERT INTO Room (RoomId, nameRoom, TypeRoomId, Status, HotelId) VALUES
('ROOM-HCM-101', N'101', 'TYPE001', N'Đang thuê', 'HOTEL002'),
('ROOM-HCM-102', N'102', 'TYPE001', N'Trống', 'HOTEL002'),
('ROOM-HCM-201', N'201', 'TYPE002', N'Trống', 'HOTEL002'),
('ROOM-HCM-301', N'301', 'TYPE003', N'Đang thuê', 'HOTEL002'),
('ROOM-HCM-302', N'302', 'TYPE003', N'Trống', 'HOTEL002'),
('ROOM-HCM-401', N'401', 'TYPE004', N'Bảo trì', 'HOTEL002'),
('ROOM-HCM-501', N'501', 'TYPE005', N'Trống', 'HOTEL002');

-- Phòng Chi nhánh Đà Nẵng
INSERT INTO Room (RoomId, nameRoom, TypeRoomId, Status, HotelId) VALUES
('ROOM-DN-101', N'101', 'TYPE001', N'Trống', 'HOTEL003'),
('ROOM-DN-102', N'102', 'TYPE001', N'Trống', 'HOTEL003'),
('ROOM-DN-201', N'201', 'TYPE002', N'Đang thuê', 'HOTEL003'),
('ROOM-DN-301', N'301', 'TYPE003', N'Trống', 'HOTEL003');
GO

-- =============================================
-- 6. USERS (Tài khoản - password đã hash sẵn cho "password123")
-- Note: Admin chính đã tạo qua API, chỉ thêm Staff & Customer mẫu
-- =============================================
-- Mật khẩu "password123" được hash bằng BCrypt strength 10
-- Hash: $2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy

INSERT INTO [User] (UserId, full_name, phone, email, password, RoleId) VALUES
-- Nhân viên Hà Nội
('USER-STAFF-001', N'Nguyễn Văn An', '0912345671', 'an.nguyen@genzcinema.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'STAFF'),
('USER-STAFF-002', N'Trần Thị Bình', '0912345672', 'binh.tran@genzcinema.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'STAFF'),
-- Nhân viên HCM
('USER-STAFF-003', N'Lê Văn Cường', '0912345673', 'cuong.le@genzcinema.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'STAFF'),
-- Giám đốc chi nhánh
('USER-ADMIN-001', N'Phạm Thị Dung', '0912345674', 'dung.pham@genzcinema.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'ADMIN'),
-- Khách hàng
('USER-CUST-001', N'Hoàng Văn Em', '0987654301', 'em.hoang@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'CUSTOMER'),
('USER-CUST-002', N'Vũ Thị Phương', '0987654302', 'phuong.vu@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'CUSTOMER'),
('USER-CUST-003', N'Đặng Minh Quân', '0987654303', 'quan.dang@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'CUSTOMER'),
('USER-CUST-004', N'Bùi Thị Lan', '0987654304', 'lan.bui@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'CUSTOMER');
GO

-- =============================================
-- 7. BOOKINGS (Lịch sử đặt phòng - đã thanh toán)
-- Dùng để test báo cáo Doanh thu theo Ngày/Tháng/Năm
-- =============================================
INSERT INTO Booking (RoomId, UserId, TypeBookingId, checkIn, checkOut, totalPrice, Status) VALUES

-- === Hà Nội ===
-- Tháng này (tháng 6/2026)
('ROOM-HN-101', 'USER-CUST-001', 'TB003', '2026-06-01 14:00', '2026-06-02 12:00', 500000, N'Đã thanh toán'),
('ROOM-HN-201', 'USER-CUST-002', 'TB002', '2026-06-05 20:00', '2026-06-06 08:00', 450000, N'Đã thanh toán'),
('ROOM-HN-301', 'USER-CUST-003', 'TB003', '2026-06-10 14:00', '2026-06-11 12:00', 900000, N'Đã thanh toán'),
('ROOM-HN-401', 'USER-CUST-001', 'TB003', '2026-06-15 14:00', '2026-06-16 12:00', 1800000, N'Đã thanh toán'),
('ROOM-HN-102', 'USER-CUST-004', 'TB002', '2026-06-18 20:00', '2026-06-19 08:00', 350000, N'Đang ở'),
-- Tháng trước (5/2026)
('ROOM-HN-101', 'USER-CUST-002', 'TB004', '2026-05-01 14:00', '2026-05-08 12:00', 2800000, N'Đã thanh toán'),
('ROOM-HN-201', 'USER-CUST-003', 'TB003', '2026-05-15 14:00', '2026-05-16 12:00', 650000, N'Đã thanh toán'),
-- Đầu năm (1/2026)
('ROOM-HN-301', 'USER-CUST-001', 'TB004', '2026-01-10 14:00', '2026-01-17 12:00', 5500000, N'Đã thanh toán'),
('ROOM-HN-401', 'USER-CUST-004', 'TB003', '2026-01-20 14:00', '2026-01-21 12:00', 1800000, N'Đã thanh toán'),

-- === HCM ===
-- Tháng này
('ROOM-HCM-101', 'USER-CUST-001', 'TB003', '2026-06-03 14:00', '2026-06-04 12:00', 500000, N'Đã thanh toán'),
('ROOM-HCM-201', 'USER-CUST-002', 'TB003', '2026-06-08 14:00', '2026-06-09 12:00', 650000, N'Đã thanh toán'),
('ROOM-HCM-301', 'USER-CUST-003', 'TB004', '2026-06-12 14:00', '2026-06-13 12:00', 1800000, N'Đã thanh toán'),
('ROOM-HCM-501', 'USER-CUST-004', 'TB003', '2026-06-16 14:00', '2026-06-17 12:00', 5000000, N'Đã thanh toán'),
-- Tháng trước
('ROOM-HCM-301', 'USER-CUST-001', 'TB004', '2026-05-10 14:00', '2026-05-17 12:00', 5500000, N'Đã thanh toán'),
('ROOM-HCM-401', 'USER-CUST-002', 'TB003', '2026-05-20 14:00', '2026-05-21 12:00', 1800000, N'Đã thanh toán'),
-- Đầu năm
('ROOM-HCM-501', 'USER-CUST-003', 'TB003', '2026-02-14 14:00', '2026-02-15 12:00', 5000000, N'Đã thanh toán'),

-- === Đà Nẵng ===
-- Tháng này
('ROOM-DN-101', 'USER-CUST-002', 'TB003', '2026-06-04 14:00', '2026-06-05 12:00', 500000, N'Đã thanh toán'),
('ROOM-DN-201', 'USER-CUST-003', 'TB003', '2026-06-14 14:00', '2026-06-15 12:00', 650000, N'Đã thanh toán'),
-- Tháng trước
('ROOM-DN-301', 'USER-CUST-004', 'TB004', '2026-05-05 14:00', '2026-05-12 12:00', 5500000, N'Đã thanh toán');
GO

-- =============================================
-- KIỂM TRA DỮ LIỆU
-- =============================================
SELECT 'Hotels' AS [Bảng], COUNT(*) AS [Số bản ghi] FROM Hotel
UNION ALL SELECT 'TypeRoom', COUNT(*) FROM TypeRoom
UNION ALL SELECT 'TypeBooking', COUNT(*) FROM TypeBooking
UNION ALL SELECT 'PriceConfig', COUNT(*) FROM PriceConfig
UNION ALL SELECT 'Room', COUNT(*) FROM Room
UNION ALL SELECT '[User]', COUNT(*) FROM [User]
UNION ALL SELECT 'Booking', COUNT(*) FROM Booking;
GO
