package genZ.PRM391GenZ.service;

import genZ.PRM391GenZ.dto.*;
import genZ.PRM391GenZ.entity.*;
import genZ.PRM391GenZ.repository.*;
import genZ.PRM391GenZ.security.JwtService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordResetTokenRepository tokenRepository;
    private final RoleRepository roleRepository;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;
    private final UserDetailsService userDetailsService;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;

    @Value("${app.reset-token.expiry-minutes}")
    private int resetTokenExpiryMinutes;

    @Value("${app.frontend-url}")
    private String frontendUrl;

    // ─── Login ──────────────────────────────────────────────────────────────────

    public LoginResponse login(LoginRequest request) {
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
            );
        } catch (BadCredentialsException e) {
            throw new RuntimeException("Email hoặc mật khẩu không đúng");
        }

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Tài khoản không tồn tại"));

        UserDetails userDetails = userDetailsService.loadUserByUsername(user.getEmail());

        String roleName = user.getRole() != null ? user.getRole().getRoleName() : "CUSTOMER";
        String roleId   = user.getRole() != null ? user.getRole().getRoleId()   : "";

        // Embed role info in JWT claims so Flutter can read it
        Map<String, Object> extraClaims = Map.of(
                "userId",   user.getUserId(),
                "fullName", user.getFullName(),
                "role",     roleName,
                "roleId",   roleId
        );

        String token = jwtService.generateToken(userDetails, extraClaims);

        return LoginResponse.builder()
                .token(token)
                .userId(user.getUserId())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .role(roleName)
                .roleId(roleId)
                .build();
    }

    // ─── Register ────────────────────────────────────────────────────────────────

    @Transactional
    public void register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email đã được sử dụng");
        }

        if (userRepository.existsByPhone(request.getPhone())) {
            throw new RuntimeException("Số điện thoại đã được sử dụng");
        }

        // Đăng ký công khai luôn là khách hàng; không cho client tự cấp STAFF/ADMIN.
        Role role = roleRepository.findById("CUSTOMER")
                .orElseThrow(() -> new RuntimeException("Vai trò khách hàng không tồn tại"));

        User user = User.builder()
                .userId(UUID.randomUUID().toString())
                .fullName(request.getFullName())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .phone(request.getPhone())
                .role(role)
                .build();

        userRepository.save(user);
        log.info("New user registered: {}", request.getEmail());
    }

    // ─── Request Password Reset ───────────────────────────────────────────────────

    @Transactional
    public void requestPasswordReset(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Email không tồn tại trong hệ thống"));

        tokenRepository.deleteByUser(user);

        String token = UUID.randomUUID().toString();
        LocalDateTime expiry = LocalDateTime.now().plusMinutes(resetTokenExpiryMinutes);

        PasswordResetToken resetToken = PasswordResetToken.builder()
                .token(token)
                .expiryTime(expiry)
                .used(false)
                .user(user)
                .build();

        tokenRepository.save(resetToken);

        String resetLink = frontendUrl + "/reset-password?token=" + token;

        boolean sent = emailService.sendPasswordResetEmail(email, resetLink, user.getFullName());
        if (!sent) {
            throw new RuntimeException("Lỗi khi gửi email. Vui lòng thử lại.");
        }
    }

    // ─── Verify Reset Token ────────────────────────────────────────────────────

    public String verifyResetToken(String token) {
        PasswordResetToken resetToken = tokenRepository.findByToken(token)
                .orElseThrow(() -> new RuntimeException("Token không hợp lệ hoặc không tồn tại"));

        if (resetToken.isUsed()) {
            throw new RuntimeException("Token đã được sử dụng. Vui lòng yêu cầu đặt lại mật khẩu mới.");
        }
        if (LocalDateTime.now().isAfter(resetToken.getExpiryTime())) {
            throw new RuntimeException("Token đã hết hạn. Vui lòng yêu cầu đặt lại mật khẩu mới.");
        }

        return resetToken.getUser().getEmail();
    }

    // ─── Reset Password ────────────────────────────────────────────────────────

    @Transactional
    public void resetPassword(ResetPasswordDto.ConfirmReset request) {
        if (!request.getPassword().equals(request.getConfirmPassword())) {
            throw new RuntimeException("Mật khẩu mới và xác nhận mật khẩu không khớp");
        }

        PasswordResetToken resetToken = tokenRepository.findByToken(request.getToken())
                .orElseThrow(() -> new RuntimeException("Token không hợp lệ"));

        if (resetToken.isUsed() || LocalDateTime.now().isAfter(resetToken.getExpiryTime())) {
            throw new RuntimeException("Token không hợp lệ hoặc đã hết hạn");
        }

        User user = resetToken.getUser();
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        userRepository.save(user);

        resetToken.setUsed(true);
        tokenRepository.save(resetToken);

        log.info("Password reset successfully for user: {}", user.getEmail());
    }

    // ─── Get Current Profile ───────────────────────────────────────────────────

    public ProfileResponse getCurrentProfile(String currentEmail) {
        User user = userRepository.findByEmail(currentEmail)
                .orElseThrow(() -> new RuntimeException("Tài khoản không tồn tại"));

        return toProfileResponse(user);
    }

    // ─── Update Profile (fullName, email, phone) ───────────────────────────────

    @Transactional
    public ProfileResponse updateProfile(String currentEmail, UpdateProfileRequest request) {
        User user = userRepository.findByEmail(currentEmail)
                .orElseThrow(() -> new RuntimeException("Tài khoản không tồn tại"));

        String newFullName = request.getFullName().trim();
        String newEmail = request.getEmail().trim();
        String newPhone = request.getPhone().trim();

        // Nếu đổi email, kiểm tra email mới chưa được dùng bởi user khác
        if (!newEmail.equalsIgnoreCase(user.getEmail())
                && userRepository.existsByEmail(newEmail)) {
            throw new RuntimeException("Email đã được sử dụng");
        }

        // Nếu đổi sđt, kiểm tra sđt mới chưa được dùng bởi user khác
        if (!newPhone.equals(user.getPhone())
                && userRepository.existsByPhone(newPhone)) {
            throw new RuntimeException("Số điện thoại đã được sử dụng");
        }

        user.setFullName(newFullName);
        user.setEmail(newEmail);
        user.setPhone(newPhone);
        userRepository.save(user);

        log.info("Profile updated for user: {}", user.getUserId());

        return toProfileResponse(user);
    }

    // ─── Change Password (authenticated) ──────────────────────────────────────

    @Transactional
    public void changePassword(String currentEmail, ChangePasswordRequest request) {
        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new RuntimeException("Mật khẩu mới và xác nhận mật khẩu không khớp");
        }

        User user = userRepository.findByEmail(currentEmail)
                .orElseThrow(() -> new RuntimeException("Tài khoản không tồn tại"));

        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPassword())) {
            throw new RuntimeException("Mật khẩu hiện tại không đúng");
        }

        if (request.getCurrentPassword().equals(request.getNewPassword())) {
            throw new RuntimeException("Mật khẩu mới phải khác mật khẩu hiện tại");
        }

        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        log.info("Password changed successfully for user: {}", user.getEmail());
    }

    private ProfileResponse toProfileResponse(User user) {
        String roleName = user.getRole() != null ? user.getRole().getRoleName() : "CUSTOMER";
        String roleId   = user.getRole() != null ? user.getRole().getRoleId()   : "";

        return ProfileResponse.builder()
                .userId(user.getUserId())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .role(roleName)
                .roleId(roleId)
                .build();
    }
}
