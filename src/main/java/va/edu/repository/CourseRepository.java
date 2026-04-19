package va.edu.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.query.Procedure;
import va.edu.entity.Course;
import va.edu.dto.VwClientCourseCard;
import va.edu.dto.VwClientCourseCurriculum;
import va.edu.dto.VwAdminManageCourse;
import java.util.List;

public interface CourseRepository extends JpaRepository<Course, Integer> {
    List<Course> findByStatus(Integer status);
    java.util.Optional<Course> findBySlug(String slug);

    @Query(value = "SELECT * FROM vw_client_course_cards", nativeQuery = true)
    List<VwClientCourseCard> getClientCourseCards();

    @Query(value = "SELECT * FROM vw_client_course_curriculum WHERE course_id = :courseId", nativeQuery = true)
    List<VwClientCourseCurriculum> getClientCourseCurriculum(Integer courseId);

    @Query(value = "SELECT * FROM vw_admin_manage_courses", nativeQuery = true)
    List<VwAdminManageCourse> getAdminManageCourses();

    @Procedure(procedureName = "sp_create_course")
    Integer createCourse(String p_name, String p_slug, String p_thumbnail, String p_description, String p_require, String p_price, Integer p_category_id);

    @Procedure(procedureName = "sp_publish_course")
    void publishCourse(Integer p_course_id);

    @Procedure(procedureName = "sp_transaction_init_full_course")
    void initFullCourse(String p_name, Integer p_category_id, Integer p_instructor_id);

    @Procedure(procedureName = "sp_transaction_cancel_course_and_refund")
    void cancelCourseAndRefund(Integer p_course_id);
}
