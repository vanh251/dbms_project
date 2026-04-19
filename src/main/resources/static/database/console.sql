-- 1. Bảng Nhóm tài khoản (Phải tạo trước để users tham chiếu tới)
CREATE TABLE "groups" (
                          "id" SERIAL PRIMARY KEY, -- SERIAL tự động tăng trong Postgres
                          "name" VARCHAR(50) NOT NULL,
                          "permission" TEXT, -- Quyền của dạng tài khoản
                          "create_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                          "update_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Bảng Người dùng
CREATE TABLE "users" (
                         "id" SERIAL PRIMARY KEY,
                         "fullname" VARCHAR(100) NOT NULL,
                         "email" VARCHAR(100) UNIQUE NOT NULL,
                         "phone" VARCHAR(20),
                         "avartar" VARCHAR(500), -- Linh giữ nguyên chính tả 'avartar' như trong ảnh nhé
                         "password" VARCHAR(100) NOT NULL,
                         "address" VARCHAR(100),
                         "forgot_token" VARCHAR(200),
                         "active_token" VARCHAR(200),
                         "status" INT DEFAULT 0, -- 0: chưa kích hoạt, 1: kích hoạt
                         "permission" TEXT, -- Quyền truy cập khóa học riêng của tài khoản này
                         "group_id" INT REFERENCES "groups"("id"), -- Liên kết với bảng group
                         "create_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                         "update_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Bảng Token đăng nhập
CREATE TABLE "TokenLogin" (
                              "id" SERIAL PRIMARY KEY,
                              "token" VARCHAR(200) NOT NULL,
                              "user_id" INT REFERENCES "users"("id") ON DELETE CASCADE, -- Nếu xóa user thì xóa luôn token
                              "create_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                              "update_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Bảng Danh mục khóa học
CREATE TABLE "course_categories" (
                                     "id" SERIAL PRIMARY KEY,
                                     "name" VARCHAR(100) NOT NULL,
                                     "create_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                     "update_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Bảng Khóa học
CREATE TABLE "courses" (
                           "id" SERIAL PRIMARY KEY,
                           "name" VARCHAR(100) NOT NULL,
                           "slug" VARCHAR(100) UNIQUE, -- Đường dẫn thân thiện
                           "thumbnail" VARCHAR(100),
                           "description" VARCHAR(200),
                           "total_lession" INT DEFAULT 0,
                           "total_part" INT DEFAULT 0,
                           "total_time" TEXT,
                           "require" TEXT,
                           "price" VARCHAR(50),
                           "old_price" VARCHAR(50),
                           "category_id" INT REFERENCES "course_categories"("id"),
                           "status" INT DEFAULT 0, -- 0: chưa ra mắt, 1: đã ra mắt
                           "create_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                           "update_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Bảng Các phần của khóa học (Chương)
CREATE TABLE "part_of_courses" (
                                   "id" SERIAL PRIMARY KEY,
                                   "course_id" INT REFERENCES "courses"("id") ON DELETE CASCADE,
                                   "name" VARCHAR(100) NOT NULL,
                                   "create_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                   "update_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Bảng Các bài học
CREATE TABLE "lessions" (
                            "id" SERIAL PRIMARY KEY,
                            "name" TEXT NOT NULL,
                            "course_id" INT REFERENCES "courses"("id") ON DELETE CASCADE,
                            "part_id" INT REFERENCES "part_of_courses"("id") ON DELETE CASCADE,
                            "length" VARCHAR(50),
                            "description" TEXT,
                            "value" TEXT, -- Nội dung bài học (video link hoặc text)
                            "create_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                            "update_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Bảng Bình luận
CREATE TABLE "comments" (
                            "id" SERIAL PRIMARY KEY,
                            "user_id" INT REFERENCES "users"("id") ON DELETE CASCADE,
                            "parent_id" INT, -- Dùng để reply bình luận (nếu null là cmt gốc)
                            "lession_id" INT REFERENCES "lessions"("id") ON DELETE CASCADE,
                            "content" TEXT NOT NULL,
                            "create_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                            "update_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================================================
-- 9. Bảng Ghi danh khóa học (Enrollment)
-- ==============================================================================
CREATE TABLE "user_courses" (
    "id" SERIAL PRIMARY KEY,
    "user_id" INT REFERENCES "users"("id") ON DELETE CASCADE,   -- ID của học viên đăng ký
    "course_id" INT REFERENCES "courses"("id") ON DELETE CASCADE, -- ID của khóa học được đăng ký
    "progress_percent" INT DEFAULT 0, -- Phần trăm tiến độ hoàn thành khóa học (0 - 100)
    "status" INT DEFAULT 1,           -- Trạng thái học: 0: Đã hủy (Unenrolled), 1: Đang học (Enrolled), 2: Đã hoàn thành (Completed)
    "create_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Thời gian đăng ký khóa học
    "update_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- Thời gian cập nhật thông tin gần nhất
);

-- ==============================================================================
-- 10. Bảng Thanh toán (Payments)
-- ==============================================================================
CREATE TABLE "payments" (
    "id" SERIAL PRIMARY KEY,
    "user_id" INT REFERENCES "users"("id") ON DELETE CASCADE,     -- Người thực hiện thanh toán
    "course_id" INT REFERENCES "courses"("id") ON DELETE CASCADE,   -- Khóa học được thanh toán
    "amount" DECIMAL(15,2) NOT NULL,    -- Số tiền phải thanh toán (VNĐ)
    "payment_method" VARCHAR(50),       -- Phương thức thanh toán (VNPAY, MOMO, CASH,...)
    "status" INT DEFAULT 0,             -- Trạng thái thanh toán: 0: Đang chờ (Pending), 1: Đã thanh toán (Completed), -1: Thất bại/Hủy (Failed)
    "transaction_id" VARCHAR(100),      -- Mã giao dịch đối soát trả về từ đối tác thanh toán (VD: VNP_xx)
    "create_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Thời gian tạo hóa đơn
    "update_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- Thời gian cập nhật trạng thái thanh toán
);

