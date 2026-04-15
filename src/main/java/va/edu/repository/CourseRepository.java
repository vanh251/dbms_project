package va.edu.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import va.edu.entity.Course;
import java.util.List;

public interface CourseRepository extends JpaRepository<Course, Integer> {
    List<Course> findByStatus(Integer status);
    java.util.Optional<Course> findBySlug(String slug);
}
