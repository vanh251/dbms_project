package va.edu.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "courses")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Course {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(unique = true, length = 100)
    private String slug;

    @Column(length = 100)
    private String thumbnail;

    @Column(length = 200)
    private String description;

    @Column(name = "total_lession")
    private Integer totalLession;

    @Column(name = "total_part")
    private Integer totalPart;

    @Column(name = "total_time")
    private String totalTime;

    @Column(columnDefinition = "TEXT")
    private String require;

    @Column(length = 50)
    private String price;

    @Column(name = "old_price", length = 50)
    private String oldPrice;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "category_id")
    private CourseCategory category;

    @Column(columnDefinition = "INT DEFAULT 0")
    private Integer status;

    @Column(name = "create_at")
    private LocalDateTime createAt;

    @Column(name = "update_at")
    private LocalDateTime updateAt;

    @PrePersist
    protected void onCreate() {
        createAt = LocalDateTime.now();
        updateAt = LocalDateTime.now();
        if (status == null) status = 0;
        if (totalLession == null) totalLession = 0;
        if (totalPart == null) totalPart = 0;
    }

    @PreUpdate
    protected void onUpdate() {
        updateAt = LocalDateTime.now();
    }
}
