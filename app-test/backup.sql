-- Test SQL backup file - SHOULD BE BLOCKED
CREATE TABLE users (
    id INT PRIMARY KEY,
    username VARCHAR(50),
    password VARCHAR(255)
);

INSERT INTO users VALUES (1, 'admin', 'hashed_password');
