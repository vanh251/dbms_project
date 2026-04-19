package va.edu.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class PaymentRequest {
    @NotBlank(message = "Phương thức thanh toán không được để trống")
    private String paymentMethod;
}
