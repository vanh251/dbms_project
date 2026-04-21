-- ==============================================================================
-- CÁC DATABASE PROCEDURES
-- ==============================================================================


-- 1. sp_delete_course
-- Xóa hoàn toàn một khóa học và toàn bộ dữ liệu liên quan theo đúng thứ tự phụ thuộc
CREATE OR REPLACE PROCEDURE sp_delete_course(p_course_id INT) LANGUAGE plpgsql AS $$
DECLARE
    v_exists INT;
BEGIN
    -- Kiểm tra khóa học có tồn tại không
    SELECT COUNT(*) INTO v_exists FROM "courses" WHERE id = p_course_id;
    IF v_exists = 0 THEN
        RAISE EXCEPTION 'Khóa học với ID % không tồn tại!', p_course_id;
    END IF;

    -- 1. Xóa tiến độ bài học của học viên (tham chiếu đến lessions & courses)
    DELETE FROM "user_lessons" WHERE course_id = p_course_id;

    -- 2. Xóa bình luận (tham chiếu đến lessions)
    DELETE FROM "comments"
    WHERE lession_id IN (SELECT id FROM "lessions" WHERE course_id = p_course_id);

    -- 3. Xóa các bài học
    DELETE FROM "lessions" WHERE course_id = p_course_id;

    -- 4. Xóa ghi danh khóa học
    DELETE FROM "user_courses" WHERE course_id = p_course_id;

    -- 5. Xóa lịch sử thanh toán liên quan
    DELETE FROM "payments" WHERE course_id = p_course_id;

    -- 6. Xóa các chương (part_of_courses)
    DELETE FROM "part_of_courses" WHERE course_id = p_course_id;

    -- 7. Xóa chính khóa học
    DELETE FROM "courses" WHERE id = p_course_id;

    RAISE NOTICE 'Đã xóa thành công khóa học ID: %', p_course_id;
END;
$$;


-- 2. sp_create_course
CREATE OR REPLACE PROCEDURE sp_create_course(
    p_name VARCHAR, p_slug VARCHAR, p_thumbnail VARCHAR, p_description VARCHAR,
    p_require TEXT, p_price VARCHAR, p_category_id INT, INOUT p_new_course_id INT DEFAULT NULL
) LANGUAGE plpgsql AS $$
BEGIN
INSERT INTO "courses" (name, slug, thumbnail, description, require, price, category_id, status, total_lession, total_part)
VALUES (p_name, p_slug, p_thumbnail, p_description, p_require, p_price, p_category_id, 0, 0, 0) RETURNING id INTO p_new_course_id;
END;
$$;

-- 3. sp_publish_course
CREATE OR REPLACE PROCEDURE sp_publish_course(p_course_id INT) LANGUAGE plpgsql AS $$
DECLARE v_total_lesson INT; v_total_part INT;
BEGIN
SELECT total_lession, total_part INTO v_total_lesson, v_total_part FROM "courses" WHERE id = p_course_id;
IF v_total_lesson > 0 AND v_total_part > 0 THEN
UPDATE "courses" SET status = 1, update_at = CURRENT_TIMESTAMP WHERE id = p_course_id;
ELSE
        RAISE EXCEPTION 'Không thể publish: Khóa học chưa có dữ liệu!';
END IF;
END;
$$;

-- 4. sp_add_comment
CREATE OR REPLACE PROCEDURE sp_add_comment(p_user_id INT, p_lesson_id INT, p_parent_id INT, p_content TEXT) LANGUAGE plpgsql AS $$
DECLARE v_parent_exists INT;
BEGIN
    IF p_parent_id IS NOT NULL THEN
SELECT count(*) INTO v_parent_exists FROM "comments" WHERE id = p_parent_id;
IF v_parent_exists = 0 THEN RAISE EXCEPTION 'Bình luận gốc không tồn tại!'; END IF;
END IF;
INSERT INTO "comments" (user_id, lession_id, parent_id, content) VALUES (p_user_id, p_lesson_id, p_parent_id, p_content);
END;
$$;

-- 5. sp_enroll_course
CREATE OR REPLACE PROCEDURE sp_enroll_course(p_user_id INT, p_course_id INT) LANGUAGE plpgsql AS $$
DECLARE v_is_enrolled INT; v_course_status INT;
BEGIN
SELECT status INTO v_course_status FROM "courses" WHERE id = p_course_id;
IF v_course_status IS NULL THEN RAISE EXCEPTION 'Khóa học không tồn tại!';
    ELSIF v_course_status != 1 THEN RAISE EXCEPTION 'Khóa học chưa publish!'; END IF;

SELECT count(*) INTO v_is_enrolled FROM "user_courses" WHERE user_id = p_user_id AND course_id = p_course_id AND status IN (1, 2);
IF v_is_enrolled > 0 THEN RAISE EXCEPTION 'Đã ghi danh khóa học!'; END IF;

INSERT INTO "user_courses" (user_id, course_id, status) VALUES (p_user_id, p_course_id, 1);
END;
$$;

-- 6. sp_unenroll_course
CREATE OR REPLACE PROCEDURE sp_unenroll_course(p_user_id INT, p_course_id INT) LANGUAGE plpgsql AS $$
BEGIN
UPDATE "user_courses" SET status = 0, update_at = CURRENT_TIMESTAMP WHERE user_id = p_user_id AND course_id = p_course_id AND status = 1;
END;
$$;

