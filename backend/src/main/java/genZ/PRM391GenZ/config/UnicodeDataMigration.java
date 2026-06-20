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
        jdbcTemplate.execute("ALTER TABLE Room ALTER COLUMN nameRoom NVARCHAR(255) NOT NULL");
        jdbcTemplate.execute("ALTER TABLE Room ALTER COLUMN Status NVARCHAR(50) NULL");
        jdbcTemplate.execute("ALTER TABLE Booking ALTER COLUMN Status NVARCHAR(50) NULL");
        jdbcTemplate.execute("ALTER TABLE TypeBooking ALTER COLUMN TypeName NVARCHAR(255) NOT NULL");
        jdbcTemplate.execute("ALTER TABLE TypeRoom ALTER COLUMN TypeRoom NVARCHAR(255) NOT NULL");
        jdbcTemplate.execute("ALTER TABLE [User] ALTER COLUMN full_name NVARCHAR(255) NOT NULL");
    }

    private void repairSeedData() {
        updateHotel("HOTEL001", "GenzCinema Hà Nội",
                "123 Hoàn Kiếm, Hoàn Kiếm, Hà Nội");
        updateHotel("HOTEL002", "GenzCinema TP. Hồ Chí Minh",
                "456 Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh");
        updateHotel("HOTEL003", "GenzCinema Đà Nẵng",
                "789 Bạch Đằng, Hải Châu, Đà Nẵng");

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

    private void updateHotel(String hotelId, String name, String address) {
        jdbcTemplate.update(
                """
                UPDATE Hotel SET name = ?, address = ?
                WHERE HotelId = ?
                  AND (name LIKE '%?%' OR name LIKE N'%�%'
                       OR address LIKE '%?%' OR address LIKE N'%�%')
                """,
                name, address, hotelId
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
