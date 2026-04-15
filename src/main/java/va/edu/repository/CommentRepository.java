package va.edu.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import va.edu.entity.Comment;
import java.util.List;

public interface CommentRepository extends JpaRepository<Comment, Integer> {
    List<Comment> findByLessonIdOrderByCreateAtAsc(Integer lessonId);
}
