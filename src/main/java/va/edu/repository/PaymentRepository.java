package va.edu.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.stereotype.Repository;
import va.edu.entity.Payment;
import java.util.List;
import java.util.Optional;

@Repository
public interface PaymentRepository extends JpaRepository<Payment, Integer> {
    Optional<Payment> findByTransactionId(String transactionId);
    List<Payment> findByUserIdOrderByCreateAtDesc(Integer userId);
    List<Payment> findAllByOrderByCreateAtDesc();

    @Procedure(procedureName = "sp_transaction_confirm_payment")
    void confirmPayment(Integer p_order_id, String p_transaction_id);
}
