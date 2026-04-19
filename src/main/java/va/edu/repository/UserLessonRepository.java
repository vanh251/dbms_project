package va.edu.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import va.edu.entity.UserLesson;
import java.util.Optional;

@Repository
public interface UserLessonRepository extends JpaRepository<UserLesson, Integer> {
    Optional<UserLesson> findByUserIdAndLessonId(Integer userId, Integer lessonId);
}
