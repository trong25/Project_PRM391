package genZ.PRM391GenZ.service;

import genZ.PRM391GenZ.entity.DiscountCode;
import genZ.PRM391GenZ.repository.DiscountRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class DiscountService {

    private final DiscountRepository repository;

    // ==========================
    // STAFF
    // ==========================

    public List<DiscountCode> getAll() {
        return repository.findAll();
    }

    // ==========================
    // CUSTOMER
    // ==========================

    public List<DiscountCode> getActiveDiscounts() {
        return repository.findByStatus("Active");
    }

    public DiscountCode getById(Integer id) {

        return repository.findById(id)
                .orElseThrow(() ->
                        new RuntimeException("Voucher not found"));
    }

    public DiscountCode create(DiscountCode discount) {

        return repository.save(discount);

    }

    public DiscountCode update(Integer id, DiscountCode data) {

        DiscountCode old = repository.findById(id)
                .orElseThrow(() ->
                        new RuntimeException("Voucher not found"));

        old.setCode(data.getCode());
        old.setDescription(data.getDescription());
        old.setDiscountType(data.getDiscountType());
        old.setDiscountValue(data.getDiscountValue());
        old.setStartDate(data.getStartDate());
        old.setEndDate(data.getEndDate());
        old.setQuantity(data.getQuantity());
        old.setStatus(data.getStatus());

        return repository.save(old);
    }

    public void delete(Integer id) {

        if (!repository.existsById(id)) {
            throw new RuntimeException("Voucher not found");
        }

        repository.deleteById(id);
    }

}