package genZ.PRM391GenZ.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;


@Entity
@Table(name="DiscountCode")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class DiscountCode {


    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer discountId;


    @Column(unique = true, nullable = false)
    private String code;


    private String description;


    private String discountType;


    private BigDecimal discountValue;


    private LocalDateTime startDate;


    private LocalDateTime endDate;


    private Integer quantity;


    private String status;

}