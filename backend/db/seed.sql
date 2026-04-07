USE faculty_management_system;

DELETE FROM teacher_uploads;
DELETE FROM course_allocations;
DELETE FROM users;

INSERT INTO users (email, password_hash, role)
VALUES
  ('admin@fms.com', '12345678', 'admin'),
  ('hod@fms.com', '12345678', 'hod'),
  ('teacher@fms.com', '12345678', 'teacher');

INSERT INTO course_allocations (faculty_name, course_name)
VALUES
  ('Fahad Malik', 'Data Structures'),
  ('Kainat Sajid', 'Introduction to Computing'),
  ('Hadia', 'Software Engineering');

INSERT INTO teacher_uploads (owner_user_id, faculty_name, course_name, file_type, file_name, status, feedback)
VALUES
  ((SELECT id FROM users WHERE email = 'teacher@fms.com' LIMIT 1), 'Kainat Sajid', 'Introduction to Computing', 'Syllabus', 'ICT-Syllabus.pdf', 'pending', ''),
  ((SELECT id FROM users WHERE email = 'teacher@fms.com' LIMIT 1), 'Kainat Sajid', 'Data Structures', 'Lesson Plan', 'DS-Lesson-Plan.pdf', 'approved', ''),
  ((SELECT id FROM users WHERE email = 'teacher@fms.com' LIMIT 1), 'Kainat Sajid', 'Software Engineering', 'Assessment', 'SE-Assessment.docx', 'rejected', 'Please add CLO mapping section.');
