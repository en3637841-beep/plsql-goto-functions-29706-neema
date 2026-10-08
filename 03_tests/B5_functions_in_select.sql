/* =====================================================================
   B5 - Functions in SQL

   Shows that the stored functions can be used directly inside SQL:
   in the SELECT list, in WHERE, in ORDER BY and in GROUP BY.
   Run after 00_setup and 02_functions.
   ===================================================================== */
SET LINESIZE 200
SET PAGESIZE 100
COLUMN full_name  FORMAT A22
COLUMN department FORMAT A12
COLUMN validation FORMAT A50

-- ---------------------------------------------------------------------
-- Query 1: Employee overview (functions in the SELECT list)
-- ---------------------------------------------------------------------
SELECT e.emp_id,
       e.full_name,
       fn_dept_name(e.dept_id)                            AS department,
       e.monthly_salary,
       fn_annual_salary(e.emp_id)                         AS annual_salary,
       fn_years_of_service(e.emp_id, DATE '2026-10-08')   AS years_service,
       fn_calculate_tax(e.monthly_salary)                 AS monthly_tax,
       e.monthly_salary - fn_calculate_tax(e.monthly_salary) AS take_home
  FROM employees e
 ORDER BY e.emp_id;

-- ---------------------------------------------------------------------
-- Query 2: Long-serving staff (function in WHERE and ORDER BY)
-- ---------------------------------------------------------------------
SELECT e.emp_id,
       e.full_name,
       fn_years_of_service(e.emp_id, DATE '2026-10-08') AS years_service
  FROM employees e
 WHERE fn_years_of_service(e.emp_id, DATE '2026-10-08') >= 5
 ORDER BY fn_years_of_service(e.emp_id, DATE '2026-10-08') DESC;

-- ---------------------------------------------------------------------
-- Query 3: Annual payroll cost per department (function in GROUP BY)
-- ---------------------------------------------------------------------
SELECT fn_dept_name(e.dept_id)        AS department,
       COUNT(*)                       AS headcount,
       SUM(fn_annual_salary(e.emp_id)) AS annual_cost
  FROM employees e
 WHERE e.status = 'ACTIVE'
 GROUP BY fn_dept_name(e.dept_id)
 ORDER BY annual_cost DESC;

-- ---------------------------------------------------------------------
-- Query 4: Payroll register with tax and validation (C1 in SQL)
-- ---------------------------------------------------------------------
SELECT p.payroll_id,
       p.emp_id,
       TO_CHAR(p.pay_month, 'YYYY-MM')                        AS month,
       p.basic_pay + p.bonus                                  AS gross,
       fn_calculate_tax(p.basic_pay + p.bonus)                AS tax,
       p.basic_pay + p.bonus
         - fn_calculate_tax(p.basic_pay + p.bonus)
         - p.deductions                                       AS net,
       fn_validate_payroll(p.payroll_id)                      AS validation
  FROM payroll p
 ORDER BY p.payroll_id;

/* Expected (Query 3, active staff only)
   Operations   5  12,480,000
   Finance      1   4,200,000
   Dispatch     1   2,640,000
   UNASSIGNED   1   2,040,000
   Maintenance  1   1,140,000
*/
