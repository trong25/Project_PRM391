package genZ.PRM391GenZ.service;

import genZ.PRM391GenZ.entity.Booking;
import genZ.PRM391GenZ.repository.BookingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.temporal.TemporalAdjusters;
import java.util.List;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final BookingRepository bookingRepository;
    
    // Giả sử status thanh toán xong là "PAID" hoặc "Đã thanh toán"
    private static final String PAID_STATUS = "Đã thanh toán";

    public BigDecimal calculateTotalRevenue(String timeFrame) {
        LocalDateTime[] range = getDateRange(timeFrame);
        List<Booking> bookings = bookingRepository.findByStatusAndCheckOutBetween(PAID_STATUS, range[0], range[1]);
        return sumRevenue(bookings);
    }

    public BigDecimal calculateRevenueByHotel(String hotelId, String timeFrame) {
        LocalDateTime[] range = getDateRange(timeFrame);
        List<Booking> bookings = bookingRepository.findByStatusAndRoom_Hotel_HotelIdAndCheckOutBetween(PAID_STATUS, hotelId, range[0], range[1]);
        return sumRevenue(bookings);
    }

    private BigDecimal sumRevenue(List<Booking> bookings) {
        return bookings.stream()
                .map(Booking::getTotalPrice)
                .filter(price -> price != null)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
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
