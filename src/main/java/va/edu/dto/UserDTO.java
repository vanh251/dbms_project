package va.edu.dto;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class UserDTO {
    private Integer id;
    private String fullname;
    private String email;
    private String phone;
    private String avartar;
    private String address;
    private Integer status;
    private Integer groupId;
    private String groupName;
}
