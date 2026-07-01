package genZ.PRM391GenZ.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "TypeRoom")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class TypeRoom {

    @Id
    @Column(name = "TypeRoomId", length = 50)
    private String typeRoomId;

    @Column(name = "TypeRoom", nullable = false)
    private String typeRoom;

    @Column(name = "pricePerHour")
    private BigDecimal pricePerHour;
}

