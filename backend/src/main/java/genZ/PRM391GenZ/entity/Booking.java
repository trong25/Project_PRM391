package genZ.PRM391GenZ.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "Booking")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Booking {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "BookingId")
    private Integer bookingId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "RoomId", nullable = false)
    private Room room;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "UserId", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "TypeBookingId", nullable = false)
    private TypeBooking typeBooking;

    @Column(name = "checkIn", nullable = false)
    private LocalDateTime checkIn;

    @Column(name = "checkOut")
    private LocalDateTime checkOut;

    @Column(name = "totalPrice", precision = 18, scale = 2)
    private BigDecimal totalPrice;

    @Column(name = "Status", columnDefinition = "NVARCHAR(50)")
    private String status;

    @Column(name = "guestName", length = 255, columnDefinition = "NVARCHAR(255)")
    private String guestName;

    @Column(name = "guestPhone", length = 20)
    private String guestPhone;

    @Column(name = "paidAt")
    private LocalDateTime paidAt;

    @Column(name = "voucherCode", length = 50)
    private String voucherCode;

    @Column(name = "discountAmount", precision = 18, scale = 2)
    private BigDecimal discountAmount;

    @Column(name = "note", columnDefinition = "NVARCHAR(MAX)")
    private String note;

    // Khai báo tường minh cho các field mới để cả Maven và IntelliJ incremental
    // build nhận diện ngay cả khi annotation-processing cache của Lombok bị cũ.
    public String getGuestName() {
        return guestName;
    }

    public void setGuestName(String guestName) {
        this.guestName = guestName;
    }

    public String getGuestPhone() {
        return guestPhone;
    }

    public void setGuestPhone(String guestPhone) {
        this.guestPhone = guestPhone;
    }

    public LocalDateTime getPaidAt() {
        return paidAt;
    }

    public void setPaidAt(LocalDateTime paidAt) {
        this.paidAt = paidAt;
    }
}
