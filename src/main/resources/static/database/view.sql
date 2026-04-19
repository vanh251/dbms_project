--1. View dùng để đổ dữ liệu ra danh sách Card trên trang chủ
CREATE OR REPLACE VIEW vw_client_course_cards AS
SELECT
    c.id AS course_id,
    cc.name AS category_name,       -- Lấy tên danh mục (để in màu xanh ngọc nhỏ nhỏ ở trên)
    c.name AS course_name,          -- Tên khóa học (in đậm to)
    c.description,                  -- Đoạn mô tả ngắn gọn
    c.total_lession,                -- Tổng số bài học
    c.total_part,                   -- Tổng số chương
    c.total_time,                   -- Tổng thời lượng (VD: 8 giờ 30 phút)
    c.price,                        -- Giá bán (VD: 299.000đ hoặc Miễn phí)
    c.old_price,                    -- Giá cũ (bị gạch ngang)
    c.thumbnail                     -- Link ảnh bìa khóa học
FROM courses c
         JOIN course_categories cc ON c.category_id = cc.id
-- Chỉ lấy những khóa học đã được duyệt (status = 1) để show cho khách xem
WHERE c.status = 1
ORDER BY c.create_at DESC; -- Sắp xếp khóa học mới nhất lên đầu

--2. View dùng để đổ dữ liệu ra phần Mục Lục (Chương và Bài học)
CREATE OR REPLACE VIEW vw_client_course_curriculum AS
SELECT
    c.id AS course_id,              -- Dùng để lọc xem đang ở khóa học nào
    p.id AS part_id,
    p.name AS part_name,            -- Tên Chương (VD: Phần 1: HTML - Nền tảng Web)
    -- Linh dùng Subquery đếm luôn số bài học trong Chương này để cậu in ra cái "1 bài", "3 bài" ở góc phải
    (SELECT COUNT(*) FROM lessions WHERE part_id = p.id) AS total_lessions_in_part,
    l.id AS lession_id,
    l.name AS lession_name,         -- Tên Bài học (VD: Học HTML & CSS Từ Con Số 0...)
    l.length AS lession_length      -- Thời lượng bài học (VD: 45:00)
FROM courses c
-- JOIN để lấy cấu trúc: Khóa học -> Chương -> Bài học
         JOIN part_of_courses p ON c.id = p.course_id
         JOIN lessions l ON p.id = l.part_id
-- Chỉ lấy những khóa học đã ra mắt
WHERE c.status = 1
-- Sắp xếp theo thứ tự ID của Chương trước, sau đó sắp xếp theo ID của Bài học trong Chương đó
ORDER BY p.id ASC, l.id ASC;

--3. View cho trang "Quản lý khóa học"
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

--4. View cho trang "Quản lý người dùng & phân quyền"
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

--5. View cho trang "Danh mục khóa học"
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