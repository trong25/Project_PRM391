package genZ.PRM391GenZ.dto.user;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserResponseDto {
    private String userId;
    private String fullName;
    private String phone;
    private String email;
    private String imageCccd;
    private String roleId;
    private String roleName;
}
