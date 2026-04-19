package va.edu.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import va.edu.entity.Comment;
import org.springframework.data.jpa.repository.query.Procedure;
import java.util.List;
import java.util.Optional;

public interface CommentRepository extends JpaRepository<Comment, Integer> {
    @Procedure(procedureName = "sp_add_comment")
    void addComment(Integer p_user_id, Integer p_lesson_id, Integer p_parent_id, String p_content);

    List<Comment> findByLessonIdOrderByCreateAtAsc(Integer lessonId);

    Optional<Comment> findTopByUserIdAndLessonIdOrderByCreateAtDesc(Integer userId, Integer lessonId);
}
