package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.entity.DiscountCode;
import genZ.PRM391GenZ.service.DiscountService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/discount")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class DiscountController {

    private final DiscountService service;

    // =====================================
    // CUSTOMER
    // =====================================

    @GetMapping("/active")
    public List<DiscountCode> getActiveDiscounts() {
        return service.getActiveDiscounts();
    }

    // =====================================
    // STAFF
    // =====================================

    @GetMapping
    public List<DiscountCode> getAll() {
        return service.getAll();
    }

    @GetMapping("/{id}")
    public DiscountCode getById(@PathVariable Integer id) {
        return service.getById(id);
    }

    @PostMapping
    public DiscountCode create(@RequestBody DiscountCode discount) {
        return service.create(discount);
    }

    @PutMapping("/{id}")
    public DiscountCode update(
            @PathVariable Integer id,
            @RequestBody DiscountCode discount) {

        return service.update(id, discount);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Integer id) {
        service.delete(id);
    }

}