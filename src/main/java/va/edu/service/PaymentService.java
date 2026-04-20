package va.edu.service;


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

import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional
public class PaymentService {

    private final PaymentRepository paymentRepository;
    private final UserRepository userRepository;
    private final CourseRepository courseRepository;
    private final va.edu.repository.UserCourseRepository userCourseRepository;

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

        payment.setStatus(1);
        payment.setTransactionId("MANUAL_CONFIRM");
        payment.setUpdateAt(java.time.LocalDateTime.now());
        payment = paymentRepository.save(payment);

        User user = payment.getUser();
        Course course = payment.getCourse();

        // Ghi danh user vào bảng user_courses (nguon chân lý duy nhất về quyền)
        boolean alreadyEnrolled = userCourseRepository
                .existsByUserIdAndCourseId(user.getId(), course.getId());
        if (!alreadyEnrolled) {
            va.edu.entity.UserCourse uc = va.edu.entity.UserCourse.builder()
                    .user(user)
                    .course(course)
                    .status(1)
                    .progressPercent(0)
                    .createAt(java.time.LocalDateTime.now())
                    .updateAt(java.time.LocalDateTime.now())
                    .build();
            userCourseRepository.save(uc);
        }

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
