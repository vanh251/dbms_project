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

-- 10. sp_confirm_payment (CẬP NHẬT - XÓA DEPENDENCY VỚI TokenLogin)
CREATE OR REPLACE PROCEDURE sp_confirm_payment(p_order_id INT, p_transaction_id VARCHAR) LANGUAGE plpgsql AS $$
DECLARE
v_user_id INT;
    v_course_id INT;
    v_status INT;
BEGIN
    -- Lấy thông tin từ bảng payments
SELECT user_id, course_id, status
INTO v_user_id, v_course_id, v_status
FROM "payments"
WHERE id = p_order_id;

-- Kiểm tra nếu thanh toán đã xác nhận rồi
IF v_status = 1 THEN
        RAISE NOTICE 'Đã xác nhận trước đó!';
        RETURN;
END IF;

    -- Cập nhật status thanh toán thành 1 (đã thanh toán)
UPDATE "payments"
SET status = 1,
    transaction_id = p_transaction_id,
    update_at = CURRENT_TIMESTAMP
WHERE id = p_order_id;

-- Tự động ghi danh học viên vào khóa học
CALL sp_enroll_course(v_user_id, v_course_id);

RAISE NOTICE 'Xác nhận thanh toán thành công cho order ID: %', p_order_id;
END;
$$;

-- ==============================================================================
-- CÁC LỆNH CALL ĐỂ TEST THỬ PROCEDURES
-- (Bôi đen từng dòng hoặc từng khối để chạy test)
-- ==============================================================================

/*
-- 1. Test tạo user mới
CALL sp_create_user('Nguyen Van A', 'nva@gmail.com', '123456', '0987654321', 'Ha Noi', 'token_kich_hoat_123');

-- 2. Test kích hoạt user
CALL sp_activate_user('nva@gmail.com', 'token_kich_hoat_123');


-- 4. Test tạo khóa học mới
-- Lưu ý: Cần có category_id hợp lệ (ví dụ: 1)
CALL sp_create_course('Khóa học Java Spring Boot', 'java-spring-boot', 'thumb.jpg', 'Học Spring Boot từ A-Z', 'Biết Java Core', '499000', 1, NULL);

-- 5. Test Publish khóa học (Sẽ báo lỗi nếu total_lession và total_part = 0)
-- CALL sp_publish_course(1); 

-- 6. Test thêm bình luận
-- CALL sp_add_comment(1, 1, NULL, 'Khóa học rất hay!'); -- Bình luận gốc
-- CALL sp_add_comment(1, 1, 1, 'Cảm ơn bạn!'); -- Trả lời bình luận id = 1

-- 7. Test đăng ký khóa học (Ghi danh miễn phí/trực tiếp)
-- Cần khóa học có status = 1 (Đã publish)
-- CALL sp_enroll_course(1, 1);

-- 8. Test hủy đăng ký khóa học
-- CALL sp_unenroll_course(1, 1);

-- 9. Test tạo đơn hàng thanh toán
-- Trả về p_order_id (ID đơn hàng)
-- CALL sp_create_payment_order(1, 1, 'VNPAY', NULL);

-- 10. Test xác nhận thanh toán thành công (Sẽ tự động gọi sp_enroll_course)
-- Đưa ID đơn hàng (ví dụ: 1) và mã giao dịch VNPay vào
-- CALL sp_confirm_payment(1, 'VNP_1234567890');
*/

