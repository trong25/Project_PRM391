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
public class UserUpdateDto {
    @NotBlank(message = "Họ tên không được để trống")
    private String fullName;
    
    private String phone;
    
    @Email(message = "Email không hợp lệ")
    private String email;
    
    private String imageCccd;
    
    private String roleId;
}
