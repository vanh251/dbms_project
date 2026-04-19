-- ==============================================================================
-- DATABASE TRIGGERS CHO DỰ ÁN E-LEARNING
-- Mục đích: Đảm bảo tính toàn vẹn dữ liệu tự động mà không cần backend xử lý.
-- ==============================================================================


-- ------------------------------------------------------------------------------
-- 1. TRIGGER: TỰ ĐỘNG CẬP NHẬT THỜI GIAN (update_at)
-- Trong PostgreSQL, không có thuộc tính "ON UPDATE CURRENT_TIMESTAMP" như MySQL.
-- Phải dùng Trigger để các bảng tự cập nhật ngày chỉnh sửa cuối khi có thay đổi.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.update_at = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Áp dụng trigger này cho các bảng cần thiết:
CREATE TRIGGER trg_users_update_at BEFORE UPDATE ON "users" FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();
CREATE TRIGGER trg_courses_update_at BEFORE UPDATE ON "courses" FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();
CREATE TRIGGER trg_lessions_update_at BEFORE UPDATE ON "lessions" FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();
CREATE TRIGGER trg_payments_update_at BEFORE UPDATE ON "payments" FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();
CREATE TRIGGER trg_user_courses_update_at BEFORE UPDATE ON "user_courses" FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();


-- ------------------------------------------------------------------------------
-- 2. TRIGGER: TỰ ĐỘNG TÍNH TỔNG SỐ CHƯƠNG (total_part)
-- Khi Thêm/Xóa 1 Chương (part) -> Tự động Cộng/Trừ số lượng trong bảng Course
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_update_total_part()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
UPDATE "courses" SET total_part = total_part + 1 WHERE id = NEW.course_id;
RETURN NEW;
ELSIF TG_OP = 'DELETE' THEN
UPDATE "courses" SET total_part = total_part - 1 WHERE id = OLD.course_id;
RETURN OLD;
END IF;
RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_count_part
    AFTER INSERT OR DELETE ON "part_of_courses"
FOR EACH ROW EXECUTE FUNCTION fn_update_total_part();


-- ------------------------------------------------------------------------------
-- 3. TRIGGER: TỰ ĐỘNG TÍNH TỔNG SỐ BÀI HỌC (total_lession)
-- Khi Thêm/Xóa 1 Bài học (lesson) -> Tự động Cộng/Trừ số lượng trong bảng Course
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_update_total_lession()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
UPDATE "courses" SET total_lession = total_lession + 1 WHERE id = NEW.course_id;
RETURN NEW;
ELSIF TG_OP = 'DELETE' THEN
UPDATE "courses" SET total_lession = total_lession - 1 WHERE id = OLD.course_id;
RETURN OLD;
END IF;
RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_count_lession
    AFTER INSERT OR DELETE ON "lessions"
FOR EACH ROW EXECUTE FUNCTION fn_update_total_lession();


-- ------------------------------------------------------------------------------
-- 4. TRIGGER: TỰ ĐỘNG CHUYỂN TRẠNG THÁI HOÀN THÀNH KHI TIẾN ĐỘ = 100%
-- Bắt sự kiện khi update tiến độ học viên của bảng lưu Enrollment
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_auto_complete_course()
RETURNS TRIGGER AS $$
BEGIN
    -- Nếu Backend cập nhật tiến độ đạt hoặc vượt 100, và trạng thái vẫn đang mở (1)
    IF NEW.progress_percent >= 100 AND NEW.status = 1 THEN
        NEW.status = 2; -- Chuyển trạng thái: Đã hoàn thành hệ thống
        NEW.progress_percent = 100;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_course_completion
    BEFORE UPDATE ON "user_courses"
    FOR EACH ROW
    WHEN (NEW.progress_percent IS DISTINCT FROM OLD.progress_percent) -- Chỉ kích hoạt khi phần trăm bị thay đổi
EXECUTE FUNCTION fn_auto_complete_course();