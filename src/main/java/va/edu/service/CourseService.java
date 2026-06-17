package va.edu.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import va.edu.dto.*;
import va.edu.entity.*;
import va.edu.repository.*;
import java.util.*;
import java.util.stream.Collectors;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.scheduling.annotation.Scheduled;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class CourseService {

    private final CourseRepository courseRepository;
    private final PartOfCourseRepository partRepository;
    private final LessonRepository lessonRepository;
    private final UserRepository userRepository;
    private final UserCourseRepository userCourseRepository;

    @Scheduled(fixedRateString = "1800000") // 30 phút = 1800000 ms
    @CacheEvict(value = {"active_courses", "course_detail"}, allEntries = true)
    public void clearCourseCaches() {
        log.info("BUFFER ĐỌC: Đã tự động dọn dẹp toàn bộ bộ nhớ đệm (RAM) sau 30 phút để cập nhật dữ liệu mới.");
    }

    @Cacheable(value = "active_courses")
    public List<CourseDTO> getActiveCourses() {
        log.info("BUFFER ĐỌC (CACHE MISS): Phải truy xuất danh sách khóa học Active từ Database!");
        return courseRepository.getClientCourseCards().stream()
                .map(vw -> CourseDTO.builder()
                        .id(vw.getCourseId())
                        .name(vw.getCourseName())
                        .categoryName(vw.getCategoryName())
                        .description(vw.getDescription())
                        .totalLession(vw.getTotalLession())
                        .totalPart(vw.getTotalPart())
                        .totalTime(vw.getTotalTime())
                        .price(vw.getPrice())
                        .oldPrice(vw.getOldPrice())
                        .thumbnail(vw.getThumbnail())
                        .status(1)
                        .build())
                .collect(Collectors.toList());
    }

    public List<CourseDTO> getAllCourses() {
        return courseRepository.findAll().stream()
                .map(this::toCourseDTO)
                .collect(Collectors.toList());
    }

    @Cacheable(value = "course_detail", key = "#id")
    public CourseDetailDTO getCourseDetail(Integer id) {
        log.info("BUFFER ĐỌC (CACHE MISS): Phải truy xuất chi tiết khóa học ID={} từ Database!", id);
        Course course = courseRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Course not found"));
        return toCourseDetailDTO(course);
    }

    public List<CourseDTO> getMyCourses(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        List<UserCourse> userCourses = userCourseRepository.findByUserId(user.getId());
        if (userCourses.isEmpty()) return Collections.emptyList();
        
        return userCourses.stream().map(uc -> {
            CourseDTO dto = toCourseDTO(uc.getCourse());
            dto.setProgressPercent(uc.getProgressPercent());
            return dto;
        }).collect(Collectors.toList());
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
        List<VwClientCourseCurriculum> curriculum = courseRepository.getClientCourseCurriculum(c.getId());
        
        Map<Integer, CourseDetailDTO.PartDTO> partMap = new LinkedHashMap<>();
        for (VwClientCourseCurriculum row : curriculum) {
            Integer partId = row.getPartId();
            if (partId == null) continue;
            CourseDetailDTO.PartDTO partDTO = partMap.computeIfAbsent(partId, k -> 
                CourseDetailDTO.PartDTO.builder()
                    .id(partId)
                    .name(row.getPartName())
                    .lessons(new ArrayList<>())
                    .build()
            );
            if (row.getLessionId() != null) {
                partDTO.getLessons().add(LessonDTO.builder()
                    .id(row.getLessionId())
                    .name(row.getLessionName())
                    .length(row.getLessionLength())
                    .courseId(c.getId())
                    .partId(partId)
                    .build());
            }
        }

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
                .parts(new ArrayList<>(partMap.values()))
                .build();
    }
}
