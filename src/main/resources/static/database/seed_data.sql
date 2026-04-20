
-- -------------------------------------------------------
-- 1. GROUPS
-- -------------------------------------------------------
INSERT INTO "groups" (id, name, permission)
VALUES (1, 'Admin',  'ADMIN'),
       (2, 'Member', 'MEMBER');

SELECT setval(pg_get_serial_sequence('"groups"', 'id'), (SELECT MAX(id) FROM "groups"));

-- -------------------------------------------------------
-- 2. USERS
-- Mật khẩu hash BCrypt (cost 10):
--   admin123  → $2a$10$7v3s6mxJWDk9N.u2R4yXGuYi2xRpXt/f/WQpFWF8AjbIEr1Sxm1Ey
--   user123   → $2a$10$N/Z8mHIq5MgCHtq7wn3fj.i9FLDhpHXQHw77yPNLnhSf5r0HbCxEy
-- -------------------------------------------------------
INSERT INTO "users" (id, fullname, email, phone, password, address, status, group_id)
VALUES
    (1, 'Administrator', 'admin@learnhub.com',  '0900000001',
     '$2a$10$7v3s6mxJWDk9N.u2R4yXGuYi2xRpXt/f/WQpFWF8AjbIEr1Sxm1Ey',
     'Hà Nội', 1, 1),

    (2, 'Nguyễn Văn An',  'user1@learnhub.com', '0900000002',
     '$2a$10$N/Z8mHIq5MgCHtq7wn3fj.i9FLDhpHXQHw77yPNLnhSf5r0HbCxEy',
     'TP. Hồ Chí Minh', 1, 2),

    (3, 'Trần Thị Bình',  'user2@learnhub.com', '0900000003',
     '$2a$10$N/Z8mHIq5MgCHtq7wn3fj.i9FLDhpHXQHw77yPNLnhSf5r0HbCxEy',
     'Đà Nẵng', 1, 2),

    (4, 'Lê Minh Khoa',   'user3@learnhub.com', '0900000004',
     '$2a$10$N/Z8mHIq5MgCHtq7wn3fj.i9FLDhpHXQHw77yPNLnhSf5r0HbCxEy',
     'Cần Thơ', 1, 2);

SELECT setval(pg_get_serial_sequence('"users"', 'id'), (SELECT MAX(id) FROM "users"));

-- -------------------------------------------------------
-- 3. COURSE CATEGORIES
-- -------------------------------------------------------
INSERT INTO "course_categories" (id, name)
VALUES (1, 'Lập trình Web Frontend'),
       (2, 'Lập trình Web Fullstack'),
       (3, 'Trí tuệ nhân tạo & AI Tools'),
       (4, 'Next.js & React'),
       (5, 'Backend & Node.js');

SELECT setval(pg_get_serial_sequence('"course_categories"', 'id'), (SELECT MAX(id) FROM "course_categories"));

-- -------------------------------------------------------
-- 4. COURSES
-- -------------------------------------------------------
INSERT INTO "courses" (id, name, slug, description, require,
                       total_lession, total_part, total_time,
                       price, old_price, category_id, status)
VALUES
    -- Course 1: HTML + CSS + JS (playlist: HTML + CSS + JS)
    (1,
     'HTML, CSS & JavaScript – Từ Zero đến Hero',
     'html-css-js-zero-to-hero',
     'Khóa học lập trình web frontend toàn diện từ HTML cơ bản đến JavaScript nâng cao, có dự án thực tế.',
     'Không cần kiến thức nền. Chỉ cần máy tính và kết nối internet.',
     6, 3, '9 giờ 30 phút',
     'Miễn phí', NULL, 1, 1),

    -- Course 2: Chat App Realtime (playlist: Realtime Chat App)
    (2,
     'Xây dựng Ứng dụng Chat Realtime Fullstack',
     'chat-app-realtime-fullstack',
     'Xây dựng ứng dụng chat realtime với React, Express, MongoDB và Socket.IO – dự án Moji hoàn chỉnh.',
     'Biết cơ bản HTML/CSS, JavaScript. Có kiến thức nền về lập trình.',
     5, 2, '10 giờ 21 phút',
     '299.000đ', '599.000đ', 2, 1),

    -- Course 3: Claude AI (playlist: ClaudeAI)
    (3,
     'Claude AI & Claude Code – Lập trình với AI',
     'claude-ai-code-lap-trinh-voi-ai',
     'Khám phá Claude AI và Claude Code – công cụ AI mạnh mẽ giúp lập trình viên tăng tốc độ làm việc.',
     'Có kiến thức lập trình cơ bản.',
     5, 1, '~30 phút',
     'Miễn phí', NULL, 3, 1),

    -- Course 4: Next.js (playlist: NextJS)
    (4,
     'Next.js – Từ Cơ Bản đến Nâng Cao',
     'nextjs-co-ban-den-nang-cao',
     'Học Next.js App Router, Server/Client Components, các chiến lược rendering và tối ưu hiệu năng.',
     'Biết React cơ bản.',
     3, 1, '23 phút',
     '199.000đ', '399.000đ', 4, 1),

    -- Course 5: ReactJS (playlist: ReactJS)
    (5,
     'ReactJS – Từ JavaScript đến Fullstack MERN',
     'reactjs-fullstack-mern',
     'Học React JS từ nền tảng JavaScript, xây dựng dự án Fullstack MERN với TypeScript, Tailwind và Shadcn.',
     'Biết JavaScript cơ bản.',
     4, 2, '4 giờ 44 phút',
     '349.000đ', '699.000đ', 4, 1),

    -- Course 6: NestJS (playlist: NestJS)
    (6,
     'NestJS – Backend Framework Hiện Đại',
     'nestjs-backend-hien-dai',
     'Tìm hiểu NestJS – framework backend đang viral trong cộng đồng developer, kiến trúc module hóa chuyên nghiệp.',
     'Biết Node.js và JavaScript/TypeScript cơ bản.',
     2, 1, '~8 phút',
     'Miễn phí', NULL, 5, 1);

SELECT setval(pg_get_serial_sequence('"courses"', 'id'), (SELECT MAX(id) FROM "courses"));

-- -------------------------------------------------------
-- 5. PARTS OF COURSES
-- -------------------------------------------------------
INSERT INTO "part_of_courses" (id, course_id, name)
VALUES
    -- Course 1: HTML CSS JS (3 phần)
    (1,  1, 'Phần 1: HTML – Nền tảng Web'),
    (2,  1, 'Phần 2: CSS – Tạo giao diện đẹp'),
    (3,  1, 'Phần 3: JavaScript & Dự án thực tế'),

    -- Course 2: Chat App (2 phần)
    (4,  2, 'Phần 1: Thiết kế & Xác thực'),
    (5,  2, 'Phần 2: Backend & Realtime'),

    -- Course 3: Claude AI (1 phần)
    (6,  3, 'Claude AI & Claude Code – Tổng quan'),

    -- Course 4: Next.js (1 phần)
    (7,  4, 'Next.js App Router'),

    -- Course 5: ReactJS (2 phần)
    (8,  5, 'Phần 1: JavaScript & TypeScript Nền tảng'),
    (9,  5, 'Phần 2: React & Dự án MERN'),

    -- Course 6: NestJS (1 phần)
    (10, 6, 'NestJS – Kiến trúc & Khái niệm cốt lõi');

SELECT setval(pg_get_serial_sequence('"part_of_courses"', 'id'), (SELECT MAX(id) FROM "part_of_courses"));

-- -------------------------------------------------------
-- 6. LESSONS (video từ kênh youtube.com/@MTikCode)
-- -------------------------------------------------------
INSERT INTO "lessions" (id, name, course_id, part_id, length, description, value)
VALUES

-- ===================================================================
-- COURSE 1 – HTML + CSS + JS (playlist: HTML + CSS + JS)
-- ===================================================================

-- Part 1: HTML
(1,
 'Học HTML & CSS Từ Con Số 0 – Phần 1: HTML',
 1, 1, '1:45:23',
 'Bài học mở đầu về HTML: cấu trúc trang web, các thẻ cơ bản, forms, tables và semantic HTML.',
 'https://www.youtube.com/watch?v=5ujZ_HOCpME'),

-- Part 2: CSS
(2,
 'Học CSS Từ Con Số 0 – Khoá Học Web Đầy Đủ',
 1, 2, '2:36:10',
 'Toàn bộ kiến thức CSS: selectors, box model, flexbox, grid, responsive design và animations.',
 'https://www.youtube.com/watch?v=OZb9dVLpEC8'),

(3,
 'Xây Dựng Landing Page Đẹp Chuẩn UI/UX – Phần 1',
 1, 2, '1:17:07',
 'Xây dựng landing page chuyên nghiệp với Tailwind CSS 4 và jQuery – phần thiết kế layout và component.',
 'https://www.youtube.com/watch?v=_mpGSMkdKdI'),

(4,
 'Xây Dựng Landing Page Đẹp Chuẩn UI/UX – Phần 2',
 1, 2, '1:31:39',
 'Hoàn thiện landing page: animations, responsive và tối ưu trải nghiệm người dùng.',
 'https://www.youtube.com/watch?v=9VOb7XD6sAQ'),

-- Part 3: JS & Project
(5,
 'Xây Dựng Portfolio Cá Nhân Chỉ Với HTML & CSS',
 1, 3, '1:32:36',
 'Hướng dẫn tạo portfolio cá nhân đẹp dành cho người mới bắt đầu lập trình web – không cần framework.',
 'https://www.youtube.com/watch?v=1lLU6Fm4sms'),

(6,
 'JavaScript Crash Course – Master JS In One Video',
 1, 3, '~1:25:00',
 'Tổng hợp toàn bộ JavaScript: variables, functions, DOM, events, async/await, fetch API.',
 'https://www.youtube.com/watch?v=g7T23Xzys-A'),

-- ===================================================================
-- COURSE 2 – Chat App Realtime (playlist: Realtime Chat App)
-- ===================================================================

-- Part 4: Design & Auth
(7,
 'Learn How to Turn Ideas → Database → API | Backend Design Guide',
 2, 4, '21:12',
 'Học cách tư duy từ ý tưởng → Database → API. Nền tảng thiết kế backend chuyên nghiệp.',
 'https://www.youtube.com/watch?v=3lH2oqKK-3U'),

(8,
 'Build Hệ Thống Xác Thực Người Dùng JWT – Dự Án Moji (Phần 1)',
 2, 4, '2:04:59',
 'Triển khai JWT authentication: register, login, refresh token với Express.js và MongoDB.',
 'https://www.youtube.com/watch?v=33BUj_fLNgk'),

-- Part 5: Backend & Realtime
(9,
 'Dựng Ứng Dụng Chat Fullstack | Backend với ExpressJS & MongoDB – Moji (Phần 2)',
 2, 5, '1:29:19',
 'Xây dựng REST API với Express.js, thiết kế schema MongoDB và kết nối các tính năng chat.',
 'https://www.youtube.com/watch?v=FQtiYJZ9FPs'),

(10,
 'Dựng Ứng Dụng Chat Fullstack | React + Socket.IO – Dự Án Moji (Phần 3)',
 2, 5, '2:37:47',
 'Tích hợp Socket.IO vào React: gửi/nhận tin nhắn theo thời gian thực, quản lý rooms và online status.',
 'https://www.youtube.com/watch?v=KssExPfHe88'),

(11,
 'Dựng Ứng Dụng Chat Fullstack | Hoàn Thiện – Dự Án Moji (Phần 4)',
 2, 5, '2:57:52',
 'Hoàn thiện app: notifications, file upload, deploy lên production và tổng kết dự án.',
 'https://www.youtube.com/watch?v=aHZgj6e0vbs'),

-- ===================================================================
-- COURSE 3 – Claude AI (playlist: ClaudeAI)
-- ===================================================================

(12,
 'What is Claude Code?',
 3, 6, '~1:00',
 'Giới thiệu Claude Code – công cụ AI mới nhất của Anthropic dành cho lập trình viên.',
 'https://www.youtube.com/watch?v=eX33TV-xFEE'),

(13,
 'Install Claude in Antigravity',
 3, 6, '~1:00',
 'Hướng dẫn cài đặt Claude Code trong Antigravity – môi trường AI coding hiện đại.',
 'https://www.youtube.com/watch?v=Gj5I0cLIhM0'),

(14,
 'The Secret Loop – Claude Code "Works By Itself"',
 3, 6, '~1:00',
 'Khám phá cơ chế vòng lặp tự động của Claude Code giúp AI tự làm việc không cần can thiệp.',
 'https://www.youtube.com/watch?v=-sFtkbxdUqA'),

(15,
 'Authorization Mechanism in Claude Code',
 3, 6, '~1:00',
 'Cách Claude Code xử lý phân quyền và bảo mật khi thao tác với file system và terminal.',
 'https://www.youtube.com/watch?v=VpX8xk6RO40'),

(16,
 'How Claude Code Compresses Memories',
 3, 6, '~1:00',
 'Tìm hiểu cơ chế nén bộ nhớ của Claude Code giúp duy trì context qua nhiều phiên làm việc.',
 'https://www.youtube.com/watch?v=J-RGv01xbYI'),

-- ===================================================================
-- COURSE 4 – Next.js (playlist: NextJS)
-- ===================================================================

(17,
 'Why Did I Switch from React SPA to Next.js?',
 4, 7, '6:18',
 'So sánh React SPA và Next.js – lý do thực tế khiến nhiều developer chuyển sang Next.js App Router.',
 'https://www.youtube.com/watch?v=e8hmRTrpoiM'),

(18,
 'Rendering Strategies in Next.js',
 4, 7, '3:09',
 'Phân tích chi tiết SSR, SSG, ISR và Streaming trong Next.js App Router.',
 'https://www.youtube.com/watch?v=6uqvzBrL1vM'),

(19,
 'When to Use Server vs Client Components in Next.js',
 4, 7, '13:35',
 'Hướng dẫn quyết định khi nào dùng Server Component, khi nào cần Client Component.',
 'https://www.youtube.com/watch?v=1hOt_-bId84'),

-- ===================================================================
-- COURSE 5 – ReactJS (playlist: ReactJS)
-- ===================================================================

-- Part 8: JS & TS Foundation
(20,
 'All JavaScript Knowledge You Need Before Learning React',
 5, 8, '24:28',
 'Tổng hợp toàn bộ kiến thức JavaScript cần nắm vững trước khi bắt đầu học React.',
 'https://www.youtube.com/watch?v=UGFaM0sT-0g'),

(21,
 'Self-Study TypeScript In 30 Minutes',
 5, 8, '35:14',
 'Học TypeScript từ đầu trong 30 phút – các khái niệm cốt lõi cần biết cho dự án React/Node.',
 'https://www.youtube.com/watch?v=POQ31Iamskw'),

-- Part 9: React & MERN Project
(22,
 'Học React JS Từ Cơ Bản – Dựng Dự Án Trắc Nghiệm',
 5, 9, '54:40',
 'Học React JS qua thực hành: components, state, props, hooks – xây dựng ứng dụng trắc nghiệm.',
 'https://www.youtube.com/watch?v=iMlO3_kKsYs'),

(23,
 'Dự Án Fullstack MERN 2025: React + Node + MongoDB + Tailwind 4 + Shadcn',
 5, 9, '2:49:30',
 'Xây dựng dự án Fullstack MERN hoàn chỉnh với React, Node.js, MongoDB, Tailwind CSS 4 và Shadcn UI.',
 'https://www.youtube.com/watch?v=L3a9c8M55Fo'),

-- ===================================================================
-- COURSE 6 – NestJS (playlist: NestJS)
-- ===================================================================

(24,
 'Why Is NestJS Going Viral in the Backend Industry?',
 6, 10, '4:59',
 'Phân tích lý do NestJS đang trở thành xu hướng trong cộng đồng backend developer toàn cầu.',
 'https://www.youtube.com/watch?v=8YArEfYCeKc'),

(25,
 'Hành Trình Của 1 Request Trong NestJS',
 6, 10, '2:33',
 'Giải thích chi tiết lifecycle của một HTTP request trong NestJS: middleware, guard, interceptor, pipe.',
 'https://www.youtube.com/watch?v=SMX1uTlIfDU');

SELECT setval(pg_get_serial_sequence('"lessions"', 'id'), (SELECT MAX(id) FROM "lessions"));

-- -------------------------------------------------------
-- CẬP NHẬT ĐÚNG total_lession VÀ total_part cho courses
-- -------------------------------------------------------
UPDATE "courses" SET total_lession = 6,  total_part = 3 WHERE id = 1;
UPDATE "courses" SET total_lession = 5,  total_part = 2 WHERE id = 2;
UPDATE "courses" SET total_lession = 5,  total_part = 1 WHERE id = 3;
UPDATE "courses" SET total_lession = 3,  total_part = 1 WHERE id = 4;
UPDATE "courses" SET total_lession = 4,  total_part = 2 WHERE id = 5;
UPDATE "courses" SET total_lession = 2,  total_part = 1 WHERE id = 6;

-- -------------------------------------------------------
-- 7. GHI DANH KHÓA HỌC (user_courses)
-- user1 (id=2): ghi danh course 1, 3 (miễn phí)
-- user2 (id=3): ghi danh tất cả course
-- user3 (id=4): ghi danh course 5, 6
-- -------------------------------------------------------
INSERT INTO "user_courses" (user_id, course_id, progress_percent, status)
VALUES
    (2, 1, 75,  1),
    (2, 3, 40,  1),
    (3, 1, 100, 1),
    (3, 2, 60,  1),
    (3, 3, 20,  1),
    (3, 4, 100, 1),
    (3, 5, 30,  1),
    (3, 6, 50,  1),
    (4, 5, 10,  1),
    (4, 6, 0,   1);

-- -------------------------------------------------------
-- 8. TIẾN ĐỘ BÀI HỌC (user_lessons)
-- -------------------------------------------------------
INSERT INTO "user_lessons" (user_id, course_id, lession_id, is_completed)
VALUES
    -- user1 học course 1
    (2, 1, 1, TRUE),
    (2, 1, 2, TRUE),
    (2, 1, 3, TRUE),
    (2, 1, 4, FALSE),
    (2, 1, 5, FALSE),
    (2, 1, 6, FALSE),
    -- user1 học course 3
    (2, 3, 12, TRUE),
    (2, 3, 13, FALSE),
    -- user2 đã hoàn thành course 1
    (3, 1, 1, TRUE),
    (3, 1, 2, TRUE),
    (3, 1, 3, TRUE),
    (3, 1, 4, TRUE),
    (3, 1, 5, TRUE),
    (3, 1, 6, TRUE),
    -- user2 học course 2
    (3, 2, 7,  TRUE),
    (3, 2, 8,  TRUE),
    (3, 2, 9,  TRUE),
    (3, 2, 10, FALSE),
    (3, 2, 11, FALSE),
    -- user2 đã hoàn thành course 4
    (3, 4, 17, TRUE),
    (3, 4, 18, TRUE),
    (3, 4, 19, TRUE),
    -- user3 học course 5
    (4, 5, 20, TRUE),
    (4, 5, 21, FALSE);

-- -------------------------------------------------------
-- 9. THANH TOÁN (payments)
-- -------------------------------------------------------
INSERT INTO "payments" (user_id, course_id, amount, payment_method, status, transaction_id)
VALUES
    (3, 2, 299000.00, 'BANK_TRANSFER', 1, 'TXN20260401001'),
    (3, 4, 199000.00, 'VNPAY',         1, 'VNP20260402002'),
    (3, 5, 349000.00, 'MOMO',          1, 'MMO20260403003'),
    (4, 5, 349000.00, 'BANK_TRANSFER', 1, 'TXN20260404004'),
    (2, 2, 299000.00, 'VNPAY',         0, NULL);  -- đang chờ xác nhận

-- -------------------------------------------------------
-- 10. BÌNH LUẬN MẪU (comments)
-- -------------------------------------------------------
INSERT INTO "comments" (user_id, lession_id, content, parent_id)
VALUES
    (2, 1,  'Bài giảng rất dễ hiểu, mình mới học web mà theo được ngay!', NULL),
    (3, 1,  'Cảm ơn thầy, phần form submission có thể giải thích thêm được không?', NULL),
    (2, 7,  'Phần thiết kế API này giúp ích mình rất nhiều, trước mình cứ bị rối.', NULL),
    (3, 12, 'Claude Code quá hay, mình đã thử và tiết kiệm được cả tiếng code mỗi ngày.', NULL),
    (2, 17, 'Từ khi xem video này mình đã quyết định chuyển toàn bộ dự án sang Next.js!', NULL),
    (4, 20, 'Tổng hợp JS rất chi tiết, mình đã ôn lại được nhiều kiến thức quan trọng.', NULL),
    (3, 24, 'NestJS architecture thật sự rất clean so với Express thuần!', NULL),
    (4, 25, 'Giải thích lifecycle của request rõ ràng hơn doc chính thức nhiều lần.', NULL);

-- =============================================================
-- DONE! Kiểm tra nhanh:
-- SELECT u.fullname, g.name AS role FROM users u JOIN groups g ON u.group_id = g.id;
-- SELECT c.name, COUNT(l.id) AS so_bai FROM courses c LEFT JOIN lessions l ON l.course_id = c.id GROUP BY c.name;
-- SELECT u.fullname, co.name AS course FROM user_courses uc JOIN users u ON uc.user_id=u.id JOIN courses co ON uc.course_id=co.id;
-- =============================================================
