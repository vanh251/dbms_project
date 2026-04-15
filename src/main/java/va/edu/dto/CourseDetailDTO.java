package va.edu.dto;

import lombok.*;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CourseDetailDTO {
    private Integer id;
    private String name;
    private String slug;
    private String thumbnail;
    private String description;
    private String require;
    private Integer totalLession;
    private Integer totalPart;
    private String totalTime;
    private String price;
    private String oldPrice;
    private String categoryName;
    private Integer status;
    private List<PartDTO> parts;

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class PartDTO {
        private Integer id;
        private String name;
        private List<LessonDTO> lessons;
    }
}
