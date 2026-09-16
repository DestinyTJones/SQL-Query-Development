/* =========================================================
   CSE 3153 - Assignment 5 Starting Schema (SQL Server)
   Theme: University Registration
   ========================================================= */

-- Create a dedicated database
CREATE DATABASE CSE3153_Assignment5_University;
GO
USE CSE3153_Assignment5_University;
GO

-- In your solutions, use schema-qualified table names: university.Student, university.Course, etc.
CREATE SCHEMA university;
GO


-- Drop if tables already exist
IF OBJECT_ID('university.Prerequisite', 'U') IS NOT NULL DROP TABLE university.Prerequisite;
IF OBJECT_ID('university.Enrollment', 'U') IS NOT NULL DROP TABLE university.Enrollment;
IF OBJECT_ID('university.Section', 'U') IS NOT NULL DROP TABLE university.Section;
IF OBJECT_ID('university.Course', 'U') IS NOT NULL DROP TABLE university.Course;
IF OBJECT_ID('university.Instructor', 'U') IS NOT NULL DROP TABLE university.Instructor;
IF OBJECT_ID('university.Student', 'U') IS NOT NULL DROP TABLE university.Student;
IF OBJECT_ID('university.Department', 'U') IS NOT NULL DROP TABLE university.Department;
GO

-- Create the Department table
CREATE TABLE university.Department (
    dept_id     INT IDENTITY(1,1) PRIMARY KEY,
    dept_name   VARCHAR(60) NOT NULL UNIQUE
);
GO

-- Create the Student table
CREATE TABLE university.Student (
    student_id  INT IDENTITY(1001,1) PRIMARY KEY,
    first_name  VARCHAR(40) NOT NULL,
    last_name   VARCHAR(40) NOT NULL,
    email       VARCHAR(120) NOT NULL UNIQUE,
    dept_id     INT NULL,
    class_year  TINYINT NOT NULL,
    CONSTRAINT FK_Student_Department
        FOREIGN KEY (dept_id) REFERENCES university.Department(dept_id),
    CONSTRAINT CK_Student_ClassYear
        CHECK (class_year BETWEEN 1 AND 4)
);
GO

-- Create the Instructor table
CREATE TABLE university.Instructor (
    instructor_id   INT IDENTITY(2001,1) PRIMARY KEY,
    instructor_name VARCHAR(80) NOT NULL,
    email           VARCHAR(120) NOT NULL UNIQUE,
    dept_id         INT NOT NULL,
    hire_date       DATE NOT NULL,
    CONSTRAINT FK_Instructor_Department
        FOREIGN KEY (dept_id) REFERENCES university.Department(dept_id)
);
GO

-- Create the Course table
CREATE TABLE university.Course (
    course_id   INT IDENTITY(3001,1) PRIMARY KEY,
    dept_id     INT NOT NULL,
    course_code VARCHAR(12) NOT NULL,
    title       VARCHAR(120) NOT NULL,
    credits     TINYINT NOT NULL,
    CONSTRAINT FK_Course_Department
        FOREIGN KEY (dept_id) REFERENCES university.Department(dept_id),
    CONSTRAINT UQ_Course_DeptCode
        UNIQUE (dept_id, course_code),
    CONSTRAINT CK_Course_Credits
        CHECK (credits BETWEEN 1 AND 6)
);
GO

-- Create the Section (offering) table
CREATE TABLE university.Section (
    section_id      INT IDENTITY(4001,1) PRIMARY KEY,
    course_id       INT NOT NULL,
    instructor_id   INT NOT NULL,
    term            CHAR(6) NOT NULL,  -- e.g., 2026SP, 2026FA
    section_no      TINYINT NOT NULL,
    capacity        INT NOT NULL,
    CONSTRAINT FK_Section_Course
        FOREIGN KEY (course_id) REFERENCES university.Course(course_id),
    CONSTRAINT FK_Section_Instructor
        FOREIGN KEY (instructor_id) REFERENCES university.Instructor(instructor_id),
    CONSTRAINT UQ_Section_UniqueOffering
        UNIQUE (course_id, term, section_no),
    CONSTRAINT CK_Section_Capacity
        CHECK (capacity > 0)
);
GO

-- Create the Enrollment (bridge) table
CREATE TABLE university.Enrollment (
    student_id  INT NOT NULL,
    section_id  INT NOT NULL,
    enrolled_on DATE NOT NULL,
    grade       CHAR(1) NULL,          -- A,B,C,D,F,W
    CONSTRAINT PK_Enrollment
        PRIMARY KEY (student_id, section_id),
    CONSTRAINT FK_Enrollment_Student
        FOREIGN KEY (student_id) REFERENCES university.Student(student_id),
    CONSTRAINT FK_Enrollment_Section
        FOREIGN KEY (section_id) REFERENCES university.Section(section_id),
    CONSTRAINT CK_Enrollment_Grade
        CHECK (grade IS NULL OR grade IN ('A','B','C','D','F','W'))
);
GO

-- Create the Prerequisite (self-relation on Course) table
CREATE TABLE university.Prerequisite (
    course_id        INT NOT NULL,
    prereq_course_id INT NOT NULL,
    CONSTRAINT PK_Prerequisite PRIMARY KEY (course_id, prereq_course_id),
    CONSTRAINT FK_Prereq_Course
        FOREIGN KEY (course_id) REFERENCES university.Course(course_id),
    CONSTRAINT FK_Prereq_PrereqCourse
        FOREIGN KEY (prereq_course_id) REFERENCES university.Course(course_id),
    CONSTRAINT CK_Prereq_NotSelf
        CHECK (course_id <> prereq_course_id)
);
GO

-- Insert data into the Department table
INSERT INTO university.Department(dept_name)
VALUES ('Computer Science'), ('Information Technology'), ('Software Engineering'),
       ('Cybersecurity'), ('Game Development'), ('Mathematics');  -- no students on purpose

-- Insert data into the Student table
INSERT INTO university.Student(first_name, last_name, email, dept_id, class_year)
VALUES
('Ava','Nguyen','ava.nguyen@university.edu', 1, 2),
('Noah','Patel','noah.patel@university.edu', 1, 3),
('Mia','Johnson','mia.johnson@university.edu', 2, 1),
('Ethan','Garcia','ethan.garcia@university.edu', 4, 4),
('Zoe','Kim','zoe.kim@university.edu', 5, 2),
('Liam','Brown','liam.brown@university.edu', 3, 3),
('Olivia','Davis','olivia.davis@university.edu', 2, 4),  
('Amara','Okonkwo','amara.okonkwo@university.edu', 1, 1);  

-- Insert data into the Instructor table
INSERT INTO university.Instructor(instructor_name, email, dept_id, hire_date)
VALUES
('Dr. Chen','chen@university.edu', 1, '2018-08-20'),
('Prof. Rivera','rivera@university.edu', 2, '2020-01-15'),
('Dr. Singh','singh@university.edu', 4, '2016-09-01'),
('Prof. Allen','allen@university.edu', 5, '2022-02-01'),
('Dr. Moore','moore@university.edu', 3, '2019-08-20');

-- Insert data into the Course table
INSERT INTO university.Course(dept_id, course_code, title, credits)
VALUES
(1, 'CSE1100', 'Intro to Programming', 3),
(1, 'CSE3153', 'Database Systems', 3),
(1, 'CSE4100', 'Advanced Databases', 3),
(2, 'IT2000',  'Networking Fundamentals', 3),
(4, 'CY3000',  'Security Principles', 3),
(5, 'GDE1200', 'Game Design Basics', 3),
(3, 'SWE2200', 'Software Design', 3);

-- Insert data into the Prerequisite table
-- CSE3153 requires CSE1100; CSE4100 requires CSE3153
INSERT INTO university.Prerequisite(course_id, prereq_course_id)
SELECT c2.course_id, c1.course_id
FROM university.Course c2
JOIN university.Course c1 ON c1.course_code='CSE1100' AND c1.dept_id=1
WHERE c2.course_code='CSE3153' AND c2.dept_id=1;

INSERT INTO university.Prerequisite(course_id, prereq_course_id)
SELECT c2.course_id, c1.course_id
FROM university.Course c2
JOIN university.Course c1 ON c1.course_code='CSE3153' AND c1.dept_id=1
WHERE c2.course_code='CSE4100' AND c2.dept_id=1;

-- Sections
-- 2026SP has multiple sections; 2026FA has one course to support set-op queries
INSERT INTO university.Section(course_id, instructor_id, term, section_no, capacity)
SELECT c.course_id, i.instructor_id, '2026SP', 1, 30
FROM university.Course c
JOIN university.Instructor i ON i.instructor_name='Dr. Chen'
WHERE c.dept_id=1 AND c.course_code='CSE3153';

INSERT INTO university.Section(course_id, instructor_id, term, section_no, capacity)
SELECT c.course_id, i.instructor_id, '2026SP', 2, 25
FROM university.Course c
JOIN university.Instructor i ON i.instructor_name='Dr. Chen'
WHERE c.dept_id=1 AND c.course_code='CSE3153';

INSERT INTO university.Section(course_id, instructor_id, term, section_no, capacity)
SELECT c.course_id, i.instructor_id, '2026SP', 1, 35
FROM university.Course c
JOIN university.Instructor i ON i.instructor_name='Prof. Rivera'
WHERE c.dept_id=2 AND c.course_code='IT2000';

INSERT INTO university.Section(course_id, instructor_id, term, section_no, capacity)
SELECT c.course_id, i.instructor_id, '2026SP', 1, 20
FROM university.Course c
JOIN university.Instructor i ON i.instructor_name='Dr. Singh'
WHERE c.dept_id=4 AND c.course_code='CY3000';

INSERT INTO university.Section(course_id, instructor_id, term, section_no, capacity)
SELECT c.course_id, i.instructor_id, '2026SP', 1, 40
FROM university.Course c
JOIN university.Instructor i ON i.instructor_name='Prof. Allen'
WHERE c.dept_id=5 AND c.course_code='GDE1200';

-- A section with zero enrollments on purpose:
INSERT INTO university.Section(course_id, instructor_id, term, section_no, capacity)
SELECT c.course_id, i.instructor_id, '2026SP', 1, 30
FROM university.Course c
JOIN university.Instructor i ON i.instructor_name='Dr. Moore'
WHERE c.dept_id=3 AND c.course_code='SWE2200';

-- 2026FA offering for set-op comparisons
INSERT INTO university.Section(course_id, instructor_id, term, section_no, capacity)
SELECT c.course_id, i.instructor_id, '2026FA', 1, 30
FROM university.Course c
JOIN university.Instructor i ON i.instructor_name='Dr. Chen'
WHERE c.dept_id=1 AND c.course_code='CSE3153';

-- Enrollments
-- Helper: get section_ids quickly by joining
-- (We insert directly using subqueries to keep this script self-contained.)

-- Ava in CSE3153 (2026SP section 1) and IT2000
INSERT INTO university.Enrollment(student_id, section_id, enrolled_on, grade)
SELECT s.student_id, sec.section_id, '2026-01-20', NULL
FROM university.Student s
JOIN university.Section sec ON sec.term='2026SP' AND sec.section_no=1
JOIN university.Course c ON c.course_id=sec.course_id AND c.dept_id=1 AND c.course_code='CSE3153'
WHERE s.email='ava.nguyen@university.edu';

INSERT INTO university.Enrollment(student_id, section_id, enrolled_on, grade)
SELECT s.student_id, sec.section_id, '2026-01-21', NULL
FROM university.Student s
JOIN university.Section sec ON sec.term='2026SP'
JOIN university.Course c ON c.course_id=sec.course_id AND c.dept_id=2 AND c.course_code='IT2000'
WHERE s.email='ava.nguyen@university.edu';

-- Noah in CSE3153 (2026SP section 2) and CY3000
INSERT INTO university.Enrollment(student_id, section_id, enrolled_on, grade)
SELECT s.student_id, sec.section_id, '2026-01-20', NULL
FROM university.Student s
JOIN university.Section sec ON sec.term='2026SP' AND sec.section_no=2
JOIN university.Course c ON c.course_id=sec.course_id AND c.dept_id=1 AND c.course_code='CSE3153'
WHERE s.email='noah.patel@university.edu';

INSERT INTO university.Enrollment(student_id, section_id, enrolled_on, grade)
SELECT s.student_id, sec.section_id, '2026-01-22', NULL
FROM university.Student s
JOIN university.Section sec ON sec.term='2026SP'
JOIN university.Course c ON c.course_id=sec.course_id AND c.dept_id=4 AND c.course_code='CY3000'
WHERE s.email='noah.patel@university.edu';

-- Mia in GDE1200 only
INSERT INTO university.Enrollment(student_id, section_id, enrolled_on, grade)
SELECT s.student_id, sec.section_id, '2026-01-23', NULL
FROM university.Student s
JOIN university.Section sec ON sec.term='2026SP'
JOIN university.Course c ON c.course_id=sec.course_id AND c.dept_id=5 AND c.course_code='GDE1200'
WHERE s.email='mia.johnson@university.edu';

-- Ethan in CY3000
INSERT INTO university.Enrollment(student_id, section_id, enrolled_on, grade)
SELECT s.student_id, sec.section_id, '2026-01-24', NULL
FROM university.Student s
JOIN university.Section sec ON sec.term='2026SP'
JOIN university.Course c ON c.course_id=sec.course_id AND c.dept_id=4 AND c.course_code='CY3000'
WHERE s.email='ethan.garcia@university.edu';

-- Zoe in CSE3153 (2026SP section 1)
INSERT INTO university.Enrollment(student_id, section_id, enrolled_on, grade)
SELECT s.student_id, sec.section_id, '2026-01-25', NULL
FROM university.Student s
JOIN university.Section sec ON sec.term='2026SP' AND sec.section_no=1
JOIN university.Course c ON c.course_id=sec.course_id AND c.dept_id=1 AND c.course_code='CSE3153'
WHERE s.email='zoe.kim@university.edu';

-- Liam in IT2000 and CSE3153 (2026FA) to support set ops
INSERT INTO university.Enrollment(student_id, section_id, enrolled_on, grade)
SELECT s.student_id, sec.section_id, '2026-01-26', NULL
FROM university.Student s
JOIN university.Section sec ON sec.term='2026SP'
JOIN university.Course c ON c.course_id=sec.course_id AND c.dept_id=2 AND c.course_code='IT2000'
WHERE s.email='liam.brown@university.edu';

INSERT INTO university.Enrollment(student_id, section_id, enrolled_on, grade)
SELECT s.student_id, sec.section_id, '2026-08-25', NULL
FROM university.Student s
JOIN university.Section sec ON sec.term='2026FA'
JOIN university.Course c ON c.course_id=sec.course_id AND c.dept_id=1 AND c.course_code='CSE3153'
WHERE s.email='liam.brown@university.edu';
