/* =====================================================================
   A4 - Rewrite Without GOTO

   Same salary review as A2, with the same rules and the same output,
   but written with structured control flow only:
     - CONTINUE   replaces "GOTO next_employee" (skip to next iteration)
     - CASE       replaces the IF/ELSIF chain for the raise percentage
     - no labels  -> the flow reads top to bottom

   Why this version is better: every exit from the loop body is a
   visible CONTINUE at the point of the decision, there is no dummy
   "NULL;" after a label, and adding a new rule does not require a new
   jump target. The behaviour is identical (compare with A2 output).

   Uses fn_years_of_service (B2).
   ===================================================================== */
SET SERVEROUTPUT ON

DECLARE
    c_review_date CONSTANT DATE   := DATE '2026-10-08';
    c_salary_cap  CONSTANT NUMBER := 500000;

    v_raise_pct   NUMBER;
    v_new_salary  NUMBER;
    v_note        VARCHAR2(30);
    v_reviewed    PLS_INTEGER := 0;
    v_skipped     PLS_INTEGER := 0;
    v_total_raise NUMBER      := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('A4 - SALARY REVIEW WITHOUT GOTO  (review date '
        || TO_CHAR(c_review_date, 'YYYY-MM-DD') || ')');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 78, '-'));

    FOR emp IN (SELECT emp_id, full_name, monthly_salary, performance_rating, status
                  FROM employees
                 ORDER BY emp_id)
    LOOP
        -- Rule 1: inactive
        IF emp.status = 'INACTIVE' THEN
            DBMS_OUTPUT.PUT_LINE(emp.emp_id || ' ' || RPAD(emp.full_name, 22) || 'SKIPPED - inactive');
            v_skipped := v_skipped + 1;
            CONTINUE;
        END IF;

        -- Rule 2: probation
        IF fn_years_of_service(emp.emp_id, c_review_date) < 1 THEN
            DBMS_OUTPUT.PUT_LINE(emp.emp_id || ' ' || RPAD(emp.full_name, 22) || 'SKIPPED - on probation');
            v_skipped := v_skipped + 1;
            CONTINUE;
        END IF;

        v_reviewed := v_reviewed + 1;

        -- Rule 3: raise by rating
        v_raise_pct := CASE
                           WHEN emp.performance_rating >= 4 THEN 10
                           WHEN emp.performance_rating = 3  THEN 5
                           ELSE 0
                       END;

        IF v_raise_pct = 0 THEN
            DBMS_OUTPUT.PUT_LINE(emp.emp_id || ' ' || RPAD(emp.full_name, 22)
                || 'NO RAISE - rating ' || emp.performance_rating || ', coaching plan');
            CONTINUE;
        END IF;

        -- Rule 4: salary cap
        v_new_salary := LEAST(ROUND(emp.monthly_salary * (1 + v_raise_pct / 100)), c_salary_cap);
        v_note := CASE WHEN v_new_salary = c_salary_cap THEN ' (capped)' END;

        DBMS_OUTPUT.PUT_LINE(emp.emp_id || ' ' || RPAD(emp.full_name, 22)
            || LPAD(v_raise_pct || '%', 4) || '  '
            || TO_CHAR(emp.monthly_salary, 'FM999,990') || ' -> '
            || TO_CHAR(v_new_salary, 'FM999,990') || v_note);

        v_total_raise := v_total_raise + (v_new_salary - emp.monthly_salary);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(RPAD('-', 78, '-'));
    DBMS_OUTPUT.PUT_LINE('Reviewed: ' || v_reviewed || '   Skipped: ' || v_skipped
        || '   Extra monthly cost: ' || TO_CHAR(v_total_raise, 'FM999,990') || ' RWF');
END;
/

/* Expected output: identical to A2 (only the title line differs). */
