/* =====================================================================
   A2 - Salary Review (GOTO)

   Annual salary review for Kigali Moto Express staff.

   Rules (checked in order)
     1. INACTIVE employees are skipped              -> GOTO next_employee
     2. Less than 1 year of service = probation     -> GOTO next_employee
     3. Rating 4-5  -> 10% raise
        Rating 3    ->  5% raise
        Rating 1-2  ->  no raise, flagged for coaching -> GOTO next_employee
     4. A new salary may not exceed the 500,000 RWF cap

   Uses fn_years_of_service (B2), so run 02_functions first.
   The review date is fixed so the output is repeatable.
   This program only PROPOSES raises; it does not update the table.
   ===================================================================== */
SET SERVEROUTPUT ON

DECLARE
    c_review_date CONSTANT DATE   := DATE '2026-10-08';
    c_salary_cap  CONSTANT NUMBER := 500000;

    v_years       NUMBER;
    v_raise_pct   NUMBER;
    v_new_salary  NUMBER;
    v_note        VARCHAR2(30);
    v_reviewed    PLS_INTEGER := 0;
    v_skipped     PLS_INTEGER := 0;
    v_total_raise NUMBER      := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('A2 - SALARY REVIEW  (review date ' || TO_CHAR(c_review_date, 'YYYY-MM-DD') || ')');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 78, '-'));

    FOR emp IN (SELECT emp_id, full_name, monthly_salary, performance_rating, status
                  FROM employees
                 ORDER BY emp_id)
    LOOP
        v_note := NULL;

        -- Rule 1
        IF emp.status = 'INACTIVE' THEN
            DBMS_OUTPUT.PUT_LINE(emp.emp_id || ' ' || RPAD(emp.full_name, 22) || 'SKIPPED - inactive');
            v_skipped := v_skipped + 1;
            GOTO next_employee;
        END IF;

        -- Rule 2
        v_years := fn_years_of_service(emp.emp_id, c_review_date);
        IF v_years < 1 THEN
            DBMS_OUTPUT.PUT_LINE(emp.emp_id || ' ' || RPAD(emp.full_name, 22) || 'SKIPPED - on probation');
            v_skipped := v_skipped + 1;
            GOTO next_employee;
        END IF;

        -- Rule 3
        IF emp.performance_rating >= 4 THEN
            v_raise_pct := 10;
        ELSIF emp.performance_rating = 3 THEN
            v_raise_pct := 5;
        ELSE
            DBMS_OUTPUT.PUT_LINE(emp.emp_id || ' ' || RPAD(emp.full_name, 22)
                || 'NO RAISE - rating ' || emp.performance_rating || ', coaching plan');
            v_reviewed := v_reviewed + 1;
            GOTO next_employee;
        END IF;

        -- Rule 4
        v_new_salary := ROUND(emp.monthly_salary * (1 + v_raise_pct / 100));
        IF v_new_salary > c_salary_cap THEN
            v_new_salary := c_salary_cap;
            v_note := ' (capped)';
        END IF;

        DBMS_OUTPUT.PUT_LINE(emp.emp_id || ' ' || RPAD(emp.full_name, 22)
            || LPAD(v_raise_pct || '%', 4) || '  '
            || TO_CHAR(emp.monthly_salary, 'FM999,990') || ' -> '
            || TO_CHAR(v_new_salary, 'FM999,990') || v_note);

        v_total_raise := v_total_raise + (v_new_salary - emp.monthly_salary);
        v_reviewed    := v_reviewed + 1;

        <<next_employee>>
        NULL;   -- a label must be followed by an executable statement
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(RPAD('-', 78, '-'));
    DBMS_OUTPUT.PUT_LINE('Reviewed: ' || v_reviewed || '   Skipped: ' || v_skipped
        || '   Extra monthly cost: ' || TO_CHAR(v_total_raise, 'FM999,990') || ' RWF');
END;
/

/* Expected output
   A2 - SALARY REVIEW  (review date 2026-10-08)
   ------------------------------------------------------------------------------
   101 Jean Claude Habimana   10%  180,000 -> 198,000
   102 Aline Uwase             5%  165,000 -> 173,250
   103 Eric Nshimiyimana      10%  220,000 -> 242,000
   104 Grace Mukamana         10%  350,000 -> 385,000
   105 Patrick Mugisha       NO RAISE - rating 2, coaching plan
   106 Diane Ingabire        SKIPPED - on probation
   107 Olivier Ndayisaba      10%  480,000 -> 500,000 (capped)
   108 Claudine Umutoni      SKIPPED - inactive
   109 Kevin Iradukunda      NO RAISE - rating 1, coaching plan
   110 Sandrine Keza          10%  170,000 -> 187,000
   ------------------------------------------------------------------------------
   Reviewed: 8   Skipped: 2   Extra monthly cost: 120,250 RWF
*/
