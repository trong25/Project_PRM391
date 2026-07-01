package genZ.PRM391GenZ.config;

import lombok.RequiredArgsConstructor;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@RequiredArgsConstructor
public class UnicodeDataMigration implements ApplicationRunner {

    private final JdbcTemplate jdbcTemplate;

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        migrateColumnsToUnicode();
        repairSeedData();
    }

    private void migrateColumnsToUnicode() {
        jdbcTemplate.execute("ALTER TABLE Hotel ALTER COLUMN name NVARCHAR(255) NOT NULL");
        jdbcTemplate.execute("ALTER TABLE Hotel ALTER COLUMN address NVARCHAR(MAX) NULL");
        jdbcTemplate.execute("ALTER TABLE Hotel ALTER COLUMN phone NVARCHAR(20) NULL");
        jdbcTemplate.execute("ALTER TABLE Room ALTER COLUMN nameRoom NVARCHAR(255) NOT NULL");
        jdbcTemplate.execute("ALTER TABLE Room ALTER COLUMN Status NVARCHAR(50) NULL");
        jdbcTemplate.execute("ALTER TABLE Booking ALTER COLUMN Status NVARCHAR(50) NULL");
        jdbcTemplate.execute("ALTER TABLE TypeBooking ALTER COLUMN TypeName NVARCHAR(255) NOT NULL");
        jdbcTemplate.execute("ALTER TABLE TypeRoom ALTER COLUMN TypeRoom NVARCHAR(255) NOT NULL");
        jdbcTemplate.execute("ALTER TABLE [User] ALTER COLUMN full_name NVARCHAR(255) NOT NULL");
    }

    private void repairSeedData() {
        upsertHotel("HOTEL001", "GenZ Cinema Hà Đông",
                "Lk13 Ngõ 2 Nguyễn Văn Lộc, Mộ Lao, Hà Đông, Hà Nội",
                "0866 521 881");
        upsertHotel("HOTEL002", "GenZ Cinema Đống Đa - Nguyễn Lương Bằng 180",
                "Số 3 Ngõ 180 Nguyễn Lương Bằng, Quang Trung, Đống Đa, Hà Nội",
                "0325 186 385");
        upsertHotel("HOTEL003", "GenZ Cinema Hai Bà Trưng",
                "130 Tân Khai, Vĩnh Hưng, Hai Bà Trưng, Hà Nội",
                "0989 838 603");
        upsertHotel("HOTEL004", "GenZ Cinema Thanh Xuân",
                "103 Hoàng Ngân, Nhân Chính, Thanh Xuân, Hà Nội",
                "0823 983 881");
        upsertHotel("HOTEL005", "GenZ Cinema Cầu Giấy",
                "24 Hoa Bằng, Yên Hoà, Cầu Giấy, Hà Nội",
                "0877 155 379");
        upsertHotel("HOTEL006", "GenZ Cinema Tây Hồ",
                "135 Nhật Chiêu, Nhật Tân, Tây Hồ, Hà Nội",
                "0838 408 881");
        upsertHotel("HOTEL007", "GenZ Cinema Đống Đa - Nguyễn Lương Bằng 86-88",
                "86 - 88 Nguyễn Lương Bằng, Quang Trung, Đống Đa, Hà Nội",
                "081 601 8881");
        upsertHotel("HOTEL008", "GenZ Cinema Bắc Từ Liêm",
                "462 Hoàng Công Chất, Cầu Diễn, Bắc Từ Liêm, Hà Nội",
                "0846 298 881");
        upsertHotel("HOTEL009", "GenZ Cinema Thanh Trì",
                "06-N05 khu tái định cư xóm chùa, Triều Khúc, Thanh Liệt, Thanh Trì, Hà Nội",
                "0823 660 705");
        refreshHotelRoomCounts();

        updateRoomStatus("Trống",
                "ROOM-DN-101", "ROOM-DN-102", "ROOM-DN-301",
                "ROOM-HCM-102", "ROOM-HCM-201", "ROOM-HCM-302", "ROOM-HCM-501",
                "ROOM-HN-101", "ROOM-HN-201", "ROOM-HN-301", "ROOM-HN-401");
        updateRoomStatus("Đang thuê",
                "ROOM-DN-201", "ROOM-HCM-101", "ROOM-HCM-301", "ROOM-HN-102");
        updateRoomStatus("Bảo trì", "ROOM-HCM-401");
        updateRoomStatus("Dọn dẹp", "ROOM-HN-202");

        jdbcTemplate.update("""
                UPDATE Booking SET Status = N'Đã thanh toán'
                WHERE BookingId <> 5 AND (Status LIKE '%?%' OR Status LIKE N'%�%')
                """);
        jdbcTemplate.update("""
                UPDATE Booking SET Status = N'Đang ở'
                WHERE BookingId = 5 AND (Status LIKE '%?%' OR Status LIKE N'%�%')
                """);

        updateTypeBooking("TB001", "Thuê theo giờ");
        updateTypeBooking("TB002", "Qua đêm (12h-12h)");
        updateTypeBooking("TB003", "Thuê nguyên ngày");
        updateTypeBooking("TB004", "Thuê theo tuần");

        updateUserName("USER-ADMIN-001", "Phạm Thị Dung");
        updateUserName("USER-CUST-001", "Hoàng Văn Em");
        updateUserName("USER-CUST-002", "Vũ Thị Phương");
        updateUserName("USER-CUST-003", "Đặng Minh Quân");
        updateUserName("USER-CUST-004", "Bùi Thị Lan");
        updateUserName("USER-STAFF-001", "Nguyễn Văn An");
        updateUserName("USER-STAFF-002", "Trần Thị Bình");
        updateUserName("USER-STAFF-003", "Lê Văn Cường");
        jdbcTemplate.update("""
                UPDATE [User] SET full_name = N'Admin Giám Đốc'
                WHERE email = 'admin@genzcinema.com' AND full_name = 'Admin Giam Doc'
                """);
    }

    private void upsertHotel(String hotelId, String name, String address, String phone) {
        int updatedRows = jdbcTemplate.update(
                """
                UPDATE Hotel
                SET name = ?, address = ?, phone = ?
                WHERE HotelId = ?
                """,
                name, address, phone, hotelId
        );

        if (updatedRows == 0) {
            jdbcTemplate.update(
                    """
                    INSERT INTO Hotel (HotelId, name, address, countRoom, phone)
                    VALUES (?, ?, ?, 0, ?)
                    """,
                    hotelId, name, address, phone
            );
        }
    }

    private void refreshHotelRoomCounts() {
        jdbcTemplate.update(
                """
                UPDATE h
                SET countRoom = roomCounts.totalRooms
                FROM Hotel h
                CROSS APPLY (
                    SELECT COUNT(*) AS totalRooms
                    FROM Room r
                    WHERE r.HotelId = h.HotelId
                ) roomCounts
                """
        );
    }

    private void updateRoomStatus(String status, String... roomIds) {
        for (String roomId : roomIds) {
            jdbcTemplate.update(
                    """
                    UPDATE Room SET Status = ?
                    WHERE RoomId = ? AND (Status LIKE '%?%' OR Status LIKE N'%�%')
                    """,
                    status, roomId
            );
        }
    }

    private void updateTypeBooking(String typeBookingId, String typeName) {
        jdbcTemplate.update(
                """
                UPDATE TypeBooking SET TypeName = ?
                WHERE TypeBookingId = ?
                  AND (TypeName LIKE '%?%' OR TypeName LIKE N'%�%')
                """,
                typeName, typeBookingId
        );
    }

    private void updateUserName(String userId, String fullName) {
        jdbcTemplate.update(
                """
                UPDATE [User] SET full_name = ?
                WHERE UserId = ?
                  AND (full_name LIKE '%?%' OR full_name LIKE N'%�%')
                """,
                fullName, userId
        );
    }
}
