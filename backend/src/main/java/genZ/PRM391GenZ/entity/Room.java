package genZ.PRM391GenZ.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "Room")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Room {

    @Id
    @Column(name = "RoomId", length = 50)
    private String roomId;

    @Column(name = "nameRoom", nullable = false)
    private String nameRoom;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "TypeRoomId")
    private TypeRoom typeRoom;

    @Column(name = "Status")
    private String status;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "HotelId")
    private Hotel hotel;
}
