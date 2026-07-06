INSERT INTO Role VALUES
('ADMIN', 'Administrator'),
('STAFF', 'Staff'),
('CUSTOMER', 'Customer');

--LƯU Ý:Vào main backend chạy hash để lấy mk mã hóa của admin, thay dãy kí tự ở password trước khi Insert
-- Admin account
-- Email: admin@genzcinema.com
-- Password: 123456
INSERT INTO [User] (
    UserId,
    full_name,
    phone,
    email,
    password,
    Image_cccd,
    RoleId
)
VALUES (
    'ADMIN01',
    N'Administrator',
    '0123456789',
    'admin@genzhotel.com',
    '$2a$10$7EqJtq98hPqEX7fNZaFWoOHi6M9Z9zV0gF4m4u2g7G8Y9i5xXQ7iG',
    NULL,
    'ADMIN'
);

-- TypeRoom
INSERT INTO TypeRoom (TypeRoomId, TypeRoom, pricePerHour) VALUES
('QUEEN', N'Phòng Queen', 96000),
('KING',  N'Phòng King',  106000);
-- TypeBooking
INSERT INTO TypeBooking (TypeBookingId, TypeName, BookingCode, DurationHours) VALUES
('TB_2H',    N'Combo 2h xem phim + đồ ăn',        'COMBO_2H',    2),
('TB_4H',    N'Combo 4h',                           'COMBO_4H',    4),
('TB_5H',    N'Combo 5h',                           'COMBO_5H',    5),
('TB_6H',    N'Combo 6h',                           'COMBO_6H',    6),
('TB_DAY',   N'Combo ngày 7h-12h (1 nước pha chế)', 'COMBO_DAY',   5),
('TB_NIGHT', N'Combo đêm 23h-7h (1 nước pha chế)',  'COMBO_NIGHT', 8);
-- PriceConfig
INSERT INTO PriceConfig (TypeRoomId, TypeBookingId, Price) VALUES
('QUEEN', 'TB_2H',    276000),
('KING',  'TB_2H',    286000),
('QUEEN', 'TB_4H',    296000),
('KING',  'TB_4H',    326000),
('QUEEN', 'TB_5H',    366000),
('KING',  'TB_5H',    396000),
('QUEEN', 'TB_6H',    416000),
('KING',  'TB_6H',    446000),
('QUEEN', 'TB_DAY',   196000),
('KING',  'TB_DAY',   246000),
('QUEEN', 'TB_NIGHT', 296000),
('KING',  'TB_NIGHT', 336000);
-- Hotel (9 cơ sở thật)
INSERT INTO Hotel (HotelId, name, address, countRoom, phone, imageUrl) VALUES
('HN001', N'GenZ Cinema - Hà Đông',      N'Lk13 Ngõ 2 Nguyễn Văn Lộc, P. Mộ Lao, Hà Đông, Hà Nội',           4, '0866521881', NULL),
('HN002', N'GenZ Cinema - Đống Đa',      N'Số 3 Ngõ 180 P. Nguyễn Lương Bằng, Quang Trung, Đống Đa, Hà Nội',  4, '0325186385', NULL),
('HN003', N'GenZ Cinema - Hai Bà Trưng', N'130 P. Tân Khai, Vĩnh Hưng, Hai Bà Trưng, Hà Nội',                 4, '0989838603', NULL),
('HN004', N'GenZ Cinema - Thanh Xuân',   N'103 P. Hoàng Ngân, Nhân Chính, Thanh Xuân, Hà Nội',                 4, '0823983881', NULL),
('HN005', N'GenZ Cinema - Cầu Giấy',     N'24 P. Hoa Bằng, Yên Hoà, Cầu Giấy, Hà Nội',                        4, '0877155379', NULL),
('HN006', N'GenZ Cinema - Tây Hồ',       N'135 P. Nhật Chiêu, Nhật Tân, Tây Hồ, Hà Nội',                      4, '0838408881', NULL),
('HN007', N'GenZ Cinema - Quang Trung',  N'86-88 P. Nguyễn Lương Bằng, Quang Trung, Hà Nội',                   4, '0816018881', NULL),
('HN008', N'GenZ Cinema - Bắc Từ Liêm',  N'462 Đ. Hoàng Công Chất, Cầu Diễn, Bắc Từ Liêm, Hà Nội',           4, '0846298881', NULL),
('HN009', N'GenZ Cinema - Thanh Liệt',   N'06-N05 khu tái định cư xóm chùa, Triều Khúc, Thanh Liệt, Hà Nội',  4, '0823660705', NULL);
-- Room (2 Queen + 2 King mỗi cơ sở)
INSERT INTO Room (RoomId, nameRoom, TypeRoomId, Status, HotelId, imageUrl) VALUES
('HN001_Q01', N'Queen 01', 'QUEEN', N'Trống', 'HN001', NULL),
('HN001_Q02', N'Queen 02', 'QUEEN', N'Trống', 'HN001', NULL),
('HN001_K01', N'King 01',  'KING',  N'Trống', 'HN001', NULL),
('HN001_K02', N'King 02',  'KING',  N'Trống', 'HN001', NULL),
('HN002_Q01', N'Queen 01', 'QUEEN', N'Trống', 'HN002', NULL),
('HN002_Q02', N'Queen 02', 'QUEEN', N'Trống', 'HN002', NULL),
('HN002_K01', N'King 01',  'KING',  N'Trống', 'HN002', NULL),
('HN002_K02', N'King 02',  'KING',  N'Trống', 'HN002', NULL),
('HN003_Q01', N'Queen 01', 'QUEEN', N'Trống', 'HN003', NULL),
('HN003_Q02', N'Queen 02', 'QUEEN', N'Trống', 'HN003', NULL),
('HN003_K01', N'King 01',  'KING',  N'Trống', 'HN003', NULL),
('HN003_K02', N'King 02',  'KING',  N'Trống', 'HN003', NULL),
('HN004_Q01', N'Queen 01', 'QUEEN', N'Trống', 'HN004', NULL),
('HN004_Q02', N'Queen 02', 'QUEEN', N'Trống', 'HN004', NULL),
('HN004_K01', N'King 01',  'KING',  N'Trống', 'HN004', NULL),
('HN004_K02', N'King 02',  'KING',  N'Trống', 'HN004', NULL),
('HN005_Q01', N'Queen 01', 'QUEEN', N'Trống', 'HN005', NULL),
('HN005_Q02', N'Queen 02', 'QUEEN', N'Trống', 'HN005', NULL),
('HN005_K01', N'King 01',  'KING',  N'Trống', 'HN005', NULL),
('HN005_K02', N'King 02',  'KING',  N'Trống', 'HN005', NULL),
('HN006_Q01', N'Queen 01', 'QUEEN', N'Trống', 'HN006', NULL),
('HN006_Q02', N'Queen 02', 'QUEEN', N'Trống', 'HN006', NULL),
('HN006_K01', N'King 01',  'KING',  N'Trống', 'HN006', NULL),
('HN006_K02', N'King 02',  'KING',  N'Trống', 'HN006', NULL),
('HN007_Q01', N'Queen 01', 'QUEEN', N'Trống', 'HN007', NULL),
('HN007_Q02', N'Queen 02', 'QUEEN', N'Trống', 'HN007', NULL),
('HN007_K01', N'King 01',  'KING',  N'Trống', 'HN007', NULL),
('HN007_K02', N'King 02',  'KING',  N'Trống', 'HN007', NULL),
('HN008_Q01', N'Queen 01', 'QUEEN', N'Trống', 'HN008', NULL),
('HN008_Q02', N'Queen 02', 'QUEEN', N'Trống', 'HN008', NULL),
('HN008_K01', N'King 01',  'KING',  N'Trống', 'HN008', NULL),
('HN008_K02', N'King 02',  'KING',  N'Trống', 'HN008', NULL),
('HN009_Q01', N'Queen 01', 'QUEEN', N'Trống', 'HN009', NULL),
('HN009_Q02', N'Queen 02', 'QUEEN', N'Trống', 'HN009', NULL),
('HN009_K01', N'King 01',  'KING',  N'Trống', 'HN009', NULL),
('HN009_K02', N'King 02',  'KING',  N'Trống', 'HN009', NULL);
