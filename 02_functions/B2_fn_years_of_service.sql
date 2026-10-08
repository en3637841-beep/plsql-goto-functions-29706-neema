/* =====================================================================
   B2 - fn_years_of_service
   Returns the number of COMPLETED years an employee has worked.

   Parameters : p_emp_id  employee id
                p_as_of   reference date (defaults to SYSDATE). Passing a
                          fixed date makes test results repeatable.
   Returns    : whole years of service (0 if hired less than a year ago
                or if p_as_of is before the hire date),
                NULL if the employee does not exist.
   ===================================================================== */
CREATE OR REPLACE FUNCTION fn_years_of_service (
    p_emp_id IN employees.emp_id%TYPE,
    p_as_of  IN DATE DEFAULT SYSDATE
) RETURN NUMBER
IS
    v_hire_date employees.hire_date%TYPE;
    v_years     NUMBER;
BEGIN
    SELECT hire_date
      INTO v_hire_date
      FROM employees
     WHERE emp_id = p_emp_id;

    v_years := TRUNC(MONTHS_BETWEEN(TRUNC(p_as_of), v_hire_date) / 12);

    RETURN GREATEST(v_years, 0);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END fn_years_of_service;
/

SHOW ERRORS FUNCTION fn_years_of_service
