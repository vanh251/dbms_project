package va.edu.dto;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class PaymentDTO {
    private Integer id;
    private Integer userId;
    private String userFullname;
    private Integer courseId;
    private String courseName;
    private BigDecimal amount;
    private String paymentMethod;
    private Integer status;
    private String transactionId;
    private LocalDateTime createAt;
    private LocalDateTime updateAt;
}
