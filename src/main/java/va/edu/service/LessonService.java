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
    private final LessonProgressBuffer lessonProgressBuffer;

    public LessonDTO getLesson(Integer lessonId, String email) {
        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new RuntimeException("Lesson not found"));

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        boolean isAdmin = user.getGroup() != null && user.getGroup().getId() == 1;

        // Kiểm tra quyền: chỉ cần tồn tại bản ghi trong user_courses
        boolean hasPermission = userCourseRepository
                .existsByUserIdAndCourseId(user.getId(), lesson.getCourse().getId());

        // Lấy trạng thái hoàn thành: Ưu tiên lấy từ RAM (buffer) trước, nếu không có mới query DB
        Boolean bufferedStatus = lessonProgressBuffer.getBufferedProgress(user.getId(), lesson.getId());
        Boolean isCompleted;
        if (bufferedStatus != null) {
            isCompleted = bufferedStatus;
        } else {
            isCompleted = userLessonRepository.findByUserIdAndLessonId(user.getId(), lesson.getId())
                    .map(ul -> Boolean.TRUE.equals(ul.getIsCompleted()))
                    .orElse(false);
        }

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

        // Đọc trạng thái hiện tại (ưu tiên từ Buffer)
        Boolean bufferedStatus = lessonProgressBuffer.getBufferedProgress(user.getId(), lesson.getId());
        boolean currentStatus;
        if (bufferedStatus != null) {
            currentStatus = bufferedStatus;
        } else {
            currentStatus = userLessonRepository.findByUserIdAndLessonId(user.getId(), lesson.getId())
                    .map(ul -> Boolean.TRUE.equals(ul.getIsCompleted()))
                    .orElse(false);
        }

        // Toggle trạng thái
        boolean newStatus = !currentStatus;
        
        // Ghi vào RAM (Buffer) thay vì ghi trực tiếp xuống DB
        lessonProgressBuffer.bufferProgress(user.getId(), lesson.getId(), lesson.getCourse().getId(), newStatus);
        
        return newStatus;
    }
}
