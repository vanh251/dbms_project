package va.edu.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import va.edu.entity.Group;

public interface GroupRepository extends JpaRepository<Group, Integer> {
}
