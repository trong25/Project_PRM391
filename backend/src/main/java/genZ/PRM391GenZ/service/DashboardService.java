package genZ.PRM391GenZ.service;

import genZ.PRM391GenZ.entity.Hotel;
import genZ.PRM391GenZ.repository.BookingRepository;
import genZ.PRM391GenZ.repository.HotelRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.HashMap;
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

        return overview;
    }

    private Map<String, BigDecimal> buildRevenueMap(String hotelId) {
        Map<String, BigDecimal> revenue = new HashMap<>();
        revenue.put("day", calculateRevenue(hotelId, "day"));
        revenue.put("month", calculateRevenue(hotelId, "month"));
        revenue.put("year", calculateRevenue(hotelId, "year"));
        return revenue;
    }

    private BigDecimal calculateRevenue(String hotelId, String timeFrame) {
        if (hotelId == null || hotelId.isBlank()) {
            return calculateTotalRevenue(timeFrame);
        }
        return calculateRevenueByHotel(hotelId, timeFrame);
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
            case "month":
                start = now.with(TemporalAdjusters.firstDayOfMonth()).with(LocalTime.MIN);
                end = now.with(TemporalAdjusters.lastDayOfMonth()).with(LocalTime.MAX);
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
