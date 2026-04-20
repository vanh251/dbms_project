package va.edu.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import va.edu.dto.*;
import va.edu.dto.request.CommentRequest;
import va.edu.entity.*;
import va.edu.repository.*;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CommentService {

    private final CommentRepository commentRepository;
    private final LessonRepository lessonRepository;
    private final UserRepository userRepository;

    public List<CommentDTO> getCommentsByLesson(Integer lessonId) {
        return commentRepository.findByLessonIdOrderByCreateAtAsc(lessonId)
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    public CommentDTO addComment(Integer lessonId, String email, CommentRequest req) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new RuntimeException("Lesson not found"));

        commentRepository.addComment(user.getId(), lesson.getId(), req.getParentId(), req.getContent());
        Comment saved = commentRepository.findTopByUserIdAndLessonIdOrderByCreateAtDesc(user.getId(), lesson.getId())
                .orElseThrow(() -> new RuntimeException("Failed to retrieve saved comment"));
        return toDTO(saved);
    }

    private CommentDTO toDTO(Comment c) {
        return CommentDTO.builder()
                .id(c.getId())
                .userId(c.getUser().getId())
                .userFullname(c.getUser().getFullname())
                .parentId(c.getParentId())
                .lessonId(c.getLesson().getId())
                .content(c.getContent())
                .createAt(c.getCreateAt())
                .build();
    }
}
