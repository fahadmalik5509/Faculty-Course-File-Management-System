CREATE DATABASE IF NOT EXISTS faculty_management_system;
USE faculty_management_system;

CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(191) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('admin', 'hod', 'teacher') NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS course_allocations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  faculty_name VARCHAR(191) NOT NULL,
  course_name VARCHAR(191) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS teacher_uploads (
  id INT AUTO_INCREMENT PRIMARY KEY,
  owner_user_id INT NOT NULL,
  faculty_name VARCHAR(191) NOT NULL,
  course_name VARCHAR(191) NOT NULL,
  file_type VARCHAR(100) NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  status ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
  feedback TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  reviewed_at TIMESTAMP NULL DEFAULT NULL,
  CONSTRAINT fk_upload_owner FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE CASCADE
);

INSERT INTO users (email, password_hash, role)
VALUES
  ('admin@fms.com', '12345678', 'admin'),
  ('hod@fms.com', '12345678', 'hod'),
  ('teacher@fms.com', '12345678', 'teacher')
ON DUPLICATE KEY UPDATE email = VALUES(email);
