--|------------------------------------------------------------------|
--| ADC Testhip Data Deserializer Module                             |
--|------------------------------------------------------------------|
--| Version P1A, Deyan Levski, deyan.levski@eng.ox.ac.uk, 14.09.2016 |
--|------------------------------------------------------------------|
--|-+-|
--
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

entity DESERIAL is
    Port ( CLOCK : in  STD_LOGIC; -- also same as d_digif_sck
           RESET : in  STD_LOGIC; -- also same as d_digif_rst
           d_digif_msb_data : in  STD_LOGIC;
           d_digif_lsb_data : in  STD_LOGIC;
	   DESERIALIZED_DATA_CLK : out STD_LOGIC;
           DESERIALIZED_DATA : out  STD_LOGIC_VECTOR (11 downto 0));
end DESERIAL;

architecture Behavioral of DESERIAL is

	signal DESER_MSB_BUF			: STD_LOGIC_VECTOR (5 downto 0);
	signal DESER_LSB_BUF			: STD_LOGIC_VECTOR (5 downto 0);
	signal DESERIALIZED_DATA_CLOCK		: STD_LOGIC;

begin

deserialization:process(CLOCK)
		variable cnt : integer range 0 to 255 := 0;

	begin
		if CLOCK'event and CLOCK = '1' then

			if RESET = '1' then
				cnt := 4;			-- one clock cycle gibberish
				DESERIALIZED_DATA(11 downto 0) <= (others => '0');
				DESERIALIZED_DATA_CLOCK <= '1';
			end if;

		DESER_MSB_BUF(0) <= d_digif_msb_data;
		DESER_MSB_BUF(5 downto 1) <= DESER_MSB_BUF(4 downto 0);
		DESER_LSB_BUF(0) <= d_digif_lsb_data;
		DESER_LSB_BUF(5 downto 1) <= DESER_LSB_BUF(4 downto 0);

			if cnt = 6 then
				DESERIALIZED_DATA (11 downto 6) <= DESER_MSB_BUF;
				DESERIALIZED_DATA (5 downto 0)	<= DESER_LSB_BUF;
				DESERIALIZED_DATA_CLOCK <= not DESERIALIZED_DATA_CLOCK; -- toggle back (falling edge) at end of DESERIALIZED_DATA
				cnt := 0;
			end if;

			if cnt = 3 then 
				DESERIALIZED_DATA_CLOCK <= not DESERIALIZED_DATA_CLOCK; -- toggle (rising edge) in middle of DESERIALIZED_DATA
			end if;

		cnt := cnt + 1;
		end if;

		if CLOCK'event and CLOCK = '0' then

			if RESET = '1' then
				cnt := 4;			-- one clock cycle gibberish
				DESERIALIZED_DATA(11 downto 0) <= (others => '0');
				DESERIALIZED_DATA_CLOCK <= '1';
			end if;

		DESER_MSB_BUF(0) <= d_digif_msb_data;
		DESER_MSB_BUF(5 downto 1) <= DESER_MSB_BUF(4 downto 0);
		DESER_LSB_BUF(0) <= d_digif_lsb_data;
		DESER_LSB_BUF(5 downto 1) <= DESER_LSB_BUF(4 downto 0);

			if cnt = 6 then
				DESERIALIZED_DATA (11 downto 6) <= DESER_MSB_BUF;
				DESERIALIZED_DATA (5 downto 0)	<= DESER_LSB_BUF;
				DESERIALIZED_DATA_CLOCK <= not DESERIALIZED_DATA_CLOCK; -- toggle back (falling edge) at end of DESERIALIZED_DATA
				cnt := 0;
			end if;

			if cnt = 3 then 
				DESERIALIZED_DATA_CLOCK <= not DESERIALIZED_DATA_CLOCK; -- toggle (rising edge) in middle of DESERIALIZED_DATA
			end if;

		cnt := cnt + 1;
		end if;

	end process;

	DESERIALIZED_DATA_CLK <= DESERIALIZED_DATA_CLOCK;

end Behavioral;

