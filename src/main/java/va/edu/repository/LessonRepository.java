package va.edu.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import va.edu.entity.Lesson;
import java.util.List;

public interface LessonRepository extends JpaRepository<Lesson, Integer> {
    List<Lesson> findByCourseIdOrderByIdAsc(Integer courseId);
    List<Lesson> findByPartIdOrderByIdAsc(Integer partId);
}
