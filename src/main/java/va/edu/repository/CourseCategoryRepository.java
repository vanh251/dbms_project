package va.edu.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import va.edu.entity.CourseCategory;
import va.edu.dto.VwAdminManageCategory;
import java.util.List;

public interface CourseCategoryRepository extends JpaRepository<CourseCategory, Integer> {
    @Query(value = "SELECT * FROM vw_admin_manage_categories", nativeQuery = true)
    List<VwAdminManageCategory> getAdminManageCategories();
}
