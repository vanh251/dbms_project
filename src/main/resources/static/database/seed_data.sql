-- =============================================================
-- LearnHub – Seed Data (Categories, Courses, Parts, Lessons)
-- Nguồn bài giảng: https://www.youtube.com/@MTikCode/playlists
--
-- ⚠️  QUAN TRỌNG: Groups và Users được tạo tự động bởi
--     DataInitializer khi Spring Boot khởi động.
--     CHỈ chạy file này để thêm nội dung khóa học.
--
-- Chạy SAU KHI đã khởi động bootRun lần đầu (JPA tạo bảng + seed users)
-- =============================================================

-- Tài khoản mặc định (seed bởi DataInitializer):
--   admin@learnhub.com  / admin123  → Admin
--   user1@learnhub.com  / user123   → User (quyền course 1,3)
--   user2@learnhub.com  / user123   → User (quyền course 1,2,3,4)

INSERT INTO "course_categories" (id, name)
VALUES (1, 'Lập trình Web Frontend'),
       (2, 'Lập trình Web Fullstack'),
       (3, 'Trí tuệ nhân tạo & AI Tools'),
       (4, 'Next.js & React');

SELECT setval(pg_get_serial_sequence('"course_categories"', 'id'), (SELECT MAX(id) FROM "course_categories"));

-- -------------------------------------------------------
-- 4. COURSES
-- -------------------------------------------------------
INSERT INTO "courses" (id, name, slug, description, require, total_lession, total_part, total_time, price, old_price,
                       category_id, status)
VALUES (1,
        'HTML, CSS & JavaScript – Từ Zero đến Hero',
        'html-css-js-zero-to-hero',
        'Khóa học lập trình web frontend toàn diện từ HTML cơ bản đến JavaScript nâng cao, có dự án thực tế.',
        'Không cần kiến thức nền. Chỉ cần máy tính và kết nối internet.',
        6, 3, '8 giờ 30 phút',
        'Miễn phí', NULL,
        1, 1),

       (2,
        'Xây dựng Ứng dụng Chat Realtime Fullstack',
        'chat-app-realtime-fullstack',
        'Xây dựng ứng dụng chat realtime với React, Express, MongoDB và Socket.IO – dự án thực tế hoàn chỉnh.',
        'Biết cơ bản HTML/CSS, JavaScript. Có kiến thức nền về lập trình.',
        5, 2, '5 giờ 45 phút',
        '299.000đ', '599.000đ',
        2, 1),

       (3,
        'Claude AI & Claude Code – Lập trình với AI',
        'claude-ai-code-lap-trinh-voi-ai',
        'Khám phá Claude AI và Claude Code – công cụ AI mạnh mẽ giúp lập trình viên tăng tốc độ làm việc.',
        'Có kiến thức lập trình cơ bản.',
        5, 1, '2 giờ 15 phút',
        'Miễn phí', NULL,
        3, 1),

       (4,
        'Next.js – Từ cơ bản đến nâng cao',
        'nextjs-co-ban-den-nang-cao',
        'Học Next.js App Router, Server/Client Components, các chiến lược rendering và tối ưu hiệu năng.',
        'Biết React cơ bản.',
        3, 1, '1 giờ 30 phút',
        '199.000đ', '399.000đ',
        4, 1);

SELECT setval(pg_get_serial_sequence('"courses"', 'id'), (SELECT MAX(id) FROM "courses"));

-- -------------------------------------------------------
-- 5. PARTS OF COURSES
-- -------------------------------------------------------
INSERT INTO "part_of_courses" (id, course_id, name)
VALUES
-- Course 1: HTML CSS JS
(1, 1, 'Phần 1: HTML – Nền tảng Web'),
(2, 1, 'Phần 2: CSS – Tạo giao diện đẹp'),
(3, 1, 'Phần 3: JavaScript – Lập trình động'),
-- Course 2: Chat App
(4, 2, 'Phần 1: Thiết kế & Xác thực'),
(5, 2, 'Phần 2: Backend & Realtime'),
-- Course 3: Claude AI (1 phần)
(6, 3, 'Claude AI & Claude Code'),
-- Course 4: Next.js (1 phần)
(7, 4, 'Next.js App Router');

SELECT setval(pg_get_serial_sequence('"part_of_courses"', 'id'), (SELECT MAX(id) FROM "part_of_courses"));

-- -------------------------------------------------------
-- 6. LESSONS (với video từ kênh MTikCode)
-- -------------------------------------------------------
INSERT INTO "lessions" (id, name, course_id, part_id, length, description, value)
VALUES

-- === Course 1 – HTML CSS JS ===
-- Part 1: HTML
(1, 'Học HTML & CSS Từ Con Số 0 – Phần 1: HTML', 1, 1,
 '45:00',
 'Bài học mở đầu về HTML: cấu trúc trang web, các thẻ cơ bản, forms, tables và semantic HTML.',
 'https://www.youtube.com/watch?v=5ujZ_HOCpME'),

(2, 'Học CSS Từ Con Số 0 – Khóa học đầy đủ', 1, 2,
 '1:10:00',
 'Toàn bộ kiến thức CSS: selectors, box model, flexbox, grid, responsive design và animations.',
 'https://www.youtube.com/watch?v=OZb9dVLpEC8'),

-- Part 2: CSS Projects
(3, 'Xây Dựng Landing Page Đẹp Chuẩn UI/UX – Phần 1', 1, 2,
 '35:00',
 'Xây dựng landing page chuyên nghiệp với Tailwind CSS 4 và jQuery – phần thiết kế layout.',
 'https://www.youtube.com/watch?v=_mpGSMkdKdI'),

(4, 'Xây Dựng Landing Page Đẹp Chuẩn UI/UX – Phần 2', 1, 2,
 '38:00',
 'Hoàn thiện landing page: animations, responsive và tối ưu trải nghiệm người dùng.',
 'https://www.youtube.com/watch?v=9VOb7XD6sAQ'),

-- Part 3: JavaScript
(5, 'Xây Dựng Portfolio Cá Nhân Với HTML & CSS', 1, 3,
 '28:00',
 'Hướng dẫn tạo portfolio cá nhân đẹp dành cho người mới bắt đầu lập trình web.',
 'https://www.youtube.com/watch?v=1lLU6Fm4sms'),

(6, 'JavaScript Crash Course – Master JS In One Video', 1, 3,
 '1:25:00',
 'Tổng hợp toàn bộ JavaScript: variables, functions, DOM, events, async/await, fetch API.',
 'https://www.youtube.com/watch?v=g7T23Xzys-A'),

-- === Course 2 – Chat App Realtime ===
-- Part 1: Design & Auth
(7, 'Thiết Kế Database & API – Backend Design Guide', 2, 4,
 '22:00',
 'Học cách tư duy từ ý tưởng → Database → API. Nền tảng thiết kế backend chuyên nghiệp.',
 'https://www.youtube.com/watch?v=3lH2oqKK-3U'),

(8, 'Xây Dựng Hệ Thống Xác Thực Người Dùng JWT – Phần 1', 2, 4,
 '48:00',
 'Triển khai JWT authentication: register, login, refresh token với Express.js và MongoDB.',
 'https://www.youtube.com/watch?v=33BUj_fLNgk'),

-- Part 2: Backend & Realtime
(9, 'Backend ExpressJS & MongoDB – Dự Án Moji Phần 2', 2, 5,
 '52:00',
 'Xây dựng REST API với Express.js, thiết kế schema MongoDB và kết nối các tính năng chat.',
 'https://www.youtube.com/watch?v=FQtiYJZ9FPs'),

(10, 'React + Socket.IO Realtime Chat – Dự Án Moji Phần 3', 2, 5,
 '55:00',
 'Tích hợp Socket.IO vào React: gửi/nhận tin nhắn theo thời gian thực, quản lý rooms.',
 'https://www.youtube.com/watch?v=KssExPfHe88'),

(11, 'Hoàn Thiện Ứng Dụng Chat Fullstack – Dự Án Moji Phần 4', 2, 5,
 '50:00',
 'Hoàn thiện app: online status, notifications, deploy lên production và tổng kết dự án.',
 'https://www.youtube.com/watch?v=aHZgj6e0vbs'),

-- === Course 3 – Claude AI ===
(12, 'What is Claude Code?', 3, 6,
 '12:00',
 'Giới thiệu Claude Code – công cụ AI mới nhất của Anthropic dành cho lập trình viên.',
 'https://www.youtube.com/watch?v=eX33TV-xFEE'),

(13, 'How Much Does Claude Code Cost?', 3, 6,
 '08:30',
 'Phân tích chi phí sử dụng Claude Code thực tế và cách tối ưu để dùng hiệu quả.',
 'https://www.youtube.com/watch?v=Gj5I0cLIhM0'),

(14, 'The Secret Loop – Claude Code Works By Itself', 3, 6,
 '15:00',
 'Khám phá cơ chế vòng lặp tự động của Claude Code giúp AI tự làm việc không cần can thiệp.',
 'https://www.youtube.com/watch?v=-sFtkbxdUqA'),

(15, 'Authorization Mechanism in Claude Code', 3, 6,
 '11:00',
 'Cách Claude Code xử lý phân quyền và bảo mật khi thao tác với file system và terminal.',
 'https://www.youtube.com/watch?v=VpX8xk6RO40'),

(16, 'How Claude Code Compresses Memories', 3, 6,
 '13:30',
 'Tìm hiểu cơ chế nén bộ nhớ của Claude Code giúp duy trì context qua nhiều phiên làm việc.',
 'https://www.youtube.com/watch?v=J-RGv01xbYI'),

-- === Course 4 – Next.js ===
(17, 'Why Did I Switch from React SPA to Next.js?', 4, 7,
 '18:00',
 'So sánh React SPA và Next.js – lý do thực tế khiến nhiều developer chuyển sang Next.js.',
 'https://www.youtube.com/watch?v=e8hmRTrpoiM'),

(18, 'Rendering Strategies in Next.js', 4, 7,
 '22:00',
 'Phân tích chi tiết SSR, SSG, ISR và Streaming trong Next.js App Router.',
 'https://www.youtube.com/watch?v=6uqvzBrL1vM'),

(19, 'When to Use Server vs Client Components in Next.js', 4, 7,
 '20:00',
 'Hướng dẫn quyết định khi nào dùng Server Component, khi nào cần Client Component.',
 'https://www.youtube.com/watch?v=1hOt_-bId84');

SELECT setval(pg_get_serial_sequence('"lessions"', 'id'), (SELECT MAX(id) FROM "lessions"));

-- -------------------------------------------------------
-- 7. CẤP QUYỀN CHO USER MẪU
-- user1 được truy cập course 1 và 3 (miễn phí)
-- user2 được truy cập tất cả course
-- -------------------------------------------------------
UPDATE "users"
SET permission = '1,3'
WHERE id = 2;
UPDATE "users"
SET permission = '1,2,3,4'
WHERE id = 3;

-- -------------------------------------------------------
-- 8. BÌNH LUẬN MẪU
-- -------------------------------------------------------
INSERT INTO "comments" (user_id, lession_id, content, parent_id)
VALUES (2, 1, 'Bài giảng rất dễ hiểu, mình mới học web mà theo được ngay!', NULL),
       (3, 1, 'Cảm ơn thầy, phần form submission có thể giải thích thêm được không?', NULL),
       (2, 7, 'Phần thiết kế API này giúp ích mình rất nhiều, trước mình cứ bị rối.', NULL),
       (3, 12, 'Claude Code quá hay, mình đã thử và tiết kiệm được cả tiếng code mỗi ngày.', NULL),
       (2, 17, 'Từ khi xem video này mình đã quyết định chuyển toàn bộ dự án sang Next.js!', NULL);

-- -------------------------------------------------------
-- DONE! Kiểm tra kết quả:
-- SELECT c.name, COUNT(l.id) AS so_bai FROM courses c
-- LEFT JOIN lessions l ON l.course_id = c.id
-- GROUP BY c.name;
-- -------------------------------------------------------


-- ==============================================================================
-- DỮ LIỆU MẪU (MOCK DATA) CHO 3 BẢNG MỚI
-- ==============================================================================

-- 1. Bảng Ghi danh (user_courses)
INSERT INTO "user_courses" (user_id, course_id, progress_percent, status)
VALUES (1, 1, 50, 1),
       (1, 2, 100, 1),
       (2, 1, 0, 1);

-- 2. Bảng Tiến độ bài học (user_lessons)
INSERT INTO "user_lessons" (user_id, course_id, lession_id, is_completed)
VALUES (1, 1, 1, TRUE),
       (1, 1, 2, FALSE),
       (1, 2, 3, TRUE),
       (1, 2, 4, TRUE);

-- 3. Bảng Thanh toán (payments)
INSERT INTO "payments" (user_id, course_id, amount, payment_method, status, transaction_id)
VALUES (1, 1, 499000.00, 'VNPAY', 1, 'VNP123456789'),
       (1, 2, 299000.00, 'MOMO', 1, 'MOMO987654321'),
       (2, 1, 499000.00, 'BANK_TRANSFER', 0, NULL);

