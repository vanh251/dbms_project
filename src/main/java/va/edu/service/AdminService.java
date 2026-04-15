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
public class AdminService {

    private final CourseRepository courseRepository;
    private final CourseCategoryRepository categoryRepository;
    private final PartOfCourseRepository partRepository;
    private final LessonRepository lessonRepository;
    private final UserRepository userRepository;

    // --- COURSE CRUD ---
    public List<CourseDTO> getAllCourses() {
        return courseRepository.findAll().stream()
                .map(this::toCourseDTO)
                .collect(Collectors.toList());
    }

    public CourseDTO createCourse(CourseRequest req) {
        CourseCategory category = req.getCategoryId() != null
                ? categoryRepository.findById(req.getCategoryId()).orElse(null) : null;

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
                ? categoryRepository.findById(req.getCategoryId()).orElse(null) : null;

        course.setName(req.getName());
        course.setSlug(req.getSlug());
        course.setThumbnail(req.getThumbnail());
        course.setDescription(req.getDescription());
        course.setRequire(req.getRequire());
        course.setTotalTime(req.getTotalTime());
        course.setPrice(req.getPrice());
        course.setOldPrice(req.getOldPrice());
        course.setCategory(category);
        if (req.getStatus() != null) course.setStatus(req.getStatus());
        courseRepository.save(course);
        return toCourseDTO(course);
    }

    public void deleteCourse(Integer id) {
        courseRepository.deleteById(id);
    }

    // --- PART CRUD ---
    public Map<String, Object> addPart(Integer courseId, String name) {
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Course not found"));
        PartOfCourse part = PartOfCourse.builder().course(course).name(name).build();
        PartOfCourse saved = partRepository.save(part);
        course.setTotalPart(course.getTotalPart() + 1);
        courseRepository.save(course);
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
        Course course = part.getCourse();
        course.setTotalLession(course.getTotalLession() + 1);
        courseRepository.save(course);
        return toLessonDTO(saved);
    }

    // --- USER MANAGEMENT ---
    public List<UserDTO> getAllUsers() {
        return userRepository.findAll().stream().map(this::toUserDTO).collect(Collectors.toList());
    }

    public UserDTO grantPermission(Integer userId, String courseIds) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.setPermission(courseIds);
        userRepository.save(user);
        return toUserDTO(user);
    }

    // --- CATEGORY ---
    public List<Map<String, Object>> getAllCategories() {
        return categoryRepository.findAll().stream()
                .map(c -> Map.<String, Object>of("id", c.getId(), "name", c.getName()))
                .collect(Collectors.toList());
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
                .status(u.getStatus()).permission(u.getPermission())
                .groupId(u.getGroup() != null ? u.getGroup().getId() : null)
                .groupName(u.getGroup() != null ? u.getGroup().getName() : null)
                .build();
    }
}
