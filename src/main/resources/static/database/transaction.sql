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