package va.edu.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import va.edu.entity.User;
import va.edu.dto.VwAdminManageUser;
import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Integer> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);

    @Query(value = "SELECT * FROM vw_admin_manage_users", nativeQuery = true)
    List<VwAdminManageUser> getAdminManageUsers();
}
