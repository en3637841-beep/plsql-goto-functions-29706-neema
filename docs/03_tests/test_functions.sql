/* =====================================================================
   test_functions.sql
   Unit tests for B1-B4. Each test compares an expected value with the
   actual function result and prints PASS or FAIL, then a summary.
   A fixed date (2026-10-08) is used so the results never change.
   ===================================================================== */
SET SERVEROUTPUT ON

DECLARE
    c_as_of  CONSTANT DATE := DATE '2026-10-08';
    v_pass   PLS_INTEGER := 0;
    v_fail   PLS_INTEGER := 0;
    v_dummy  NUMBER;

    PROCEDURE check_num (p_test VARCHAR2, p_expected NUMBER, p_actual NUMBER) IS
    BEGIN
        IF (p_expected = p_actual) OR (p_expected IS NULL AND p_actual IS NULL) THEN
            v_pass := v_pass + 1;
            DBMS_OUTPUT.PUT_LINE('PASS  ' || p_test);
        ELSE
            v_fail := v_fail + 1;
            DBMS_OUTPUT.PUT_LINE('FAIL  ' || p_test || '  expected=' || NVL(TO_CHAR(p_expected), 'NULL')
                                 || ' actual=' || NVL(TO_CHAR(p_actual), 'NULL'));
        END IF;
    END check_num;

    PROCEDURE check_str (p_test VARCHAR2, p_expected VARCHAR2, p_actual VARCHAR2) IS
    BEGIN
        IF p_expected = p_actual THEN
            v_pass := v_pass + 1;
            DBMS_OUTPUT.PUT_LINE('PASS  ' || p_test);
        ELSE
            v_fail := v_fail + 1;
            DBMS_OUTPUT.PUT_LINE('FAIL  ' || p_test || '  expected=' || p_expected
                                 || ' actual=' || NVL(p_actual, 'NULL'));
        END IF;
    END check_str;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== B1 fn_annual_salary ===');
    check_num('annual salary of 101 = 2,160,000', 2160000, fn_annual_salary(101));
    check_num('annual salary of 104 = 4,200,000', 4200000, fn_annual_salary(104));
    check_num('annual salary of 106 = 660,000',    660000, fn_annual_salary(106));
    check_num('unknown employee 999 -> NULL',          NULL, fn_annual_salary(999));

    DBMS_OUTPUT.PUT_LINE('=== B2 fn_years_of_service ===');
    check_num('101 hired 2019-03-15 -> 7 years', 7, fn_years_of_service(101, c_as_of));
    check_num('107 hired 2017-05-12 -> 9 years', 9, fn_years_of_service(107, c_as_of));
    check_num('106 hired 2026-07-01 -> 0 years', 0, fn_years_of_service(106, c_as_of));
    check_num('date before hire -> 0',           0, fn_years_of_service(106, DATE '2020-01-01'));
    check_num('unknown employee 999 -> NULL',  NULL, fn_years_of_service(999, c_as_of));

    DBMS_OUTPUT.PUT_LINE('=== B3 fn_calculate_tax ===');
    check_num('tax on 0 = 0',                    0, fn_calculate_tax(0));
    check_num('tax on 60,000 = 0 (top of 0% band)', 0, fn_calculate_tax(60000));
    check_num('tax on 100,000 = 4,000',       4000, fn_calculate_tax(100000));
    check_num('tax on 150,000 = 14,000',     14000, fn_calculate_tax(150000));
    check_num('tax on 200,000 = 24,000',     24000, fn_calculate_tax(200000));
    check_num('tax on 480,000 = 108,000',   108000, fn_calculate_tax(480000));
    check_num('tax on NULL = NULL',           NULL, fn_calculate_tax(NULL));

    BEGIN
        v_dummy := fn_calculate_tax(-5000);
        v_fail  := v_fail + 1;
        DBMS_OUTPUT.PUT_LINE('FAIL  negative gross should raise ORA-20010');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20010 THEN
                v_pass := v_pass + 1;
                DBMS_OUTPUT.PUT_LINE('PASS  negative gross raises ORA-20010');
            ELSE
                v_fail := v_fail + 1;
                DBMS_OUTPUT.PUT_LINE('FAIL  wrong error: ' || SQLERRM);
            END IF;
    END;

    DBMS_OUTPUT.PUT_LINE('=== B4 fn_dept_name ===');
    check_str('dept 10 = Operations',          'Operations',         fn_dept_name(10));
    check_str('dept 30 = Finance',             'Finance',            fn_dept_name(30));
    check_str('dept NULL = UNASSIGNED',        'UNASSIGNED',         fn_dept_name(NULL));
    check_str('dept 99 = UNKNOWN DEPARTMENT',  'UNKNOWN DEPARTMENT', fn_dept_name(99));

    DBMS_OUTPUT.PUT_LINE('-----------------------------------------');
    DBMS_OUTPUT.PUT_LINE('TOTAL: ' || (v_pass + v_fail) || '   PASSED: ' || v_pass || '   FAILED: ' || v_fail);
END;
/
