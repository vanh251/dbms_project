-- ==============================================================================
-- CÁC DATABASE PROCEDURES
-- ==============================================================================

-- 1. sp_create_user
CREATE OR REPLACE PROCEDURE sp_create_user(
    p_fullname VARCHAR, p_email VARCHAR, p_password VARCHAR, 
    p_phone VARCHAR, p_address VARCHAR, p_active_token VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO "users" (fullname, email, password, phone, address, status, active_token, group_id)
    VALUES (p_fullname, p_email, p_password, p_phone, p_address, 0, p_active_token,
        (SELECT id FROM "groups" WHERE name = 'STUDENT' LIMIT 1));
END;
$$;

-- 2. sp_activate_user
CREATE OR REPLACE PROCEDURE sp_activate_user(p_email VARCHAR, p_active_token VARCHAR) LANGUAGE plpgsql AS $$
DECLARE v_user_id INT;
BEGIN
    SELECT id INTO v_user_id FROM "users" WHERE email = p_email AND active_token = p_active_token AND status = 0;
    IF v_user_id IS NOT NULL THEN
        UPDATE "users" SET status = 1, active_token = NULL, update_at = CURRENT_TIMESTAMP WHERE id = v_user_id;
    ELSE
        RAISE EXCEPTION 'Email/Token không hợp lệ hoặc tài khoản đã kích hoạt!';
    END IF;
END;
$$;

-- 3. sp_login
CREATE OR REPLACE PROCEDURE sp_login(p_email VARCHAR, p_password VARCHAR, p_login_token VARCHAR, INOUT p_user_id INT DEFAULT NULL) LANGUAGE plpgsql AS $$
BEGIN
    SELECT id INTO p_user_id FROM "users" WHERE email = p_email AND password = p_password AND status = 1;
    IF p_user_id IS NOT NULL THEN
        INSERT INTO "TokenLogin" (token, user_id) VALUES (p_login_token, p_user_id);
    ELSE
        RAISE EXCEPTION 'Sai thông tin đăng nhập hoặc tài khoản chưa kích hoạt!';
    END IF;
END;
$$;

-- 4. sp_create_course
CREATE OR REPLACE PROCEDURE sp_create_course(
    p_name VARCHAR, p_slug VARCHAR, p_thumbnail VARCHAR, p_description VARCHAR, 
    p_require TEXT, p_price VARCHAR, p_category_id INT, INOUT p_new_course_id INT DEFAULT NULL
) LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO "courses" (name, slug, thumbnail, description, require, price, category_id, status, total_lession, total_part)
    VALUES (p_name, p_slug, p_thumbnail, p_description, p_require, p_price, p_category_id, 0, 0, 0) RETURNING id INTO p_new_course_id;
END;
$$;

-- 5. sp_publish_course
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

-- 6. sp_add_comment
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

-- 7. sp_enroll_course
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

-- 8. sp_unenroll_course
CREATE OR REPLACE PROCEDURE sp_unenroll_course(p_user_id INT, p_course_id INT) LANGUAGE plpgsql AS $$
BEGIN
    UPDATE "user_courses" SET status = 0, update_at = CURRENT_TIMESTAMP WHERE user_id = p_user_id AND course_id = p_course_id AND status = 1;
END;
$$;

-- 9. sp_create_payment_order
CREATE OR REPLACE PROCEDURE sp_create_payment_order(
    p_user_id INT, p_course_id INT, p_payment_method VARCHAR, INOUT p_order_id INT DEFAULT NULL
) LANGUAGE plpgsql AS $$
DECLARE v_price VARCHAR; v_price_number DECIMAL(15,2);
BEGIN
    SELECT price INTO v_price FROM "courses" WHERE id = p_course_id;
    IF v_price IS NULL OR v_price = '' THEN v_price_number := 0; ELSE v_price_number := CAST(v_price AS DECIMAL(15,2)); END IF;
    INSERT INTO "payments" (user_id, course_id, amount, payment_method, status)
    VALUES (p_user_id, p_course_id, v_price_number, p_payment_method, 0) RETURNING id INTO p_order_id;
END;
$$;

-- 10. sp_confirm_payment
CREATE OR REPLACE PROCEDURE sp_confirm_payment(p_order_id INT, p_transaction_id VARCHAR) LANGUAGE plpgsql AS $$
DECLARE v_user_id INT; v_course_id INT; v_status INT;
BEGIN
    SELECT user_id, course_id, status INTO v_user_id, v_course_id, v_status FROM "payments" WHERE id = p_order_id;
    IF v_status = 1 THEN RAISE NOTICE 'Đã xác nhận trước đó!'; RETURN; END IF;
    UPDATE "payments" SET status = 1, transaction_id = p_transaction_id, update_at = CURRENT_TIMESTAMP WHERE id = p_order_id;
    CALL sp_enroll_course(v_user_id, v_course_id);
END;
$$;

-- ==============================================================================
-- DATABASE TRANSACTIONS CHO DỰ ÁN E-LEARNING
-- Các Procedure dưới đây được sử dụng Transaction (giao dịch) với cơ chế
-- COMMIT (Lưu thành công tất cả) và ROLLBACK (Hủy toàn bộ nếu có lỗi).
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- TRANSACTION 1: XÁC NHẬN THANH TOÁN VÀ GHI DANH AN TOÀN (SAFE CHECKOUT)
-- Ngữ cảnh: Khi cập nhật trạng thái đã thu tiền, bắt buộc phải cấp quyền học (Enroll).
-- Nếu lỗi ở khâu cấp quyền (VD: user bị khóa), thì lệnh thu tiền cũng phải bị hủy
-- để tránh tình trạng "Đã nhận tiền nhưng không có khóa học".
-- ------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_transaction_confirm_payment(
    p_order_id INT,
    p_transaction_id VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
v_user_id INT;
    v_course_id INT;
    v_status INT;
BEGIN
    -- Lấy thông tin thanh toán
SELECT user_id, course_id, status INTO v_user_id, v_course_id, v_status
FROM "payments" WHERE id = p_order_id;

-- Chống spam
IF v_status = 1 THEN
        RAISE NOTICE 'Đơn hàng này đã được xác nhận trước đó!';
        RETURN;
END IF;

    -- BƯỚC 1: Cập nhật hóa đơn
UPDATE "payments"
SET status = 1, transaction_id = p_transaction_id, update_at = CURRENT_TIMESTAMP
WHERE id = p_order_id;

-- BƯỚC 2: Ghi danh (Tạo bản ghi trong user_courses)
-- Thay vì gọi bằng thủ tục khác, ta viết trực tiếp để dễ rollback
INSERT INTO "user_courses" (user_id, course_id, status)
VALUES (v_user_id, v_course_id, 1);

-- NẾU CẢ BA BƯỚC THÀNH CÔNG -> Xác nhận lưu tất cả vào DB
COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        -- NẾU CÓ BẤT KỲ LỖI GÌ -> Hủy bỏ toàn bộ thao tác (Rollback)
        ROLLBACK;
        RAISE EXCEPTION 'Lỗi giao dịch thanh toán: %', SQLERRM;
END;
$$;


-- ------------------------------------------------------------------------------
-- TRANSACTION 2: HỦY KHÓA HỌC KHẨN CẤP VÀ HOÀN TIỀN (COURSE CANCELLATION & REFUND)
-- Ngữ cảnh: Admin muốn đánh sập/dừng vĩnh viễn 1 khóa học đang hoạt động do vi phạm.
-- Yêu cầu: Khóa học ẩn đi (status=-1) VÀ tất cả học viên đang học bị chuyển status=0 (hủy)
-- VÀ cập nhật trạng thái thanh toán của họ sang -1 (Cần Hoàn Tiền).
-- ------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_transaction_cancel_course_and_refund(
    p_course_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- BƯỚC 1: Soft Delete khóa học
UPDATE "courses"
SET status = -1, update_at = CURRENT_TIMESTAMP
WHERE id = p_course_id;

-- BƯỚC 2: Ngưng quyền truy cập của toàn bộ học viên đang học khóa này
UPDATE "user_courses"
SET status = 0, update_at = CURRENT_TIMESTAMP
WHERE course_id = p_course_id;

-- BƯỚC 3: Chuyển các hóa đơn đã thanh toán (1) của khóa này thành Hủy (-1)
-- Để phòng kế toán biết đối soát Refund cho User
UPDATE "payments"
SET status = -1, update_at = CURRENT_TIMESTAMP
WHERE course_id = p_course_id AND status = 1;

-- NẾU ĐÚNG TẤT CẢ -> Lưu trữ
COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        -- Bị lỗi ở 1 trong 3 bảng -> Hoàn tác lại như cũ
        ROLLBACK;
        RAISE EXCEPTION 'Lỗi khi hủy khóa học và hoàn tiền: %', SQLERRM;
END;
$$;


-- ------------------------------------------------------------------------------
-- TRANSACTION 3: TẠO MỚI KHÓA HỌC KÈM CẤU TRÚC ĐẦY ĐỦ (FULL COURSE INIT)
-- Ngữ cảnh: Khi user bấm "Tạo thư mục Khóa học", hệ thống không chỉ tạo Course trống
-- mà tạo luôn Chương(Part) 1 + Bài mở đầu (Lession) mặc định chung một lúc.
-- Đảm bảo dữ liệu trọn vẹn, không xảy ra cảnh khóa học bị nằm mồ côi.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_transaction_init_full_course(
    p_name VARCHAR,
    p_category_id INT,
    p_instructor_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
v_course_id INT;
    v_part_id INT;
BEGIN
    -- BƯỚC 1: Tạo record Khóa học
INSERT INTO "courses" (name, category_id, status, description)
VALUES (p_name, p_category_id, 0, 'Đây là mô tả mặc định của khóa học')
    RETURNING id INTO v_course_id;

-- BƯỚC 2: Gắn quyền Giấy phép/Sở hữu vào người tạo (Admin/Giảng viên)
-- (Trong DB bạn có trường "permission" của user, ví dụ nhét course_id vào)
-- Tạm bỏ qua nếu quản lý bằng bảng phụ, ở đây ví dụ chèn Part:

INSERT INTO "part_of_courses" (course_id, name)
VALUES (v_course_id, 'Chương 1: Mở đầu và Giới thiệu')
    RETURNING id INTO v_part_id;

-- BƯỚC 3: Tạo Video nội dung bài 1 giả lập
INSERT INTO "lessions" (name, course_id, part_id, description)
VALUES ('Bài 1: Giới thiệu khóa học', v_course_id, v_part_id, 'Chào mừng các bạn đến khóa học!');

-- Xong hết -> Lưu
COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE EXCEPTION 'Lỗi khi khởi tạo khung khóa học: %', SQLERRM;
END;
$$;


