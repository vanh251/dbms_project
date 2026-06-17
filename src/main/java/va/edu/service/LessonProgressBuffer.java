package va.edu.service;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.BatchPreparedStatementSetter;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
@RequiredArgsConstructor
@Slf4j
public class LessonProgressBuffer {

    private final JdbcTemplate jdbcTemplate;

    // Buffer: Key = "userId_lessonId", Value = ProgressData
    private final ConcurrentHashMap<String, ProgressData> progressBuffer = new ConcurrentHashMap<>();

    @Data
    @AllArgsConstructor
    public static class ProgressData {
        private Integer userId;
        private Integer lessonId;
        private Integer courseId;
        private Boolean isCompleted;
    }

    /**
     * Thêm tiến độ bài học vào buffer bộ nhớ trong (RAM).
     * Hàm này phản hồi cực nhanh vì không gọi xuống DB.
     */
    public void bufferProgress(Integer userId, Integer lessonId, Integer courseId, Boolean isCompleted) {
        String key = userId + "_" + lessonId;
        progressBuffer.put(key, new ProgressData(userId, lessonId, courseId, isCompleted));
        log.info("BUFFER GHI (RAM): Đã đưa tiến độ bài học {} của User {} vào bộ đệm tạm thời.", lessonId, userId);
    }

    public Boolean getBufferedProgress(Integer userId, Integer lessonId) {
        String key = userId + "_" + lessonId;
        ProgressData data = progressBuffer.get(key);
        return data != null ? data.getIsCompleted() : null;
    }

    /**
     * Lấy dữ liệu từ buffer và ghi xuống DB định kỳ.
     * Cấu hình thời gian lấy từ application.properties
     */
    @Scheduled(fixedDelayString = "${app.buffer.progress.flush-delay-ms:10000}")
    @Transactional
    public void flushProgressToDB() {
        if (progressBuffer.isEmpty()) {
            return;
        }

        // 1. Copy dữ liệu để xả, đồng thời clear buffer gốc cho các request mới
        Map<String, ProgressData> batchData;
        synchronized (this) {
            batchData = new ConcurrentHashMap<>(progressBuffer);
            progressBuffer.clear();
        }

        List<ProgressData> recordsToUpdate = new ArrayList<>(batchData.values());

        // 2. Sử dụng Upsert (INSERT ON CONFLICT) của PostgreSQL để batch
        String sql = "INSERT INTO user_lessons(user_id, lession_id, course_id, is_completed, update_at) " +
                     "VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP) " +
                     "ON CONFLICT (user_id, lession_id) " +
                     "DO UPDATE SET is_completed = EXCLUDED.is_completed, update_at = EXCLUDED.update_at";

        jdbcTemplate.batchUpdate(sql, new BatchPreparedStatementSetter() {
            @Override
            public void setValues(PreparedStatement ps, int i) throws SQLException {
                ProgressData data = recordsToUpdate.get(i);
                ps.setInt(1, data.getUserId());
                ps.setInt(2, data.getLessonId());
                ps.setInt(3, data.getCourseId());
                ps.setBoolean(4, data.getIsCompleted());
            }

            @Override
            public int getBatchSize() {
                return recordsToUpdate.size();
            }
        });

        log.info("BUFFER GHI (DB): Đã xả thành công lô (batch) {} bản ghi tiến độ xuống Database.", recordsToUpdate.size());
    }
}
