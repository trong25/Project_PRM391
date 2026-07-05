package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.dto.ApiResponse;
import genZ.PRM391GenZ.dto.user.UserCreateDto;
import genZ.PRM391GenZ.dto.user.UserResponseDto;
import genZ.PRM391GenZ.dto.user.UserUpdateDto;
import genZ.PRM391GenZ.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<List<UserResponseDto>>> getUsers(
            @RequestParam(required = false) String roleId) {
        List<UserResponseDto> users = (roleId != null && !roleId.isEmpty()) 
                ? userService.getUsersByRole(roleId)
                : userService.getAllUsers();
        return ResponseEntity.ok(ApiResponse.success("Danh sách người dùng", users));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<UserResponseDto>> getUserById(@PathVariable String id) {
        return ResponseEntity.ok(ApiResponse.success("Thông tin người dùng", userService.getUserById(id)));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<UserResponseDto>> createUser(@Valid @RequestBody UserCreateDto dto) {
        return ResponseEntity.ok(ApiResponse.success("Tạo người dùng thành công", userService.createUser(dto)));
    }

    @PostMapping("/admin")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<UserResponseDto>> createAdmin(@Valid @RequestBody UserCreateDto dto) {
        dto.setRoleId("ADMIN");
        return ResponseEntity.ok(ApiResponse.success("Tạo giám đốc thành công", userService.createUser(dto)));
    }

    @PostMapping("/staff")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<UserResponseDto>> createStaff(@Valid @RequestBody UserCreateDto dto) {
        dto.setRoleId("STAFF");
        return ResponseEntity.ok(ApiResponse.success("Tạo nhân viên thành công", userService.createUser(dto)));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<UserResponseDto>> updateUser(
            @PathVariable String id, @Valid @RequestBody UserUpdateDto dto) {
        return ResponseEntity.ok(ApiResponse.success("Cập nhật thành công", userService.updateUser(id, dto)));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteUser(@PathVariable String id) {
        userService.deleteUser(id);
        return ResponseEntity.ok(ApiResponse.success("Xóa người dùng thành công"));
    }

    @GetMapping("/phone/{phone}")
    @PreAuthorize("hasAnyRole('ADMIN', 'STAFF')")
    public ResponseEntity<ApiResponse<UserResponseDto>> getUserByPhone(@PathVariable String phone) {
        return userService.getUserByPhone(phone)
                .map(u -> ResponseEntity.ok(ApiResponse.success("Thông tin người dùng", u)))
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/customer")
    @PreAuthorize("hasAnyRole('ADMIN', 'STAFF')")
    public ResponseEntity<ApiResponse<UserResponseDto>> createCustomerForStaff(@Valid @RequestBody UserCreateDto dto) {
        dto.setRoleId("CUSTOMER");
        if (dto.getPassword() == null || dto.getPassword().isEmpty()) {
            dto.setPassword("password123");
        }
        return ResponseEntity.ok(ApiResponse.success("Tạo khách hàng thành công", userService.createUser(dto)));
    }
}
