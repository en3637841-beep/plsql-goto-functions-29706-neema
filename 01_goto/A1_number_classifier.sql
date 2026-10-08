/* =====================================================================
   A1 - Number Classifier (GOTO)

   Classifies each number in a list as:
     NULL, NEGATIVE, ZERO, PRIME, EVEN or ODD
   The checks run in that order. As soon as a category is found, GOTO
   jumps to the label for that category, which sets the description and
   then jumps to the common <<print_result>> label.

   GOTO rules respected here:
     - every label is in the SAME loop body as the GOTOs that use it
     - GOTOs leave IF blocks (allowed); they never jump INTO an IF/LOOP
     - every label is followed by an executable statement
   ===================================================================== */
SET SERVEROUTPUT ON

DECLARE
    TYPE t_numbers IS TABLE OF NUMBER;
    v_numbers  t_numbers := t_numbers(17, -4, 0, 8, 1, 25, 2, NULL, 97, 100);

    v_n        NUMBER;
    v_divisor  PLS_INTEGER;
    v_is_prime BOOLEAN;
    v_category VARCHAR2(20);
BEGIN
    DBMS_OUTPUT.PUT_LINE('A1 - NUMBER CLASSIFIER');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 32, '-'));

    FOR i IN 1 .. v_numbers.COUNT LOOP
        v_n := v_numbers(i);

        IF v_n IS NULL THEN
            GOTO is_null;
        END IF;

        IF v_n < 0 THEN
            GOTO is_negative;
        END IF;

        IF v_n = 0 THEN
            GOTO is_zero;
        END IF;

        -- Prime test (trial division up to the square root)
        v_is_prime := (v_n > 1 AND v_n = TRUNC(v_n));
        v_divisor  := 2;
        WHILE v_is_prime AND v_divisor * v_divisor <= v_n LOOP
            IF MOD(v_n, v_divisor) = 0 THEN
                v_is_prime := FALSE;
            END IF;
            v_divisor := v_divisor + 1;
        END LOOP;

        IF v_is_prime THEN
            GOTO is_prime;
        END IF;

        IF MOD(v_n, 2) = 0 THEN
            GOTO is_even;
        END IF;

        GOTO is_odd;

        <<is_null>>
        v_category := 'NULL (no value)';
        GOTO print_result;

        <<is_negative>>
        v_category := 'NEGATIVE';
        GOTO print_result;

        <<is_zero>>
        v_category := 'ZERO';
        GOTO print_result;

        <<is_prime>>
        v_category := 'PRIME';
        GOTO print_result;

        <<is_even>>
        v_category := 'EVEN';
        GOTO print_result;

        <<is_odd>>
        v_category := 'ODD';

        <<print_result>>
        DBMS_OUTPUT.PUT_LINE(RPAD(NVL(TO_CHAR(v_n), 'NULL'), 8) || ' -> ' || v_category);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(RPAD('-', 32, '-'));
    DBMS_OUTPUT.PUT_LINE('Classified ' || v_numbers.COUNT || ' values.');
END;
/

/* Expected output
   A1 - NUMBER CLASSIFIER
   --------------------------------
   17       -> PRIME
   -4       -> NEGATIVE
   0        -> ZERO
   8        -> EVEN
   1        -> ODD
   25       -> ODD
   2        -> PRIME
   NULL     -> NULL (no value)
   97       -> PRIME
   100      -> EVEN
   --------------------------------
   Classified 10 values.
*/
