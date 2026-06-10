package genZ.PRM391GenZ.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "Role")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Role {

    @Id
    @Column(name = "RoleId", length = 50)
    private String roleId;

    @Column(name = "RoleName", nullable = false)
    private String roleName;
}
