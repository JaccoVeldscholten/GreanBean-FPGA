library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity edge_recognition_register is
port(
		
		-- normal port
		activated 	: in std_logic;
		reset			: in std_logic;
		clk_i 		: in std_logic;
		dapixel 		: in std_logic_vector (11 downto 0); -- data of each pixel
		pixel_address 	: in std_logic_vector (16 downto 0);		-- address of each pixel
		edge_adresA	: out std_logic_vector(16 downto 0) := std_logic_vector(to_unsigned(0, 17));
		edge_adresB	: out std_logic_vector(16 downto 0) := std_logic_vector(to_unsigned(0, 17));
		edge_adresC	: out std_logic_vector(16 downto 0) := std_logic_vector(to_unsigned(0, 17));
		edge_adresD	: out std_logic_vector(16 downto 0) := std_logic_vector(to_unsigned(0, 17));
		edge_adresE	: out std_logic_vector(16 downto 0) := std_logic_vector(to_unsigned(0, 17));
		edge_adresF	: out std_logic_vector(16 downto 0) := std_logic_vector(to_unsigned(0, 17));
		edge_adresG	: out std_logic_vector(16 downto 0) := std_logic_vector(to_unsigned(0, 17));
		edge_adresH	: out std_logic_vector(16 downto 0) := std_logic_vector(to_unsigned(0, 17));
		X1, X2, X3, X4, X5, X6, X7, Y1, Y2, Y3, Y4, Y5, Y6, Y7 : out std_logic_vector(16 downto 0);
		-- A/1 = hor bottom left, B/2 = hor bottom right, C/3 vertical address, D/4 top left, E/5 top right, F/6 = middle left, G/7 = middle right
		found_edges : out unsigned(3 downto 0)
	);
end edge_recognition_register;

architecture edge_recognition_register_arch of edge_recognition_register is
	
	component XY is
	port(
		start		: in std_logic;
		reset		: in std_logic;
		address 	: in std_logic_vector(16 downto 0);
		clk_50	: in std_logic;
		done		: out std_logic;
		X, Y 		: out std_logic_vector(16 downto 0)
	);
	end component;
	
	component edge_Recognition is
	  Port (
	  -- testpins:
		testpins : out std_logic_vector (16 downto 0);
	  -- regular component
		 activated	: in std_logic;
		 reset		: in std_logic;
		 clk_i 		: in std_logic;
		 dapixel 		: in std_logic_vector (11 downto 0);
		 pixel_address 	: in std_logic_vector (16 downto 0);		-- address of each pixel
		 address_min	: in std_logic_vector (16 downto 0);
		 address_max	: in std_logic_vector (16 downto 0);
		 edge_A_addr : out std_logic_vector (16 downto 0);
		 edge_B_addr : out std_logic_vector (16 downto 0);
		 found_edge : out std_logic);
	 end component;
	
	type adressArrType is array(7 downto 0) of std_logic_vector(16 downto 0);
	signal adressFoundArr 	: adressArrType;
	signal X						: adressArrType;
	signal Y						: adressArrType;
	signal edges_calculated	: std_LOGIC_vector(7 downto 0);
	signal edge_found_temp 	: std_logic_vector(7 downto 0);
	signal start_value 		: unsigned(16 downto 0) := to_unsigned(70_400 , 17);
	signal row_width			: unsigned(16 downto 0) := to_unsigned(320, 17);
	signal start_value_temp	: integer range 0 to 76800 := 0;
	signal start_value_temp1	: integer range 0 to 76800 := 0;
	signal ready				: std_logic := '0';
	
	signal start_value_v 		: unsigned(16 downto 0) := to_unsigned(0, 17); 	-- briyan
	signal max_value_v 		: unsigned(16 downto 0) := to_unsigned(20000, 17); -- briyan
begin
	edge_adresA <= adressFoundArr(0);
	edge_adresB <= adressFoundArr(1);
	edge_adresC <= adressFoundArr(2);
	edge_adresD <= adressFoundArr(3);
	edge_adresE <= adressFoundArr(4);
	edge_adresF <= adressFoundArr(5);
	edge_adresG <= adressFoundArr(6);
	edge_adresH <= adressFoundArr(7);
	
	X1 <= X(0);
	X2 <= X(1);
	X3 <= X(2);
	X4 <= X(3);
	X5 <= X(4);
	X6 <= X(5);
	Y1 <= Y(0);
	Y2 <= Y(1);
	Y3 <= Y(2);
	Y4 <= Y(3);
	
	Inst_Edge_Recognition_A_B : edge_Recognition port map (
		activated => activated,
		reset => reset,
		clk_i => clk_i,
		dapixel => dapixel,
		pixel_address => pixel_address,		-- address of each pixel
		address_min	=> std_LOGIC_vector(start_value),
		address_max	=> std_LOGIC_vector(start_value + row_width),
		edge_A_addr => adressFoundArr(0),
		edge_B_addr => adressFoundArr(1),
		found_edge => edge_found_temp(0)
  );
  
  inst_XY_1 : XY port map (edge_found_temp(0), reset or edges_calculated(6), adressFoundArr(0), clk_i, edges_calculated(0), X(0), Y(0)); -- XY co of botttom left coordinate
  
  inst_XY_2 : XY port map (edge_found_temp(0), reset or edges_calculated(6), adressFoundArr(1), clk_i, edges_calculated(1), X(1), Y(1)); -- XY co of botttom right coordinate
  
  Inst_Edge_Recognition_vert_C : edge_Recognition port map (
		activated => edges_calculated(0),
		reset => reset,
		clk_i => clk_i,
		dapixel => dapixel,
		pixel_address => pixel_address,		-- address of each pixel
		address_min	=> std_LOGIC_vector(start_value_v),
		address_max	=> std_LOGIC_vector(max_value_v),
		edge_A_addr => adressFoundArr(2),
		found_edge => edge_found_temp(2)
  );
  
	-- edge D is non existent
  
  inst_XY_3 : XY port map (edge_found_temp(2), reset or edges_calculated(6), adressFoundArr(2), clk_i, edges_calculated(2), X(2), Y(2)); -- XY co of top of the glass 
    
  p1 : process(edges_calculated(4), clk_i)
	variable glass_height : integer range 0 to 220;
	variable i : integer range 0 to 220 := 0;
  begin
	if (edges_calculated(4) = '1') then
		start_value_temp <= to_integer(unsigned(Y(2)) * row_width);
		if (rising_edge(clk_i)) then -- delen niet mogelijk in vhdl dan maar zo
			if (i + start_value_temp >= 110 and ready = '0') then
				glass_height := i;
				start_value_temp1 <= (i * to_integer(row_width));
				ready <= '1';
			end if;
			i := i + 1;
		end if;
	end if;
  end process;
  
  Inst_Edge_Recognition_D_E : edge_Recognition port map (
		activated => edges_calculated(0),
		reset => reset,
		clk_i => clk_i,
		dapixel => dapixel,
		pixel_address => pixel_address,		-- address of each pixel
		address_min	=> std_LOGIC_vector(to_unsigned(start_value_temp, 17)),
		address_max	=> std_LOGIC_vector((to_unsigned(start_value_temp, 17) + row_width)),
		edge_A_addr => adressFoundArr(3),
		edge_B_addr => adressFoundArr(4),
		found_edge => edge_found_temp(3)
  );
  
  Inst_Edge_Recognition_G_H : edge_Recognition port map (
		activated => edges_calculated(0),
		reset => reset,
		clk_i => clk_i,
		dapixel => dapixel,
		pixel_address => pixel_address,		-- address of each pixel
		address_min	=> std_LOGIC_vector(to_unsigned(start_value_temp1, 17)),
		address_max	=> std_LOGIC_vector((to_unsigned(start_value_temp1, 17) + row_width)),
		edge_A_addr => adressFoundArr(5),
		edge_B_addr => adressFoundArr(6),
		found_edge => edge_found_temp(4)
  );
	
  inst_XY_4 : XY port map (edge_found_temp(3), reset or edges_calculated(6), adressFoundArr(3), clk_i, edges_calculated(3), X(3), Y(3)); -- XY co of top left of the glass 
  inst_XY_5 : XY port map (edge_found_temp(4), reset or edges_calculated(6), adressFoundArr(4), clk_i, edges_calculated(4), X(4), Y(4)); -- XY co of top of top right the glass 
  
  inst_XY_6 : XY port map (edge_found_temp(5), reset or edges_calculated(6), adressFoundArr(5), clk_i, edges_calculated(5), X(5), Y(5)); -- XY co of middle left of the glass 
  inst_XY_7 : XY port map (edge_found_temp(6), reset or edges_calculated(6), adressFoundArr(6), clk_i, edges_calculated(6), X(6), Y(6)); -- XY co of middle right the glass 
  
  
	
end architecture;