CREATE DATABASE GenzCinemaHotel

-- Bảng Hotel
CREATE TABLE Hotel (
    HotelId VARCHAR(50) PRIMARY KEY,
    name NVARCHAR(255) NOT NULL,
    address NVARCHAR(MAX),
    countRoom INT DEFAULT 0,
    phone VARCHAR(20)
);

-- Bảng Role (Phân quyền)
CREATE TABLE Role (
    RoleId VARCHAR(50) PRIMARY KEY,
    RoleName NVARCHAR(100) NOT NULL
);

INSERT INTO Role VALUES('ADMIN', 'Administrator'),('STAFF', 'Staff'),('CUSTOMER', 'Customer');

-- Bảng TypeRoom (Loại phòng)
CREATE TABLE TypeRoom (
    TypeRoomId VARCHAR(50) PRIMARY KEY,
    TypeRoom NVARCHAR(100) NOT NULL -- Tên loại phòng (VD: Standard, VIP)
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
    FOREIGN KEY (TypeRoomId) REFERENCES TypeRoom(TypeRoomId)
);

ALTER TABLE Room ADD HotelId VARCHAR(50);
ALTER TABLE Room ADD CONSTRAINT FK_Room_Hotel FOREIGN KEY (HotelId) REFERENCES Hotel(HotelId);

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