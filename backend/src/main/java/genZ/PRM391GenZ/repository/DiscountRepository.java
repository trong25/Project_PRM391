package genZ.PRM391GenZ.repository;

import genZ.PRM391GenZ.entity.DiscountCode;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DiscountRepository extends JpaRepository<DiscountCode, Integer> {

    List<DiscountCode> findByStatus(String status);

}