/* =====================================================================
   B3 - fn_calculate_tax
   Calculates monthly PAYE tax (RWF) on a gross monthly amount using
   progressive brackets modelled on Rwanda's PAYE schedule:

       0       - 60,000   :  0%
       60,001  - 100,000  : 10%
       100,001 - 200,000  : 20%
       above 200,000      : 30%

   Each rate applies only to the part of the income inside its bracket.
   Example: 150,000 -> (40,000 x 10%) + (50,000 x 20%) = 14,000

   Parameters : p_gross  gross monthly pay
   Returns    : tax amount rounded to 2 decimals, NULL for NULL input
   Exceptions : ORA-20010 raised for a negative gross amount.
   ===================================================================== */
CREATE OR REPLACE FUNCTION fn_calculate_tax (
    p_gross IN NUMBER
) RETURN NUMBER
DETERMINISTIC
IS
    c_band1_limit CONSTANT NUMBER := 60000;
    c_band2_limit CONSTANT NUMBER := 100000;
    c_band3_limit CONSTANT NUMBER := 200000;
    v_tax         NUMBER := 0;
BEGIN
    IF p_gross IS NULL THEN
        RETURN NULL;
    END IF;

    IF p_gross < 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'Gross pay cannot be negative: ' || p_gross);
    END IF;

    IF p_gross <= c_band1_limit THEN
        v_tax := 0;
    ELSIF p_gross <= c_band2_limit THEN
        v_tax := (p_gross - c_band1_limit) * 0.10;
    ELSIF p_gross <= c_band3_limit THEN
        v_tax := (c_band2_limit - c_band1_limit) * 0.10
               + (p_gross - c_band2_limit) * 0.20;
    ELSE
        v_tax := (c_band2_limit - c_band1_limit) * 0.10
               + (c_band3_limit - c_band2_limit) * 0.20
               + (p_gross - c_band3_limit) * 0.30;
    END IF;

    RETURN ROUND(v_tax, 2);
END fn_calculate_tax;
/

SHOW ERRORS FUNCTION fn_calculate_tax
