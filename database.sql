-- Create encrypted database
CREATE DATABASE IF NOT EXISTS todo_db;
USE todo_db;

-- Drop procedures if they exist
DROP PROCEDURE IF EXISTS create_user;
DROP PROCEDURE IF EXISTS get_user_by_email_hash;
DROP PROCEDURE IF EXISTS get_tasks;
DROP PROCEDURE IF EXISTS add_task;
DROP PROCEDURE IF EXISTS delete_task;
DROP PROCEDURE IF EXISTS toggle_task;
DROP PROCEDURE IF EXISTS edit_task;
DROP PROCEDURE IF EXISTS delete_account;

-- Create tables
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email_hash VARCHAR(255) NOT NULL UNIQUE,
    display_name BLOB NOT NULL,
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

CREATE PROCEDURE create_user(
    IN p_email_hash VARCHAR(255),
    IN p_display_name BLOB,
    IN p_password BLOB
)
BEGIN
    INSERT INTO users (email_hash, display_name, password)
    VALUES (p_email_hash, p_display_name, p_password);
END //

CREATE PROCEDURE get_user_by_email_hash(IN p_email_hash VARCHAR(255))
BEGIN
    SELECT * FROM users WHERE email_hash = p_email_hash;
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

CREATE PROCEDURE edit_task(IN p_task_id INT, IN p_title BLOB)
BEGIN
    UPDATE tasks 
    SET title = p_title 
    WHERE id = p_task_id;
END //

CREATE PROCEDURE delete_account(IN p_user_id INT)
BEGIN
    DELETE FROM tasks WHERE user_id = p_user_id;
    DELETE FROM users WHERE id = p_user_id;
END //

DELIMITER ;
