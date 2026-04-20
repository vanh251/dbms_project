package va.edu.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import va.edu.dto.*;
import va.edu.dto.request.CourseRequest;
import va.edu.entity.*;
import va.edu.repository.*;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final CourseRepository courseRepository;
    private final CourseCategoryRepository categoryRepository;
    private final PartOfCourseRepository partRepository;
    private final LessonRepository lessonRepository;
    private final UserRepository userRepository;
    private final UserCourseRepository userCourseRepository;

    // --- COURSE CRUD ---
    public List<CourseDTO> getAllCourses() {
        return courseRepository.getAdminManageCourses().stream()
                .map(vw -> CourseDTO.builder()
                        .id(vw.getCourseId())
                        .name(vw.getCourseName())
                        .slug(vw.getSlug())
                        .thumbnail(vw.getThumbnail())
                        .description(vw.getDescription())
                        .require(vw.getRequire())
                        .totalLession(vw.getTotalLession())
                        .totalPart(vw.getTotalPart())
                        .totalTime(vw.getTotalTime())
                        .price(vw.getPrice())
                        .oldPrice(vw.getOldPrice())
                        .categoryId(vw.getCategoryId())
                        .categoryName(vw.getCategoryName())
                        .status(vw.getStatus())
                        .build())
                .collect(Collectors.toList());
    }

    public CourseDTO createCourse(CourseRequest req) {
        CourseCategory category = req.getCategoryId() != null
                ? categoryRepository.findById(req.getCategoryId()).orElse(null)
                : null;

        Course course = Course.builder()
                .name(req.getName())
                .slug(req.getSlug())
                .thumbnail(req.getThumbnail())
                .description(req.getDescription())
                .require(req.getRequire())
                .totalTime(req.getTotalTime())
                .price(req.getPrice())
                .oldPrice(req.getOldPrice())
                .category(category)
                .status(req.getStatus() != null ? req.getStatus() : 0)
                .build();
        Course saved = courseRepository.save(course);
        return toCourseDTO(saved);
    }

    public CourseDTO updateCourse(Integer id, CourseRequest req) {
        Course course = courseRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Course not found"));
        CourseCategory category = req.getCategoryId() != null
                ? categoryRepository.findById(req.getCategoryId()).orElse(null)
                : null;

        course.setName(req.getName());
        course.setSlug(req.getSlug());
        course.setThumbnail(req.getThumbnail());
        course.setDescription(req.getDescription());
        course.setRequire(req.getRequire());
        course.setTotalTime(req.getTotalTime());
        course.setPrice(req.getPrice());
        course.setOldPrice(req.getOldPrice());
        course.setCategory(category);
        if (req.getStatus() != null)
            course.setStatus(req.getStatus());
        courseRepository.save(course);
        return toCourseDTO(course);
    }

    public void deleteCourse(Integer id) {
        courseRepository.deleteCourse(id);
    }

    // --- PART CRUD ---
    public Map<String, Object> addPart(Integer courseId, String name) {
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Course not found"));
        PartOfCourse part = PartOfCourse.builder().course(course).name(name).build();
        PartOfCourse saved = partRepository.save(part);
        // course.setTotalPart(course.getTotalPart() + 1);
        // courseRepository.save(course); // Bỏ qua vì đã có Trigger
        // fn_update_total_part
        return Map.of("id", saved.getId(), "name", saved.getName());
    }

    // --- LESSON CRUD ---
    public LessonDTO addLesson(Integer partId, LessonDTO req) {
        PartOfCourse part = partRepository.findById(partId)
                .orElseThrow(() -> new RuntimeException("Part not found"));
        Lesson lesson = Lesson.builder()
                .name(req.getName())
                .length(req.getLength())
                .description(req.getDescription())
                .value(req.getValue())
                .course(part.getCourse())
                .part(part)
                .build();
        Lesson saved = lessonRepository.save(lesson);
        // Course course = part.getCourse();
        // course.setTotalLession(course.getTotalLession() + 1);
        // courseRepository.save(course); // Bỏ qua vì đã có Trigger
        // fn_update_total_lession
        return toLessonDTO(saved);
    }

    // --- USER MANAGEMENT ---
    public List<UserDTO> getAllUsers() {
        return userRepository.getAdminManageUsers().stream()
                .map(vw -> UserDTO.builder()
                        .id(vw.getUserId())
                        .fullname(vw.getFullname())
                        .email(vw.getEmail())
                        .groupName(vw.getGroupName())
                        .build())
                .collect(Collectors.toList());
    }

    /**
     * Trả về danh sách khóa học mà user đã ghi danh (để admin xem, không cần phân
     * quyền thủ công)
     */
    public List<CourseDTO> getUserCourses(Integer userId) {
        List<Integer> courseIds = userCourseRepository.findCourseIdsByUserId(userId);
        if (courseIds.isEmpty())
            return Collections.emptyList();
        return courseRepository.findAllById(courseIds).stream()
                .map(this::toCourseDTO)
                .collect(Collectors.toList());
    }

    /**
     * Cấp quyền: ghi danh user vào từng course trong danh sách courseIds (cách nhau
     * bằng dấu phẩy).
     * Đây là nguồn chân lý duy nhất – không còn dùng cột permission trên bảng
     * users.
     */
    public UserDTO grantPermission(Integer userId, String courseIds) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (courseIds != null && !courseIds.isBlank()) {
            java.util.Arrays.stream(courseIds.split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .map(Integer::parseInt)
                    .forEach(courseId -> {
                        if (!userCourseRepository.existsByUserIdAndCourseId(userId, courseId)) {
                            courseRepository.findById(courseId).ifPresent(course -> {
                                va.edu.entity.UserCourse uc = va.edu.entity.UserCourse.builder()
                                        .user(user)
                                        .course(course)
                                        .status(1)
                                        .progressPercent(0)
                                        .createAt(java.time.LocalDateTime.now())
                                        .updateAt(java.time.LocalDateTime.now())
                                        .build();
                                userCourseRepository.save(uc);
                            });
                        }
                    });
        }
        return toUserDTO(user);
    }

    // --- CATEGORY ---
    public List<Map<String, Object>> getAllCategories() {
        return categoryRepository.getAdminManageCategories().stream()
                .map(vw -> Map.<String, Object>of(
                        "id", vw.getCategoryId(),
                        "name", vw.getCategoryName(),
                        "totalCourses", vw.getTotalCourses()))
                .collect(Collectors.toList());
    }

    public Map<String, Object> createCategory(String name) {
        CourseCategory category = CourseCategory.builder().name(name).build();
        CourseCategory saved = categoryRepository.save(category);
        return Map.<String, Object>of("id", saved.getId(), "name", saved.getName());
    }

    public void deleteCategory(Integer id) {
        categoryRepository.deleteById(id);
    }

    private CourseDTO toCourseDTO(Course c) {
        return CourseDTO.builder()
                .id(c.getId()).name(c.getName()).slug(c.getSlug())
                .thumbnail(c.getThumbnail()).description(c.getDescription())
                .totalLession(c.getTotalLession()).totalPart(c.getTotalPart())
                .totalTime(c.getTotalTime()).price(c.getPrice()).oldPrice(c.getOldPrice())
                .categoryName(c.getCategory() != null ? c.getCategory().getName() : null)
                .status(c.getStatus()).build();
    }

    private LessonDTO toLessonDTO(Lesson l) {
        return LessonDTO.builder()
                .id(l.getId()).name(l.getName()).length(l.getLength())
                .description(l.getDescription()).value(l.getValue())
                .courseId(l.getCourse() != null ? l.getCourse().getId() : null)
                .partId(l.getPart() != null ? l.getPart().getId() : null)
                .build();
    }

    private UserDTO toUserDTO(User u) {
        return UserDTO.builder()
                .id(u.getId()).fullname(u.getFullname()).email(u.getEmail())
                .phone(u.getPhone()).avartar(u.getAvartar()).address(u.getAddress())
                .status(u.getStatus())
                .groupId(u.getGroup() != null ? u.getGroup().getId() : null)
                .groupName(u.getGroup() != null ? u.getGroup().getName() : null)
                .build();
    }
}
