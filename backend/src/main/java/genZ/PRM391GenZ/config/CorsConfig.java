package genZ.PRM391GenZ.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

@Configuration
public class CorsConfig {

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();

        // Phải chỉ định origin cụ thể khi dùng allowCredentials = true
        // Wildcard (*) + credentials = true là cấu hình không hợp lệ với trình duyệt
        config.setAllowedOriginPatterns(List.of(
            "http://localhost:*",
            "http://10.0.2.2:*",
            "http://127.0.0.1:*",
            "https://*.ngrok-free.app",
            "https://*.ngrok.io"
        ));

        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));

        config.setAllowedHeaders(List.of("*"));
        config.setExposedHeaders(List.of("*"));

        config.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);

        return source;
    }
}