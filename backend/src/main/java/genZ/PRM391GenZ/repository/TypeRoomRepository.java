package genZ.PRM391GenZ.repository;

import genZ.PRM391GenZ.entity.TypeRoom;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TypeRoomRepository extends JpaRepository<TypeRoom, String> {
}
