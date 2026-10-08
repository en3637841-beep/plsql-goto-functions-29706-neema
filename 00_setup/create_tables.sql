/* =====================================================================
   Project : Kigali Moto Express - Rider & Staff Payroll
   File    : 00_setup/create_tables.sql
   Purpose : Create the schema and load sample data used by every
             GOTO program, function and test in this repository.

   Scenario
   --------
   Kigali Moto Express is a motorcycle delivery and transport company
   in Kigali. It employs riders, dispatchers, mechanics, finance and
   support staff. Each month the company prepares a payroll record per
   employee (basic pay + bonus - deductions - PAYE tax). The PL/SQL
   code in this project reviews salaries, computes tax and service
   years, and validates payroll records before payment.

   Tables
   ------
   DEPARTMENTS (1) ----< (N) EMPLOYEES (1) ----< (N) PAYROLL
   ===================================================================== */

SET SERVEROUTPUT ON

-- ---------------------------------------------------------------------
-- 1. Drop existing tables (safe to re-run)
-- ---------------------------------------------------------------------
BEGIN
    FOR t IN (SELECT table_name
                FROM user_tables
               WHERE table_name IN ('PAYROLL', 'EMPLOYEES', 'DEPARTMENTS'))
    LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
        DBMS_OUTPUT.PUT_LINE('Dropped table ' || t.table_name);
    END LOOP;
END;
/

-- ---------------------------------------------------------------------
-- 2. Create tables
-- ---------------------------------------------------------------------
CREATE TABLE departments (
    dept_id     NUMBER(4)     CONSTRAINT pk_departments PRIMARY KEY,
    dept_name   VARCHAR2(50)  CONSTRAINT nn_dept_name NOT NULL
                              CONSTRAINT uq_dept_name UNIQUE,
    location    VARCHAR2(50)
);

CREATE TABLE employees (
    emp_id              NUMBER(5)     CONSTRAINT pk_employees PRIMARY KEY,
    full_name           VARCHAR2(80)  CONSTRAINT nn_emp_name NOT NULL,
    job_title           VARCHAR2(40),
    dept_id             NUMBER(4)     CONSTRAINT fk_emp_dept
                                      REFERENCES departments (dept_id),
    monthly_salary      NUMBER(10,2)  CONSTRAINT ck_emp_salary CHECK (monthly_salary > 0),
    hire_date           DATE          CONSTRAINT nn_emp_hire NOT NULL,
    performance_rating  NUMBER(1)     CONSTRAINT ck_emp_rating
                                      CHECK (performance_rating BETWEEN 1 AND 5),
    status              VARCHAR2(10)  DEFAULT 'ACTIVE'
                                      CONSTRAINT ck_emp_status
                                      CHECK (status IN ('ACTIVE', 'INACTIVE'))
);

CREATE TABLE payroll (
    payroll_id  NUMBER(6)     CONSTRAINT pk_payroll PRIMARY KEY,
    emp_id      NUMBER(5)     CONSTRAINT nn_pay_emp NOT NULL
                              CONSTRAINT fk_pay_emp REFERENCES employees (emp_id),
    pay_month   DATE          CONSTRAINT nn_pay_month NOT NULL,
    basic_pay   NUMBER(10,2)  CONSTRAINT nn_pay_basic NOT NULL,
    bonus       NUMBER(10,2)  DEFAULT 0,
    deductions  NUMBER(10,2)  DEFAULT 0,
    CONSTRAINT uq_pay_emp_month UNIQUE (emp_id, pay_month)
);

-- ---------------------------------------------------------------------
-- 3. Sample data
-- ---------------------------------------------------------------------
INSERT INTO departments VALUES (10, 'Operations',  'Nyarugenge Hub');
INSERT INTO departments VALUES (20, 'Dispatch',    'Kimironko Office');
INSERT INTO departments VALUES (30, 'Finance',     'Head Office, Kacyiru');
INSERT INTO departments VALUES (40, 'Maintenance', 'Gikondo Garage');

-- emp_id, name, title, dept, monthly_salary (RWF), hire_date, rating, status
INSERT INTO employees VALUES (101, 'Jean Claude Habimana', 'Senior Rider',       10, 180000, DATE '2019-03-15', 5, 'ACTIVE');
INSERT INTO employees VALUES (102, 'Aline Uwase',          'Rider',              10, 165000, DATE '2022-06-01', 3, 'ACTIVE');
INSERT INTO employees VALUES (103, 'Eric Nshimiyimana',    'Dispatcher',         20, 220000, DATE '2020-01-10', 4, 'ACTIVE');
INSERT INTO employees VALUES (104, 'Grace Mukamana',       'Finance Officer',    30, 350000, DATE '2018-09-03', 4, 'ACTIVE');
INSERT INTO employees VALUES (105, 'Patrick Mugisha',      'Mechanic',           40,  95000, DATE '2023-02-20', 2, 'ACTIVE');
INSERT INTO employees VALUES (106, 'Diane Ingabire',       'Trainee Rider',      10,  55000, DATE '2026-07-01', 3, 'ACTIVE');
INSERT INTO employees VALUES (107, 'Olivier Ndayisaba',    'Operations Manager', 10, 480000, DATE '2017-05-12', 5, 'ACTIVE');
INSERT INTO employees VALUES (108, 'Claudine Umutoni',     'Dispatcher',         20, 140000, DATE '2021-11-08', 3, 'INACTIVE');
INSERT INTO employees VALUES (109, 'Kevin Iradukunda',     'Rider',              10, 160000, DATE '2024-04-01', 1, 'ACTIVE');
INSERT INTO employees VALUES (110, 'Sandrine Keza',        'Customer Support',   NULL, 170000, DATE '2025-08-18', 4, 'ACTIVE');

-- September 2026 payroll (records 1001-1007, 1009-1010 are valid)
INSERT INTO payroll VALUES (1001, 101, DATE '2026-09-01', 180000, 15000, 10000);
INSERT INTO payroll VALUES (1002, 102, DATE '2026-09-01', 165000,     0,  5000);
INSERT INTO payroll VALUES (1003, 103, DATE '2026-09-01', 220000, 20000, 15000);
INSERT INTO payroll VALUES (1004, 104, DATE '2026-09-01', 350000,     0, 20000);
INSERT INTO payroll VALUES (1005, 105, DATE '2026-09-01',  95000,  5000,     0);
INSERT INTO payroll VALUES (1006, 106, DATE '2026-09-01',  55000,     0,     0);
INSERT INTO payroll VALUES (1007, 107, DATE '2026-09-01', 480000,     0, 30000);
INSERT INTO payroll VALUES (1008, 108, DATE '2026-09-01', 140000, 10000,     0); -- inactive employee
INSERT INTO payroll VALUES (1009, 109, DATE '2026-09-01', 160000,     0,     0);
INSERT INTO payroll VALUES (1010, 110, DATE '2026-09-01', 170000,     0,  5000);

-- Deliberately invalid records used to test the payroll validator (C1)
INSERT INTO payroll VALUES (1011, 101, DATE '2026-08-01', 180000, 120000,      0); -- bonus above 50% of basic
INSERT INTO payroll VALUES (1012, 102, DATE '2026-08-01', 150000,      0,      0); -- basic pay does not match salary
INSERT INTO payroll VALUES (1013, 105, DATE '2026-08-01',  95000,      0, 100000); -- net pay would be negative
INSERT INTO payroll VALUES (1014, 103, DATE '2027-01-01', 220000,      0,      0); -- pay month in the future

COMMIT;

-- ---------------------------------------------------------------------
-- 4. Quick verification
-- ---------------------------------------------------------------------
SELECT 'DEPARTMENTS' AS table_name, COUNT(*) AS row_count FROM departments
UNION ALL
SELECT 'EMPLOYEES', COUNT(*) FROM employees
UNION ALL
SELECT 'PAYROLL', COUNT(*) FROM payroll;
