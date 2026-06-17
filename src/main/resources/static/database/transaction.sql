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
INSERT INTO "user_courses" (user_id, course_id, status, progress_percent, create_at, update_at)
VALUES (v_user_id, v_course_id, 1, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (user_id, course_id) DO NOTHING;

-- Không có COMMIT/ROLLBACK ở đây — Spring @Transactional quản lý từ bên ngoài.
-- Nếu có lỗi, Spring sẽ tự rollback toàn bộ transaction.
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Lỗi giao dịch thanh toán: %', SQLERRM;
END;
$$;


