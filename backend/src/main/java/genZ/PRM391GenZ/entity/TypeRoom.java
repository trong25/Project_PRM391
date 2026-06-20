package genZ.PRM391GenZ.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "TypeRoom")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TypeRoom {

    @Id
    @Column(name = "TypeRoomId", length = 50)
    private String typeRoomId;

    @Column(name = "TypeRoom", nullable = false, columnDefinition = "NVARCHAR(255)")
    private String typeRoom;
}

