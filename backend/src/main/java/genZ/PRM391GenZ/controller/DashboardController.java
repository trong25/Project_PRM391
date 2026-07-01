package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.dto.ApiResponse;
import genZ.PRM391GenZ.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService dashboardService;

    @GetMapping("/revenue/overview")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getRevenueOverview() {
        return ResponseEntity.ok(ApiResponse.success(
                "Tổng hợp doanh thu theo từng khoảng thời gian của từng chi nhánh",
                dashboardService.getRevenueOverview()
        ));
    }

    @GetMapping("/revenue/total")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, BigDecimal>>> getTotalRevenue(
            @RequestParam(defaultValue = "month") String timeFrame) {
        BigDecimal total = dashboardService.calculateTotalRevenue(timeFrame);
        Map<String, BigDecimal> result = new HashMap<>();
        result.put("revenue", total);
        return ResponseEntity.ok(ApiResponse.success("Tổng doanh thu toàn hệ thống", result));
    }

    @GetMapping("/revenue/hotel/{hotelId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, BigDecimal>>> getHotelRevenue(
            @PathVariable String hotelId,
            @RequestParam(defaultValue = "month") String timeFrame) {
        BigDecimal total = dashboardService.calculateRevenueByHotel(hotelId, timeFrame);
        Map<String, BigDecimal> result = new HashMap<>();
        result.put("revenue", total);
        return ResponseEntity.ok(ApiResponse.success("Doanh thu chi nhánh", result));
    }
}
