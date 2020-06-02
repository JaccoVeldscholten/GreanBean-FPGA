-- UART 1.0 Jacco Veldscholten
-- Op Basis van de State Machine van DigiKey

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
 
entity UART_RX is
  generic (
			prescaler_setting : integer := 5208     -- (Clock / Baud) = (50Mhz / 9600 = 5208.33333333)
    );
  port (
		 clk       : in  std_logic;
		 in_RX 		: in  std_logic;
		 int_rx	 : out std_logic;
		 out_RX   : out std_logic_vector(7 downto 0)
    );
end UART_RX;
 
 
architecture rtl of UART_RX is
 
  type t_SM_Main is (s_Idle, s_RX_Start_Bit, s_RX_Data, s_RX_StopBit, s_Cleanup);
  signal RX_StateMachine : t_SM_Main := s_Idle;
 
  signal RX_Data_Received : std_logic := '0';
  signal RX_Data   : std_logic := '0';
   
  signal r_Clk_Count : integer range 0 to prescaler_setting-1 := 0;
  signal bit_index : integer range 0 to 7 := 0;  -- 8 Bits Total
  signal rx_byte   : std_logic_vector(7 downto 0) := (others => '0');
   
begin
 
  process (clk)
  begin
    if rising_edge(clk) then
      RX_Data_Received <= in_RX;
      RX_Data   <= RX_Data_Received;
    end if;
  end process;
   
 
  process (clk)
  begin
    if rising_edge(clk) then
         
      case RX_StateMachine is
 
        when s_Idle =>
		    int_rx <= '0';
          r_Clk_Count <= 0;										-- Standaard waardes toekennen
          bit_index <= 0;											-- Standaard waardes toekennen
 
          if RX_Data = '0' then       							-- Start bit gevonden (Lijn omlaag))
            RX_StateMachine <= s_RX_Start_Bit;
          else
            RX_StateMachine <= s_Idle;							-- Idle. Er is geen UART Data.
          end if;		
 
           
		  -- Controle voor redudencie (Nog steeds start bit?)
		  -- Deze controle wordt door de halve clock gedaan. 
        when s_RX_Start_Bit =>
          if r_Clk_Count = (prescaler_setting-1)/2 then	-- Prescaler / 2 (Helft van de baud)
            if RX_Data = '0' then
              r_Clk_Count <= 0; 				 					-- Midden klok
              RX_StateMachine   <= s_RX_Data;
            else
              RX_StateMachine   <= s_Idle;			 		-- Geen juiste start bit. Terug naar Idle
            end if;
          else
            r_Clk_Count <= r_Clk_Count + 1;					-- Counter ophogen voor 2/ baud
            RX_StateMachine   <= s_RX_Start_Bit;			-- State machine voor start Bit
          end if;
 
           
        -- Elke klokpuls kijken we of de coounter nog klopt.
        when s_RX_Data =>
          if r_Clk_Count < prescaler_setting-1 then
            r_Clk_Count <= r_Clk_Count + 1;
            RX_StateMachine   <= s_RX_Data;
          else
            r_Clk_Count            <= 0;
            rx_byte(bit_index) <= RX_Data;
             
            -- Check if we have sent out all bits
            if bit_index < 7 then
              bit_index <= bit_index + 1;
              RX_StateMachine   <= s_RX_Data;
            else
              bit_index <= 0;
              RX_StateMachine   <= s_RX_StopBit;
            end if;
          end if;
 
 
        -- Ontvangen Stop bit.  Stop bit = 1
        when s_RX_StopBit =>
          -- Controle of we echt een stopbit hebben
          if r_Clk_Count < prescaler_setting-1 then
            r_Clk_Count <= r_Clk_Count + 1;
            RX_StateMachine   <= s_RX_StopBit;
          else
            r_Clk_Count <= 0;
            RX_StateMachine   <= s_Cleanup;
				int_rx <= '1';
          end if;
 
                   
        -- 1 clock wachten om schoon te maken
        when s_Cleanup =>
          RX_StateMachine <= s_Idle;
			 int_rx <= '0';
 
         -- Valse waardes filteren
        when others =>
          RX_StateMachine <= s_Idle;
 
      end case;
    end if;
  end process;

  out_RX <= rx_byte;
   
end rtl;