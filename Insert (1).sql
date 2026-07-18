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
    '$2a$10$xJZIGPQiCx2/KFXhsKsw0evQoqyNpq7Y1s24vzhfoKsEzeKIMxO5m',
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
-- Room (4 Queen + 5 King mỗi cơ sở)
INSERT INTO Room (RoomId, nameRoom, TypeRoomId, Status, HotelId, imageUrl) VALUES
('HN001_201', N'201 Barbie Hà Đông', 'QUEEN', N'Trống', 'HN001', NULL),
('HN001_202', N'202 DC Hà Đông', 'QUEEN', N'Trống', 'HN001', NULL),
('HN001_301', N'301 Japan Hà Đông', 'QUEEN', N'Trống', 'HN001', NULL),
('HN001_302', N'302 Football Hà Đông', 'QUEEN', N'Trống', 'HN001', NULL),
('HN001_401', N'401 Gaming Hà Đông', 'KING', N'Trống', 'HN001', NULL),
('HN001_402', N'402 HongKong Hà Đông', 'KING', N'Trống', 'HN001', NULL),
('HN001_501', N'501 Hội An Hà Đông', 'KING', N'Trống', 'HN001', NULL),
('HN001_502', N'502 Teddy Hà Đông', 'KING', N'Trống', 'HN001', NULL),
('HN001_602', N'602 Onepice Hà Đông', 'KING', N'Trống', 'HN001', NULL),

('HN002_201', N'201 Barbie Đông Đa', 'QUEEN', N'Trống', 'HN002', NULL),
('HN002_202', N'202 DC Đông Đa', 'QUEEN', N'Trống', 'HN002', NULL),
('HN002_301', N'301 Japan Đông Đa', 'QUEEN', N'Trống', 'HN002', NULL),
('HN002_302', N'302 Football Đông Đa', 'QUEEN', N'Trống', 'HN002', NULL),
('HN002_401', N'401 Gaming Đông Đa', 'KING', N'Trống', 'HN002', NULL),
('HN002_402', N'402 HongKong Đông Đa', 'KING', N'Trống', 'HN002', NULL),
('HN002_501', N'501 Hội An Đông Đa', 'KING', N'Trống', 'HN002', NULL),
('HN002_502', N'502 Teddy Đông Đa', 'KING', N'Trống', 'HN002', NULL),
('HN002_602', N'602 Onepice Đông Đa', 'KING', N'Trống', 'HN002', NULL),

('HN003_201', N'201 Barbie Hai Bà Trưng', 'QUEEN', N'Trống', 'HN003', NULL),
('HN003_202', N'202 DC Hai Bà Trưng', 'QUEEN', N'Trống', 'HN003', NULL),
('HN003_301', N'301 Japan Hai Bà Trưng', 'QUEEN', N'Trống', 'HN003', NULL),
('HN003_302', N'302 Football Hai Bà Trưng', 'QUEEN', N'Trống', 'HN003', NULL),
('HN003_401', N'401 Gaming Hai Bà Trưng', 'KING', N'Trống', 'HN003', NULL),
('HN003_402', N'402 HongKong Hai Bà Trưng', 'KING', N'Trống', 'HN003', NULL),
('HN003_501', N'501 Hội An Hai Bà Trưng', 'KING', N'Trống', 'HN003', NULL),
('HN003_502', N'502 Teddy Hai Bà Trưng', 'KING', N'Trống', 'HN003', NULL),
('HN003_602', N'602 Onepice Hai Bà Trưng', 'KING', N'Trống', 'HN003', NULL),

('HN004_201', N'201 Barbie Thanh Xuân', 'QUEEN', N'Trống', 'HN004', NULL),
('HN004_202', N'202 DC Thanh Xuân', 'QUEEN', N'Trống', 'HN004', NULL),
('HN004_301', N'301 Japan Thanh Xuân', 'QUEEN', N'Trống', 'HN004', NULL),
('HN004_302', N'302 Football Thanh Xuân', 'QUEEN', N'Trống', 'HN004', NULL),
('HN004_401', N'401 Gaming Thanh Xuân', 'KING', N'Trống', 'HN004', NULL),
('HN004_402', N'402 HongKong Thanh Xuân', 'KING', N'Trống', 'HN004', NULL),
('HN004_501', N'501 Hội An Thanh Xuân', 'KING', N'Trống', 'HN004', NULL),
('HN004_502', N'502 Teddy Thanh Xuân', 'KING', N'Trống', 'HN004', NULL),
('HN004_602', N'602 Onepice Thanh Xuân', 'KING', N'Trống', 'HN004', NULL),

('HN005_201', N'201 Barbie Cầu Giấy', 'QUEEN', N'Trống', 'HN005', NULL),
('HN005_202', N'202 DC Cầu Giấy', 'QUEEN', N'Trống', 'HN005', NULL),
('HN005_301', N'301 Japan Cầu Giấy', 'QUEEN', N'Trống', 'HN005', NULL),
('HN005_302', N'302 Football Cầu Giấy', 'QUEEN', N'Trống', 'HN005', NULL),
('HN005_401', N'401 Gaming Cầu Giấy', 'KING', N'Trống', 'HN005', NULL),
('HN005_402', N'402 HongKong Cầu Giấy', 'KING', N'Trống', 'HN005', NULL),
('HN005_501', N'501 Hội An Cầu Giấy', 'KING', N'Trống', 'HN005', NULL),
('HN005_502', N'502 Teddy Cầu Giấy', 'KING', N'Trống', 'HN005', NULL),
('HN005_602', N'602 Onepice Cầu Giấy', 'KING', N'Trống', 'HN005', NULL),

('HN006_201', N'201 Barbie Tây Hồ', 'QUEEN', N'Trống', 'HN006', NULL),
('HN006_202', N'202 DC Tây Hồ', 'QUEEN', N'Trống', 'HN006', NULL),
('HN006_301', N'301 Japan Tây Hồ', 'QUEEN', N'Trống', 'HN006', NULL),
('HN006_302', N'302 Football Tây Hồ', 'QUEEN', N'Trống', 'HN006', NULL),
('HN006_401', N'401 Gaming Tây Hồ', 'KING', N'Trống', 'HN006', NULL),
('HN006_402', N'402 HongKong Tây Hồ', 'KING', N'Trống', 'HN006', NULL),
('HN006_501', N'501 Hội An Tây Hồ', 'KING', N'Trống', 'HN006', NULL),
('HN006_502', N'502 Teddy Tây Hồ', 'KING', N'Trống', 'HN006', NULL),
('HN006_602', N'602 Onepice Tây Hồ', 'KING', N'Trống', 'HN006', NULL),

('HN007_201', N'201 Barbie Quang Trung', 'QUEEN', N'Trống', 'HN007', NULL),
('HN007_202', N'202 DC Quang Trung', 'QUEEN', N'Trống', 'HN007', NULL),
('HN007_301', N'301 Japan Quang Trung', 'QUEEN', N'Trống', 'HN007', NULL),
('HN007_302', N'302 Football Quang Trung', 'QUEEN', N'Trống', 'HN007', NULL),
('HN007_401', N'401 Gaming Quang Trung', 'KING', N'Trống', 'HN007', NULL),
('HN007_402', N'402 HongKong Quang Trung', 'KING', N'Trống', 'HN007', NULL),
('HN007_501', N'501 Hội An Quang Trung', 'KING', N'Trống', 'HN007', NULL),
('HN007_502', N'502 Teddy Quang Trung', 'KING', N'Trống', 'HN007', NULL),
('HN007_602', N'602 Onepice Quang Trung', 'KING', N'Trống', 'HN007', NULL),

('HN008_201', N'201 Barbie Bắc Từ Liêm', 'QUEEN', N'Trống', 'HN008', NULL),
('HN008_202', N'202 DC Bắc Từ Liêm', 'QUEEN', N'Trống', 'HN008', NULL),
('HN008_301', N'301 Japan Bắc Từ Liêm', 'QUEEN', N'Trống', 'HN008', NULL),
('HN008_302', N'302 Football Bắc Từ Liêm', 'QUEEN', N'Trống', 'HN008', NULL),
('HN008_401', N'401 Gaming Bắc Từ Liêm', 'KING', N'Trống', 'HN008', NULL),
('HN008_402', N'402 HongKong Bắc Từ Liêm', 'KING', N'Trống', 'HN008', NULL),
('HN008_501', N'501 Hội An Bắc Từ Liêm', 'KING', N'Trống', 'HN008', NULL),
('HN008_502', N'502 Teddy Bắc Từ Liêm', 'KING', N'Trống', 'HN008', NULL),
('HN008_602', N'602 Onepice Bắc Từ Liêm', 'KING', N'Trống', 'HN008', NULL),

('HN009_201', N'201 Barbie Thanh Liệt', 'QUEEN', N'Trống', 'HN009', NULL),
('HN009_202', N'202 DC Thanh Liệt', 'QUEEN', N'Trống', 'HN009', NULL),
('HN009_301', N'301 Japan Thanh Liệt', 'QUEEN', N'Trống', 'HN009', NULL),
('HN009_302', N'302 Football Thanh Liệt', 'QUEEN', N'Trống', 'HN009', NULL),
('HN009_401', N'401 Gaming Thanh Liệt', 'KING', N'Trống', 'HN009', NULL),
('HN009_402', N'402 HongKong Thanh Liệt', 'KING', N'Trống', 'HN009', NULL),
('HN009_501', N'501 Hội An Thanh Liệt', 'KING', N'Trống', 'HN009', NULL),
('HN009_502', N'502 Teddy Thanh Liệt', 'KING', N'Trống', 'HN009', NULL),
('HN009_602', N'602 Onepice Thanh Liệt', 'KING', N'Trống', 'HN009', NULL);
