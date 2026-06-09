package genZ.PRM391GenZ.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;

@Entity
@Table(name = "PriceConfig")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PriceConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "PriceConfigId")
    private Integer priceConfigId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "TypeRoomId", nullable = false)
    private TypeRoom typeRoom;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "TypeBookingId", nullable = false)
    private TypeBooking typeBooking;

    @Column(name = "Price", nullable = false, precision = 18, scale = 2)
    private BigDecimal price;
}
