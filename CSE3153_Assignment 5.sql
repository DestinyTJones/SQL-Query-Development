/*=========================================================
  CSE3153 - Assignment 5
  Name: Destiny Jones
  =========================================================*/

USE CSE3153_Assignment5_University;
GO

/*=========================================================
#1 - Add phone column to Student
=========================================================*/
ALTER TABLE university.Student
ADD phone VARCHAR(20) NULL;
GO

/* Verify */
SELECT * FROM university.Student;
GO

/*=========================================================
#2 - Insert one new student
=========================================================*/
INSERT INTO university.Student
(first_name, last_name, email, dept_id, class_year, phone)
VALUES
('Destiny',
 'Jones',
 'destiny.jones@university.edu',
 3,
 4,
 '770-555-1234');
GO

/* Verify */
SELECT *
FROM university.Student
WHERE email='destiny.jones@university.edu';
GO

/*=========================================================
#3 - Enroll the new student into an existing section
=========================================================*/
INSERT INTO university.Enrollment
(student_id, section_id, enrolled_on, grade)

SELECT
    s.student_id,
    sec.section_id,
    GETDATE(),
    NULL
FROM university.Student s
JOIN university.Section sec
    ON sec.term='2026SP'
JOIN university.Course c
    ON c.course_id=sec.course_id
WHERE s.email='destiny.jones@university.edu'
AND c.course_code='CSE3153'
AND sec.section_no=1;
GO

/* Verify */
SELECT *
FROM university.Enrollment
WHERE student_id=
(
SELECT student_id
FROM university.Student
WHERE email='destiny.jones@university.edu'
);
GO

/*=========================================================
#4 - Update one section so one student has A
and another has W
=========================================================*/

DECLARE @SectionID INT;

SELECT @SectionID = sec.section_id
FROM university.Section sec
JOIN university.Course c
ON sec.course_id=c.course_id
WHERE c.course_code='CSE3153'
AND sec.term='2026SP'
AND sec.section_no=1;

WITH Students AS
(
SELECT
student_id,
ROW_NUMBER() OVER(ORDER BY student_id) AS rn
FROM university.Enrollment
WHERE section_id=@SectionID
)

UPDATE e
SET grade=
CASE
WHEN s.rn=1 THEN 'A'
WHEN s.rn=2 THEN 'W'
ELSE grade
END
FROM university.Enrollment e
JOIN Students s
ON e.student_id=s.student_id
AND e.section_id=@SectionID;
GO

/* Verify */
SELECT *
FROM university.Enrollment
WHERE section_id=
(
SELECT section_id
FROM university.Section sec
JOIN university.Course c
ON sec.course_id=c.course_id
WHERE c.course_code='CSE3153'
AND sec.term='2026SP'
AND sec.section_no=1
);
GO

/*=========================================================
#5 - Student with Department
=========================================================*/

SELECT
s.student_id,
s.first_name,
s.last_name,
d.dept_name
FROM university.Student s
JOIN university.Department d
ON s.dept_id=d.dept_id;
GO

/*=========================================================
#6 - Student Schedule for 2026SP
=========================================================*/

SELECT
s.first_name + ' ' + s.last_name AS StudentName,
c.course_code,
sec.section_no,
i.instructor_name
FROM university.Student s
JOIN university.Enrollment e
ON s.student_id=e.student_id
JOIN university.Section sec
ON e.section_id=sec.section_id
JOIN university.Course c
ON sec.course_id=c.course_id
JOIN university.Instructor i
ON sec.instructor_id=i.instructor_id
WHERE sec.term='2026SP'
ORDER BY StudentName;
GO

/*=========================================================
#7 - All Courses with Enrollment Count
=========================================================*/

SELECT
c.course_code,
COUNT(e.student_id) AS StudentsEnrolled
FROM university.Course c

LEFT JOIN university.Section sec
ON c.course_id=sec.course_id
AND sec.term='2026SP'

LEFT JOIN university.Enrollment e
ON sec.section_id=e.section_id

GROUP BY c.course_code
ORDER BY c.course_code;
GO

/*=========================================================
#8 - Courses and Their Prerequisites
=========================================================*/

SELECT
c.course_code,
p.course_code AS prerequisite_course
FROM university.Prerequisite pr
JOIN university.Course c
ON pr.course_id=c.course_id
JOIN university.Course p
ON pr.prereq_course_id=p.course_id
ORDER BY c.course_code;
GO

/*=========================================================
#9 - Departments with more than 2 students
=========================================================*/

SELECT
d.dept_name,
COUNT(s.student_id) AS StudentCount
FROM university.Department d
JOIN university.Student s
ON d.dept_id=s.dept_id
GROUP BY d.dept_name
HAVING COUNT(s.student_id)>2;
GO

/*=========================================================
#10 - Students enrolled in CSE3153 in 2026SP
but NOT in 2026FA
=========================================================*/

SELECT
s.student_id,
s.first_name,
s.last_name

FROM university.Student s

JOIN university.Enrollment e
ON s.student_id=e.student_id

JOIN university.Section sec
ON e.section_id=sec.section_id

JOIN university.Course c
ON sec.course_id=c.course_id

WHERE
c.course_code='CSE3153'
AND sec.term='2026SP'

EXCEPT

SELECT
s.student_id,
s.first_name,
s.last_name

FROM university.Student s

JOIN university.Enrollment e
ON s.student_id=e.student_id

JOIN university.Section sec
ON e.section_id=sec.section_id

JOIN university.Course c
ON sec.course_id=c.course_id

WHERE
c.course_code='CSE3153'
AND sec.term='2026FA';
GO