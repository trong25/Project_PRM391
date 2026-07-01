package genZ.PRM391GenZ.dto.user;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserCreateDto {
    @NotBlank(message = "Họ tên không được để trống")
    private String fullName;
    
    private String phone;
    
    @Email(message = "Email không hợp lệ")
    private String email;
    
    @NotBlank(message = "Mật khẩu không được để trống")
    private String password;
    
    private String imageCccd;
    
    @NotBlank(message = "Role không được để trống")
    private String roleId;
}
