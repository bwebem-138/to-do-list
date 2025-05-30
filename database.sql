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

-- Create tables
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(64) NOT NULL
);

CREATE TABLE IF NOT EXISTS tasks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Create stored procedures
DELIMITER //

CREATE PROCEDURE create_user(IN p_username VARCHAR(255), IN p_password VARCHAR(64))
BEGIN
    INSERT INTO users (username, password) VALUES (p_username, p_password);
END //

CREATE PROCEDURE get_user_by_username(IN p_username VARCHAR(255))
BEGIN
    SELECT * FROM users WHERE username = p_username;
END //

CREATE PROCEDURE get_tasks(IN p_user_id INT)
BEGIN
    SELECT * FROM tasks WHERE user_id = p_user_id;
END //

CREATE PROCEDURE add_task(IN p_user_id INT, IN p_title VARCHAR(255))
BEGIN
    INSERT INTO tasks (user_id, title) VALUES (p_user_id, p_title);
END //

CREATE PROCEDURE delete_task(IN p_task_id INT)
BEGIN
    DELETE FROM tasks WHERE id = p_task_id;
END //

DELIMITER ;
