package va.edu.service;

import jakarta.persistence.EntityManager;
import jakarta.persistence.ParameterMode;
import jakarta.persistence.StoredProcedureQuery;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import va.edu.dto.PaymentDTO;
import va.edu.dto.PaymentRequest;
import va.edu.entity.Course;
import va.edu.entity.Payment;
import va.edu.entity.User;
import va.edu.repository.CourseRepository;
import va.edu.repository.PaymentRepository;
import va.edu.repository.UserRepository;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PaymentService {

    private final PaymentRepository paymentRepository;
    private final UserRepository userRepository;
    private final CourseRepository courseRepository;
    private final EntityManager entityManager;

    public PaymentDTO createPaymentOrder(String email, Integer courseId, PaymentRequest req) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Course not found"));

        StoredProcedureQuery query = entityManager.createStoredProcedureQuery("sp_create_payment_order");
        query.registerStoredProcedureParameter("p_user_id", Integer.class, ParameterMode.IN);
        query.registerStoredProcedureParameter("p_course_id", Integer.class, ParameterMode.IN);
        query.registerStoredProcedureParameter("p_payment_method", String.class, ParameterMode.IN);
        query.registerStoredProcedureParameter("p_order_id", Integer.class, ParameterMode.INOUT);

        query.setParameter("p_user_id", user.getId());
        query.setParameter("p_course_id", courseId);
        query.setParameter("p_payment_method", req.getPaymentMethod());
        query.setParameter("p_order_id", null);

        query.execute();

        Integer orderId = (Integer) query.getOutputParameterValue("p_order_id");

        Payment payment = paymentRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Failed to retrieve created payment order"));

        return toDTO(payment);
    }

    public PaymentDTO confirmPayment(Integer orderId, String transactionId) {
        paymentRepository.confirmPayment(orderId, transactionId);

        Payment payment = paymentRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Payment not found after confirmation"));

        return toDTO(payment);
    }

    public List<PaymentDTO> getPendingPayments() {
        return paymentRepository.findAllByOrderByCreateAtDesc().stream()
                .filter(p -> p.getStatus() == 0)
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    public List<PaymentDTO> getAllPayments() {
        return paymentRepository.findAllByOrderByCreateAtDesc().stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    public List<PaymentDTO> getMyPayments(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return paymentRepository.findByUserIdOrderByCreateAtDesc(user.getId()).stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    private PaymentDTO toDTO(Payment p) {
        return PaymentDTO.builder()
                .id(p.getId())
                .userId(p.getUser().getId())
                .userFullname(p.getUser().getFullname())
                .courseId(p.getCourse().getId())
                .courseName(p.getCourse().getName())
                .amount(p.getAmount())
                .paymentMethod(p.getPaymentMethod())
                .status(p.getStatus())
                .transactionId(p.getTransactionId())
                .createAt(p.getCreateAt())
                .updateAt(p.getUpdateAt())
                .build();
    }
}
