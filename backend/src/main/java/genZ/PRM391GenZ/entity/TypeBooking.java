package genZ.PRM391GenZ.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "TypeBooking")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TypeBooking {

    @Id
    @Column(name = "TypeBookingId", length = 50)
    private String typeBookingId;

    @Column(name = "TypeName", nullable = false, columnDefinition = "NVARCHAR(255)")
    private String typeName;

    @Column(name = "BookingCode", nullable = false, length = 50)
    private String bookingCode;

    @Column(name = "DurationHours")
    private Integer durationHours;
}

