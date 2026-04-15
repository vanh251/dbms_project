package va.edu.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import va.edu.entity.PartOfCourse;
import java.util.List;

public interface PartOfCourseRepository extends JpaRepository<PartOfCourse, Integer> {
    List<PartOfCourse> findByCourseIdOrderByIdAsc(Integer courseId);
}
