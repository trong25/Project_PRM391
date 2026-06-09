package genZ.PRM391GenZ.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "PasswordResetToken")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PasswordResetToken {

    @Id
    @Column(name = "token", length = 255)
    private String token;

    @Column(name = "expiryTime", nullable = false)
    private LocalDateTime expiryTime;

    @Column(name = "isUsed", nullable = false)
    private boolean used = false;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "UserId", nullable = false)
    private User user;
}

