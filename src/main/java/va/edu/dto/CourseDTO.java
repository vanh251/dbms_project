package va.edu.dto;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CourseDTO {
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
    private Integer categoryId;
    private String categoryName;
    private Integer status;
}
