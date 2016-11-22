--------------------------------------------------------------------------------
-- AWAIBA GmbH
--------------------------------------------------------------------------------
-- MODUL NAME:  FIFO_WRITE_SM
-- FILENAME:    FIFO_WRITE_SM.vhd
-- AUTHOR:      Pedro Santos
--              email: pedro@awaiba.com
--
-- CREATED:     25.07.2013
--------------------------------------------------------------------------------
-- DESCRIPTION: STATE MACHINE to control the write to Segment fifo. 
--				Used on STAR project
--
--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
-- REVISIONS:
-- DATE         VERSION		AUTHOR      	DESCRIPTION
-- 25.07.2013   01     		P. Santos    	Initial version
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use ieee.std_logic_arith.all;

library UNISIM;
use UNISIM.VComponents.all;


entity FIFO_WRITE_SM is
	generic (
		C_NBR_OF_SEG_PIXELS:  integer:=128);	-- Number of segment pixels
	port (
		RESET:			in  std_logic;	-- Global system reset
		WRITE_CLOCK:		in  std_logic;	-- FIFO WRITE Clock - clock used on Sensor side
		--
		FIFO_EMPTY_ACK:		in  std_logic;	-- FLAG from the read counter
		WR_ENABLE:		in  std_logic;	-- Write enable from the Arbitrer
		READ_ENABLE:		in  std_logic;	-- READ enable STATUS from the Arbitrer
		LVAL_IN:		in  std_logic;	-- LVAL signals from all segmants
		LVAL_FLAG:		out std_logic;	-- Flag to indicate to Arbitrer that LVAL edge was detected
		FIFO_FULL_ACK:		out std_logic;	-- FLAG from the write counter
		ERROR_OUT:		out std_logic 	-- ERROR flag - debug only
	);
end entity FIFO_WRITE_SM;

architecture RTL of FIFO_WRITE_SM is

-- STATES to WRITE State Machine
-- constant C_NBR_OF_SEG_PIXELS:	integer:=1023;
type T_STATES_WR is (IDLE,WRITE_TO_FIFO,FIFO_FULL,ERROR,READY_TO_READ);
signal I_PRESENT_STATE_WR:	T_STATES_WR;
--
subtype PIX_CNT is integer range 0 to C_NBR_OF_SEG_PIXELS-1;
signal I_PIX_count:		PIX_CNT;
--
signal I_LVAL_dly0:		std_logic;
signal I_LVAL_dly1:		std_logic;
signal I_LVAL_FLAG:		std_logic;
signal I_FIFO_FULL:		std_logic;
signal I_ERROR:			std_logic;

begin

--------------------------------------------------------------------------------
-- WRITE TO FIFO CONTROL STATE MACHINE --		
--------------------------------------------------------------------------------

--  TO DO: CREATE A FOR CYCLE TO ADDRESS ALL 4 FIFOS 

WR_FIFO_CRTL_SM: process(RESET,WRITE_CLOCK)
begin
	if (RESET = '1') then
		I_PRESENT_STATE_WR <= IDLE;
	elsif (rising_edge(WRITE_CLOCK)) then
		case I_PRESENT_STATE_WR is
		-- IDLE - default state used to inicialise the write process
		when IDLE =>
		  if (WR_ENABLE = '1') then
			if (I_LVAL_FLAG ='1') then	-- Is LVAL rising edge?
				I_PRESENT_STATE_WR <= WRITE_TO_FIFO;
			else 
				I_PRESENT_STATE_WR <= I_PRESENT_STATE_WR;
			end if;
		  else
			I_PRESENT_STATE_WR <= I_PRESENT_STATE_WR;
		  end if;
		-- WRITE_TO_FIFO - state used to write to the fifo
		when WRITE_TO_FIFO =>
		  if (WR_ENABLE = '1') then
			if (I_FIFO_FULL ='1') then	-- is the fifo full?
				I_PRESENT_STATE_WR <= FIFO_FULL;
			else 
				I_PRESENT_STATE_WR <= I_PRESENT_STATE_WR;
			end if;
		  else
			I_PRESENT_STATE_WR <= IDLE;
		  end if;
		-- FIFO_FULL - state to signalize that the fifo is full
		when FIFO_FULL =>
		  if (WR_ENABLE = '1') then
			if (LVAL_IN ='0') then 		-- Is LVAL low?
				I_PRESENT_STATE_WR <= READY_TO_READ;
			else 
				I_PRESENT_STATE_WR <= I_PRESENT_STATE_WR; --ERROR;
			end if;
		  else
			I_PRESENT_STATE_WR <= IDLE;
		  end if;
		-- READY_TO_READ - used to signalize that the fifo is full and ready to be read
		when READY_TO_READ =>
		  if (WR_ENABLE = '1') then
			if (FIFO_EMPTY_ACK='1') then	-- Is FIFO already Read?
				I_PRESENT_STATE_WR <= IDLE;
			else 
				I_PRESENT_STATE_WR <= I_PRESENT_STATE_WR;
			end if;
		  else
			I_PRESENT_STATE_WR <= IDLE;
		  end if;
		-- others: currently unused states
		when others =>
		  null;
		end case;
		
	end if;
end process WR_FIFO_CRTL_SM;

LVAL_Edge_detect_proc: process (RESET, WRITE_CLOCK)
begin
	if (RESET = '1') then
		I_LVAL_FLAG <= '0';
		I_ERROR <= '0';
		I_LVAL_dly0 <= '0';
		I_LVAL_dly1 <= '0';
	elsif (rising_edge(WRITE_CLOCK)) then
		I_ERROR <= '0';
		I_LVAL_dly0 <= LVAL_IN;
		I_LVAL_dly1 <= I_LVAL_dly0;
		if (READ_ENABLE = '0') then
			if (LVAL_IN='1' and I_LVAL_dly0='0') then	-- Is LVAL rising edge?
				I_LVAL_FLAG <= '1';
			else 
				I_LVAL_FLAG <= '0';
			end if;
		end if;
	end if;
end process LVAL_Edge_detect_proc;

WRITE_Count_Proc: process(RESET,WRITE_CLOCK)
begin
	if (RESET = '1') then
		I_PIX_count <= 0;
		I_FIFO_FULL <= '0';
	elsif (rising_edge(WRITE_CLOCK)) then
		if (READ_ENABLE = '0') then
			if (I_PRESENT_STATE_WR = WRITE_TO_FIFO) then
				if (LVAL_IN ='0'and I_LVAL_dly0='1') or (I_PIX_count = (C_NBR_OF_SEG_PIXELS-1)) then
					I_PIX_count <= 0;
					I_FIFO_FULL <= '1';
				else
					I_PIX_count <= I_PIX_count + 1;
					I_FIFO_FULL <= '0';
				end if;
			elsif (I_PRESENT_STATE_WR = FIFO_FULL) then
				I_PIX_count <= 0;
				I_FIFO_FULL <= '0';
			else
				I_PIX_count <= 0;
				I_FIFO_FULL <= '0';
			end if;
		end if;
	end if;
end process WRITE_Count_Proc;

FIFO_FULL_ACK <= I_FIFO_FULL;
LVAL_FLAG <= I_LVAL_FLAG;
ERROR_OUT <= I_ERROR;

end RTL;