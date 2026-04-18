-- Procedure tạo tài khoản User để chạy thử
CREATE OR REPLACE PROCEDURE sp_test_create_student(
    p_fullname VARCHAR,
    p_email VARCHAR,
    p_password VARCHAR,
    INOUT p_user_id INT DEFAULT NULL -- Tham số này để trả về ID của user vừa tạo
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_group_id INT;
BEGIN
    -- 1. Kiểm tra xem nhóm 'STUDENT' đã tồn tại chưa, nếu chưa thì tạo mới
    SELECT id INTO v_group_id FROM "groups" WHERE name = 'STUDENT' LIMIT 1;
    
    IF v_group_id IS NULL THEN
        INSERT INTO "groups" (name, permission) 
        VALUES ('STUDENT', 'Sử dụng các tính năng dành cho học viên')
        RETURNING id INTO v_group_id;
    END IF;

    -- 2. Thêm User mới vào bảng "users"
    INSERT INTO "users" (fullname, email, password, status, group_id)
    VALUES (p_fullname, p_email, p_password, 1, v_group_id)
    RETURNING id INTO p_user_id;

    -- 3. Thông báo ra màn hình console của DB
    RAISE NOTICE 'Đã tạo thành công User: % với ID: %', p_fullname, p_user_id;
END;
$$;

-- Cách chạy thử:
-- CALL sp_test_create_student('Học Viên Thử Nghiệm', 'test_user@gmail.com', '123456', NULL);

-- Xem kết quả:
-- SELECT u.id, u.fullname, u.email, g.name as group_name, u.create_at 
-- FROM "users" u JOIN "groups" g ON u.group_id = g.id WHERE u.email = 'test_user@gmail.com';
