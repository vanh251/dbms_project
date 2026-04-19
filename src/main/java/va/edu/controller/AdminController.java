package va.edu.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import va.edu.dto.*;
import va.edu.service.AdminService;
import java.util.*;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;
    private final va.edu.service.PaymentService paymentService;

    // --- COURSES ---
    @GetMapping("/courses")
    public ResponseEntity<ApiResponse<List<CourseDTO>>> getAllCourses() {
        return ResponseEntity.ok(ApiResponse.success(adminService.getAllCourses()));
    }

    @PostMapping("/courses")
    public ResponseEntity<ApiResponse<CourseDTO>> createCourse(@Valid @RequestBody CourseRequest req) {
        return ResponseEntity.ok(ApiResponse.success("Tạo khóa học thành công", adminService.createCourse(req)));
    }

    @PutMapping("/courses/{id}")
    public ResponseEntity<ApiResponse<CourseDTO>> updateCourse(
            @PathVariable Integer id, @Valid @RequestBody CourseRequest req) {
        return ResponseEntity.ok(ApiResponse.success("Cập nhật thành công", adminService.updateCourse(id, req)));
    }

    @DeleteMapping("/courses/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteCourse(@PathVariable Integer id) {
        adminService.deleteCourse(id);
        return ResponseEntity.ok(ApiResponse.success("Đã xóa khóa học", null));
    }

    // --- PARTS ---
    @PostMapping("/courses/{courseId}/parts")
    public ResponseEntity<ApiResponse<Map<String, Object>>> addPart(
            @PathVariable Integer courseId,
            @RequestBody Map<String, String> body) {
        String name = body.get("name");
        if (name == null || name.isBlank()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Tên chương không được để trống"));
        }
        return ResponseEntity.ok(ApiResponse.success("Thêm chương thành công", adminService.addPart(courseId, name)));
    }

    // --- LESSONS ---
    @PostMapping("/parts/{partId}/lessons")
    public ResponseEntity<ApiResponse<LessonDTO>> addLesson(
            @PathVariable Integer partId,
            @Valid @RequestBody LessonDTO req) {
        return ResponseEntity.ok(ApiResponse.success("Thêm bài học thành công", adminService.addLesson(partId, req)));
    }

    // --- USERS ---
    @GetMapping("/users")
    public ResponseEntity<ApiResponse<List<UserDTO>>> getAllUsers() {
        return ResponseEntity.ok(ApiResponse.success(adminService.getAllUsers()));
    }

    @PutMapping("/users/{userId}/permission")
    public ResponseEntity<ApiResponse<UserDTO>> grantPermission(
            @PathVariable Integer userId,
            @RequestBody Map<String, String> body) {
        String courseIds = body.get("permission");
        return ResponseEntity.ok(ApiResponse.success("Cập nhật quyền thành công", adminService.grantPermission(userId, courseIds)));
    }

    // --- CATEGORIES ---
    @GetMapping("/categories")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getCategories() {
        return ResponseEntity.ok(ApiResponse.success(adminService.getAllCategories()));
    }

    @PostMapping("/categories")
    public ResponseEntity<ApiResponse<Map<String, Object>>> createCategory(@RequestBody Map<String, String> body) {
        String name = body.get("name");
        if (name == null || name.isBlank()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Tên danh mục không được để trống"));
        }
        return ResponseEntity.ok(ApiResponse.success("Thêm danh mục thành công", adminService.createCategory(name)));
    }

    // --- PAYMENTS ---
    @GetMapping("/payments")
    public ResponseEntity<ApiResponse<List<PaymentDTO>>> getAllPayments() {
        return ResponseEntity.ok(ApiResponse.success(paymentService.getAllPayments()));
    }

    @PostMapping("/payments/{id}/confirm")
    public ResponseEntity<ApiResponse<PaymentDTO>> confirmPayment(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.success("Xác nhận thanh toán thành công", paymentService.confirmPayment(id)));
    }
}
