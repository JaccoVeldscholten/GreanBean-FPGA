library ieee; 
USE ieee.std_logic_1164.ALL; 
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;

entity GreenBean IS   
  port ( 

		-- Defaults
		CLK_50M 		: IN STD_LOGIC; 
		
		-- DRAM 
		DRAM_CLK		: OUT STD_LOGIC;
		DRAM_ADDR	: OUT STD_LOGIC_VECTOR(12 DOWNTO 0);
		DRAM_BA		: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
		DRAM_CAS_N	: OUT STD_LOGIC;
		DRAM_CKE		: OUT STD_LOGIC;
		DRAM_CS_N	: OUT STD_LOGIC;
		DRAM_DQ		: INOUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		DRAM_DQM		: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		DRAM_RAS_N	: OUT STD_LOGIC;
		DRAM_WE_N	: OUT STD_LOGIC;

		-- SD Card
		SD_CLK		: OUT STD_LOGIC;
		SD_CMD		: INOUT STD_LOGIC;
		SD_DAT		: INOUT STD_LOGIC;
		SD_DAT3		: INOUT STD_LOGIC;

		-- Pixel Buffer (SRAM)
		SRAM_ADDR	: OUT STD_LOGIC_VECTOR(19 DOWNTO 0);
		SRAM_CE_N	: OUT STD_LOGIC;
		SRAM_DQ		: INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		SRAM_LB_N	: OUT STD_LOGIC;
		SRAM_OE_N	: OUT STD_LOGIC;
		SRAM_UB_N	: OUT STD_LOGIC;
		SRAM_WE_N	: OUT STD_LOGIC;

		-- VGA
		VGA_CLK		: OUT STD_LOGIC;
		VGA_HS		: OUT STD_LOGIC;
		VGA_VS		: OUT STD_LOGIC;
		VGA_BLANK_N	: OUT STD_LOGIC;
		VGA_SYNC_N	: OUT STD_LOGIC;
		VGA_R			: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		VGA_G			: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		VGA_B			: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		
		-- Camera
		ov7670_pclk  			: IN  	STD_LOGIC;
		ov7670_xclk  			: OUT 	STD_LOGIC;
		ov7670_vsync 			: IN  	STD_LOGIC;
		ov7670_href  			: IN  	STD_LOGIC;
		ov7670_data  			: IN  	STD_LOGIC_VECTOR(7 downto 0);
		ov7670_sioc  			: OUT 	STD_LOGIC;
		ov7670_siod  			: INOUT 	STD_LOGIC;
		ov7670_pwdn  			: OUT 	STD_LOGIC;
		ov7670_reset 			: OUT 	STD_LOGIC;
		SW							: IN 		STD_LOGIC_VECTOR(17 downto 0);
		KEY						: IN 		STD_LOGIC_VECTOR(3 downto 1);
		
		-- Heater PWMOUT
		pwmPin		: OUT STD_LOGIC;
		scoopPin		: OUT STD_LOGIC;
		
		-- Barcode UART
		barcode_in_RX  		: IN STD_LOGIC;
		LEDR						: OUT STD_LOGIC_VECTOR(17 downto 0);

		
		-- Temp sensor
		temp_in_RX  		: IN STD_LOGIC;
		LEDG				   : OUT STD_LOGIC_VECTOR(2 downto 0)
		
	); 
END GreenBean; 

architecture GreenBean_Arch OF GreenBean IS 

	signal dutyTemp 			: std_logic_vector(19 downto 0);
	
	signal dataOutBarcode	: std_logic_vector(7 downto 0);
	signal interruptBarcode : std_logic;
		
	signal dataOutTemp 		: std_logic_vector(7 downto 0);
	signal interruptTemp 	: std_logic;

	signal coffeeControlSig : std_logic_vector(2 downto 0);
	
	-- Camera Signals
	signal camera_X1Sig, camera_X2Sig, camera_X3Sig, camera_X4Sig, camera_X5Sig, 
	camera_X6Sig,  camera_X7Sig, camera_Y1Sig, camera_Y2Sig, camera_Y3Sig, 
	camera_Y4Sig, camera_Y5Sig, camera_Y6Sig, camera_Y7Sig : std_logic_vector(16 downto 0);
	
	--Sjoerd
	signal SWsignal			: std_LOGIC_vector(17 downto 0); 
			
			
	component GreenBeanCPU is
		port (
		
			-- Defaults
			clk_clk 						: IN STD_LOGIC; 
			reset_reset_n      		: IN STD_LOGIC; 
			
			-- SDRAM (DRAM)
			sdram_clk_clk				: OUT STD_LOGIC;
			sdram_wire_addr			: OUT STD_LOGIC_VECTOR(12 DOWNTO 0);
			sdram_wire_ba				: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
			sdram_wire_cas_n			: OUT STD_LOGIC;
			sdram_wire_cke				: OUT STD_LOGIC;
			sdram_wire_cs_n			: OUT STD_LOGIC;
			sdram_wire_dq				: INOUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			sdram_wire_dqm				: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
			sdram_wire_ras_n			: OUT STD_LOGIC;
			sdram_wire_we_n			: OUT STD_LOGIC;

			-- SD Card
			sd_card_wire_o_SD_clock		: OUT STD_LOGIC;
			sd_card_wire_b_SD_cmd		: INOUT STD_LOGIC;
			sd_card_wire_b_SD_dat		: INOUT STD_LOGIC;
			sd_card_wire_b_SD_dat3		: INOUT STD_LOGIC;
			
			-- Pixel Buffer (SRAM)
			pixel_buffer_wire_ADDR		: OUT STD_LOGIC_VECTOR(19 DOWNTO 0);
			pixel_buffer_wire_CE_N		: OUT STD_LOGIC;
			pixel_buffer_wire_DQ			: INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			pixel_buffer_wire_LB_N		: OUT STD_LOGIC;
			pixel_buffer_wire_OE_N		: OUT STD_LOGIC;
			pixel_buffer_wire_UB_N		: OUT STD_LOGIC;
			pixel_buffer_wire_WE_N		: OUT STD_LOGIC;

			-- VGA Controller (VGA)
			vga_controller_wire_CLK		: OUT STD_LOGIC;
			vga_controller_wire_HS		: OUT STD_LOGIC;
			vga_controller_wire_VS		: OUT STD_LOGIC;
			vga_controller_wire_BLANK	: OUT STD_LOGIC;
			vga_controller_wire_SYNC	: OUT STD_LOGIC;
			vga_controller_wire_R		: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			vga_controller_wire_G		: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			vga_controller_wire_B		: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			
			-- PWM Heater
			pwmduty_export					: out std_logic_vector(19 downto 0);
			
			-- Barcode UART
			barcode_in_export				: IN STD_LOGIC_VECTOR(7 DOWNTO 0);		-- Readable
			barcode_int_export 			: IN STD_LOGIC;								-- Interrupt

	
			-- Temp In UART
			temp_in_export					: IN STD_LOGIC_VECTOR(7 DOWNTO 0);		-- Readable
			temp_int_export 				: IN STD_LOGIC;									-- Interrupt
			
			-- Coffee Controller
			coffee_control_export 		: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);	   -- Interrupt
			
			-- Camera -- X Coords
			camera_x1_export           : IN    std_logic_vector(16 downto 0);
			camera_x2_export           : IN    std_logic_vector(16 downto 0);
			camera_x3_export           : IN    std_logic_vector(16 downto 0);
			camera_x4_export           : IN    std_logic_vector(16 downto 0);
			camera_x5_export           : IN    std_logic_vector(16 downto 0);
			camera_x6_export           : IN    std_logic_vector(16 downto 0);
			camera_x7_export           : IN    std_logic_vector(16 downto 0);
			-- Camera -- Y Coords
			camera_y1_export           : IN    std_logic_vector(16 downto 0);
			camera_y2_export           : IN    std_logic_vector(16 downto 0);
			camera_y3_export           : IN    std_logic_vector(16 downto 0);
			camera_y4_export           : IN    std_logic_vector(16 downto 0);
			camera_y5_export           : IN    std_logic_vector(16 downto 0);
			camera_y6_export           : IN    std_logic_vector(16 downto 0);
			camera_y7_export           : IN    std_logic_vector(16 downto 0);
			SWsignal_export				: OUT	  std_LOGIC_VECTOR(17 downto 0)
		
		);
	end component GreenBeanCPU;
	

	
	component GreenBean_Camera IS 
	Port ( 
    -- testpins
	 SW : in std_LOGIC_vector(17 downto 0);
	 KEY : in std_LOGIC_vector(3 downto 1);
	 LEDR : out STD_LOGIC_vector(17 downto 0);
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
	 end component GreenBean_Camera;

	component heaterPWM is
		PORT (
			clk 			: IN STD_LOGIC;
			dutyIn		: IN STD_LOGIC_VECTOR(19 downto 0);
			pwmOUTDebug	: OUT std_LOGIC;
			pwmOUT 		: OUT STD_LOGIC
		);
	end component heaterPWM;
	
	component UART_RX IS
	PORT (
		 clk       : in  std_logic;
		 in_RX 	  : in  std_logic;
		 int_RX	  : out  std_logic;
		 out_RX    : out std_logic_vector(7 downto 0)
	);
	END component UART_RX;
	
	begin
		CPU : GreenBeanCPU PORT MAP(
		
			-- Defaults
			clk_clk 						=> CLK_50M, 
			reset_reset_n 				=> KEY(1),
			
			-- SDRam
			sdram_clk_clk 				=> DRAM_CLK,
			sdram_wire_addr 			=> DRAM_ADDR(12 DOWNTO 0),
			sdram_wire_ba				=>	DRAM_BA(1 DOWNTO 0),
			sdram_wire_cas_n			=>	DRAM_CAS_N,
			sdram_wire_cke				=>	DRAM_CKE,
			sdram_wire_cs_n			=>	DRAM_CS_N,
			sdram_wire_dq				=>	DRAM_DQ(31 DOWNTO 0),
			sdram_wire_dqm				=>	DRAM_DQM(3 DOWNTO 0),
			sdram_wire_ras_n			=>	DRAM_RAS_N,
			sdram_wire_we_n			=>	DRAM_WE_N,

			-- SD Card
			sd_card_wire_o_SD_clock		=> SD_CLK,
			sd_card_wire_b_SD_cmd		=>	SD_CMD,
			sd_card_wire_b_SD_dat		=>	SD_DAT,
			sd_card_wire_b_SD_dat3		=>	SD_DAT3,

			-- Pixel Buffer (SRAM)
			pixel_buffer_wire_ADDR		=> SRAM_ADDR(19 DOWNTO 0),
			pixel_buffer_wire_CE_N		=>	SRAM_CE_N,
			pixel_buffer_wire_DQ			=> SRAM_DQ(15 DOWNTO 0),
			pixel_buffer_wire_LB_N		=>	SRAM_LB_N,
			pixel_buffer_wire_OE_N		=>	SRAM_OE_N,
			pixel_buffer_wire_UB_N		=>	SRAM_UB_N,
			pixel_buffer_wire_WE_N		=>	SRAM_WE_N,
			
			-- VGA Controller
			vga_controller_wire_CLK		=>	VGA_CLK,
			vga_controller_wire_HS		=>	VGA_HS,
			vga_controller_wire_VS		=>	VGA_VS,
			vga_controller_wire_BLANK	=>	VGA_BLANK_N,
			vga_controller_wire_SYNC	=>	VGA_SYNC_N,
			vga_controller_wire_R		=>	VGA_R(7 DOWNTO 0),
			vga_controller_wire_G		=>	VGA_G(7 DOWNTO 0),
			vga_controller_wire_B		=>	VGA_B(7 DOWNTO 0),
			
			-- PWM Heater
			pwmduty_export 				=> dutyTemp,
			
			-- Barcode UART
			barcode_in_export				=> dataOutBarcode,		-- Readble by Nios
			barcode_int_export			=> interruptBarcode,		-- Readble by Nios
			
			-- Temp In UART
			temp_in_export					=> dataOutTemp,			-- Readble by Nios
			temp_int_export				=> interruptTemp,			-- Readble by Nios
			
			-- Coffee Control
			coffee_control_export		=> coffeeControlSig,		-- Writable By Nios
			
			-- camera -- X Coords
			camera_x1_export				=> camera_X1Sig,			-- Readable by Nios
			camera_x2_export				=> camera_X2Sig,			-- Readable by Nios
			camera_x3_export				=> camera_X3Sig,			-- Readable by Nios
			camera_x4_export				=> camera_X4Sig,			-- Readable by Nios
			camera_x5_export				=> camera_X5Sig,			-- Readable by Nios
			camera_x6_export				=> camera_X6Sig,			-- Readable by Nios
			camera_x7_export				=> camera_X7Sig,			-- Readable by Nios
			-- Camera -- Y Coords
			camera_y1_export				=> camera_y1Sig,			-- Readable by Nios
			camera_y2_export				=> camera_y2Sig,			-- Readable by Nios
			camera_y3_export				=> camera_y3Sig,			-- Readable by Nios
			camera_y4_export				=> camera_y4Sig,			-- Readable by Nios
			camera_y5_export				=> camera_y5Sig,			-- Readable by Nios
			camera_y6_export				=> camera_y6Sig,			-- Readable by Nios
			camera_y7_export				=> camera_y7Sig,			-- Readable by Nios
			SWsignal_export				=> SWsignal					-- writable by Nios
		); 
		
		tempUart: UART_RX PORT MAP (
			clk								=> clk_50M,
			in_RX								=> temp_in_RX,
			int_RX							=> interruptTemp, 	-- Readable by Nios 2
			out_RX							=> dataOutTemp			-- Readable by Nios 2	
		);
		
	
		hPWM: heaterPWM PORT MAP (
			clk 								=> CLK_50M,
			dutyIn							=> dutyTemp,			-- Writable by Nios 2
			pwmOUTDebug						=> scoopPin,
			pwmOUT							=> pwmPin
		);
		
		
		barcodeUart: UART_RX PORT MAP (
			clk								=> clk_50M,
			in_RX								=> barcode_in_RX,
			int_RX							=> interruptBarcode, -- Readable by Nios 2
			out_RX							=> dataoutBarcode		-- Readable by Nios 2	
		);
		
		cameraAlgo: GreenBean_Camera PORT MAP (
			CLK25				=> clk_50M,								-- Clock of VGA is 25Mhz
			clk_50 			=> clk_50M,
			SW					=> SWsignal,
			KEY				=> KEY,
			ov7670_pclk 	=> ov7670_pclk,
			ov7670_xclk  	=> ov7670_xclk,
			ov7670_vsync 	=>	ov7670_vsync,
			ov7670_href  	=>	ov7670_href,
			ov7670_data  	=>	ov7670_data,
			ov7670_sioc  	=>	ov7670_sioc,
			ov7670_siod  	=>	ov7670_siod,
			ov7670_pwdn  	=>	ov7670_pwdn,
			ov7670_reset 	=>	ov7670_reset,
			X1					=> camera_X1Sig,
			X2					=> camera_X2Sig,
			X3					=> camera_X3Sig,
			X4					=> camera_X4Sig,
			X5					=> camera_X5Sig, 
			X6					=> camera_X6Sig, 
			X7					=> camera_X7Sig,
			Y1					=> camera_Y1Sig,
			Y2					=> camera_Y2Sig,
			Y3					=> camera_Y3Sig,
			Y4					=> camera_Y4Sig,
			Y5					=> camera_Y5Sig,
			Y6					=> camera_Y6Sig,
			Y7					=> camera_Y7Sig,	
			LEDR				=> LEDR
		);
		
		--ledG(0) <= SW(17);

		
		--LEDG <= dataOutTemp;
		LEDG		<= coffeeControlSig;
end GreenBean_Arch;
