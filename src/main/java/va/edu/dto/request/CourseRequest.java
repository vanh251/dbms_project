package va.edu.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CourseRequest {
    @NotBlank(message = "Tên khóa học không được để trống")
    @Size(max = 100, message = "Tên khóa học không quá 100 ký tự")
    private String name;

    @Size(max = 100, message = "Slug không quá 100 ký tự")
    private String slug;

    private String thumbnail;

    @Size(max = 200, message = "Mô tả không quá 200 ký tự")
    private String description;

    private String require;
    private String totalTime;
    private String price;
    private String oldPrice;
    private Integer categoryId;

    @Min(value = 0, message = "Trạng thái không hợp lệ")
    @Max(value = 1, message = "Trạng thái không hợp lệ")
    private Integer status;
}
