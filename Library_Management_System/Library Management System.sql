Use Library_Management_System;
-------------------
--To check the data type of table
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'branch';

EXEC sp_help 'employees';

-----------------------------

--change data type of emp_id
ALTER TABLE employees DROP CONSTRAINT PK_employees;
-----------------

ALTER TABLE employees
ALTER COLUMN emp_id int not null;

ALTER TABLE issued_status
ALTER COLUMN issued_emp_id int not null;

alter table books
alter column status bit;

alter table branch
alter column manager_id int not null;
---------------------
--Add Primary Key----
---------------------

alter table branch
add constraint pk_branch primary key (branch_id);

alter table books
add constraint pk_books primary key (isbn);

alter table employees
add constraint pk_employees primary key (emp_id);

alter table issued_status
add constraint pk_issued_status primary key (issued_id);

alter table return_status
add constraint pk_return_status primary key (return_id);

------------------------
---Foreign Key----------
------------------------
alter table issued_status
add constraint fk_members foreign key(issued_member_id)
REFERENCES members(member_id); 

alter table issued_status
add constraint fk_books foreign key(issued_book_isbn)
references books(isbn);

alter table issued_status
add constraint fk_employees foreign key(issued_emp_id)
references employees(emp_id);

alter table employees
add constraint fk_branch foreign key(branch_id)
references branch (branch_id);


alter table return_status
add constraint fk_issued_status foreign key(issued_id)
references issued_status (issued_id);

---------------------------------------------------------------------------------------------
--These issued_id didn't exit in issued_status but exit in return_status, so need to remove this first before adding foreign key
SELECT issued_id
FROM return_status
WHERE issued_id NOT IN (SELECT issued_id FROM issued_status);
------------------
--Update status value 'Yes' to 1 or 0 for bit datatype.
UPDATE books
SET status = CASE 
    WHEN status IN ('yes', 'true', '1') THEN '1'
    ELSE '0'
END;



DELETE FROM return_status
WHERE issued_id IN ('IS101', 'IS105', 'IS103');

-----------------------------------------------------------------------------------------------------
-------CRUD Operations-----------
----Create: Inserted sample records into the books table.
----Read: Retrieved and displayed data from various tables.
----Update: Updated records in the employees table.
----Delete: Removed records from the members table as needed

--1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')
INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES('978-1-60129-457-2', 'To Kill a Mockingbird', 'Classic', 6.00, 1, 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT * FROM books;

--2. Update an Existing Member's Address
UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103';


--3. Delete a Record from the books Table
DELETE FROM books
WHERE   isbn =  '978-1-60129-457-2';

--4. Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.

SELECT * FROM issued_status
WHERE issued_member_id = 'C110';
------------------------------------------------------------
------------All Expected Questions.

--1.Retrieve all books whose rental price is above the average rental price.

select book_title, rental_price from books
where rental_price>
(select avg(rental_price) from books);

--2.List all employees working in branch B001.

select * from employees
where branch_id='B001';

--3.Show all members registered after 2021‑05‑15.

select * from members
where reg_date= '2021-05-15';

--4.Display all books issued by employee 104.

select issued_book_name from issued_status
where issued_emp_id= 104;

--5.Find all books that have not been returned yet (compare issued_status and return_status).

select i.issued_book_name
from issued_status as i
left join return_status as r
on i.issued_id= r.issued_id
where r.return_book_name is null;

--6.Show all issued books along with the member name and employee name who issued them.

select i.issued_book_name,i.issued_date,
m.member_name, e.emp_name
from issued_status as i
inner join employees as e
on i.issued_emp_id=e.emp_id
inner join members as m
on m.member_id= i.issued_member_id;

--7.Retrieve all books issued from branches located on Pine St.

select i.issued_book_name, i.issued_date
from issued_status as i
join employees as e
on i.issued_emp_id= e.emp_id
join branch as b
on b.branch_id= e.branch_id
where b.branch_address='567 Pine St';

--8.Display all employees along with their branch address.

select e.emp_name, b.branch_address
from employees as e
inner join branch as b
on e.branch_id= b.branch_id;

--9.List all members and the books they have borrowed (include book title and issue date).

select m.member_name,b.book_title, 
i.issued_book_name, i.issued_date
from members as m
join issued_status as i
on m.member_id= i.issued_member_id
join books as b
on b.isbn= i.issued_book_isbn;

--10.Show all books returned along with the return date and the employee who issued them.

select r.return_book_name, r.return_date, e.emp_name
from return_status as r
join issued_status as i
on r.return_book_isbn= i.issued_book_isbn
join employees as e
on e.emp_id= i.issued_emp_id;

--11.Find employees whose salary is greater than the average salary of all employees.

select emp_id, emp_name, salary
from employees
where salary > (select avg(salary) from employees);

--12.Retrieve books whose rental price is higher than the maximum rental price of “Classic” category books.

select book_title , rental_price
from books 
where rental_price> (select max(rental_price)
from books
where category= 'Classic');

--13.List members who have borrowed more than one book.

select m.member_id,
       m.member_name,
       count(*) as books_borrowed
from members m
join issued_status i
    on m.member_id = i.issued_member_id
group by m.member_id, m.member_name
having count(*) > 1;

--14.Show books issued by employees who work in branches managed by employee ID 109.

select i.issued_book_name
from issued_status as i
join employees as e
on i.issued_emp_id= e.emp_id
join branch as b
on e.branch_id= b.branch_id
where b.manager_id= 109.00;

--15.Find members who have borrowed books authored by George R.R. Martin.

select m.member_name, b.book_title, b.author
from books as b
inner join issued_status as i
on b.isbn= i.issued_book_isbn
join members as m
on m.member_id= i.issued_member_id
where b.author= 'George R.R. Martin';

--16.Retrieve all books that are either issued or returned (use UNION).

select issued_book_name from issued_status
union
select return_book_name from return_status;

--17.Find books that were issued but not yet returned (use EXCEPT).

select issued_book_name from issued_status
except 
select return_book_name from return_status;

--18.List all employees who have not issued any books (use NOT IN or EXCEPT).

select emp_id, emp_name
from employees
where emp_id not in (
    select issued_emp_id
    from issued_status);

--19.Count how many books have been issued by each employee.
select count(*) as books_count, issued_emp_id
from issued_status
group by issued_emp_id;

--20.Find the total rental income per category.
select sum(rental_price) 
as total_rental_income, category
from books
group by category;

--21.Display the number of members registered per year.

select count(*) as registered_members,
year(reg_date) as registered_year
from members
group by YEAR(reg_date);


--22.Show the average salary of employees per branch.

select avg(e.salary) as avg_salary, b.branch_address
from employees as e
inner join branch as b
on e.branch_id= b.branch_id
group by b.branch_address;

--23.Find the branch with the highest number of issued books.

select top 1 count(i.issued_id) as issued_books, b.branch_address
from issued_status as i 
join employees as e
on i.issued_emp_id= e.emp_id
join branch as b
on b.branch_id= e.branch_id
group by b.branch_address
order by count(i.issued_id)desc;


--24.Create a CTE that lists the top 3 employees by number of books issued.

with top3employees as (
select count(i.issued_emp_id) as book_issued_count, e.emp_name
from issued_status as i
inner join employees as e
on i.issued_emp_id= e.emp_id
group by e.emp_name)
select top 3 * from top3employees
order by book_issued_count desc;

--25.Create a view IssuedBooksDetails showing member name, book title, issue date, and employee name.

create view Issued_books_details as
select m.member_name, b.book_title, i.issued_date, e.emp_name
from members as m
join issued_status as i
on m.member_id= i.issued_member_id
join employees as e
on i.issued_emp_id= e.emp_id
join books as b
on b.isbn= i.issued_book_isbn;

select * from Issued_books_details;


--26.Create a CTE that calculates the total number of books issued and returned per month.

with monthly_books as (
    select 
        month(issued_date) as month,
        count(*) as books_issued,
        0 as books_returned
    from issued_status
    group by month(issued_date)

    union all

    select 
        month(return_date) as month,
        0 as books_issued,
        count(*) as books_returned
    from return_status
    group by month(return_date)
)
select 
    month,
    sum(books_issued) as total_books_issued,
    sum(books_returned) as total_books_returned
from monthly_books
group by month
order by month;

--27.Create a view BranchPerformance showing branch ID, total issued books, and total returned books.

create view Branch_per_performance as
select b.branch_id, count(i.issued_id)as total_issued_books,count(r.return_id) as total_returned_books
from branch as b
join employees as e
on b.branch_id= e.branch_id
join issued_status as i
on i.issued_emp_id= e.emp_id
left join return_status as r
on r.issued_id= i.issued_id
group by b.branch_id;

select * from Branch_per_performance;

--28.Use RANK() to rank employees by the number of books they issued.

select  e.emp_name, count(i.issued_book_name) as book_issued_count,
rank() over(order by count(i.issued_book_name)desc) as issued_rank
from employees as e
join issued_status as i
on e.emp_id= i.issued_emp_id
group by e.emp_name
order by issued_rank;

--29.Use ROW_NUMBER() to assign a unique sequence number to each issued book per member.

select m.member_name, i.issued_book_name,
ROW_NUMBER() over(
partition by m.member_name order by i.issued_date) as row_num
from members as m
join issued_status as i
on m.member_id= i.issued_member_id;

--30.Use DENSE_RANK() to rank books by rental price within each category.
select book_title, 
category, rental_price,
DENSE_RANK() over(partition by
category order by rental_price desc) as dens_rank
from books;

--31. Create an index on issued_book_isbn to optimize book‑tracking queries.
create index idx_issued_book_isbn
on issued_status(issued_book_isbn);

create index idx_issued_emp_id
on issued_status(issued_emp_id);

create index idx_issued_member_id
on issued_status(issued_member_id);
---------------------------------------

---------------------------------------

select * from books;
select * from branch;
select * from employees;
select * from issued_status;
select * from members;
select * from return_status;




