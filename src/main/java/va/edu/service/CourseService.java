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
public class CourseService {

    private final CourseRepository courseRepository;
    private final PartOfCourseRepository partRepository;
    private final LessonRepository lessonRepository;
    private final UserRepository userRepository;

    public List<CourseDTO> getActiveCourses() {
        return courseRepository.findByStatus(1).stream()
                .map(this::toCourseDTO)
                .collect(Collectors.toList());
    }

    public List<CourseDTO> getAllCourses() {
        return courseRepository.findAll().stream()
                .map(this::toCourseDTO)
                .collect(Collectors.toList());
    }

    public CourseDetailDTO getCourseDetail(Integer id) {
        Course course = courseRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Course not found"));
        return toCourseDetailDTO(course);
    }

    public List<CourseDTO> getMyCourses(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
        if (user.getPermission() == null || user.getPermission().isBlank()) {
            return Collections.emptyList();
        }
        List<Integer> ids = Arrays.stream(user.getPermission().split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .map(Integer::parseInt)
                .collect(Collectors.toList());
        return courseRepository.findAllById(ids).stream()
                .map(this::toCourseDTO)
                .collect(Collectors.toList());
    }

    private CourseDTO toCourseDTO(Course c) {
        return CourseDTO.builder()
                .id(c.getId())
                .name(c.getName())
                .slug(c.getSlug())
                .thumbnail(c.getThumbnail())
                .description(c.getDescription())
                .totalLession(c.getTotalLession())
                .totalPart(c.getTotalPart())
                .totalTime(c.getTotalTime())
                .price(c.getPrice())
                .oldPrice(c.getOldPrice())
                .categoryName(c.getCategory() != null ? c.getCategory().getName() : null)
                .status(c.getStatus())
                .build();
    }

    public CourseDetailDTO toCourseDetailDTO(Course c) {
        List<PartOfCourse> parts = partRepository.findByCourseIdOrderByIdAsc(c.getId());
        List<CourseDetailDTO.PartDTO> partDTOs = parts.stream().map(p -> {
            List<Lesson> lessons = lessonRepository.findByPartIdOrderByIdAsc(p.getId());
            List<LessonDTO> lessonDTOs = lessons.stream().map(l -> LessonDTO.builder()
                    .id(l.getId())
                    .name(l.getName())
                    .length(l.getLength())
                    .courseId(c.getId())
                    .partId(p.getId())
                    .build())
                    .collect(Collectors.toList());
            return CourseDetailDTO.PartDTO.builder()
                    .id(p.getId())
                    .name(p.getName())
                    .lessons(lessonDTOs)
                    .build();
        }).collect(Collectors.toList());

        return CourseDetailDTO.builder()
                .id(c.getId())
                .name(c.getName())
                .slug(c.getSlug())
                .thumbnail(c.getThumbnail())
                .description(c.getDescription())
                .require(c.getRequire())
                .totalLession(c.getTotalLession())
                .totalPart(c.getTotalPart())
                .totalTime(c.getTotalTime())
                .price(c.getPrice())
                .oldPrice(c.getOldPrice())
                .categoryName(c.getCategory() != null ? c.getCategory().getName() : null)
                .status(c.getStatus())
                .parts(partDTOs)
                .build();
    }
}
