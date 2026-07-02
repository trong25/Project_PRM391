package genZ.PRM391GenZ.security;

import genZ.PRM391GenZ.entity.User;
import genZ.PRM391GenZ.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.*;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class UserDetailsServiceImpl implements UserDetailsService {

    private final UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("Không tìm thấy tài khoản: " + email));

        String roleId = user.getRole() != null ? user.getRole().getRoleId() : "CUSTOMER";
        String authority = roleId.toUpperCase().startsWith("ROLE_")
                ? roleId.toUpperCase()
                : "ROLE_" + roleId.toUpperCase();

        return org.springframework.security.core.userdetails.User.builder()
                .username(user.getEmail())
                .password(user.getPassword())
                .authorities(List.of(new SimpleGrantedAuthority(authority)))
                .build();
    }
}
