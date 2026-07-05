CREATE DATABASE GenzCinemaHotel

-- Bảng Hotel
CREATE TABLE Hotel (
    HotelId VARCHAR(50) PRIMARY KEY,
    name NVARCHAR(255) NOT NULL,
    address NVARCHAR(MAX),
    countRoom INT DEFAULT 0,
    phone VARCHAR(20),
    imageUrl VARCHAR(MAX) -- Cột lưu ảnh cơ sở
);
-- Bảng Role (Phân quyền)
CREATE TABLE Role (
    RoleId VARCHAR(50) PRIMARY KEY,
    RoleName NVARCHAR(100) NOT NULL
);

-- Bảng TypeRoom (Loại phòng)
CREATE TABLE TypeRoom (
    TypeRoomId VARCHAR(50) PRIMARY KEY,
    TypeRoom NVARCHAR(100) NOT NULL, -- Tên loại phòng (VD: Standard, VIP)
    pricePerHour DECIMAL(18,2) NULL
);
-- Bảng TypeBooking (Loại hình thuê)
CREATE TABLE TypeBooking (
    TypeBookingId VARCHAR(50) PRIMARY KEY,
    TypeName NVARCHAR(100) NOT NULL,
    BookingCode VARCHAR(50) NOT NULL,
    DurationHours INT NULL -- Có thể Null nếu là thuê theo giờ linh hoạt
);
-- Bảng User (Phụ thuộc vào Role)
CREATE TABLE [User] (
    UserId VARCHAR(50) PRIMARY KEY,
    full_name NVARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    password VARCHAR(255) NOT NULL,
    Image_cccd VARCHAR(MAX), -- Lưu đường dẫn ảnh hoặc chuỗi Base64
    RoleId VARCHAR(50),
    FOREIGN KEY (RoleId) REFERENCES Role(RoleId)
);
-- Bảng Room (Phụ thuộc vào TypeRoom)
CREATE TABLE Room (
    RoomId VARCHAR(50) PRIMARY KEY,
    nameRoom NVARCHAR(100) NOT NULL,
    TypeRoomId VARCHAR(50),
    Status NVARCHAR(50), -- Trạng thái phòng (VD: Trống, Đang thuê, Dọn dẹp)
    HotelId VARCHAR(50),
    imageUrl VARCHAR(MAX), -- Cột lưu ảnh phòng
    FOREIGN KEY (TypeRoomId) REFERENCES TypeRoom(TypeRoomId),
    FOREIGN KEY (HotelId) REFERENCES Hotel(HotelId)
);
-- Bảng PriceConfig (Phụ thuộc vào TypeRoom và TypeBooking)
CREATE TABLE PriceConfig (
    PriceConfigId INT IDENTITY(1,1) PRIMARY KEY, -- Dùng số tự tăng cho ID bảng cấu hình
    TypeRoomId VARCHAR(50) NOT NULL,
    TypeBookingId VARCHAR(50) NOT NULL,
    Price DECIMAL(18, 2) NOT NULL,
    FOREIGN KEY (TypeRoomId) REFERENCES TypeRoom(TypeRoomId),
    FOREIGN KEY (TypeBookingId) REFERENCES TypeBooking(TypeBookingId)
);
-- Bảng Booking (Phụ thuộc vào Room, User, TypeBooking)
CREATE TABLE Booking (
    BookingId INT IDENTITY(1,1) PRIMARY KEY, 
    RoomId VARCHAR(50) NOT NULL,
    UserId VARCHAR(50) NOT NULL,
    TypeBookingId VARCHAR(50) NOT NULL,
    checkIn DATETIME NOT NULL,
    checkOut DATETIME NULL,
    totalPrice DECIMAL(18, 2),
    Status NVARCHAR(50), -- Trạng thái Booking (VD: Đã thanh toán, Chưa thanh toán, Đã hủy)
    voucherCode VARCHAR(50) NULL,
    discountAmount DECIMAL(18, 2) NULL DEFAULT 0.00,
    note NVARCHAR(MAX) NULL,
    
    FOREIGN KEY (RoomId) REFERENCES Room(RoomId),
    FOREIGN KEY (UserId) REFERENCES [User](UserId),
    FOREIGN KEY (TypeBookingId) REFERENCES TypeBooking(TypeBookingId)
);

--Bảng lưu token
CREATE TABLE PasswordResetToken (
    token        VARCHAR(255) PRIMARY KEY,
    expiryTime   DATETIME     NOT NULL,
    isUsed       BIT          NOT NULL DEFAULT 0,
    UserId       VARCHAR(50),
    FOREIGN KEY (UserId) REFERENCES [User](UserId)
);

--Bảng lưu tin nhắn Chat
CREATE TABLE [dbo].[ChatMessage] (
    [id]          BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [sender_id]   VARCHAR(50)          NOT NULL,
    [sender_name] NVARCHAR(255)        NOT NULL,
    [receiver_id] VARCHAR(50)          NOT NULL,
    [content]     NVARCHAR(MAX)        NOT NULL,
    [sent_at]     DATETIME2(6)         NOT NULL DEFAULT GETDATE(),
    [is_read]     BIT                  NOT NULL DEFAULT 0
);

--Bảng Voucher
CREATE TABLE DiscountCode (
    DiscountId INT IDENTITY(1,1) PRIMARY KEY,
    Code VARCHAR(50) UNIQUE NOT NULL,-- Mã giảm giá: VD GENZ20, SUMMER50
    Description NVARCHAR(255),-- Nội dung giảm giá
    DiscountType VARCHAR(20) NOT NULL,-- PERCENT: giảm theo %
    -- AMOUNT: giảm tiền trực tiếp
    DiscountValue DECIMAL(18,2) NOT NULL,-- Giá trị giảm
    StartDate DATETIME NOT NULL,  -- Ngày bắt đầu áp dụng
    EndDate DATETIME NOT NULL,-- Ngày hết hạn
    Quantity INT DEFAULT 0,-- Số lượng mã phát hành
    Status NVARCHAR(50) DEFAULT N'Active'    -- Active: đang sử dụng
    -- Expired: hết hạn
    -- Disable: khóa
);



