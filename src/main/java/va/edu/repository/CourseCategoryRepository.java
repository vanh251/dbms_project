package va.edu.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import va.edu.entity.CourseCategory;

public interface CourseCategoryRepository extends JpaRepository<CourseCategory, Integer> {
}
