CREATE DATABASE GenzCinemaHotel
GO
USE GenzCinemaHotel
GO

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
    LastSeenAt DATETIME NULL, -- [MỚI] phục vụ hiển thị online/offline trong chat
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
    PriceConfigId INT IDENTITY(1,1) PRIMARY KEY,
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
    guestName NVARCHAR(255) NULL,
    guestPhone VARCHAR(20) NULL,
    paidAt DATETIME NULL,
    voucherCode VARCHAR(50) NULL,
    discountAmount DECIMAL(18, 2) NULL DEFAULT 0.00,
    note NVARCHAR(MAX) NULL,

    FOREIGN KEY (RoomId) REFERENCES Room(RoomId),
    FOREIGN KEY (UserId) REFERENCES [User](UserId),
    FOREIGN KEY (TypeBookingId) REFERENCES TypeBooking(TypeBookingId)
);

-- Bảng lưu token
CREATE TABLE PasswordResetToken (
    token        VARCHAR(255) PRIMARY KEY,
    expiryTime   DATETIME     NOT NULL,
    isUsed       BIT          NOT NULL DEFAULT 0,
    UserId       VARCHAR(50),
    FOREIGN KEY (UserId) REFERENCES [User](UserId)
);


--Bảng quản lý phiên chat
CREATE TABLE Conversation (
    ConversationId VARCHAR(50) PRIMARY KEY,
    CustomerId VARCHAR(50) NOT NULL,
    StaffId VARCHAR(50) NULL,              -- staff đang phụ trách, NULL = chưa ai nhận
    BookingId INT NULL,                    -- optional: gắn hội thoại với 1 booking cụ thể
    Status NVARCHAR(50) DEFAULT N'Open',   -- Open, Pending, Closed
    CreatedAt DATETIME DEFAULT GETDATE(),
    LastMessageAt DATETIME NULL,
    FOREIGN KEY (CustomerId) REFERENCES [User](UserId),
    FOREIGN KEY (StaffId) REFERENCES [User](UserId),
    FOREIGN KEY (BookingId) REFERENCES Booking(BookingId)
);

-- Bảng CSKH (ChatMessage)


CREATE TABLE [dbo].[ChatMessage] (
    [id]              BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [ConversationId]  VARCHAR(50)          NOT NULL, -- [MỚI] gắn tin nhắn vào 1 hội thoại
    [sender_id]       VARCHAR(50)          NOT NULL,
    [sender_name]     NVARCHAR(255)        NOT NULL,
    [receiver_id]     VARCHAR(50)          NULL,     -- giữ lại để tương thích ngược, không bắt buộc
    [content]         NVARCHAR(MAX)        NOT NULL,
    [message_type]    VARCHAR(20)          NOT NULL DEFAULT 'TEXT', -- [MỚI] TEXT, IMAGE, FILE, SYSTEM
    [attachment_url]  VARCHAR(MAX)         NULL,     -- [MỚI] link ảnh/file nếu có
    [sent_at]         DATETIME2(6)         NOT NULL DEFAULT GETDATE(),
    [is_read]         BIT                  NOT NULL DEFAULT 0,

    FOREIGN KEY (ConversationId) REFERENCES Conversation(ConversationId),
    FOREIGN KEY (sender_id) REFERENCES [User](UserId),
    FOREIGN KEY (receiver_id) REFERENCES [User](UserId)
);

-- Bảng Voucher
CREATE TABLE DiscountCode (
    DiscountId INT IDENTITY(1,1) PRIMARY KEY,
    Code VARCHAR(50) UNIQUE NOT NULL,
    Description NVARCHAR(255),
    DiscountType VARCHAR(20) NOT NULL,       -- PERCENT / AMOUNT
    DiscountValue DECIMAL(18,2) NOT NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NOT NULL,
    Quantity INT DEFAULT 0,
    Status NVARCHAR(50) DEFAULT N'Active'    -- Active / Expired / Disable
);


-- Index phục vụ truy vấn chat real-time
CREATE INDEX IX_ChatMessage_Conversation_SentAt ON ChatMessage(ConversationId, sent_at);
CREATE INDEX IX_Conversation_Staff_Status ON Conversation(StaffId, Status);
CREATE INDEX IX_Conversation_LastMessageAt ON Conversation(LastMessageAt DESC);
