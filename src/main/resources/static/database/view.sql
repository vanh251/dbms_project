--1. View dùng để đổ dữ liệu ra danh sách Card trên trang chủ
CREATE OR REPLACE VIEW vw_client_course_cards AS
SELECT
    c.id AS course_id,
    cc.name AS category_name,
    c.name AS course_name,
    c.description,
    c.total_lession,
    c.total_part,
    c.total_time,
    c.price,
    c.old_price,
    c.thumbnail
FROM courses c
         JOIN course_categories cc ON c.category_id = cc.id
WHERE c.status = 1
ORDER BY c.create_at DESC;

--2. View dùng để đổ dữ liệu ra phần Mục Lục (Chương và Bài học)
CREATE OR REPLACE VIEW vw_client_course_curriculum AS
SELECT
    c.id AS course_id,
    p.id AS part_id,
    p.name AS part_name,
    (SELECT COUNT(*) FROM lessions WHERE part_id = p.id) AS total_lessions_in_part,
    l.id AS lession_id,
    l.name AS lession_name,
    l.length AS lession_length
FROM courses c
         JOIN part_of_courses p ON c.id = p.course_id
         JOIN lessions l ON p.id = l.part_id
WHERE c.status = 1
ORDER BY p.id ASC, l.id ASC;

--3. View cho trang "Quản lý khóa học"
CREATE OR REPLACE VIEW vw_admin_manage_courses AS
SELECT
    c.id          AS course_id,
    c.name        AS course_name,
    c.slug,
    c.thumbnail,
    c.description,
    c.require,
    c.total_lession,
    c.total_part,
    c.total_time,
    c.price,
    c.old_price,
    c.status,
    c.category_id,
    cc.name       AS category_name
FROM courses c
         JOIN course_categories cc ON c.category_id = cc.id
ORDER BY c.id;

--4. View cho trang "Quản lý người dùng & phân quyền"
CREATE OR REPLACE VIEW vw_admin_manage_users AS
SELECT
    u.id AS user_id,
    u.fullname,
    u.email,
    g.name AS group_name
FROM users u
         JOIN "groups" g ON u.group_id = g.id
ORDER BY u.id;

--5. View cho trang "Danh mục khóa học"
CREATE OR REPLACE VIEW vw_admin_manage_categories AS
SELECT
    cc.id AS category_id,
    cc.name AS category_name,
    COUNT(c.id) AS total_courses
FROM course_categories cc
         LEFT JOIN courses c ON cc.id = c.category_id
GROUP BY cc.id, cc.name
ORDER BY cc.id;