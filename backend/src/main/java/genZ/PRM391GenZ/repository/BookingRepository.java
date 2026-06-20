package genZ.PRM391GenZ.repository;

import genZ.PRM391GenZ.entity.Booking;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface BookingRepository extends JpaRepository<Booking, Integer> {
    List<Booking> findByUser_UserId(String userId);
    List<Booking> findByRoom_RoomId(String roomId);
    List<Booking> findByStatus(String status);
    
    List<Booking> findByStatusAndCheckOutBetween(String status, LocalDateTime start, LocalDateTime end);
    List<Booking> findByStatusAndRoom_Hotel_HotelIdAndCheckOutBetween(String status, String hotelId, LocalDateTime start, LocalDateTime end);
}