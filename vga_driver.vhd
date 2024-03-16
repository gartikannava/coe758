----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:57:00 11/17/2023 
-- Design Name: 
-- Module Name:    vga_driver - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
ENTITY vga_driver IS
PORT (
CLK : IN STD_LOGIC;
SW0 : IN STD_LOGIC; --paddle left
SW1 : IN STD_LOGIC; --paddle right
SW2 : IN STD_LOGIC;
SW3 : IN STD_LOGIC;
RST : IN STD_LOGIC;
DAC_CLK : OUT STD_LOGIC;
HSYNC : OUT STD_LOGIC;
VSYNC : OUT STD_LOGIC;
Gout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
Bout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
Rout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
END vga_driver;
ARCHITECTURE Behavioral OF vga_driver IS
--Horizontal Parameters
CONSTANT HD : INTEGER := 639; --Horizontal Display (640p)
CONSTANT HFP : INTEGER := 16; --Front Porch
CONSTANT HSP : INTEGER := 96; --Sync Pulse
CONSTANT HBP : INTEGER := 48; --Back Porch
--Vertical Parameters
CONSTANT VD : INTEGER := 479; --Vertical Display (480p)
CONSTANT VFP : INTEGER := 10; --Front Porch
CONSTANT VSP : INTEGER := 2; --Sync Pulse
CONSTANT VBP : INTEGER := 33; --Back Porch

SIGNAL videoOn : std_logic := '0';
--VGA signals
SIGNAL clk25 : std_logic := '0';
SIGNAL reset : std_logic := '0';
SIGNAL new_frame : std_logic := '0';
SIGNAL hPos : INTEGER := 0; --hsync counter
SIGNAL vPos : INTEGER := 0; --vsync counter
--Paddle Signals
SIGNAL paddle_h1 : INTEGER RANGE 0 TO 640 := 26;
SIGNAL paddle_v1 : INTEGER RANGE 0 TO 480 := 375;
SIGNAL paddle_h2 : INTEGER RANGE 0 TO 640 := 599;
SIGNAL paddle_v2 : INTEGER RANGE 0 TO 480 := 375;
--Ball signals
SIGNAL ball_pos_h1 : INTEGER RANGE 0 TO 640 := 305;
SIGNAL ball_pos_v1 : INTEGER RANGE 0 TO 480 := 240;
SIGNAL ball_up : std_logic := '0';
SIGNAL ball_right : std_logic := '1';
SIGNAL start_game : std_logic := '1';
TYPE state_value IS (state0, state1, state2, state3);
SIGNAL current_state : state_value;
SIGNAL state : STD_LOGIC_VECTOR(2 DOWNTO 0);

BEGIN

States : PROCESS (RST) --process to change states

	BEGIN
	IF (RST = '1') THEN --if reset turns 1 then everything stops
		current_state <= state0; --state0 = stop
	ELSIF start_game = '1' THEN --start_game is kept always to one to keep moving
		current_state <= state1;
	ELSE
		current_state <= state0;
	END IF;
END PROCESS;
	
clk_div : PROCESS (CLK, current_state)
	BEGIN
	IF (CLK'EVENT AND CLK = '1' AND current_state =state1) THEN
	--clock counter
	clk25 <= NOT clk25;
	DAC_CLK <= NOT clk25;
	ELSIF (CLK'EVENT AND CLK = '1' AND current_state = state0) THEN
		clk25 <= clk25;
	END IF;
	
END PROCESS;

Horizontal_position_counter : PROCESS (clk25,RST)
	BEGIN
		if(RST='1')then
			hPos<=0;
		
		ELSIF (clk25'EVENT AND clk25 = '1') THEN
		
			IF (hPos = (HD + HFP + HSP + HBP)) THEN
				hPos<=0;
			
		--IF (vPos = (VD + VFP + VSP + VBP)) THEN
		
				new_frame <= '1';
		
			ELSE
		
				hPos<=hPos+1;
				new_frame <= '0';
			END IF;
		END IF;
	END PROCESS;
	
Vertical_position_counter : PROCESS (clk25, hPos,RST)
BEGIN
	IF(RST='1')then
	vPos<=0;
	elsIF (clk25'EVENT AND clk25 = '1') THEN
		IF (hpos = (HD + HFP + HSP + HBP)) THEN
			IF (vPos = (VD + VFP + VSP + VBP)) THEN
				vPos <= 0;
			ELSE
				vPos <= vPos + 1;
			END IF;
		END IF;
	END IF;
END PROCESS;

Horizontal_Synchronication : PROCESS (clk25, hPos,RST)
BEGIN
	IF(RST='1')then
		HSYNC<='0';
		ELSIF (clk25'EVENT AND clk25 = '1') THEN
			IF ((hPos <= (HD + HFP)) OR (hPos > HD + HFP + HSP)) THEN
				HSYNC <= '1';
			ELSE
				HSYNC <= '0';
			END IF;
		END IF;
	END PROCESS;

Vertical_Synchronication : PROCESS (clk25, vPos,RST)
BEGIN
	IF(RST='1')then
		VSYNC<='0';
	ELSIF (clk25'EVENT AND clk25 = '1') THEN
		IF ((vPos <= (VD + VFP)) OR (vPos > VD + VFP + VSP)) THEN
			VSYNC <= '1';
		ELSE
			VSYNC <= '0';
		END IF;
	END IF;
END PROCESS;

video_on : PROCESS (clk25, hPos, vPos,RST)
BEGIN
	if(RST='1')then
		videoOn<='0';
	ELSIF (clk25'EVENT AND clk25 = '1') THEN
		IF (hPos <= HD AND vPos <= VD) THEN
		videoOn <= '0';
		ELSE
		videoOn <= '1';
		END IF;
	END IF;
END PROCESS;

draw : PROCESS (clk25, hPos, vPos, videoOn)
BEGIN
	
	IF (clk25'EVENT AND clk25 = '1') THEN
	
		IF (((hPos >= 30 AND hPos <= 610) AND (vPos >= 15 AND vPos <= 30)) -- white borders
		OR ((hPos >= 30 AND hPos <= 610) AND (vPos >= 450 AND vPos <= 465))
		OR ((hPos >= 30 AND hPos <= 55) AND (vPos >= 15 AND vPos <= 150)) 
		OR ((hPos >= 30 AND hPos <= 55) AND (vPos>= 330 AND vPos <= 465))
		OR ((hPos >= 585 AND hPos <= 610) AND (vPos>= 15 AND vPos <= 150))
		OR ((hPos >= 585 AND hPos <= 610) AND (vPos >= 330 AND vPos <= 465))) THEN
			Rout <= "11111111";
			Bout <="11111111";
			Gout <="11111111";
	
		

		ELSIF (hPos >= 0 AND hPos <= 640) AND (vPos >=0 AND vPos <= 480) THEN -- background
			Rout <= "00000000";
			Bout <= "00000000";
			Gout <= "11111111";
		ELSE
			Rout <= "00000000";
			Bout <= "00000000";
			Gout <= "00000000";
	END IF; --ends if((hPos ...)
		
		IF((hPos >=85 and hpos<=100) and (vPos >=180 and Vpos <=300)) Then
			Rout <= "00000000";
			Bout <="11111111";
			Gout <="00000000";
		end if;
		IF((hPos >=540 and hpos<=555) and (vPos >=180 and Vpos <=300)) Then
			Rout <= "11111111";
			Bout <="00000000";
			Gout <="00000000";
		end if;
		
		IF((hPos >=315 and hpos<=325) and (vPos >=235 and Vpos <=245)) Then
			Rout <= "11111111";
			Bout <="00000000";
			Gout <="11111111";
		end if;
		
		IF((hPos >=315 and hpos<=325) and (vPos >=235 and Vpos <=245)) Then
			Rout <= "11111111";
			Bout <="00000000";
			Gout <="11111111";
		end if;
		
	END IF; --ends if (clk25'event...)
	
END PROCESS;



end Behavioral;