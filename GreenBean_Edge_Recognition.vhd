library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity edge_Recognition is
  Port (
  -- testpins:
	testpins : out std_logic_vector (16 downto 0);
  -- regular component
    activated			: in std_logic;
	 reset				: in std_logic;
    clk_i 				: in std_logic;
	 dapixel 			: in std_logic_vector (11 downto 0);
	 pixel_address 	: in std_logic_vector (16 downto 0);		-- address of each pixel
    address_min		: in std_logic_vector (16 downto 0);
	 address_max		: in std_logic_vector (16 downto 0);
	 edge_A_addr 		: out std_logic_vector (16 downto 0);
	 edge_B_addr 		: out std_logic_vector (16 downto 0);
	 found_edge 		: out std_logic);
 end edge_Recognition;
 
 
 architecture edge_Recognition_arch of edge_Recognition is
  
 begin
	p1 : process(clk_i, activated, reset)
		variable temp_red			: unsigned(3 downto 0) := unsigned(dapixel(11 downto 8));
		variable temp_green		: unsigned(3 downto 0) := unsigned(dapixel(7 downto 4));
		variable temp_blue		: unsigned(3 downto 0) := unsigned(dapixel(3 downto 0)); 
		variable prev_red			: unsigned(3 downto 0) := unsigned(dapixel(11 downto 8));
		variable prev_green		: unsigned(3 downto 0) := unsigned(dapixel(7 downto 4));
		variable prev_blue		: unsigned(3 downto 0) := unsigned(dapixel(3 downto 0)); 
		variable null1				: unsigned(16 downto 0)	:= to_unsigned(1, 17);-- 0 value to reset edge_*_addr
		variable max_collor_val	: unsigned(3 downto 0) := to_unsigned(8, 4);
		variable edge_found		: std_logic := '0';
		variable edge_found1		: std_logic := '0';
		variable temp_edge		: std_logic := '0'; -- om te laten weten dat er iets is gevonden voor edge 2
	begin
		if (reset = '1' or activated = '0') then
			edge_found := '0';
			edge_found1 := '0';
			edge_A_addr <= std_logic_vector(null1);
			edge_B_addr <= std_logic_vector(null1);
		elsif (rising_edge(clk_i)) then
			if (unsigned(pixel_address) < unsigned(address_max) and unsigned(pixel_address) > unsigned(address_min))then
				if (temp_green > max_collor_val and edge_found = '0') then
					edge_found := '1';
					edge_A_addr <= pixel_address;
					edge_found1 := '0';
					testpins(11 downto 0) <= dapixel;
				elsif (temp_green > max_collor_val and edge_found = '1' and edge_found1 = '0') then
					edge_B_addr <= pixel_address;
					temp_edge := '1';
				end if;
			elsif (unsigned(pixel_address) > unsigned(address_max) and temp_edge = '1') then
				edge_found1 := '1';
				edge_found := '0';
			end if;
		end if;
		found_edge <= edge_found or edge_found1;
	end process;
 end architecture;