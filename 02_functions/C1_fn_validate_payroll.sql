/* =====================================================================
   C1 - fn_validate_payroll   (Combined task: function + GOTO + exceptions)

   Validates one payroll record before payment. The checks run in order
   and the FIRST failed check stops validation. GOTO is used to jump
   straight to a single exit point (<<finish>>) so there is exactly one
   RETURN for the normal path.

   Rules
     1. Employee must be ACTIVE
     2. Pay month must not be in the future
     3. Basic pay must equal the employee's monthly salary
     4. Bonus must be between 0 and 50% of basic pay
     5. Net pay (gross - tax - deductions) must be greater than 0
        (tax comes from fn_calculate_tax, B3)

   Parameters : p_payroll_id  payroll record to validate
   Returns    : 'VALID: net pay <amount> RWF'
                'INVALID: <reason>'
                'ERROR: <message>' for unexpected errors
   Depends on : fn_calculate_tax
   ===================================================================== */
CREATE OR REPLACE FUNCTION fn_validate_payroll (
    p_payroll_id IN payroll.payroll_id%TYPE
) RETURN VARCHAR2
IS
    c_max_bonus_ratio CONSTANT NUMBER := 0.5;

    v_pay    payroll%ROWTYPE;
    v_emp    employees%ROWTYPE;
    v_gross  NUMBER;
    v_tax    NUMBER;
    v_net    NUMBER;
    v_result VARCHAR2(200);
BEGIN
    -- Raises NO_DATA_FOUND if the payroll record does not exist
    SELECT * INTO v_pay FROM payroll   WHERE payroll_id = p_payroll_id;
    SELECT * INTO v_emp FROM employees WHERE emp_id     = v_pay.emp_id;

    -- Rule 1: active employee
    IF v_emp.status <> 'ACTIVE' THEN
        v_result := 'INVALID: employee ' || v_emp.emp_id || ' is ' || v_emp.status;
        GOTO finish;
    END IF;

    -- Rule 2: no future pay months
    IF v_pay.pay_month > TRUNC(SYSDATE, 'MM') THEN
        v_result := 'INVALID: pay month ' || TO_CHAR(v_pay.pay_month, 'YYYY-MM')
                 || ' is in the future';
        GOTO finish;
    END IF;

    -- Rule 3: basic pay matches the salary on file
    IF v_pay.basic_pay <> v_emp.monthly_salary THEN
        v_result := 'INVALID: basic pay ' || v_pay.basic_pay
                 || ' does not match salary ' || v_emp.monthly_salary;
        GOTO finish;
    END IF;

    -- Rule 4: bonus within limits
    IF NVL(v_pay.bonus, 0) < 0
       OR NVL(v_pay.bonus, 0) > v_pay.basic_pay * c_max_bonus_ratio THEN
        v_result := 'INVALID: bonus ' || NVL(v_pay.bonus, 0)
                 || ' exceeds 50% of basic pay';
        GOTO finish;
    END IF;

    -- Rule 5: positive net pay
    v_gross := v_pay.basic_pay + NVL(v_pay.bonus, 0);
    v_tax   := fn_calculate_tax(v_gross);
    v_net   := v_gross - v_tax - NVL(v_pay.deductions, 0);

    IF v_net <= 0 THEN
        v_result := 'INVALID: net pay ' || v_net || ' is not positive';
        GOTO finish;
    END IF;

    -- All rules passed
    v_result := 'VALID: net pay ' || TO_CHAR(v_net, 'FM999,999,990') || ' RWF';

    <<finish>>
    RETURN v_result;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'INVALID: payroll record ' || p_payroll_id || ' not found';
    WHEN OTHERS THEN
        RETURN 'ERROR: ' || SQLERRM;
END fn_validate_payroll;
/

SHOW ERRORS FUNCTION fn_validate_payroll
