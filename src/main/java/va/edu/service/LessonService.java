package va.edu.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import va.edu.dto.*;
import va.edu.entity.*;
import va.edu.repository.*;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class LessonService {

    private final LessonRepository lessonRepository;
    private final UserRepository userRepository;
    private final UserCourseRepository userCourseRepository;

    public LessonDTO getLesson(Integer lessonId, String email) {
        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new RuntimeException("Lesson not found"));

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        boolean isAdmin = user.getGroup() != null && user.getGroup().getId() == 1;

        // Kiểm tra quyền: chỉ cần tồn tại bản ghi trong user_courses
        boolean hasPermission = userCourseRepository
                .existsByUserIdAndCourseId(user.getId(), lesson.getCourse().getId());

        return LessonDTO.builder()
                .id(lesson.getId())
                .name(lesson.getName())
                .length(lesson.getLength())
                .description(lesson.getDescription())
                .value(isAdmin || hasPermission ? lesson.getValue() : null)
                .courseId(lesson.getCourse() != null ? lesson.getCourse().getId() : null)
                .partId(lesson.getPart() != null ? lesson.getPart().getId() : null)
                .build();
    }
}
