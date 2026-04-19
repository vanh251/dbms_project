package va.edu.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.stereotype.Repository;
import va.edu.entity.UserCourse;
import java.util.Optional;

@Repository
public interface UserCourseRepository extends JpaRepository<UserCourse, Integer> {
    Optional<UserCourse> findByUserIdAndCourseId(Integer userId, Integer courseId);

    @Procedure(procedureName = "sp_enroll_course")
    void enrollCourse(Integer p_user_id, Integer p_course_id);

    @Procedure(procedureName = "sp_unenroll_course")
    void unenrollCourse(Integer p_user_id, Integer p_course_id);
}
