/* =====================================================================
   B4 - fn_dept_name
   Looks up a department name from its id.

   Parameters : p_dept_id  department id (may be NULL)
   Returns    : department name
                'UNASSIGNED'         when p_dept_id is NULL
                'UNKNOWN DEPARTMENT' when no department has that id
   ===================================================================== */
CREATE OR REPLACE FUNCTION fn_dept_name (
    p_dept_id IN departments.dept_id%TYPE
) RETURN VARCHAR2
IS
    v_name departments.dept_name%TYPE;
BEGIN
    IF p_dept_id IS NULL THEN
        RETURN 'UNASSIGNED';
    END IF;

    SELECT dept_name
      INTO v_name
      FROM departments
     WHERE dept_id = p_dept_id;

    RETURN v_name;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'UNKNOWN DEPARTMENT';
END fn_dept_name;
/

SHOW ERRORS FUNCTION fn_dept_name
