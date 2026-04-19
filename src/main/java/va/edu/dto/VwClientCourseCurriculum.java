package va.edu.dto;

public interface VwClientCourseCurriculum {
    Integer getCourseId();
    Integer getPartId();
    String getPartName();
    Long getTotalLessionsInPart();
    Integer getLessionId();
    String getLessionName();
    String getLessionLength();
}
