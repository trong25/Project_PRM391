package genZ.PRM391GenZ.dto;

import lombok.*;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class LoginResponse {
    private String token;
    private String userId;
    private String fullName;
    private String email;
    private String role;
    private String roleId;
}
