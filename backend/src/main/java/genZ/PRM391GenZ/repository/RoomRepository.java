package genZ.PRM391GenZ.repository;

import genZ.PRM391GenZ.entity.Room;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RoomRepository extends JpaRepository<Room, String> {
    List<Room> findByStatus(String status);
    List<Room> findByHotel_HotelId(String hotelId);
    List<Room> findByTypeRoom_TypeRoomId(String typeRoomId);
}