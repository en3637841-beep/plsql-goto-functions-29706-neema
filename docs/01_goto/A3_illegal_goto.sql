/* =====================================================================
   A3 - Illegal GOTO and Fix

   Oracle refuses to compile a GOTO that branches:
     - INTO an IF statement, LOOP or sub-block
     - from one IF/ELSIF/ELSE branch into another
     - from an EXCEPTION handler back into the block's executable part
     - out of a subprogram
   The compiler reports PLS-00375 (illegal GOTO statement).

   This file contains two illegal examples (Part 1 and Part 3), each
   followed by a working fix. Running the illegal blocks is expected to
   FAIL with PLS-00375; that error is what the screenshot shows.
   ===================================================================== */
SET SERVEROUTPUT ON

-- ---------------------------------------------------------------------
-- PART 1 - ILLEGAL: jumping INTO an IF block
-- Scenario: give a 10,000 RWF fuel bonus to riders earning > 100,000.
-- The GOTO tries to land on a label that lives inside the IF.
-- Expected: PLS-00375: illegal GOTO statement ... label 'APPLY_FUEL_BONUS'
-- ---------------------------------------------------------------------
DECLARE
    v_salary NUMBER := 180000;
BEGIN
    GOTO apply_fuel_bonus;            -- ILLEGAL: target is inside an IF

    IF v_salary > 100000 THEN
        <<apply_fuel_bonus>>
        DBMS_OUTPUT.PUT_LINE('Fuel bonus of 10,000 RWF applied');
    END IF;
END;
/

-- ---------------------------------------------------------------------
-- PART 2 - FIX: keep the label at the same level as the GOTO and jump
-- AROUND the bonus code instead of into it.
-- ---------------------------------------------------------------------
DECLARE
    v_salary NUMBER := 180000;
BEGIN
    IF v_salary <= 100000 THEN
        GOTO skip_fuel_bonus;         -- LEGAL: leaves the IF, lands outside it
    END IF;

    DBMS_OUTPUT.PUT_LINE('Fuel bonus of 10,000 RWF applied');

    <<skip_fuel_bonus>>
    DBMS_OUTPUT.PUT_LINE('Fixed version: bonus check complete for salary ' || v_salary);
END;
/

-- ---------------------------------------------------------------------
-- PART 3 - ILLEGAL: jumping from an EXCEPTION handler back into the block
-- Scenario: "retry" a cost-per-trip calculation after a divide by zero.
-- Expected: PLS-00375: illegal GOTO statement ... label 'RETRY_CALC'
-- ---------------------------------------------------------------------
DECLARE
    v_trips   NUMBER := 0;
    v_fuel    NUMBER := 45000;
    v_per_trip NUMBER;
BEGIN
    <<retry_calc>>
    v_per_trip := v_fuel / v_trips;
    DBMS_OUTPUT.PUT_LINE('Fuel cost per trip: ' || v_per_trip);
EXCEPTION
    WHEN ZERO_DIVIDE THEN
        v_trips := 1;
        GOTO retry_calc;              -- ILLEGAL: handler cannot re-enter the block
END;
/

-- ---------------------------------------------------------------------
-- PART 4 - FIX: put the risky statement in a nested block inside a loop.
-- The nested block handles the error, and the loop provides the retry.
-- ---------------------------------------------------------------------
DECLARE
    v_trips    NUMBER := 0;
    v_fuel     NUMBER := 45000;
    v_per_trip NUMBER;
    v_attempt  PLS_INTEGER := 0;
BEGIN
    LOOP
        v_attempt := v_attempt + 1;
        BEGIN
            v_per_trip := v_fuel / v_trips;
            DBMS_OUTPUT.PUT_LINE('Fixed version: fuel cost per trip = ' || v_per_trip
                || ' RWF (attempt ' || v_attempt || ')');
            EXIT;
        EXCEPTION
            WHEN ZERO_DIVIDE THEN
                DBMS_OUTPUT.PUT_LINE('Attempt ' || v_attempt || ': zero trips, defaulting to 1');
                v_trips := 1;
        END;
        EXIT WHEN v_attempt >= 3;     -- safety stop
    END LOOP;
END;
/

/* Expected results
   Part 1 -> PLS-00375: illegal GOTO statement (compile error, block not run)
   Part 2 -> Fuel bonus of 10,000 RWF applied
             Fixed version: bonus check complete for salary 180000
   Part 3 -> PLS-00375: illegal GOTO statement (compile error, block not run)
   Part 4 -> Attempt 1: zero trips, defaulting to 1
             Fixed version: fuel cost per trip = 45000 RWF (attempt 2)
*/
