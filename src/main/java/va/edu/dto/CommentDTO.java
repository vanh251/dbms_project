package va.edu.dto;

import lombok.*;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CommentDTO {
    private Integer id;
    private Integer userId;
    private String userFullname;
    private Integer parentId;
    private Integer lessonId;
    private String content;
    private LocalDateTime createAt;
}
