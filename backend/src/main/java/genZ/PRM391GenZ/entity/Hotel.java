package genZ.PRM391GenZ.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "Hotel")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Hotel {

    @Id
    @Column(name = "HotelId", length = 50)
    private String hotelId;

    @Column(name = "[name]", nullable = false)
    private String name;

    @Column(name = "address", columnDefinition = "NVARCHAR(MAX)")
    private String address;

    @Column(name = "countRoom")
    private Integer countRoom = 0;

    @Column(name = "phone", length = 20)
    private String phone;

    @Column(name = "imageUrl", columnDefinition = "NVARCHAR(MAX)")
    private String imageUrl;
}
