--|-------------------------------------------------------------------|
--| ADC Testchip DIGIF interface model                                |
--|-------------------------------------------------------------------|
--| Version P1A - Deyan Levski, deyan.levski@eng.ox.ac.uk, 14.09.2016 |
--|-------------------------------------------------------------------|
--
--| -+- | Implements a DDR 6:1 serializer |
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DIGIF is
    Port ( d_digif_sck : in  STD_LOGIC;
           d_digif_rst : in  STD_LOGIC;
           d_digif_msb_data : out  STD_LOGIC;
           d_digif_lsb_data : out  STD_LOGIC);
end DIGIF;

architecture Behavioral of DIGIF is

	signal PREAMBLE : STD_LOGIC_VECTOR(5 downto 0);
	signal DATA0 	: STD_LOGIC_VECTOR(11 downto 0);
	signal DATA1	: STD_LOGIC_VECTOR(11 downto 0);
	shared variable TXBUF_M : STD_LOGIC_VECTOR(5 downto 0);
	shared variable TXBUF_L : STD_LOGIC_VECTOR(5 downto 0);

	shared variable sck_counter :integer range 0 to 255 := 0; -- 8-bit register
	shared variable preamble_counter :integer range 0 to 31 :=0;
	shared variable PREAMBLE_var :std_logic_vector (5 downto 0);
	signal PREAMBLE_OUT_RISE : STD_LOGIC;
	signal PREAMBLE_OUT_FALL : STD_LOGIC;

begin

--|--------------------------------------------|
--| Alternate transmission with two data words |
--|--------------------------------------------|

	PREAMBLE <= "101011";
	DATA0	 <= "010010001011";
	DATA1	 <= "111101000110";

	process(d_digif_sck)

--	variable sck_counter :integer range 0 to 255 := 0; -- 8-bit register
--	variable preamble_counter :integer range 0 to 255 :=0;
--	variable PREAMBLE_var :std_logic_vector (5 downto 0);

	begin


	if (d_digif_sck'event and d_digif_sck = '1') then	-- DDR

		if (d_digif_rst = '1') then
			TXBUF_M := DATA0(11 downto 6);
			TXBUF_L := DATA0(5 downto 0);

			preamble_counter := preamble_counter + 1;
			PREAMBLE_OUT_RISE <= PREAMBLE_var(5);

			PREAMBLE_var (5 downto 1) := PREAMBLE_var (4 downto 0);
			sck_counter := 0;

			if preamble_counter = 6 then
			PREAMBLE_var := PREAMBLE;
			preamble_counter := 0;
			end if;
		else

			TXBUF_M (5 downto 1) := TXBUF_M (4 downto 0);
			TXBUF_L (5 downto 1) := TXBUF_L (4 downto 0);
			sck_counter := sck_counter + 1;	

			if sck_counter = 6 then
			TXBUF_M := DATA1(11 downto 6);
			TXBUF_L := DATA1(5 downto 0);
			elsif sck_counter = 12 then
			TXBUF_M := DATA0(11 downto 6);
			TXBUF_L := DATA0(5 downto 0);
			sck_counter := 0;
			end if;

		end if;

	end if;

	end process;


--d_digif_msb_data <= PREAMBLE_var(5) when d_digif_rst = '1' else TXBUF_M(5) when d_digif_rst = '0' else '0';
--d_digif_lsb_data <= PREAMBLE_var(5) when d_digif_rst = '1' else TXBUF_L(5) when d_digif_rst = '0' else '0';


d_digif_msb_data <= (PREAMBLE_OUT_RISE or PREAMBLE_OUT_FALL) when d_digif_rst='1' else TXBUF_M(5);

	process(d_digif_sck)

	begin

	if (d_digif_sck'event and d_digif_sck = '0') then

		if (d_digif_rst = '1') then
			TXBUF_M := DATA0(11 downto 6);
			TXBUF_L := DATA0(5 downto 0);

			PREAMBLE_OUT_FALL <= PREAMBLE_var(5);
			preamble_counter := preamble_counter + 1;

			PREAMBLE_var (5 downto 1) := PREAMBLE_var (4 downto 0);
			sck_counter := 0;

			if preamble_counter = 6 then
			PREAMBLE_var := PREAMBLE;
			preamble_counter := 0;
			end if;

		else
			TXBUF_M (5 downto 1) := TXBUF_M (4 downto 0);
			TXBUF_L (5 downto 1) := TXBUF_L (4 downto 0);
			sck_counter := sck_counter + 1;	

			if sck_counter = 6 then
			TXBUF_M := DATA1(11 downto 6);
			TXBUF_L := DATA1(5 downto 0);
			elsif sck_counter = 12 then
			TXBUF_M := DATA0(11 downto 6);
			TXBUF_L := DATA0(5 downto 0);
			sck_counter := 0;
			end if;

		end if;

	end if;

	end process;

end Behavioral;

