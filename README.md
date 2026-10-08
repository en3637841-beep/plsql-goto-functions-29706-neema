# PL/SQL GOTO Statements and Functions: Kigali Moto Express Payroll

**Course:** Database Development with PL/SQL (INSY 8311)
**Instructor:** Eric Maniraguha
**Assignment:** Individual Assignment III
**Student:** Neema Esther
**Student ID:** 29706

---

## 1. Project Idea

**Kigali Moto Express** is a motorcycle delivery and transport company operating in Kigali, Rwanda. It employs riders, dispatchers, mechanics, finance and customer support staff across four departments.

Every month the company prepares a payroll record for each employee. Before money is paid out, the payroll team needs to:

- calculate PAYE tax on each employee's gross pay,
- know each employee's annual salary and years of service,
- review salaries once a year and propose raises based on performance,
- validate every payroll record so that no invalid payment is made.

This repository implements those needs in PL/SQL using **GOTO statements**, **stored functions**, **exception handling** and **functions called from SQL**.

## 2. Database Design

```
DEPARTMENTS (1) ──────< (N) EMPLOYEES (1) ──────< (N) PAYROLL
```

| Table | Purpose | Key columns |
|---|---|---|
| `DEPARTMENTS` | Company departments | `dept_id` (PK), `dept_name` (unique), `location` |
| `EMPLOYEES` | Staff records | `emp_id` (PK), `dept_id` (FK, nullable), `monthly_salary`, `hire_date`, `performance_rating` (1 to 5), `status` (ACTIVE / INACTIVE) |
| `PAYROLL` | One pay record per employee per month | `payroll_id` (PK), `emp_id` (FK), `pay_month`, `basic_pay`, `bonus`, `deductions`, unique (`emp_id`, `pay_month`) |

**Sample data:** 4 departments, 10 employees, 14 payroll records. The data includes edge cases on purpose: an inactive employee, a trainee on probation, an employee with no department, a salary that hits the raise cap, and four deliberately invalid payroll records (records 1011 to 1014) used to test the validator.

### Tax rule (used by B3 and C1)

Progressive monthly PAYE modelled on Rwanda's schedule:

| Monthly gross (RWF) | Rate |
|---|---|
| 0 to 60,000 | 0% |
| 60,001 to 100,000 | 10% |
| 100,001 to 200,000 | 20% |
| Above 200,000 | 30% |

## 3. Repository Structure

```
plsql-goto-functions-29706
-neema/
├── README.md
├── .gitignore
├── 00_setup/
│   └── create_tables.sql            schema + sample data (re-runnable)
├── 01_goto/
│   ├── A1_number_classifier.sql     GOTO-based classifier
│   ├── A2_salary_review.sql         salary review using GOTO
│   ├── A3_illegal_goto.sql          two illegal GOTOs (PLS-00375) and their fixes
│   └── A4_rewrite_no_goto.sql       A2 rewritten with CONTINUE / CASE
├── 02_functions/
│   ├── B1_fn_annual_salary.sql
│   ├── B2_fn_years_of_service.sql
│   ├── B3_fn_calculate_tax.sql
│   ├── B4_fn_dept_name.sql
│   └── C1_fn_validate_payroll.sql   combined task: function + GOTO + exceptions
├── 03_tests/
│   ├── B5_functions_in_select.sql   functions in SELECT, WHERE, ORDER BY, GROUP BY
│   ├── test_functions.sql           21 PASS/FAIL unit tests for B1 to B4
│   └── test_validate_payroll.sql    9 PASS/FAIL tests for C1
├── screenshots/
└── docs/
    └── REFLECTION.md                C2
```

## 4. How to Run

Tested on Oracle Database (SQL Developer / SQL*Plus). Run the files in this order:

1. `00_setup/create_tables.sql`
2. All files in `02_functions/` (B1, B2, B3, B4, then C1, because C1 calls B3)
3. All files in `01_goto/` (A2 and A4 call `fn_years_of_service`)
4. All files in `03_tests/`
5. Compare results with the expected output written at the bottom of each file and with the screenshots.

In SQL Developer use **Run Script (F5)** and enable DBMS output. In SQL*Plus:

```sql
@00_setup/create_tables.sql
@02_functions/B1_fn_annual_salary.sql
@02_functions/B2_fn_years_of_service.sql
@02_functions/B3_fn_calculate_tax.sql
@02_functions/B4_fn_dept_name.sql
@02_functions/C1_fn_validate_payroll.sql
@01_goto/A1_number_classifier.sql
@01_goto/A2_salary_review.sql
@01_goto/A3_illegal_goto.sql
@01_goto/A4_rewrite_no_goto.sql
@03_tests/B5_functions_in_select.sql
@03_tests/test_functions.sql
@03_tests/test_validate_payroll.sql
```

## 5. Task Summary

### Part A: GOTO

| Task | What it does | GOTO usage |
|---|---|---|
| **A1** Number Classifier | Classifies 10 values (including NULL) as NULL, NEGATIVE, ZERO, PRIME, EVEN or ODD | Each test jumps to a category label; every category jumps to one shared `<<print_result>>` label |
| **A2** Salary Review | Proposes raises: inactive and probation staff skipped, rating 4 to 5 gets 10%, rating 3 gets 5%, rating 1 to 2 gets coaching, new salary capped at 500,000 RWF | `GOTO next_employee` skips the rest of the loop body; `<<next_employee>> NULL;` closes it |
| **A3** Illegal GOTO and Fix | Part 1 jumps **into an IF block**; Part 3 jumps **from an exception handler back into the block**. Both fail with **PLS-00375**. Parts 2 and 4 are the fixed versions | Shows the scope rules for GOTO |
| **A4** Rewrite Without GOTO | Same logic and output as A2 using `CONTINUE`, `CASE` and `LEAST` | None |

### Part B: Functions

| Task | Function | Returns | Exception handling |
|---|---|---|---|
| **B1** | `fn_annual_salary(p_emp_id)` | monthly salary x 12 | `NO_DATA_FOUND` returns NULL |
| **B2** | `fn_years_of_service(p_emp_id, p_as_of DEFAULT SYSDATE)` | completed years (never negative) | `NO_DATA_FOUND` returns NULL |
| **B3** | `fn_calculate_tax(p_gross)` | progressive PAYE tax (`DETERMINISTIC`) | negative input raises `ORA-20010` |
| **B4** | `fn_dept_name(p_dept_id)` | department name | NULL id returns `UNASSIGNED`; missing id returns `UNKNOWN DEPARTMENT` |
| **B5** | `B5_functions_in_select.sql` | four queries using the functions in SELECT, WHERE, ORDER BY and GROUP BY | |

### Part C: Combined Task

**C1 `fn_validate_payroll(p_payroll_id)`** checks a payroll record against five rules in order:

1. employee is ACTIVE
2. pay month is not in the future
3. basic pay equals the salary on file
4. bonus is between 0 and 50% of basic pay
5. net pay (gross minus tax from `fn_calculate_tax` minus deductions) is positive

The first failed rule sets the message and jumps with `GOTO finish` to a single exit point. A missing record is handled by `NO_DATA_FOUND`, and any unexpected error by `WHEN OTHERS`. It returns `VALID: net pay ... RWF` or `INVALID: <reason>`.

**C2** reflection is in [`docs/REFLECTION.md`](docs/REFLECTION.md).

## 6. Test Results

| Test file | Tests | Expected |
|---|---|---|
| `test_functions.sql` | 21 | 21 passed, 0 failed |
| `test_validate_payroll.sql` | 9 | 9 passed, 0 failed |

Tests use a fixed date (2026-10-08) for years of service so results are repeatable.

## 7. Screenshots

| File | Shows |
|---|---|
| `screenshots/A1_output.png` | A1 classifier output |
| `screenshots/A2_output.png` | A2 salary review output |
| `screenshots/A3_error_and_fix.png` | PLS-00375 errors and the fixed blocks running |
| `screenshots/A4_output.png` | A4 output (same results as A2) |
| `screenshots/B5_select_output.png` | Functions used inside SELECT queries |
| `screenshots/C1_output.png` | Payroll validator tests |

## 8. Notes

- **AI assistance:** I used an AI assistant (Claude, by Anthropic) to help draft the code structure, sample data, tests and documentation. I ran every script on my own Oracle database, checked the results against the expected outputs, and took the screenshots myself. I can explain every part of the submitted code.
- The salary review (A2 and A4) only prints proposals; it does not update the `EMPLOYEES` table.
- Record 1014 is dated January 2027 to test the "future month" rule. It will become valid for that rule once that month arrives.
