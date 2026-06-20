package genZ.PRM391GenZ;

import genZ.PRM391GenZ.service.DashboardService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.Map;
import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
class Prm391GenZApplicationTests {

	@Autowired
	private DashboardService dashboardService;

	@Autowired
	private JdbcTemplate jdbcTemplate;

	@Test
	void contextLoads() {
	}

	@Test
	void dashboardRevenueOverviewLoads() {
		Map<String, Object> overview = dashboardService.getRevenueOverview();
		@SuppressWarnings("unchecked")
		Map<String, BigDecimal> total = (Map<String, BigDecimal>) overview.get("total");

		assertThat(overview).containsKeys("total", "hotels");
		assertThat(total.get("month")).isPositive();
		assertThat(total.get("year")).isPositive();
	}

	@Test
	void unicodeDataIsRepaired() {
		assertThat(jdbcTemplate.queryForObject(
				"SELECT name FROM Hotel WHERE HotelId = 'HOTEL001'", String.class
		)).isEqualTo("GenzCinema Hà Nội");
		assertThat(jdbcTemplate.queryForObject(
				"SELECT Status FROM Room WHERE RoomId = 'ROOM-HCM-401'", String.class
		)).isEqualTo("Bảo trì");
		assertThat(jdbcTemplate.queryForObject(
				"SELECT Status FROM Booking WHERE BookingId = 1", String.class
		)).isEqualTo("Đã thanh toán");
		assertThat(jdbcTemplate.queryForObject(
				"SELECT TypeName FROM TypeBooking WHERE TypeBookingId = 'TB003'", String.class
		)).isEqualTo("Thuê nguyên ngày");
		assertThat(jdbcTemplate.queryForObject(
				"SELECT full_name FROM [User] WHERE UserId = 'USER-STAFF-001'", String.class
		)).isEqualTo("Nguyễn Văn An");
	}

	@Test
	void businessTextColumnsUseUnicodeTypes() {
		assertUnicodeColumn("Hotel", "name");
		assertUnicodeColumn("Hotel", "address");
		assertUnicodeColumn("Room", "Status");
		assertUnicodeColumn("Booking", "Status");
		assertUnicodeColumn("TypeBooking", "TypeName");
		assertUnicodeColumn("User", "full_name");
	}

	private void assertUnicodeColumn(String tableName, String columnName) {
		String dataType = jdbcTemplate.queryForObject(
				"""
				SELECT DATA_TYPE
				FROM INFORMATION_SCHEMA.COLUMNS
				WHERE TABLE_NAME = ? AND COLUMN_NAME = ?
				""",
				String.class,
				tableName,
				columnName
		);
		assertThat(dataType).isIn("nvarchar", "nchar", "ntext");
	}

}
