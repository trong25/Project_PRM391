package genZ.PRM391GenZ.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfigurationSource;

@Configuration
public class SecurityConfig {

    private final CorsConfigurationSource corsConfigurationSource;
    private final JwtAuthFilter jwtAuthFilter;

    public SecurityConfig(
            CorsConfigurationSource corsConfigurationSource,
            JwtAuthFilter jwtAuthFilter
    ) {
        this.corsConfigurationSource = corsConfigurationSource;
        this.jwtAuthFilter = jwtAuthFilter;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {

        http
                .cors(cors -> cors.configurationSource(corsConfigurationSource))
                .csrf(csrf -> csrf.disable())

                .authorizeHttpRequests(auth -> auth

                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()

                        //======================
                        // AUTH
                        //======================
                        .requestMatchers(
                                "/auth/login",
                                "/auth/register",
                                "/auth/request-reset",
                                "/auth/verify-token",
                                "/auth/reset-password",
                                "/auth/logout",
                                "/webhook/sepay"
                        ).permitAll()

                        //======================
                        // PUBLIC API
                        //======================
                        .requestMatchers(HttpMethod.GET,
                                "/rooms/**",
                                "/rooms",
                                "/hotels/**",
                                "/hotels",
                                "/type-rooms/**",
                                "/type-rooms"
                        ).permitAll()


                        //================================================
                        // CUSTOMER xem voucher Active
                        //================================================
                        .requestMatchers(HttpMethod.GET,
                                "/discount/active")
                        .authenticated()

                        //================================================
                        // STAFF xem toàn bộ voucher
                        //================================================
                        .requestMatchers(HttpMethod.GET,
                                "/discount")
                        .hasRole("STAFF")

                        .requestMatchers(HttpMethod.GET,
                                "/discount/{id}")
                        .hasRole("STAFF")

                        //================================================
                        // STAFF CRUD
                        //================================================
                        .requestMatchers(HttpMethod.POST,
                                "/discount")
                        .hasRole("STAFF")

                        .requestMatchers(HttpMethod.PUT,
                                "/discount/**")
                        .hasRole("STAFF")

                        .requestMatchers(HttpMethod.DELETE,
                                "/discount/**")
                        .hasRole("STAFF")


                        // WebSocket STOMP endpoint - allow handshake without token
                        // (token được truyền qua STOMP header sau khi kết nối)
                        .requestMatchers("/ws/**").permitAll()
                        // All other requests (including /auth/profile, /auth/change-password) need auth

                        .anyRequest().authenticated()
                )

                .sessionManagement(session ->
                        session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                )

                .addFilterBefore(jwtAuthFilter,
                        UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public AuthenticationManager authenticationManager(
            AuthenticationConfiguration configuration)
            throws Exception {

        return configuration.getAuthenticationManager();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}