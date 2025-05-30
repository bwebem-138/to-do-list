-- Enable encryption settings
--SET GLOBAL innodb_encrypt_tables = 1;
--SET GLOBAL innodb_encrypt_log = 1;
--SET GLOBAL innodb_encrypt_temporary_tables = 1;
--SET GLOBAL innodb_encryption_threads = 4;

-- Create encrypted database
CREATE DATABASE IF NOT EXISTS todo_db;
USE todo_db;

-- Drop procedures if they exist
DROP PROCEDURE IF EXISTS create_user;
DROP PROCEDURE IF EXISTS get_user_by_username;
DROP PROCEDURE IF EXISTS get_tasks;
DROP PROCEDURE IF EXISTS add_task;
DROP PROCEDURE IF EXISTS delete_task;
DROP PROCEDURE IF EXISTS toggle_task;
DROP PROCEDURE IF EXISTS delete_account;

-- Create tables
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username BLOB UNIQUE NOT NULL,
    password BLOB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tasks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title BLOB NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create stored procedures
DELIMITER //

CREATE PROCEDURE create_user(IN p_username BLOB, IN p_password BLOB)
BEGIN
    INSERT INTO users (username, password) VALUES (p_username, p_password);
END //

CREATE PROCEDURE get_user_by_username(IN p_username BLOB)
BEGIN
    SELECT * FROM users WHERE username = p_username;
END //

CREATE PROCEDURE toggle_task(IN p_task_id INT)
BEGIN
    UPDATE tasks 
    SET is_completed = NOT is_completed 
    WHERE id = p_task_id;
END //

CREATE PROCEDURE get_tasks(IN p_user_id INT)
BEGIN
    SELECT * FROM tasks 
    WHERE user_id = p_user_id 
    ORDER BY is_completed ASC, id DESC;
END //

CREATE PROCEDURE add_task(IN p_user_id INT, IN p_title BLOB)
BEGIN
    INSERT INTO tasks (user_id, title) VALUES (p_user_id, p_title);
END //

CREATE PROCEDURE delete_task(IN p_task_id INT)
BEGIN
    DELETE FROM tasks WHERE id = p_task_id;
END //

CREATE PROCEDURE delete_account(IN p_user_id INT)
BEGIN
    DELETE FROM tasks WHERE user_id = p_user_id;
    DELETE FROM users WHERE id = p_user_id;
END //

DELIMITER ;
