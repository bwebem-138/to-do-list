-- Enable encryption settings
--SET GLOBAL innodb_encrypt_tables = 1;
--SET GLOBAL innodb_encrypt_log = 1;
--SET GLOBAL innodb_encrypt_temporary_tables = 1;
--SET GLOBAL innodb_encryption_threads = 4;

-- Create encrypted database
CREATE DATABASE IF NOT EXISTS todo_db;
USE todo_db;

-- Create encrypted users table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create encrypted tasks table
CREATE TABLE tasks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_email VARCHAR(255) NOT NULL,
    task TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_email) REFERENCES users(email) ON DELETE CASCADE
);


DELIMITER //

CREATE PROCEDURE RegisterUser(IN user_email VARCHAR(255), IN user_password VARCHAR(255))
BEGIN
    INSERT INTO users (email, password) VALUES (user_email, user_password);
END //

CREATE PROCEDURE AuthenticateUser(IN user_email VARCHAR(255))
BEGIN
    SELECT password FROM users WHERE email = user_email;
END //

CREATE PROCEDURE GetTasks(IN user_email VARCHAR(255))
BEGIN
    SELECT id, task FROM tasks WHERE user_email = user_email;
END //

CREATE PROCEDURE AddTask(IN user_email VARCHAR(255), IN task_text TEXT)
BEGIN
    INSERT INTO tasks (user_email, task) VALUES (user_email, task_text);
END //

CREATE PROCEDURE DeleteTask(IN task_id INT)
BEGIN
    DELETE FROM tasks WHERE id = task_id;
END //

CREATE PROCEDURE DeleteUser(IN user_email VARCHAR(255))
BEGIN
    DELETE FROM users WHERE email = user_email;
    DELETE FROM tasks WHERE user_email = user_email;
END //

DELIMITER ;
