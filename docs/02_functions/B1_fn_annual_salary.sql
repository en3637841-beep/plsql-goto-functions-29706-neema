/* =====================================================================
   B1 - fn_annual_salary
   Returns an employee's annual salary (monthly_salary x 12) in RWF.

   Parameters : p_emp_id  employee id
   Returns    : annual salary, or NULL if the employee does not exist
   Exceptions : NO_DATA_FOUND is handled and turned into NULL so the
                function is safe to call from a SELECT statement.
   ===================================================================== */
CREATE OR REPLACE FUNCTION fn_annual_salary (
    p_emp_id IN employees.emp_id%TYPE
) RETURN NUMBER
IS
    v_monthly employees.monthly_salary%TYPE;
BEGIN
    SELECT monthly_salary
      INTO v_monthly
      FROM employees
     WHERE emp_id = p_emp_id;

    RETURN v_monthly * 12;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END fn_annual_salary;
/

SHOW ERRORS FUNCTION fn_annual_salary
