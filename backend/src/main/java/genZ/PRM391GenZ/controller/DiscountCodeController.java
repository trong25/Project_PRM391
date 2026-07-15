package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.dto.ApiResponse;
import genZ.PRM391GenZ.entity.DiscountCode;
import genZ.PRM391GenZ.repository.DiscountCodeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/discount-codes")
@RequiredArgsConstructor
public class DiscountCodeController {

    private final DiscountCodeRepository discountCodeRepository;

    @GetMapping
    public ResponseEntity<ApiResponse<List<DiscountCode>>> getAllDiscountCodes() {
        return ResponseEntity.ok(
                ApiResponse.success("Danh sách mã giảm giá", discountCodeRepository.findAll())
        );
    }

    @GetMapping("/active")
    public ResponseEntity<ApiResponse<List<DiscountCode>>> getActiveDiscountCodes() {
        return ResponseEntity.ok(
                ApiResponse.success("Danh sách mã giảm giá đang kích hoạt", discountCodeRepository.findByStatusIgnoreCase("Active"))
        );
    }
}
