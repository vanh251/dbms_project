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

    private final UserLessonRepository userLessonRepository;

    public LessonDTO getLesson(Integer lessonId, String email) {
        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new RuntimeException("Lesson not found"));

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        boolean isAdmin = user.getGroup() != null && user.getGroup().getId() == 1;

        // Kiểm tra quyền: chỉ cần tồn tại bản ghi trong user_courses
        boolean hasPermission = userCourseRepository
                .existsByUserIdAndCourseId(user.getId(), lesson.getCourse().getId());

        // Lấy trạng thái hoàn thành
        Boolean isCompleted = userLessonRepository.findByUserIdAndLessonId(user.getId(), lesson.getId())
                .map(ul -> Boolean.TRUE.equals(ul.getIsCompleted()))
                .orElse(false);

        return LessonDTO.builder()
                .id(lesson.getId())
                .name(lesson.getName())
                .length(lesson.getLength())
                .description(lesson.getDescription())
                .value(isAdmin || hasPermission ? lesson.getValue() : null)
                .courseId(lesson.getCourse() != null ? lesson.getCourse().getId() : null)
                .partId(lesson.getPart() != null ? lesson.getPart().getId() : null)
                .isCompleted(hasPermission ? isCompleted : null)
                .build();
    }

    public boolean toggleLessonCompleted(Integer lessonId, String email) {
        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new RuntimeException("Lesson not found"));

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        boolean hasPermission = userCourseRepository
                .existsByUserIdAndCourseId(user.getId(), lesson.getCourse().getId());
        if (!hasPermission) {
            throw new RuntimeException("Bạn chưa ghi danh khóa học này");
        }

        UserLesson userLesson = userLessonRepository.findByUserIdAndLessonId(user.getId(), lesson.getId())
                .orElseGet(() -> UserLesson.builder()
                        .user(user)
                        .lesson(lesson)
                        .course(lesson.getCourse())
                        .isCompleted(false)
                        .build());

        // Toggle trạng thái
        boolean newStatus = !Boolean.TRUE.equals(userLesson.getIsCompleted());
        userLesson.setIsCompleted(newStatus);
        userLessonRepository.save(userLesson);
        return newStatus;
    }
}
