package genZ.PRM391GenZ.service;

import genZ.PRM391GenZ.entity.Hotel;
import genZ.PRM391GenZ.repository.BookingRepository;
import genZ.PRM391GenZ.repository.HotelRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.YearMonth;
import java.time.temporal.ChronoUnit;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final BookingRepository bookingRepository;
    private final HotelRepository hotelRepository;

    public BigDecimal calculateTotalRevenue(String timeFrame) {
        LocalDateTime[] range = getDateRange(timeFrame);
        return safeRevenue(bookingRepository.sumRevenueBetween(range[0], range[1]));
    }

    public BigDecimal calculateRevenueByHotel(String hotelId, String timeFrame) {
        LocalDateTime[] range = getDateRange(timeFrame);
        return safeRevenue(bookingRepository.sumRevenueByHotelBetween(hotelId, range[0], range[1]));
    }

    public Map<String, Object> getRevenueOverview() {
        Map<String, Object> overview = new HashMap<>();
        overview.put("total", buildRevenueMap(null));

        List<Map<String, Object>> hotelsRevenue = new ArrayList<>();
        for (Hotel hotel : hotelRepository.findAll()) {
            Map<String, Object> item = new HashMap<>();
            item.put("hotelId", hotel.getHotelId());
            item.put("hotelName", hotel.getName());
            item.put("revenue", buildRevenueMap(hotel.getHotelId()));
            hotelsRevenue.add(item);
        }
        overview.put("hotels", hotelsRevenue);
        overview.put("trends", buildRevenueTrends());

        return overview;
    }

    private Map<String, Object> buildRevenueTrends() {
        Map<String, Object> trends = new HashMap<>();
        trends.put("daysInMonth", buildDaysInMonthRevenue());
        trends.put("monthsInYear", buildMonthsInYearRevenue());
        trends.put("years", buildRecentYearsRevenue());
        return trends;
    }

    private List<Map<String, Object>> buildDaysInMonthRevenue() {
        YearMonth currentMonth = YearMonth.now();
        List<Map<String, Object>> result = new ArrayList<>();

        for (int day = 1; day <= currentMonth.lengthOfMonth(); day++) {
            LocalDate date = currentMonth.atDay(day);
            result.add(buildRevenuePoint(
                    String.format("%02d/%02d", day, currentMonth.getMonthValue()),
                    calculateTotalRevenueBetween(date.atStartOfDay(), date.atTime(LocalTime.MAX))
            ));
        }

        return result;
    }

    private List<Map<String, Object>> buildMonthsInYearRevenue() {
        int year = LocalDate.now().getYear();
        List<Map<String, Object>> result = new ArrayList<>();

        for (int month = 1; month <= 12; month++) {
            YearMonth yearMonth = YearMonth.of(year, month);
            result.add(buildRevenuePoint(
                    "Tháng " + month,
                    calculateTotalRevenueBetween(
                            yearMonth.atDay(1).atStartOfDay(),
                            yearMonth.atEndOfMonth().atTime(LocalTime.MAX)
                    )
            ));
        }

        return result;
    }

    private List<Map<String, Object>> buildRecentYearsRevenue() {
        int currentYear = LocalDate.now().getYear();
        List<Map<String, Object>> result = new ArrayList<>();

        for (int year = currentYear - 2; year <= currentYear; year++) {
            LocalDate startDate = LocalDate.of(year, 1, 1);
            LocalDate endDate = LocalDate.of(year, 12, 31);
            result.add(buildRevenuePoint(
                    String.valueOf(year),
                    calculateTotalRevenueBetween(startDate.atStartOfDay(), endDate.atTime(LocalTime.MAX))
            ));
        }

        return result;
    }

    private Map<String, Object> buildRevenuePoint(String label, BigDecimal value) {
        Map<String, Object> point = new LinkedHashMap<>();
        point.put("label", label);
        point.put("value", safeRevenue(value));
        return point;
    }

    private Map<String, BigDecimal> buildRevenueMap(String hotelId) {
        Map<String, BigDecimal> revenue = new HashMap<>();
        revenue.put("day", calculateRevenue(hotelId, "day"));
        revenue.put("week", calculateRevenue(hotelId, "week"));
        revenue.put("month", calculateRevenue(hotelId, "month"));
        revenue.put("lastMonth", calculateRevenue(hotelId, "lastMonth"));
        revenue.put("year", calculateRevenue(hotelId, "year"));
        return revenue;
    }

    private BigDecimal calculateRevenue(String hotelId, String timeFrame) {
        if (hotelId == null || hotelId.isBlank()) {
            return calculateTotalRevenue(timeFrame);
        }
        return calculateRevenueByHotel(hotelId, timeFrame);
    }

    private BigDecimal calculateTotalRevenueBetween(LocalDateTime start, LocalDateTime end) {
        return safeRevenue(bookingRepository.sumRevenueBetween(start, end));
    }

    private BigDecimal safeRevenue(BigDecimal revenue) {
        return revenue != null ? revenue : BigDecimal.ZERO;
    }

    private LocalDateTime[] getDateRange(String timeFrame) {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime start;
        LocalDateTime end = now;

        switch (timeFrame.toLowerCase()) {
            case "day":
                start = now.with(LocalTime.MIN);
                end = now.with(LocalTime.MAX);
                break;
            case "week":
                start = now.minusDays(6).with(LocalTime.MIN);
                end = now.with(LocalTime.MAX);
                break;
            case "month":
                start = now.with(TemporalAdjusters.firstDayOfMonth()).with(LocalTime.MIN);
                end = now.with(TemporalAdjusters.lastDayOfMonth()).with(LocalTime.MAX);
                break;
            case "lastmonth":
                LocalDateTime lastMonth = now.minus(1, ChronoUnit.MONTHS);
                start = lastMonth.with(TemporalAdjusters.firstDayOfMonth()).with(LocalTime.MIN);
                end = lastMonth.with(TemporalAdjusters.lastDayOfMonth()).with(LocalTime.MAX);
                break;
            case "year":
                start = now.with(TemporalAdjusters.firstDayOfYear()).with(LocalTime.MIN);
                end = now.with(TemporalAdjusters.lastDayOfYear()).with(LocalTime.MAX);
                break;
            default:
                start = now.with(LocalTime.MIN);
        }
        return new LocalDateTime[]{start, end};
    }
}
