-- PWM Module voor Heater
-- Geschreven door Jacco Veldscholten
-- Project: GreenBean Koffieautomaat

library ieee; 
USE ieee.std_logic_1164.ALL; 
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;

ENTITY heaterPWM IS
	PORT (
		clk 			: IN STD_LOGIC;
		dutyIn		: IN STD_LOGIC_VECTOR(19 downto 0);
		pwmOUTDebug	: OUT std_LOGIC;
		pwmOUT 		: OUT STD_LOGIC);
END heaterPWM;

ARCHITECTURE Behavioral OF heaterPWM IS
	SIGNAL counter : INTEGER RANGE 0 TO 100000;
	SIGNAL compare : INTEGER RANGE 0 TO 100000;
BEGIN
	
	compare <= to_integer(unsigned(dutyIn));		-- 10% Duty (10000) |  25% Duty (25000) |  50% Duty (50000) | 80% (80000)
	--compare <= 25000;

	
	PROCESS (clk)
	BEGIN
		IF (rising_edge(clk)) THEN
			counter <= counter + 1;
			IF (counter = 100000 - 1) THEN
				counter <= 0;
				pwmOUT <= '1';
				pwmOUTDebug <= '1';
			ELSIF (counter = compare) THEN
				pwmOUT <= '0';
				pwmOUTDebug <= '0';
			END IF;
		END IF;
	END PROCESS;
END Behavioral;