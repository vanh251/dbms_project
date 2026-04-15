package va.edu.dto;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class LessonDTO {
    private Integer id;
    private String name;
    private String length;
    private String description;
    private String value;    // content/video URL (only if user has permission)
    private Integer courseId;
    private Integer partId;
}
