-- create database
create database first_project;
use first_project;

-- Department table
CREATE TABLE departments (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    location VARCHAR(50)
);

INSERT INTO departments (id, name, location) VALUES
(1, 'HR', 'Dhaka'),
(2, 'Finance', 'Chittagong'),
(3, 'IT', 'Dhaka'),
(4, 'Marketing', 'Sylhet'),
(5, 'Operations', 'Rajshahi');

-- employees table
CREATE TABLE employees (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    department_id INT,
    salary DECIMAL(10,2),
    joining_date DATE,
    FOREIGN KEY (department_id) REFERENCES departments(id)
);


INSERT INTO employees (id, name, department_id, salary, joining_date) VALUES
(1, 'Arafat', 1, 40000, '2020-01-15'),
(2, 'Sadia', 2, 55000, '2019-05-20'),
(3, 'Rakib', 3, 60000, '2018-03-10'),
(4, 'Mitu', 3, 45000, '2021-07-25'),
(5, 'Hasan', 4, 35000, '2022-09-12'),
(6, 'Tania', 2, 50000, '2020-11-01'),
(7, 'Sabbir', NULL, 30000, '2023-02-15'),
(8, 'Sumaiya', 5, 47000, '2021-06-10'),
(9, 'Anik', 1, 52000, '2019-12-20'),
(10, 'Sami', 4, 40000, '2020-08-05');

-- QUESTION AND ANSWERS
-- 1. Find the name and salary of those employees whose salary is greater than the average salary of all employees.  
SELECT name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- 2. Show the names of departments where at least one employee works. 
SELECT DISTINCT d.name as department_name
FROM departments d
INNER JOIN employees e ON d.id = e.department_id;

-- 3. List all employees along with their department names (even if they don’t belong to any department). 
SELECT e.name, COALESCE(d.name, 'No Department') as department_name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.id;

-- 4. Display project name and total number of employees working on each project. 
SELECT d.name as department_name, COUNT(e.id) as total_employees
FROM departments d
LEFT JOIN employees e ON d.id = e.department_id
GROUP BY d.id, d.name;

-- 5. Create a CTE to find the top 3 highest-paid employees.  
WITH TopEmployees AS (
    SELECT name, salary
    FROM employees
    ORDER BY salary DESC
    LIMIT 3
)
SELECT * FROM TopEmployees;

-- 6. Using a CTE, find each department’s average salary and select only those where avg salary > 50000.
WITH DeptAvgSalary AS (
    SELECT d.name as department_name, AVG(e.salary) as avg_salary
    FROM departments d
    JOIN employees e ON d.id = e.department_id
    GROUP BY d.id, d.name
)
SELECT * FROM DeptAvgSalary WHERE avg_salary > 50000;

-- 7. Create a stored procedure to get all employees by department name (IN parameter). 
DELIMITER //
CREATE PROCEDURE GetEmployeesByDepartment(IN dept_name_param VARCHAR(50))
BEGIN
    SELECT e.name, e.salary, e.joining_date
    FROM employees e
    JOIN departments d ON e.department_id = d.id
    WHERE d.name = dept_name_param;
END //
DELIMITER ;
CALL GetEmployeesByDepartment('IT');

-- 8.  Create a stored procedure that takes department name (IN) and returns employee count (OUT).  
DELIMITER //
CREATE PROCEDURE GetEmployeeCountByDepartment(
    IN dept_name_param VARCHAR(50),
    OUT employee_count INT
)
BEGIN
    SELECT COUNT(*) INTO employee_count
    FROM employees e
    JOIN departments d ON e.department_id = d.id
    WHERE d.name = dept_name_param;
END //
DELIMITER ;
CALL GetEmployeeCountByDepartment('IT', @count);
SELECT @count as employee_count;

-- 9. Rank each employee based on their salary (highest to lowest).  
SELECT 
    name, 
    salary,
    RANK() OVER (ORDER BY salary DESC) as salary_rank
FROM employees;

-- 10. Find employees who worked on more than one project. 
SELECT e.name, d.name as department, d.location
FROM employees e
JOIN departments d ON e.department_id = d.id
WHERE d.location = 'Dhaka';