-- Insert groups
INSERT INTO "groups" (id, name, permission)
VALUES (1, 'Admin', '1,2,3,4'),
       (2, 'User', NULL);

SELECT setval(pg_get_serial_sequence('"groups"', 'id'), (SELECT MAX(id) FROM "groups"));

-- Insert users
INSERT INTO "users" (id, fullname, email, password, status, permission, group_id)
VALUES (1, 'Admin User', 'admin@learnhub.com', 'admin123', 1, '1,2,3,4', 1),
       (2, 'User One', 'user1@learnhub.com', 'user123', 1, '1,3', 2),
       (3, 'User Two', 'user2@learnhub.com', 'user123', 1, '1,2,3,4', 2);

SELECT setval(pg_get_serial_sequence('"users"', 'id'), (SELECT MAX(id) FROM "users"));
