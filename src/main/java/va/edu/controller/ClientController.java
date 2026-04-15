package va.edu.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import va.edu.dto.*;
import va.edu.service.*;
import java.util.List;

@RestController
@RequestMapping("/api/client")
@RequiredArgsConstructor
public class ClientController {

    private final CourseService courseService;
    private final LessonService lessonService;
    private final CommentService commentService;

    @GetMapping("/courses")
    public ResponseEntity<ApiResponse<List<CourseDTO>>> getCourses() {
        return ResponseEntity.ok(ApiResponse.success(courseService.getActiveCourses()));
    }

    @GetMapping("/courses/{id}")
    public ResponseEntity<ApiResponse<CourseDetailDTO>> getCourseDetail(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.success(courseService.getCourseDetail(id)));
    }

    @GetMapping("/my-courses")
    public ResponseEntity<ApiResponse<List<CourseDTO>>> getMyCourses(
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.success(courseService.getMyCourses(userDetails.getUsername())));
    }

    @GetMapping("/lessons/{id}")
    public ResponseEntity<ApiResponse<LessonDTO>> getLesson(
            @PathVariable Integer id,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.success(lessonService.getLesson(id, userDetails.getUsername())));
    }

    @GetMapping("/lessons/{id}/comments")
    public ResponseEntity<ApiResponse<List<CommentDTO>>> getComments(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.success(commentService.getCommentsByLesson(id)));
    }

    @PostMapping("/lessons/{id}/comments")
    public ResponseEntity<ApiResponse<CommentDTO>> postComment(
            @PathVariable Integer id,
            @Valid @RequestBody CommentRequest req,
            @AuthenticationPrincipal UserDetails userDetails) {
        CommentDTO comment = commentService.addComment(id, userDetails.getUsername(), req);
        return ResponseEntity.ok(ApiResponse.success("Bình luận thành công", comment));
    }
}
