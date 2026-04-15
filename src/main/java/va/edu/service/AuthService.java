package va.edu.service;

import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import va.edu.dto.*;
import va.edu.entity.*;
import va.edu.repository.*;
import va.edu.security.JwtUtil;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final GroupRepository groupRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email already exists");
        }
        // Default group_id = 2 (regular user)
        Group group = groupRepository.findById(2)
                .orElseGet(() -> {
                    Group g = Group.builder().name("User").build();
                    return groupRepository.save(g);
                });

        User user = User.builder()
                .fullname(request.getFullname())
                .email(request.getEmail())
                .phone(request.getPhone())
                .password(passwordEncoder.encode(request.getPassword()))
                .group(group)
                .status(1)
                .build();
        userRepository.save(user);

        String token = jwtUtil.generateToken(user.getEmail());
        return AuthResponse.builder()
                .token(token)
                .userId(user.getId())
                .fullname(user.getFullname())
                .email(user.getEmail())
                .groupId(group.getId())
                .permission(user.getPermission())
                .build();
    }

    public AuthResponse login(AuthRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Invalid email or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new RuntimeException("Invalid email or password");
        }

        String token = jwtUtil.generateToken(user.getEmail());
        Integer groupId = user.getGroup() != null ? user.getGroup().getId() : null;

        return AuthResponse.builder()
                .token(token)
                .userId(user.getId())
                .fullname(user.getFullname())
                .email(user.getEmail())
                .groupId(groupId)
                .permission(user.getPermission())
                .build();
    }
}
