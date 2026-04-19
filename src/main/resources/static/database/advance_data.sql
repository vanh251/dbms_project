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

--View cho trang "Quản lý khóa học"
CREATE OR REPLACE VIEW vw_admin_manage_courses AS
SELECT
    c.id AS course_id,              -- Cột ID
    c.name AS course_name,          -- Cột TÊN KHÓA HỌC
    cc.name AS category_name,       -- Cột DANH MỤC (Lấy từ bảng course_categories)
    c.price,                        -- Cột GIÁ
    c.status                        -- Cột TRẠNG THÁI (Backend/Frontend sẽ tự map 1 là Hoạt động)
FROM courses c
-- Ghép bảng khóa học với bảng danh mục dựa trên chốt nối là category_id
         JOIN course_categories cc ON c.category_id = cc.id
-- Sắp xếp ID tăng dần để giao diện hiển thị từ 1, 2, 3...
ORDER BY c.id;

-- View cho trang "Quản lý người dùng & phân quyền"
CREATE OR REPLACE VIEW vw_admin_manage_users AS
SELECT
    u.id AS user_id,                -- Cột ID
    u.fullname,                     -- Cột HỌ TÊN
    u.email,                        -- Cột EMAIL
    g.name AS group_name            -- Cột NHÓM (Lấy từ bảng groups)
FROM users u
-- Ghép bảng người dùng với bảng nhóm dựa trên chốt nối là group_id
         JOIN "groups" g ON u.group_id = g.id
ORDER BY u.id;

-- View cho trang "Danh mục khóa học"
CREATE OR REPLACE VIEW vw_admin_manage_categories AS
SELECT
    cc.id AS category_id,           -- Cột ID
    cc.name AS category_name,       -- Cột TÊN DANH MỤC
    -- Đếm xem có bao nhiêu khóa học đang gắn với category_id này
    COUNT(c.id) AS total_courses
FROM course_categories cc
-- Dùng LEFT JOIN để lỡ danh mục nào chưa có khóa học nào thì nó vẫn hiện ra, số lượng = 0
         LEFT JOIN courses c ON cc.id = c.category_id
-- Khi dùng hàm đếm COUNT() thì bắt buộc phải GROUP BY các cột còn lại
GROUP BY cc.id, cc.name
ORDER BY cc.id;

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

-- thủ tục xoá danh mục các khoá học
CREATE OR REPLACE PROCEDURE sp_Delete_Category_Cascade(p_category_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
    -- 1. Quét sạch tất cả bình luận thuộc về các khóa học trong danh mục này
DELETE FROM comments WHERE lession_id IN (
    SELECT id FROM lessions WHERE course_id IN (SELECT id FROM courses WHERE category_id = p_category_id)
);

-- 2. Xóa toàn bộ bài học
DELETE FROM lessions WHERE course_id IN (SELECT id FROM courses WHERE category_id = p_category_id);

-- 3. Xóa toàn bộ các chương
DELETE FROM part_of_courses WHERE course_id IN (SELECT id FROM courses WHERE category_id = p_category_id);

-- 4. Xóa toàn bộ khóa học nằm trong danh mục
DELETE FROM courses WHERE category_id = p_category_id;

-- 5. Cuối cùng, "tiêu diệt" danh mục
DELETE FROM course_categories WHERE id = p_category_id;
END;
$$;

-- Cách gọi thử:
-- CALL sp_Delete_Category_Cascade(1);