package va.edu.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import va.edu.entity.User;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Integer> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
}
