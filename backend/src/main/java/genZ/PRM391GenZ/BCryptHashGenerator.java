package genZ.PRM391GenZ;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class BCryptHashGenerator {
    public static void main(String[] args) {
        String rawPassword = "Admin@123"; // ← đổi mật khẩu muốn hash ở đây
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        String hash = encoder.encode(rawPassword);
        System.out.println("Raw password : " + rawPassword);
        System.out.println("BCrypt hash  : " + hash);
    }
}
