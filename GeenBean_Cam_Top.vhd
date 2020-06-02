library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.ALL;

entity GreenBean_Camera is
  Port ( 
    -- testpins
	 SW : in std_LOGIC_vector(17 downto 0);
	 KEY : in std_LOGIC_vector(3 downto 1);
	 LEDR : out unsigned(17 downto 0);
	 -- greenbean
		edge_adresA	: out std_logic_vector(16 downto 0) := std_logic_vector(to_unsigned(0, 17));
		edge_adresB	: out std_logic_vector(16 downto 0) := std_logic_vector(to_unsigned(0, 17));
		edge_adresC	: out std_logic_vector(16 downto 0) := std_logic_vector(to_unsigned(0, 17));
		edge_adresD	: out std_logic_vector(16 downto 0) := std_logic_vector(to_unsigned(0, 17));
		edge_adresE	: out std_logic_vector(16 downto 0) := std_logic_vector(to_unsigned(0, 17));
		edge_adresF	: out std_logic_vector(16 downto 0) := std_logic_vector(to_unsigned(0, 17));
		edge_adresG	: out std_logic_vector(16 downto 0) := std_logic_vector(to_unsigned(0, 17));
		X1, X2, X3, X4, X5, X6, X7, Y1, Y2, Y3, Y4, Y5, Y6, Y7 : out std_logic_vector(16 downto 0);
		-- A/1 = hor bottom left, B/2 = hor bottom right, C/3 vertical address, D/4 top left, E/5 top right, F/6 = middle left, G/7 = middle right
		CLK25	: in STD_LOGIC;
	 --implementation 1
	 clk_50 : in  STD_LOGIC;
    led_config_finished : out STD_LOGIC;

    ov7670_pclk  : in  STD_LOGIC;
    ov7670_xclk  : out STD_LOGIC;
    ov7670_vsync : in  STD_LOGIC;
    ov7670_href  : in  STD_LOGIC;
    ov7670_data  : in  STD_LOGIC_vector(7 downto 0);
    ov7670_sioc  : out STD_LOGIC;
    ov7670_siod  : inout STD_LOGIC;
    ov7670_pwdn  : out STD_LOGIC;
    ov7670_reset : out STD_LOGIC
  );
end GreenBean_Camera;


architecture my_structural of GreenBean_Camera is
	
	COMPONENT VGA
  PORT(
    CLK25 : IN std_logic; 
    Hsync : OUT std_logic;
    Vsync : OUT std_logic;
    Nblank : OUT std_logic;      
    clkout : OUT std_logic;
    activeArea : OUT std_logic;
    Nsync : OUT std_logic
    );
  END COMPONENT;

  COMPONENT ov7670_controller
  PORT(
    clk : IN std_logic;
    resend : IN std_logic;    
    siod : INOUT std_logic;      
    config_finished : OUT std_logic;
    sioc : OUT std_logic;
    reset : OUT std_logic;
    pwdn : OUT std_logic;
    xclk : OUT std_logic
    );
  END COMPONENT;

  COMPONENT frame_buffer
  PORT(
    data : IN std_logic_vector(11 downto 0);
    rdaddress : IN std_logic_vector(16 downto 0);
    rdclock : IN std_logic;
    wraddress : IN std_logic_vector(16 downto 0);
    wrclock : IN std_logic;
    wren : IN std_logic;          
    q : OUT std_logic_vector(11 downto 0)
    );
  END COMPONENT;

  COMPONENT ov7670_capture
  PORT(
    pclk : IN std_logic;
    vsync : IN std_logic;
    href : IN std_logic;
    d : IN std_logic_vector(7 downto 0);          
    addr : OUT std_logic_vector(16 downto 0);
    dout : OUT std_logic_vector(11 downto 0);
    we : OUT std_logic
    );
  END COMPONENT;

  COMPONENT Address_Generator
  PORT(
    CLK25       : IN  std_logic;
    enable      : IN  std_logic;       
    vsync       : in  STD_LOGIC;
    address     : OUT std_logic_vector(16 downto 0)
    );
  END COMPONENT;
  
  component edge_recognition_register
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
  end component;
  


	signal clk_50_camera : std_logic;
	signal clk_25_vga    : std_logic;
	signal wren       : std_logic;
	signal resend     : std_logic;
	signal nBlank     : std_logic;
	signal vSync      : std_logic;

	signal wraddress  : std_logic_vector(16 downto 0);
	signal wrdata     : std_logic_vector(11 downto 0);   
	signal rdaddress  : std_logic_vector(16 downto 0);
	signal rddata     : std_logic_vector(11 downto 0);
	signal red,green,blue : std_logic_vector(7 downto 0);
	signal activeArea : std_logic;
   
	signal Edge1_addr :std_logic_vector (16 downto 0);
	signal Edge2_addr :std_logic_vector (16 downto 0);
	signal Found_edge :std_logic := '0';

	signal adrrMin : unsigned(16 downto 0) := to_unsigned(40360, 17);
	signal adrrMax : unsigned(16 downto 0) := to_unsigned(40800, 17);
	signal testpins_edge_rec : std_logic_vector (16 downto 0);
	signal pixlout : std_logic_vector(11 downto 0);
	signal pixladdressOut : std_logic_vector (16 downto 0);
	signal Edge1_vert_addr : std_LOGIC_vector(16 downto 0);
	signal edgeadr : std_logic_vector(16 downto 0);
	
	type adressArrType is array(7 downto 0) of std_logic_vector(16 downto 0);
	signal adressFoundArr 	: adressArrType;
	signal X						: adressArrType;
	signal Y						: adressArrType;
	
	signal notkey3				: std_LOGIC;
begin
	
	edge_adresA <= adressFoundArr(0);
	edge_adresB <= adressFoundArr(1);
	edge_adresC <= adressFoundArr(2);
	edge_adresD <= adressFoundArr(3);
	edge_adresE <= adressFoundArr(4);
	edge_adresF <= adressFoundArr(5);
	edge_adresG <= adressFoundArr(6);
	
	X1 <= X(0);
	X2 <= X(1);
	X3 <= X(2);
	X4 <= X(3);
	X5 <= X(4);
	X6 <= X(5);
	X7 <= X(6);
	Y1 <= Y(0);
	Y2 <= Y(1);
	Y3 <= Y(2);
	Y4 <= Y(3);
	Y5 <= Y(4);
	Y6 <= Y(5);
	Y7 <= Y(6);

	resend <= not KEY(2); -- color changing to greyscale
	CLK_25_vga <= CLK25;
	notkey3 <= not key(3);
	Inst_Edge_Recognition_Register : edge_recognition_register port map (
		activated => SW(17),
		reset => notkey3,
		clk_i => clk_50,
		dapixel => rddata,
		pixel_address => rdaddress,
		edge_adresA => adressFoundArr(0),
		edge_adresB => adressFoundArr(1),
		edge_adresC => adressFoundArr(2),
		edge_adresD => adressFoundArr(3),
		edge_adresE => adressFoundArr(4),
		edge_adresF => adressFoundArr(5),
		edge_adresG => adressFoundArr(6),
		X1 => X(0),
		X2 => X(1),
		X3 => X(2),
		X4 => X(3),
		X5 => X(4),
		X6 => X(5),
		X7 => X(6),
		Y1 => Y(0),
		Y2 => Y(1),
		Y3 => Y(2),
		Y4 => Y(3),
		Y5 => Y(4),
		Y6 => Y(5),
		Y7 => Y(6)
	);
	

  Inst_ov7670_controller: ov7670_controller PORT MAP(
    clk             => clk_50,
    resend          => resend,
    config_finished => led_config_finished,
    sioc            => ov7670_sioc,
    siod            => ov7670_siod,
    reset           => ov7670_reset,
    pwdn            => ov7670_pwdn,
    xclk            => ov7670_xclk
  );
   
  Inst_ov7670_capture: ov7670_capture PORT MAP(
    pclk  => ov7670_pclk,
    vsync => ov7670_vsync,
    href  => ov7670_href,
    d     => ov7670_data,
    addr  => wraddress,
    dout  => wrdata,
    we    => wren
  );

  Inst_frame_buffer: frame_buffer PORT MAP(
    rdaddress => rdaddress,
    rdclock   => clk_25_vga,
    q         => rddata,      
    wrclock   => ov7670_pclk,
    wraddress => wraddress(16 downto 0),
    data      => wrdata,
    wren      => wren
  );

  Inst_Address_Generator: Address_Generator PORT MAP(
    CLK25 => clk_25_vga,
    enable => activeArea,
    vsync => vsync,
    address => rdaddress
  );
  
  Inst_VGA: VGA PORT MAP(
    CLK25      => clk_25_vga,
    Vsync      => vsync,
    Nblank     => nBlank,
    activeArea => activeArea
  );

end my_structural;