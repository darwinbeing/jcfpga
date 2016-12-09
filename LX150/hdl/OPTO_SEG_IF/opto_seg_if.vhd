--|---------------------------|
--| Deserialization Module    |
--|---------------------------|
--| Version A - Deyan Levski  |
--|---------------------------|

library IEEE,UNISIM;
use IEEE.STD_LOGIC_1164.all;
use UNISIM.VCOMPONENTS.all;


entity OPTO_SEG_IF is
	generic (
	G_SIMULATION:               boolean:= false;                       -- simulation mode
	C_TP:                       std_logic_vector:=x"D3D3D3D3");        -- training pattern
	port(
        G_INVERT_MSB:               in boolean:= false;                    -- invert MSB sensor data
        G_INVERT_LSB:               in boolean:= false;                    -- invert LSB sensor data
	-- system signals
        RESET:                      in  std_logic;                         -- async. reset
        ENABLE:                     in  std_logic;                         -- module activation
        IO_CLK:                     in  std_logic;                         -- bit clock
        DIV_CLK:                    in  std_logic;                         -- bit clock / 4
        BYTE_CLK:                   in  std_logic;                         -- word clock
        SERDESSTROBE_IN:            in  std_logic;                         -- strobe to ISERDES
       	-- serial interconnect
        DIGIF_MSB_P:                in  std_logic;                         -- MS-Byte (LVDS+)
        DIGIF_MSB_N:                in  std_logic;                         -- MS-Byte (LVDS-)
        DIGIF_LSB_P:                in  std_logic;                         -- LS-Byte (LVDS+)
        DIGIF_LSB_N:                in  std_logic;                         -- LS-Byte (LVDS+)
        -- image data interface
        DATA:                       inout std_logic_vector(15 downto 0);     -- data output
        DATA_EN:                    inout std_logic;                         -- DATA_IN data valid
       	-- bitslip
	I_BIT_SLIP_AUTO:	    in std_logic;			   -- auto bitslip
	I_BIT_SLIP_POS:		    in std_logic_vector(1 downto 0);	   -- manual bitslip pos
	PREAMBLE:		    in std_logic_vector(5 downto 0);	   -- bitslip preamble
	d_digif_serial_rst:	    in std_logic;			   -- DIGIF reset
	CLOCK_RSTDLY:		    in std_logic;			   -- bitslip process clk
	-- debug
        DIV_CLK_CS:                 out std_logic;
        DEBUG_IN:                   in  std_logic_vector(7 downto 0);
        DEBUG_OUT:                  out std_logic_vector(15 downto 0));
end entity OPTO_SEG_IF;


architecture STRUCTURAL of OPTO_SEG_IF is

	component SAMPLING
	generic (
	-- the data for the system
   	sys_w:                      integer := 1;
	-- the data for the device
   	dev_w:                      integer := 6);
   	port (
        DELAY_INC:                  in  std_logic;
        DELAY_CE:                   in  std_logic;
        DISABLE_PD:                 in  std_logic; -- disable phase detector
	-- From the system into the device
        DATA_IN_FROM_PINS:          in  std_logic_vector(sys_w-1 downto 0);
        DATA_IN_TO_DEVICE:          out std_logic_vector(dev_w-1 downto 0);
        DEBUG_IN:                   in  std_logic_vector (1 downto 0);		-- Tied to "00"
        DEBUG_OUT:                  out std_logic_vector ((3*sys_w)+5 downto 0);-- Ouput debug data
	 -- Clock and reset signals
        CLK_IN:                     in  std_logic;  -- Fast clock from PLL/MMCM
        CLK_DIV_IN:                 in  std_logic;  -- Slow clock from PLL/MMCM
        SERDESSTROBE_IN:            in  std_logic;  -- strobe to ISERDES
        IO_RESET:                   in  std_logic); -- Reset signal for IO circuit
	end component SAMPLING;


	component DESERIALIZER is
	generic (
	G_N:                        positive:=6);   -- output data width
	port (
	RESET:                      in    std_logic; -- async. reset
	CLOCK:                      in    std_logic; -- system clock
	DIV_CLOCK:                  in    std_logic; -- slow clock from sampling
	DATA_IN:                    in    std_logic_vector(5 downto 0); -- 6-bit data input
	BITSLIP:                    in    std_logic; -- enables bitslip operation
	DATA_OUT_EN:                out   std_logic; -- '1' = DATA_OUT valid
	DATA_OUT:                   out   std_logic_vector(G_N-1 downto 0)); -- parallel data out
	end component DESERIALIZER;

	signal I_DIGIF_MSB:             std_logic;
	signal I_DIGIF_LSB:             std_logic;
	signal I_SAMPLING_MSB_OUT:      std_logic_vector(5 downto 0);
	signal I_SAMPLING_LSB_OUT:      std_logic_vector(5 downto 0);
	signal I_DESER_MSB_IN:          std_logic_vector(5 downto 0);
	signal I_DESER_LSB_IN:          std_logic_vector(5 downto 0);
	signal I_BITSLIP_MSB_EN:        std_logic:='0';
	signal I_BITSLIP_LSB_EN:        std_logic:='0';
	signal I_DESER_MSB_OUT_EN:      std_logic;
	signal I_DESER_MSB_OUT:         std_logic_vector(5 downto 0);
	signal I_DESER_LSB_OUT_EN:      std_logic;
	signal I_DESER_LSB_OUT:         std_logic_vector(5 downto 0);
	signal I_DESER_MSB_OUT_SEL:     std_logic_vector(5 downto 0);
	signal I_DESER_LSB_OUT_SEL:     std_logic_vector(5 downto 0);

	signal I_DEBUG_IN0_1: std_logic;
	signal I_DEBUG_IN0_2: std_logic;
	signal I_DEBUG_IN1_1: std_logic;
	signal I_DEBUG_IN1_2: std_logic;
	signal I_DATA:                  std_logic_vector(15 downto 0);
	signal INV_MSB_DATA: 		std_logic_vector(5 downto 0);
	signal INV_LSB_DATA:		std_logic_vector(5 downto 0);
	signal I_DATA_EN:               std_logic;

	signal I_BIT_SLIP_1A_LSB_FLAG : std_logic;
	signal I_BIT_SLIP_1A_MSB_FLAG : std_logic;
	signal I_BIT_SLIP_POS_AUTO : std_logic_vector(1 downto 0);
	signal DIGIF_SER_RST_DLY : std_logic_vector(63 downto 0);


--debug
	signal I_DIV_CLK_CS:            std_logic;
	signal I_DIV_CLK_N:             std_logic;
	signal I_SERDESSTROBE_IN_DEBUG: std_logic;
	signal I_IO_CLK_DEBUG:          std_logic;
	signal I_DIV_CLK_DEBUG:         std_logic;
	signal I_DEBUG_CLK:             std_logic;


begin

--|-------------------------------------------------------|
--| Differential Input Buffers for DIGIF sensor interface |
--|-------------------------------------------------------|

	I_DIGIF_MSB_IBUFDS: IBUFDS
	generic map (
	DIFF_TERM			=> TRUE,
	IBUF_LOW_PWR			=> FALSE)
	port map (
	O				=> I_DIGIF_MSB,
	I				=> DIGIF_MSB_P,
	IB				=> DIGIF_MSB_N);

	I_DIGIF_LSB_IBUFDS: IBUFDS
	generic map (
	DIFF_TERM			=> TRUE,
	IBUF_LOW_PWR			=> FALSE)
	port map (
	O				=> I_DIGIF_LSB,
	I				=> DIGIF_LSB_P,
	IB				=> DIGIF_LSB_N);

--|---------------|
--| Data Sampling |
--|---------------|

	I_SAMPLING_MSB: SAMPLING
	generic map (
	-- width of the data for the system
	sys_w                       => 1,
	-- width of the data for the device
	dev_w                       => 6)
	port map (
	DELAY_INC                   => '0',
	DELAY_CE                    => '0',
	DISABLE_PD                  => '0', -- disable phase detector
	-- From the system into the device
	DATA_IN_FROM_PINS(0)        => I_DIGIF_MSB,
	DATA_IN_TO_DEVICE           => I_SAMPLING_MSB_OUT,
	DEBUG_IN                    => "00", -- Input debug data. Tie to "00" if not used
	DEBUG_OUT                   => open, -- Ouput debug data. Leave NC if not required
												    	    -- Clock and reset signals
	CLK_IN                      => IO_CLK,  -- Fast clock from PLL/MMCM
	CLK_DIV_IN                  => DIV_CLK, -- Slow clock from PLL/MMCM
	SERDESSTROBE_IN             => SERDESSTROBE_IN, -- strobe to ISERDES
	IO_RESET                    => RESET);  -- Reset signal for IO circuit

	I_SAMPLING_LSB: SAMPLING
	generic map (
        -- width of the data for the system
	sys_w                       => 1,
        -- width of the data for the device
	dev_w                       => 6)
	port map (
	DELAY_INC                   => '0',
	DELAY_CE                    => '0',
	DISABLE_PD                  => '0', -- disable phase detector
	-- From the system into the device
	DATA_IN_FROM_PINS(0)        => I_DIGIF_LSB,
	DATA_IN_TO_DEVICE           => I_SAMPLING_LSB_OUT,
	DEBUG_IN                    => "00", -- Input debug data. Tie to "00" if not used
	DEBUG_OUT                   => open, -- Ouput debug data. Leave NC if not required
	-- Clock and reset signals
	CLK_IN                      => IO_CLK,  -- Fast clock from PLL/MMCM
	CLK_DIV_IN                  => DIV_CLK, -- Slow clock from PLL/MMCM
	SERDESSTROBE_IN             => SERDESSTROBE_IN, -- strobe to ISERDES
	IO_RESET                    => RESET); -- Reset signal for IO circuit

	DIV_CLK_CS <= '0';

--|--------------|
--| Word Bitslip |
--|--------------|

	I_DESERIALIZER_MSB: DESERIALIZER
	generic map (
	G_N                         => 6) -- output data width
	port map (
	RESET                       => RESET,    -- async. reset
	CLOCK                       => BYTE_CLK, -- system clock
	DIV_CLOCK                   => DIV_CLK,  -- slow clock from sampling
	DATA_IN                     => I_SAMPLING_MSB_OUT, -- 4-bit data input
	BITSLIP                     => I_BITSLIP_MSB_EN,   -- enables bitslip operation
	DATA_OUT_EN                 => I_DESER_MSB_OUT_EN, -- '1' = DATA_OUT valid
	DATA_OUT                    => I_DESER_MSB_OUT);   -- parallel data output

	I_DESER_MSB_OUT_SEL <= (not I_DESER_MSB_OUT) when G_INVERT_MSB else I_DESER_MSB_OUT;
--	I_DESER_MSB_OUT_SEL <= I_DESER_MSB_OUT;

	I_DESERIALIZER_LSB: DESERIALIZER
	generic map (
	G_N                         => 6) -- output data width
	port map (
	RESET                       => RESET, -- async. reset
	CLOCK                       => BYTE_CLK, -- system clock
	DIV_CLOCK                   => DIV_CLK,  -- slow clock from sampling
	DATA_IN                     => I_SAMPLING_LSB_OUT, -- 4-bit data input
	BITSLIP                     => I_BITSLIP_LSB_EN,   -- enables bitslip operation
	DATA_OUT_EN                 => I_DESER_LSB_OUT_EN, -- '1' = DATA_OUT valid
	DATA_OUT                    => I_DESER_LSB_OUT);   -- parallel data output

	I_DESER_LSB_OUT_SEL <= (not I_DESER_LSB_OUT) when G_INVERT_LSB else I_DESER_LSB_OUT;
--	I_DESER_LSB_OUT_SEL <= I_DESER_LSB_OUT;

--|-----------------|
--| Bitslip Control |
--|-----------------|

	DIGIF_SERIAL_RST_DLY_PROC: process(RESET,CLOCK_RSTDLY)
	begin

		if (RESET = '1') then
			DIGIF_SER_RST_DLY <= "0000000000000000000000000000000000000000000000000000000000000000";
		elsif (rising_edge(CLOCK_RSTDLY)) then
			DIGIF_SER_RST_DLY(0) <= d_digif_serial_rst;
			DIGIF_SER_RST_DLY(63 downto 1) <= DIGIF_SER_RST_DLY(62 downto 0);
		end if;

	end process DIGIF_SERIAL_RST_DLY_PROC;


	BIT_SLIP_SEG1A_PROC: process(RESET,BYTE_CLK)
	begin
		if (RESET = '1') then
			I_BIT_SLIP_1A_LSB_FLAG <= '0';
			I_BIT_SLIP_1A_MSB_FLAG <= '0';
		--
			I_BIT_SLIP_POS_AUTO(1 downto 0) <= (others => '0');
		elsif (rising_edge(BYTE_CLK)) then
			if (I_BIT_SLIP_AUTO ='1') then

				if ((DIGIF_SER_RST_DLY(63) = '1') and (I_BIT_SLIP_1A_LSB_FLAG = '0')) then
					if (I_DATA(5 downto 0) = PREAMBLE) then --110100
						I_BIT_SLIP_POS_AUTO(0) <= '0';
					else
						I_BIT_SLIP_POS_AUTO(0) <= '1';
					end if;
					I_BIT_SLIP_1A_LSB_FLAG <= '1';
				else
					I_BIT_SLIP_POS_AUTO(0) <= '0';
				end if;

				if ((DIGIF_SER_RST_DLY(63) = '1') and (I_BIT_SLIP_1A_MSB_FLAG = '0')) then
					if (I_DATA(11 downto 6) = PREAMBLE) then --110100
						I_BIT_SLIP_POS_AUTO(1) <= '0';
					else
						I_BIT_SLIP_POS_AUTO(1) <= '1';
					end if;
					I_BIT_SLIP_1A_MSB_FLAG <= '1';
				else
					I_BIT_SLIP_POS_AUTO(1) <= '0';
				end if;

			else
				I_BIT_SLIP_POS_AUTO(1 downto 0) <= (others => '0');
				I_BIT_SLIP_1A_LSB_FLAG <= '0';
				I_BIT_SLIP_1A_MSB_FLAG <= '0';
			end if;

			if (d_digif_serial_rst = '0') then
				I_BIT_SLIP_POS_AUTO(1 downto 0) <= (others => '0');
				I_BIT_SLIP_1A_LSB_FLAG <= '0';
				I_BIT_SLIP_1A_MSB_FLAG <= '0';
			end if;
		end if;

	end process BIT_SLIP_SEG1A_PROC;

--|-----------------|
--| Output Register |
--|-----------------|

	OUTREG: process(RESET,BYTE_CLK)
	begin
		if (RESET = '1') then
			I_DATA    <= (others => '0');
			I_DEBUG_IN0_1 <= '0';
			I_DEBUG_IN0_2 <= '0';
			I_DEBUG_IN1_1 <= '0';
			I_DEBUG_IN1_2 <= '0';
		elsif (falling_edge(BYTE_CLK)) then
			I_DATA	<= "0000" & I_DESER_MSB_OUT_SEL & I_DESER_LSB_OUT_SEL;
			I_DEBUG_IN0_1 <= (I_BIT_SLIP_POS(0) or I_BIT_SLIP_POS_AUTO(0));
			I_DEBUG_IN0_2 <= I_DEBUG_IN0_1;
			I_DEBUG_IN1_1 <= (I_BIT_SLIP_POS(1) or I_BIT_SLIP_POS_AUTO(1));
			I_DEBUG_IN1_2 <= I_DEBUG_IN1_1;
		end if;
	end process OUTREG;

	I_BITSLIP_LSB_EN <= I_DEBUG_IN0_1 and not I_DEBUG_IN0_2;
	I_BITSLIP_MSB_EN <= I_DEBUG_IN1_1 and not I_DEBUG_IN1_2;

	DATA    <= I_DATA(15 downto 13) & I_DATA(6) & I_DATA(7) & I_DATA(8) & I_DATA(9) & I_DATA(10) & I_DATA(11) & I_DATA(12) & I_DATA(0) & I_DATA(1) & I_DATA(2) & I_DATA(3) & I_DATA(4) & I_DATA(5);
--	INV_MSB_DATA <= not I_DATA(11 downto 6) when G_INVERT_MSB else I_DATA(11 downto 6);
--	INV_LSB_DATA <= not I_DATA(5 downto 0)  when G_INVERT_LSB else I_DATA(5 downto 0);
--	DATA <= "0000" & INV_MSB_DATA & INV_LSB_DATA;

	DATA_EN <= '1'; --I_DATA_EN;

	DEBUG_OUT <=  "00" & I_DIGIF_MSB & I_SAMPLING_MSB_OUT & I_DIGIF_LSB & I_SAMPLING_LSB_OUT;

end STRUCTURAL;
