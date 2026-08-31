# 📚 Library Management System (SQL Project)

A comprehensive SQL-based project designed to manage and analyze library operations — including book issuance, returns, employee performance, and branch management.  
This project demonstrates practical SQL skills through database design, constraints, CRUD operations, analytical queries, and advanced SQL concepts.

---

## 🧾 Overview

The **Library Management System** project simulates a real-world library database.  
It includes tables for **Books**, **Members**, **Employees**, **Branches**, **Issued Status**, and **Return Status**, along with relationships and constraints to maintain data integrity.

The project covers:
- Database creation and schema modification  
- Primary and foreign key constraints  
- CRUD operations  
- Analytical and reporting queries  
- Views, CTEs, and ranking functions  
- Indexing for performance optimization  

---

## 📂 Repository Structure

| File Name | Description |
|------------|-------------|
| `Library_Management_System.sql` | Main SQL script containing schema setup, constraints, and queries |
| `books.xlsx` | Dataset of books available in the library |
| `members.xlsx` | Member registration details |
| `employees.xlsx` | Employee and branch assignment data |
| `issued_status.xlsx` | Records of issued books |
| `return_status.xlsx` | Records of returned books |
| `library_erd.png` | Entity Relationship Diagram of the database |
| `Use Library_Management_System;.txt` | Executable SQL commands and practice queries |
| `README.md` | Documentation for the project |

---

## 🧠 Learning Objectives

By working through this project, you will:
- Understand relational database design and normalization.
- Practice SQL DDL and DML operations.
- Learn how to apply constraints and relationships.
- Execute analytical queries using joins, subqueries, and aggregate functions.
- Use advanced SQL features like CTEs, Views, and Ranking functions.
- Optimize queries using indexes.

---

## ⚙️ Key Features

### 🔹 Database Setup
- Defined tables for `books`, `members`, `employees`, `branch`, `issued_status`, and `return_status`.
- Added **Primary Keys** and **Foreign Keys** for relational integrity.
- Modified data types and constraints for consistency.

### 🔹 CRUD Operations
- Inserted, updated, deleted, and retrieved records from multiple tables.
- Example:
  ```sql
  INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
  VALUES('978-1-60129-457-2', 'To Kill a Mockingbird', 'Classic', 6.00, 1, 'Harper Lee', 'J.B. Lippincott & Co.');
