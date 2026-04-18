-- ---------------------------------------------------------
-- 3. TẠO CÁC KHUNG NHÌN (VIEWS)
-- ---------------------------------------------------------

-- View Chi tiết khóa học kèm danh mục và số lượng bình luận
CREATE OR REPLACE VIEW vw_Course_Details AS
SELECT
    c.id AS course_id,
    c.name AS course_name,
    c.price,
    c.status,
    cc.name AS category_name,
    (SELECT COUNT(*) FROM comments cm JOIN lessions l ON cm.lession_id = l.id WHERE l.course_id = c.id) AS total_comments
FROM courses c
         JOIN course_categories cc ON c.category_id = cc.id;

-- View Khung chương trình học (Mục lục bài học)
CREATE OR REPLACE VIEW vw_Course_Curriculum AS
SELECT
    c.id AS course_id,
    c.name AS course_name,
    p.id AS part_id,
    p.name AS part_name,
    l.id AS lession_id,
    l.name AS lession_name,
    l.length AS lession_length
FROM courses c
         JOIN part_of_courses p ON c.id = p.course_id
         JOIN lessions l ON p.id = l.part_id;

-- View Người dùng đang hoạt động (Ẩn mật khẩu)
CREATE OR REPLACE VIEW vw_Active_Users AS
SELECT
    u.id AS user_id,
    u.fullname,
    u.email,
    u.phone,
    g.name AS role_name
FROM users u
         JOIN "groups" g ON u.group_id = g.id
WHERE u.status = 1;

-- ---------------------------------------------------------
-- 4. TẠO CÁC BỘ KÍCH HOẠT (TRIGGERS)
-- ---------------------------------------------------------

-- Hàm cập nhật số lượng bài học tự động
CREATE OR REPLACE FUNCTION func_update_lession_total() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
UPDATE courses SET total_lession = total_lession + 1 WHERE id = NEW.course_id;
RETURN NEW;
ELSIF (TG_OP = 'DELETE') THEN
UPDATE courses SET total_lession = total_lession - 1 WHERE id = OLD.course_id;
RETURN OLD;
END IF;
RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_Update_Course_Totals_Lession
    AFTER INSERT OR DELETE ON lessions
FOR EACH ROW EXECUTE FUNCTION func_update_lession_total();

-- Hàm cập nhật số lượng chương tự động
CREATE OR REPLACE FUNCTION func_update_part_total() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
UPDATE courses SET total_part = total_part + 1 WHERE id = NEW.course_id;
RETURN NEW;
ELSIF (TG_OP = 'DELETE') THEN
UPDATE courses SET total_part = total_part - 1 WHERE id = OLD.course_id;
RETURN OLD;
END IF;
RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_Update_Course_Totals_Part
    AFTER INSERT OR DELETE ON part_of_courses
FOR EACH ROW EXECUTE FUNCTION func_update_part_total();

-- Hàm lưu lịch sử xóa khóa học
CREATE OR REPLACE FUNCTION func_audit_delete_course() RETURNS TRIGGER AS $$
BEGIN
INSERT INTO courses_audit (course_id, course_name) VALUES (OLD.id, OLD.name);
RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_Audit_Delete_Course
    BEFORE DELETE ON courses
    FOR EACH ROW EXECUTE FUNCTION func_audit_delete_course();

-- ---------------------------------------------------------
-- 5. TẠO CÁC THỦ TỤC & HÀM (PROCEDURES & FUNCTIONS)
-- ---------------------------------------------------------

-- Thủ tục cấp quyền khóa học (Cập nhật cột permission)
CREATE OR REPLACE PROCEDURE sp_Enroll_User_Course(p_user_id INT, p_course_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
v_current_permission TEXT;
    v_course_id_str TEXT;
BEGIN
    v_course_id_str := p_user_id::TEXT; -- Fix logic: p_course_id mới đúng
    v_course_id_str := p_course_id::TEXT;

SELECT permission INTO v_current_permission FROM users WHERE id = p_user_id FOR UPDATE;

IF v_current_permission IS NULL OR v_current_permission = '' THEN
UPDATE users SET permission = v_course_id_str WHERE id = p_user_id;
ELSIF NOT (v_current_permission = v_course_id_str OR
               v_current_permission LIKE v_course_id_str || ',%' OR
               v_current_permission LIKE '%,' || v_course_id_str || ',%' OR
               v_current_permission LIKE '%,' || v_course_id_str) THEN
UPDATE users SET permission = CONCAT(v_current_permission, ',', v_course_id_str) WHERE id = p_user_id;
END IF;
END;
$$;

-- Hàm lấy danh sách khóa học người dùng đã đăng ký
CREATE OR REPLACE FUNCTION sp_Get_User_Registered_Courses(p_user_id INT)
RETURNS TABLE (course_id INT, course_name VARCHAR, thumbnail VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
RETURN QUERY
SELECT c.id, c.name, c.thumbnail
FROM courses c
WHERE c.id IN (
    SELECT unnest(string_to_array((SELECT permission FROM users WHERE id = p_user_id), ','))::INT
);
END;
$$;