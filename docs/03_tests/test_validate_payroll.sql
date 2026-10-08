/* =====================================================================
   test_validate_payroll.sql
   Tests C1 fn_validate_payroll against one record for every rule,
   plus a missing record (exception path).
   ===================================================================== */
SET SERVEROUTPUT ON

DECLARE
    v_pass   PLS_INTEGER := 0;
    v_fail   PLS_INTEGER := 0;

    PROCEDURE expect (p_id NUMBER, p_expected_prefix VARCHAR2, p_desc VARCHAR2) IS
        v_actual VARCHAR2(200);
    BEGIN
        v_actual := fn_validate_payroll(p_id);
        IF v_actual LIKE p_expected_prefix || '%' THEN
            v_pass := v_pass + 1;
            DBMS_OUTPUT.PUT_LINE('PASS  ' || RPAD(p_id, 6) || RPAD(p_desc, 28) || '| ' || v_actual);
        ELSE
            v_fail := v_fail + 1;
            DBMS_OUTPUT.PUT_LINE('FAIL  ' || RPAD(p_id, 6) || RPAD(p_desc, 28) || '| expected "'
                || p_expected_prefix || '..." got "' || v_actual || '"');
        END IF;
    END expect;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== C1 fn_validate_payroll ===');

    -- Valid records
    expect(1001, 'VALID: net pay 162,000 RWF', 'valid, with deductions');
    expect(1006, 'VALID: net pay 55,000 RWF',  'valid, 0% tax band');
    expect(1007, 'VALID: net pay 342,000 RWF', 'valid, 30% tax band');

    -- One failing record per rule
    expect(1008, 'INVALID: employee 108 is INACTIVE', 'rule 1: inactive employee');
    expect(1014, 'INVALID: pay month 2027-01',        'rule 2: future month');
    expect(1012, 'INVALID: basic pay',                'rule 3: basic mismatch');
    expect(1011, 'INVALID: bonus',                    'rule 4: bonus over 50%');
    expect(1013, 'INVALID: net pay',                  'rule 5: negative net');

    -- Exception path
    expect(9999, 'INVALID: payroll record 9999 not found', 'missing record');

    DBMS_OUTPUT.PUT_LINE('-----------------------------------------');
    DBMS_OUTPUT.PUT_LINE('TOTAL: ' || (v_pass + v_fail) || '   PASSED: ' || v_pass || '   FAILED: ' || v_fail);
END;
/

-- Batch view: validate every September 2026 record in one query
SELECT payroll_id, emp_id, fn_validate_payroll(payroll_id) AS result
  FROM payroll
 WHERE pay_month = DATE '2026-09-01'
 ORDER BY payroll_id;
