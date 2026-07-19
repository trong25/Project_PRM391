package genZ.PRM391GenZ.repository;

import genZ.PRM391GenZ.entity.Booking;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface BookingRepository extends JpaRepository<Booking, Integer> {
    List<Booking> findByUser_UserId(String userId);
    List<Booking> findByRoom_RoomId(String roomId);
    List<Booking> findByStatus(String status);
    
    List<Booking> findByStatusAndCheckOutBetween(String status, LocalDateTime start, LocalDateTime end);
    List<Booking> findByStatusAndRoom_Hotel_HotelIdAndCheckOutBetween(String status, String hotelId, LocalDateTime start, LocalDateTime end);

    @Query("""
            select coalesce(sum(b.totalPrice), 0)
            from Booking b
            where b.status = 'Đã thanh toán'
              and b.checkOut between :start and :end
              and b.totalPrice is not null
            """)
    BigDecimal sumRevenueBetween(
            @Param("start") LocalDateTime start,
            @Param("end") LocalDateTime end
    );

    @Query("""
            select coalesce(sum(b.totalPrice), 0)
            from Booking b
            where b.room.hotel.hotelId = :hotelId
              and b.status = 'Đã thanh toán'
              and b.checkOut between :start and :end
              and b.totalPrice is not null
            """)
    BigDecimal sumRevenueByHotelBetween(
            @Param("hotelId") String hotelId,
            @Param("start") LocalDateTime start,
            @Param("end") LocalDateTime end
    );
}
