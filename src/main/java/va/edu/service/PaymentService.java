package va.edu.service;


import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import va.edu.dto.PaymentDTO;
import va.edu.dto.request.PaymentRequest;
import va.edu.entity.Course;
import va.edu.entity.Payment;
import va.edu.entity.User;
import va.edu.repository.CourseRepository;
import va.edu.repository.PaymentRepository;
import va.edu.repository.UserRepository;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional
public class PaymentService {

    private final PaymentRepository paymentRepository;
    private final UserRepository userRepository;
    private final CourseRepository courseRepository;

    public PaymentDTO createPaymentOrder(String email, Integer courseId, PaymentRequest req) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Course not found"));

        java.math.BigDecimal amount = java.math.BigDecimal.ZERO;
        try {
            if (course.getPrice() != null && !course.getPrice().isBlank()) {
                String numericPrice = course.getPrice().replaceAll("[^0-9]", "");
                if (!numericPrice.isEmpty()) {
                    amount = new java.math.BigDecimal(numericPrice);
                }
            }
        } catch (Exception e) {
            // Ignore parse error, default to 0
        }

        Payment payment = Payment.builder()
                .user(user)
                .course(course)
                .amount(amount)
                .paymentMethod(req.getPaymentMethod())
                .status(0)
                .createAt(java.time.LocalDateTime.now())
                .updateAt(java.time.LocalDateTime.now())
                .build();

        payment = paymentRepository.save(payment);
        return toDTO(payment);
    }

    public PaymentDTO confirmPayment(Integer orderId) {
        Payment payment = paymentRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Payment not found"));

        if (payment.getStatus() == 1) {
            return toDTO(payment); // Already confirmed
        }

        // Gọi stored procedure — transaction đảm bảo cả hai bước (update payment + enroll user)
        // được commit hoặc rollback cùng nhau ở tầng DB.
        String transactionId = "MANUAL_" + orderId + "_" + System.currentTimeMillis();
        paymentRepository.confirmPayment(orderId, transactionId);

        // Reload để lấy dữ liệu mới nhất sau khi procedure chạy
        payment = paymentRepository.findById(orderId)
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
