# C2: Reflection

**Project:** Kigali Moto Express Payroll
**Student:** Neema Esther

## 1. Why I chose this scenario

I wanted a scenario where GOTO and functions solve real problems rather than toy examples. A payroll system for a motorcycle delivery company in Kigali fits well: it has clear business rules (tax brackets, raise rules, validation rules), it naturally needs reusable calculations (annual salary, years of service, tax), and it has real edge cases such as inactive staff, trainees on probation and an employee who has not been assigned to a department yet.

## 2. What I learned about GOTO

- **How it works:** GOTO transfers control to a labelled statement (`<<label>>`). The label must be followed by an executable statement, which is why A2 uses `<<next_employee>> NULL;` at the end of the loop body.
- **Where it is allowed:** a GOTO can jump forward or backward within the same sequence of statements, and it can jump *out of* an IF, a loop or a sub-block to a label in an enclosing block.
- **Where it is illegal (A3):** it cannot jump *into* an IF statement, a loop or a sub-block, cannot move between branches of an IF, and cannot jump from an exception handler back into the block that raised the error. Oracle catches these at compile time with **PLS-00375**, so the block never runs at all.
- **Fixing an illegal GOTO:** in A3 I fixed the first error by moving the label outside the IF and jumping *around* the bonus code instead of *into* it. I fixed the second one by putting the risky statement in a nested block inside a loop, so the nested block handles the error and the loop provides the retry.

## 3. GOTO versus structured code (A2 vs A4)

A2 and A4 produce exactly the same output. Comparing them showed me:

- In A2 the reader has to scan down to find `<<next_employee>>` to understand where each skip goes. In A4 each `CONTINUE` says what happens right where the decision is made.
- A4 removes the dummy `NULL;` statement and replaces the IF/ELSIF chain with a single `CASE` expression, so it is shorter and easier to change.
- If I add a new rule to A4 I only write one more `IF ... CONTINUE`. In A2 I would also need to be careful that the jump target stays in the same scope.

My conclusion is that `CONTINUE`, `EXIT` and `CASE` should be the default. GOTO is still acceptable in a narrow case: jumping forward to a **single exit point** when many checks can each end the work early. That is how I used it in C1.

## 4. What I learned about functions

- A function must **return a value on every path**. I made sure each function has a RETURN in the normal flow and in its exception handlers.
- **Handling exceptions inside the function** (for example `NO_DATA_FOUND` returning NULL or `'UNKNOWN DEPARTMENT'`) makes a function safe to use inside a SELECT. One missing row would otherwise stop the whole query.
- **Validating input** matters: `fn_calculate_tax` raises `ORA-20010` for a negative amount, because a wrong tax figure is worse than a clear error. My tests check that the error code is exactly -20010.
- Using `%TYPE` for parameters ties them to the table columns, so the functions still work if a column size changes.
- `fn_years_of_service` takes an optional date parameter (`DEFAULT SYSDATE`). This made my tests repeatable: with a fixed date the expected years never change.
- Functions can be used in **SELECT, WHERE, ORDER BY and GROUP BY** (B5), which keeps business rules in one place instead of copying the tax formula into every query.

## 5. The combined task (C1)

`fn_validate_payroll` brought everything together: it reads two tables, calls another function (`fn_calculate_tax`), applies five rules in order, uses `GOTO finish` to reach a single exit point, and handles both a missing record and unexpected errors. I created one invalid payroll record for each rule so every path is tested, and the test file reports PASS or FAIL for each.

## 6. Challenges

- Remembering that a label cannot be the last thing before `END LOOP` or `END`; it needs a statement after it.
- Getting progressive tax right: each rate applies only to the part of income inside its bracket, not to the whole amount. I checked the values by hand at every bracket boundary (60,000, 100,000 and 200,000).
- Making tests deterministic. Using `SYSDATE` directly would have made the years-of-service results change over time.

## 7. What I would do next

- Put the functions into a `PAYROLL_PKG` package so related logic is grouped and private helpers can be hidden.
- Store tax brackets in a table instead of constants, so a change in the tax law does not need a code change.
- Add a procedure that applies approved raises from the salary review and logs each change to an audit table.
