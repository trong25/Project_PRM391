package genZ.PRM391GenZ.service;

import genZ.PRM391GenZ.dto.user.UserCreateDto;
import genZ.PRM391GenZ.dto.user.UserResponseDto;
import genZ.PRM391GenZ.dto.user.UserUpdateDto;
import genZ.PRM391GenZ.entity.Role;
import genZ.PRM391GenZ.entity.User;
import genZ.PRM391GenZ.repository.RoleRepository;
import genZ.PRM391GenZ.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class UserService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;

    public List<UserResponseDto> getAllUsers() {
        return userRepository.findAll().stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    public List<UserResponseDto> getUsersByRole(String roleId) {
        return userRepository.findAll().stream()
                .filter(user -> user.getRole() != null && user.getRole().getRoleId().equalsIgnoreCase(roleId))
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    public UserResponseDto getUserById(String id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng với ID: " + id));
        return mapToDto(user);
    }

    @Transactional
    public UserResponseDto createUser(UserCreateDto dto) {
        if ("ADMIN".equalsIgnoreCase(dto.getRoleId())) {
            throw new RuntimeException("Hệ thống không cho phép tạo thêm tài khoản giám đốc chi nhánh");
        }

        if (userRepository.findByEmail(dto.getEmail()).isPresent()) {
            throw new RuntimeException("Email đã được sử dụng");
        }

        Role role = roleRepository.findById(dto.getRoleId())
                .orElseThrow(() -> new RuntimeException("Role không tồn tại"));

        User user = User.builder()
                .userId(UUID.randomUUID().toString())
                .fullName(dto.getFullName())
                .phone(dto.getPhone())
                .email(dto.getEmail())
                .password(passwordEncoder.encode(dto.getPassword()))
                .imageCccd(dto.getImageCccd())
                .role(role)
                .build();

        User savedUser = userRepository.save(user);
        log.info("Created new user: {}", savedUser.getEmail());
        return mapToDto(savedUser);
    }

    @Transactional
    public UserResponseDto updateUser(String id, UserUpdateDto dto) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng với ID: " + id));

        user.setFullName(dto.getFullName());
        user.setPhone(dto.getPhone());
        
        if (dto.getEmail() != null && !dto.getEmail().equals(user.getEmail())) {
            if (userRepository.findByEmail(dto.getEmail()).isPresent()) {
                throw new RuntimeException("Email đã được sử dụng");
            }
            user.setEmail(dto.getEmail());
        }

        user.setImageCccd(dto.getImageCccd());

        if (dto.getRoleId() != null) {
            boolean assigningAdmin = "ADMIN".equalsIgnoreCase(dto.getRoleId());
            boolean alreadyAdmin = user.getRole() != null
                    && "ADMIN".equalsIgnoreCase(user.getRole().getRoleId());
            if (assigningAdmin && !alreadyAdmin) {
                throw new RuntimeException("Không được chuyển tài khoản thành giám đốc chi nhánh");
            }

            Role role = roleRepository.findById(dto.getRoleId())
                .orElseThrow(() -> new RuntimeException("Role không tồn tại"));
            user.setRole(role);
        }

        User updatedUser = userRepository.save(user);
        log.info("Updated user: {}", updatedUser.getEmail());
        return mapToDto(updatedUser);
    }

    @Transactional
    public void deleteUser(String id) {
        if (!userRepository.existsById(id)) {
            throw new RuntimeException("Không tìm thấy người dùng với ID: " + id);
        }
        userRepository.deleteById(id);
        log.info("Deleted user with ID: {}", id);
    }

    public java.util.Optional<UserResponseDto> getUserByPhone(String phone) {
        return userRepository.findByPhone(phone).map(this::mapToDto);
    }

    private UserResponseDto mapToDto(User user) {
        return UserResponseDto.builder()
                .userId(user.getUserId())
                .fullName(user.getFullName())
                .phone(user.getPhone())
                .email(user.getEmail())
                .imageCccd(user.getImageCccd())
                .roleId(user.getRole() != null ? user.getRole().getRoleId() : null)
                .roleName(user.getRole() != null ? user.getRole().getRoleName() : null)
                .build();
    }
}
