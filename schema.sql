
-- Create Database
CREATE DATABASE IF NOT EXISTS employee_directory;
USE employee_directory;

-- Create Table
CREATE TABLE IF NOT EXISTS employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert Dummy Data for the Demo
INSERT INTO employees (name, role, email) VALUES 
('Alice Johnson', 'Software Engineer', 'alice@example.com'),
('Bob Smith', 'Project Manager', 'bob@example.com'),
('Charlie Davis', 'DevOps Engineer', 'charlie@example.com');