library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity XY is
	port(
		start		: in std_logic;
		reset		: in std_logic;
		address 	: in std_logic_vector(16 downto 0);
		clk_50	: in std_logic;
		done		: out std_logic;
		X, Y 		: out std_logic_vector(16 downto 0)
	);
end entity;

architecture XY_ARCH of XY is
	signal i	: integer range 0 to 240 := 0;
begin
	p1 : process(address, start, reset, clk_50)
		variable X1 			: unsigned(16 downto 0);
		variable Y1 			: unsigned(16 downto 0);
		variable row_width 	: unsigned(8 downto 0) := to_unsigned(320, 9);
		variable done2			: std_logic := '0';
		variable done1			: std_logic := '0';
		variable start1		: std_logic := start;
		
		variable addr_tmp		: unsigned(16 downto 0) := unsigned(address);
		variable n				: unsigned(16 downto 0) := to_unsigned(320, 17);
		variable minusone		: signed(1 downto 0) := "11";
	begin
		if (reset = '1') then
			done1 := '0';
			X1 := to_unsigned(0, X1'left+1);
			Y1 := to_unsigned(0, Y1'left+1);
			n := to_unsigned(320, 17);
		elsif(rising_edge(clk_50) and start = '1') then
			if (n > to_unsigned(76801, 17)) then -- error, OUT OF BOUNDS (320 * 240 pixels)
				Y1 := unsigned(to_signed((-1), 17)); -- max value
			elsif (n <= unsigned(address)) then
				n := n + row_width;
				Y1 := Y1 + to_unsigned(1, 17);
			elsif (unsigned(address) > X1 + (Y1 * row_width)) then
				if (unsigned(address) > X1 + to_unsigned(100, 17) + (Y1 * row_width)) then
					X1 := X1 + to_unsigned(100, 17);
				elsif (unsigned(address) > X1 + to_unsigned(30, 17) + (Y1 * row_width)) then
					X1 := X1 + to_unsigned(30, 17);
				elsif (unsigned(address) > X1 + to_unsigned(10, 17) + (Y1 * row_width)) then
					X1 := X1 + to_unsigned(10, 17);
				else
					X1 := X1 + to_unsigned(5, 17);
				end if;
			else
				done1 := '1';
				Y(Y1'left downto 0) <= std_logic_vector(Y1);
				X(X1'left downto 0) <= std_logic_vector(X1);
			end if;
		end if;
--		Y(Y1'left downto 0) <= std_logic_vector(Y1);
--		X(X1'left downto 0) <= std_logic_vector(X1);
		done <= done1;
	end process;
end architecture;	