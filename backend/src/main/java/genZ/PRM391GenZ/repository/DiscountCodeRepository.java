package genZ.PRM391GenZ.repository;

import genZ.PRM391GenZ.entity.DiscountCode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DiscountCodeRepository extends JpaRepository<DiscountCode, Integer> {
    Optional<DiscountCode> findByCodeIgnoreCase(String code);
    List<DiscountCode> findByStatusIgnoreCase(String status);
}
