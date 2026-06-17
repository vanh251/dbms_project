-- 1. Bảng Nhóm tài khoản
CREATE TABLE "groups" (
                          "id" SERIAL PRIMARY KEY,
                          "name" VARCHAR(50) NOT NULL,
                          "permission" TEXT,
                          "create_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                          "update_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Bảng Người dùng
CREATE TABLE "users" (
                         "id" SERIAL PRIMARY KEY,
                         "fullname" VARCHAR(100) NOT NULL,
                         "email" VARCHAR(100) UNIQUE NOT NULL,
                         "phone" VARCHAR(20),
                         "avartar" VARCHAR(500),
                         "password" VARCHAR(100) NOT NULL,
                         "address" VARCHAR(100),
                         "status" INT DEFAULT 0,
                         "group_id" INT REFERENCES "groups"("id"),
                         "create_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                         "update_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Bảng Danh mục khóa học
CREATE TABLE "course_categories" (
                                     "id" SERIAL PRIMARY KEY,
                                     "name" VARCHAR(100) NOT NULL,
                                     "create_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                     "update_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Bảng Khóa học
CREATE TABLE "courses" (
                           "id" SERIAL PRIMARY KEY,
                           "name" VARCHAR(100) NOT NULL,
                           "slug" VARCHAR(100) UNIQUE,
                           "thumbnail" VARCHAR(100),
                           "description" VARCHAR(200),
                           "total_lession" INT DEFAULT 0,
                           "total_part" INT DEFAULT 0,
                           "total_time" TEXT,
                           "require" TEXT,
                           "price" VARCHAR(50),
                           "old_price" VARCHAR(50),
                           "category_id" INT REFERENCES "course_categories"("id"),
                           "status" INT DEFAULT 0,
                           "create_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                           "update_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Bảng Các phần của khóa học
CREATE TABLE "part_of_courses" (
                                   "id" SERIAL PRIMARY KEY,
                                   "course_id" INT REFERENCES "courses"("id") ON DELETE CASCADE,
                                   "name" VARCHAR(100) NOT NULL,
                                   "create_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                   "update_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Bảng Các bài học
CREATE TABLE "lessions" (
                            "id" SERIAL PRIMARY KEY,
                            "name" TEXT NOT NULL,
                            "course_id" INT REFERENCES "courses"("id") ON DELETE CASCADE,
                            "part_id" INT REFERENCES "part_of_courses"("id") ON DELETE CASCADE,
                            "length" VARCHAR(50),
                            "description" TEXT,
                            "value" TEXT,
                            "create_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                            "update_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Bảng Bình luận
CREATE TABLE "comments" (
                            "id" SERIAL PRIMARY KEY,
                            "user_id" INT REFERENCES "users"("id") ON DELETE CASCADE,
                            "parent_id" INT,
                            "lession_id" INT REFERENCES "lessions"("id") ON DELETE CASCADE,
                            "content" TEXT NOT NULL,
                            "create_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                            "update_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Bảng Ghi danh khóa học
CREATE TABLE "user_courses" (
    "id" SERIAL PRIMARY KEY,
    "user_id" INT REFERENCES "users"("id") ON DELETE CASCADE,
    "course_id" INT REFERENCES "courses"("id") ON DELETE CASCADE,
    "progress_percent" INT DEFAULT 0, 
    "status" INT DEFAULT 1, 
    "create_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "update_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE("user_id", "course_id")
);

-- 9. Bảng theo dõi tiến độ từng bài học của học viên
CREATE TABLE "user_lessons" (
    "id" SERIAL PRIMARY KEY,
    "user_id" INT REFERENCES "users"("id") ON DELETE CASCADE,
    "lession_id" INT REFERENCES "lessions"("id") ON DELETE CASCADE,
    "course_id" INT REFERENCES "courses"("id") ON DELETE CASCADE,
    "is_completed" BOOLEAN DEFAULT FALSE,
    "create_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "update_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE("user_id", "lession_id")
);

-- 10. Bảng Thanh toán
CREATE TABLE "payments" (
    "id" SERIAL PRIMARY KEY,
    "user_id" INT REFERENCES "users"("id") ON DELETE CASCADE,
    "course_id" INT REFERENCES "courses"("id") ON DELETE CASCADE,
    "amount" DECIMAL(15,2) NOT NULL, 
    "payment_method" VARCHAR(50),      
    "status" INT DEFAULT 0,            
    "transaction_id" VARCHAR(100),     
    "create_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "update_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE user_courses ADD CONSTRAINT uq_user_course UNIQUE (user_id, course_id);

-- ==========================================
-- INDEXES CHO TỐI ƯU HIỆU SUẤT (PERFORMANCE)
-- ==========================================

-- 1. Index cho các Foreign Key (Tối ưu truy vấn JOIN và DELETE/UPDATE)
CREATE INDEX "idx_users_group_id" ON "users"("group_id");
CREATE INDEX "idx_courses_category_id" ON "courses"("category_id");
CREATE INDEX "idx_part_of_courses_course_id" ON "part_of_courses"("course_id");
CREATE INDEX "idx_lessions_course_id" ON "lessions"("course_id");
CREATE INDEX "idx_lessions_part_id" ON "lessions"("part_id");
CREATE INDEX "idx_comments_user_id" ON "comments"("user_id");
CREATE INDEX "idx_comments_lession_id" ON "comments"("lession_id");
CREATE INDEX "idx_comments_parent_id" ON "comments"("parent_id");
CREATE INDEX "idx_user_lessons_user_id" ON "user_lessons"("user_id");
CREATE INDEX "idx_user_lessons_course_id" ON "user_lessons"("course_id");
CREATE INDEX "idx_payments_user_id" ON "payments"("user_id");
CREATE INDEX "idx_payments_course_id" ON "payments"("course_id");

-- 2. Index cho các trường thường xuyên truy vấn/lọc (Filtering)
CREATE INDEX "idx_courses_status" ON "courses"("status");
CREATE INDEX "idx_payments_transaction_id" ON "payments"("transaction_id");
CREATE INDEX "idx_users_status" ON "users"("status");

-- 3. Composite Index (Index kết hợp)
-- Tối ưu khi lấy danh sách comment của một bài học và sắp xếp theo thời gian mới nhất
CREATE INDEX "idx_comments_lession_created" ON "comments"("lession_id", "create_at" DESC);