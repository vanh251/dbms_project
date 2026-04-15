package va.edu.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import va.edu.entity.TokenLogin;

public interface TokenLoginRepository extends JpaRepository<TokenLogin, Integer> {
    void deleteByUserId(Integer userId);
}
