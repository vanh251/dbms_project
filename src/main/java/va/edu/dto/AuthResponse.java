package va.edu.dto;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AuthResponse {
    private String token;
    private Integer userId;
    private String fullname;
    private String email;
    private Integer groupId;   // 1 = admin
}
