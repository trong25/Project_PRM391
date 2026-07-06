package genZ.PRM391GenZ.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "DiscountCode")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class DiscountCode {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "DiscountId")
    private Integer discountId;

    @Column(name = "Code", unique = true, nullable = false, length = 50)
    private String code;

    @Column(name = "Description", columnDefinition = "NVARCHAR(255)")
    private String description;

    @Column(name = "DiscountType", nullable = false, length = 20)
    private String discountType; // PERCENT or AMOUNT

    @Column(name = "DiscountValue", nullable = false)
    private BigDecimal discountValue;

    @Column(name = "StartDate", nullable = false)
    private LocalDateTime startDate;

    @Column(name = "EndDate", nullable = false)
    private LocalDateTime endDate;

    @Column(name = "Quantity")
    private Integer quantity;

    @Column(name = "Status", columnDefinition = "NVARCHAR(50)")
    private String status; // Active, Expired, Disable
}
