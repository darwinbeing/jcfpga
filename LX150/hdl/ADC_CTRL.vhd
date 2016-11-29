--|------------------------------------------------------------------------------------------------|
--| Sensor Control Module                                                                          |
--|------------------------------------------------------------------------------------------------|
--| Version B, Ported to LX150 Version, Author: Deyan Levski deyan.levski@eng.ox.ac.uk, 09.09.2016 |
--|------------------------------------------------------------------------------------------------|
--| Version C, Added row/digif/board seq sig, Deyan Levski, 04.11.2016                             |
--|------------------------------------------------------------------------------------------------|
--|-+-|
--
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package LINE_COMBINE_PKG is
  type T_DATA_SEG is array(natural range <>) of std_logic_vector(15 downto 0);
end package;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

library WORK;
use WORK.LINE_COMBINE_PKG.all;

entity ADC_CTRL is
	Port ( 
	   -- UART
		     RX : in  STD_LOGIC;   -- GPIO5 : out STD_LOGIC;
		     TX : out  STD_LOGIC;  -- GPIO6 : out STD_LOGIC;
					   -- CLK/RST
		     CLOCK : in  STD_LOGIC;
		     RESET : in  STD_LOGIC;
	   -- CHIP SPI
		     SPI_SEN : inout  STD_LOGIC;
		     SPI_SCK : inout  STD_LOGIC;
		     SPI_SDA : inout  STD_LOGIC;
	   -- DAC SPI
		     SPI_DAC_SCK : inout STD_LOGIC;
		     SPI_DAC_SDA : inout STD_LOGIC;
		     SPI_DAC_A_SYNC : inout STD_LOGIC;
		     SPI_DAC_B_SYNC : inout STD_LOGIC;
	   -- BOARD GPIO
		     GPIO1 : out STD_LOGIC; -- DEBUG_PIN / SREG LOADED
		     GPIO2 : out STD_LOGIC; -- SYNC_CLOCK / Scope Trigger
		     GPIO3 : out STD_LOGIC;
		     GPIO4 : out STD_LOGIC;
	   	  -- GPIO5 : out STD_LOGIC;
		  -- GPIO6 : out STD_LOGIC;
	   -- BOARD CTRL
		     SHUTDOWN_VDD : out STD_LOGIC;
		     SHUTDOWN_VDA : out STD_LOGIC;
		     SPI_ADC_CS   : out STD_LOGIC;
		     SPI_ADC_MOSI : out STD_LOGIC;
		     SPI_ADC_CLK  : out STD_LOGIC;
		     SPI_ADC_MISO : in STD_LOGIC;
	   -- LVDS COUNT CLK
		     COUNT_CLK_P : inout STD_LOGIC;
		     COUNT_CLK_N : inout STD_LOGIC;
	   -- LVDS DIGIF CLK
		     SRX_P : inout STD_LOGIC;
		     SRX_N : inout STD_LOGIC;
	   -- CHIP sequencer
	   -- row_drv
		     d_row_addr : inout STD_LOGIC_VECTOR(7 downto 0);
		     d_row_rs   : inout STD_LOGIC;
		     d_row_rst  : inout STD_LOGIC;
		     d_row_tx   : inout STD_LOGIC;
	   -- col_vln
		     d_col_vln_sh : inout STD_LOGIC;
	   -- sampling
		     d_shs : inout  STD_LOGIC;
		     d_shr : inout  STD_LOGIC;
		     d_ads : inout  STD_LOGIC;
		     d_adr : inout  STD_LOGIC;
	   -- col_comp
		     d_comp_bias_sh : inout  STD_LOGIC;
		     d_comp_dyn_pon : inout  STD_LOGIC;
	   -- col_count
		     d_count_en : inout  STD_LOGIC;
		     d_count_rst : inout  STD_LOGIC;
		     d_count_inv_clk : inout  STD_LOGIC;
		     d_count_hold : inout  STD_LOGIC;
		     d_count_updn : inout  STD_LOGIC;
		     d_count_inc_one : inout  STD_LOGIC;
		     d_count_jc_shift_en : inout  STD_LOGIC;
		     d_count_lsb_en : inout  STD_LOGIC;
		     d_count_lsb_clk : inout  STD_LOGIC;
		     d_count_mem_wr : inout  STD_LOGIC;
	   -- ref_vref
		     d_ref_vref_ramp_rst : inout  STD_LOGIC;
		     d_ref_vref_sh : inout  STD_LOGIC;
		     d_ref_vref_clamp_en : inout  STD_LOGIC;
		     d_ref_vref_ramp_ota_dyn_pon : inout  STD_LOGIC;
	   -- digif
		     d_digif_serial_rst : inout  STD_LOGIC;
		     G0LTX_N : in STD_LOGIC;
		     G0LTX_P : in STD_LOGIC;
		     G0HTX_N : in STD_LOGIC;
		     G0HTX_P : in STD_LOGIC;
		     G1LTX_N : in STD_LOGIC;
		     G1LTX_P : in STD_LOGIC;
		     G1HTX_N : in STD_LOGIC;
		     G1HTX_P : in STD_LOGIC;
		     G2LTX_N : in STD_LOGIC;
		     G2LTX_P : in STD_LOGIC;
		     G2HTX_N : in STD_LOGIC;
		     G2HTX_P : in STD_LOGIC;
		     G3LTX_N : in STD_LOGIC;
		     G3LTX_P : in STD_LOGIC;
		     G3HTX_N : in STD_LOGIC;
		     G3HTX_P : in STD_LOGIC;
		     G4LTX_N : in STD_LOGIC;
		     G4LTX_P : in STD_LOGIC;
		     G4HTX_N : in STD_LOGIC;
		     G4HTX_P : in STD_LOGIC;
		     G5LTX_N : in STD_LOGIC;
		     G5LTX_P : in STD_LOGIC;
		     G5HTX_N : in STD_LOGIC;
		     G5HTX_P : in STD_LOGIC;
		     G6LTX_N : in STD_LOGIC;
		     G6LTX_P : in STD_LOGIC;
		     G6HTX_N : in STD_LOGIC;
		     G6HTX_P : in STD_LOGIC;
		     G7LTX_N : in STD_LOGIC;
		     G7LTX_P : in STD_LOGIC;
		     G7HTX_N : in STD_LOGIC;
		     G7HTX_P : in STD_LOGIC;
	   -- FX3 GPIFII Interface
		     GPIFII_PCLK_IN : in   std_logic;			-- fx3 interface clock
		     GPIFII_PCLK : out   std_logic;			-- fx3 interface clock
		     GPIFII_D : inout std_logic_vector(31 downto 0);	-- fx3 data bus
		     GPIFII_ADDR : out   std_logic_vector(4 downto 0);	-- fx3 fifo address
		     GPIFII_SLCS_N : out   std_logic;			-- fx3 fifo chip select
		     GPIFII_SLRD_N : out   std_logic;			-- fx3 fifo read enable
		     GPIFII_SLWR_N : out   std_logic;			-- fx3 fifo write enable
		     GPIFII_SLOE_N : out   std_logic;			-- fx3 fifo output enable
		     GPIFII_PKTEND_N : out   std_logic;			-- fx3 fifo packet end flag
		     GPIFII_EPSWITCH : out   std_logic;			-- fx3 endpoint switch
		     GPIFII_FLAGA : in    std_logic;			-- fx3 fifo flag
		     GPIFII_FLAGB : in    std_logic			-- fx3 fifo flag
	     );
end ADC_CTRL;

architecture Behavioral of ADC_CTRL is


	component PLL_F250 is
		port (
			     CLK_IN1           : in     std_logic;
		-- Clock out ports
			     CLK_OUT1          : out    std_logic;
			     CLK_OUT2          : out    std_logic;
			     CLK_OUT3	       : out	std_logic
		     );
	end component;

	component PLL_FX3 is
		port
		(
			CLK_IN1           : in     std_logic;
		  -- Clock out ports
			CLK_OUT1          : out    std_logic
		);
	end component;

	component PLL_DESER is
		port
		(-- Clock in ports
			CLK_IN1           : in     std_logic;
			CLKFB_IN          : in     std_logic;
		  -- Clock out ports
			CLK_OUT1          : out    std_logic;
			CLK_OUT2          : out    std_logic;
			CLKFB_OUT         : out    std_logic;
		  -- Status and control signals
			RESET             : in     std_logic;
			LOCKED            : out    std_logic
		);
	end component;

	component SREG_CONTROL is
		port (
			     RX      : in  STD_LOGIC;
			     TX      : out STD_LOGIC;
			     CLOCK   : in  STD_LOGIC;
			     RESET   : in  STD_LOGIC;
			     SPI_SEN : inout  STD_LOGIC;
			     SPI_SCK : inout  STD_LOGIC;
			     SPI_SDA : inout  STD_LOGIC;
			     SPI_DAC_SCK : inout STD_LOGIC;
			     SPI_DAC_SDA : inout STD_LOGIC;
			     SPI_DAC_A_SYNC : inout STD_LOGIC;
			     SPI_DAC_B_SYNC : inout STD_LOGIC;

			     MEM_FLAG : inout STD_LOGIC;
			     MEM_DATA : inout STD_LOGIC_VECTOR(31 downto 0);
			     INC_MEM_ADD : inout STD_LOGIC;


			     DEBUG_PIN : out STD_LOGIC;
			     DEBUG_PIN2: out STD_LOGIC
		     );
	end component;

	component BLOCKMEM is
		PORT (
			     clka : IN STD_LOGIC;
			     rsta : IN STD_LOGIC;
			     ena : IN STD_LOGIC;
			     wea : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
			     addra : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
			     dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);			     
			     douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
		     );
	end component;

	component BLOCKMEM_CTRL is
		Port ( 
			     CLOCK : in  STD_LOGIC;
			     RESET : in  STD_LOGIC;
			     MEM_FLAG : in STD_LOGIC;
			     INC_MEM_ADD : in STD_LOGIC;
			     MEMCLK : out  STD_LOGIC;
			     MEMADDR : out  STD_LOGIC_VECTOR (31 downto 0)
		     );
	end component;

	component DIGIF is
		port ( d_digif_sck : in  STD_LOGIC;
		       d_digif_rst : in  STD_LOGIC;
		       RESET	   : in  STD_LOGIC;
		       d_digif_msb_data : out  STD_LOGIC;
		       d_digif_lsb_data : out  STD_LOGIC);
	end component;

	component OPTO_SEG_IF is
	generic (
	     G_SIMULATION:               boolean:= false;                   -- simulation mode
	     C_TP:                       std_logic_vector:=x"D3D3D3D3");    -- training pattern
	port (
	     G_INVERT_MSB:               in boolean:= false;                -- invert MSB data
	     G_INVERT_LSB:               in boolean:= false;                -- invert LSB data
	     -- system signals
	     RESET:                      in  std_logic;                     -- async. reset
	     ENABLE:                     in  std_logic;                     -- module activation
	     IO_CLK:                     in  std_logic;                     -- bit clock
	     DIV_CLK:                    in  std_logic;                     -- bit clock / 4
	     BYTE_CLK:                   in  std_logic;                     -- word clock
	     SERDESSTROBE_IN:            in  std_logic;                     -- strobe to ISERDES
	     -- serial interconnect
	     DIGIF_MSB_P:                in  std_logic;                     -- MS-Byte (LVDS+)
	     DIGIF_MSB_N:                in  std_logic;                     -- MS-Byte (LVDS-)
	     DIGIF_LSB_P:                in  std_logic;                     -- LS-Byte (LVDS+)
	     DIGIF_LSB_N:                in  std_logic;                     -- LS-Byte (LVDS+)
	     -- image data interface
	     DATA:                       inout std_logic_vector(15 downto 0); -- data output
	     DATA_EN:                    inout std_logic;                     -- DATA_IN data valid
	     -- bitslip
	     I_BIT_SLIP_AUTO:		 in std_logic;		  	    -- auto bitslip
	     I_BIT_SLIP_POS:		 in std_logic_vector(1 downto 0);   -- manual bitslip pos
	     PREAMBLE:			 in std_logic_vector(5 downto 0);   -- bitslip preamble
	     d_digif_serial_rst:    	 in std_logic;		   	    -- DIGIF reset
	     CLOCK_RSTDLY:		 in std_logic;		   	    -- bitslip process clk
	     -- debug
	     DIV_CLK_CS:                 out std_logic;
	     DEBUG_IN:                   in  std_logic_vector(7 downto 0);
	     DEBUG_OUT:                  out std_logic_vector(15 downto 0));
	end component;

	component DUAL_FIFO_LINE_COMBINE is
	generic (
	     G_NBR_DATA_SEG:   integer := 8);-- Number of data segment fifo pairs
	port (
	     RESET:			in  std_logic;	-- Global system reset
	     FIFO_ENABLE:		in  std_logic;	-- Enables the fifo control arbitrer
	     --
	     WRITE_CLOCK:		in  std_logic;	-- FIFO WRITE Clock - clock used on Sensor side
	     DATA_SEG:       		in  T_DATA_SEG(0 to G_NBR_DATA_SEG-1); -- Segment Data
	     LVAL_IN:			in  std_logic_vector(G_NBR_DATA_SEG-1 downto 0); -- LVAL signals from all segmants
	     --
	     READ_CLOCK:		in  std_logic;  -- FIFO READ Clock - clock used on Camera Link side
	     DATA_LINE_OUT:		out std_logic_vector(15 downto 0); -- Output DATA from fifo to Camera Link
	     FVAL_OUT:			out std_logic;
	     LVAL_OUT:			out std_logic; -- Output LVAL from fifo to Camera Link
	     DEBUG_OUT:      		out std_logic_vector(1 downto 0) -- Debug output
	);
	end component;

	component FX3_SLAVE is
	port (	CLOCK : in  std_logic;
             RESET : in  std_logic;
             CLOCK_IMG : in std_logic;
             LED   : out std_logic;
             FVAL_IN : in std_logic;
             LVAL_IN : in std_logic;
             DATA_IN : in std_logic_vector(15 downto 0);
       -- FX3 GPIFII Interface
             GPIFII_PCLK : out   std_logic;			-- fx3 interface clock
             GPIFII_D : inout std_logic_vector(31 downto 0);	-- fx3 data bus
             GPIFII_ADDR : out   std_logic_vector(4 downto 0);	-- fx3 fifo address
             GPIFII_SLCS_N : out   std_logic;			-- fx3 fifo chip select
             GPIFII_SLRD_N : out   std_logic;			-- fx3 fifo read enable
             GPIFII_SLWR_N : out   std_logic;			-- fx3 fifo write enable
             GPIFII_SLOE_N : out   std_logic;			-- fx3 fifo output enable
             GPIFII_PKTEND_N : out   std_logic;			-- fx3 fifo packet end flag
             GPIFII_EPSWITCH : out   std_logic;			-- fx3 endpoint switch
             GPIFII_FLAGA : in    std_logic;			-- fx3 fifo flag
             GPIFII_FLAGB : in    std_logic			-- fx3 fifo flag
	       );
	end component;

	signal CLOCK_I 	 : std_logic;
	signal CLOCK_100 : std_logic;
	signal CLOCK_200 : std_logic;
	signal CLOCK_250 : std_logic;
	signal CLOCK_100_PCLK : std_logic;
	signal CLOCK_100_PCLK_N : std_logic;
	signal FX3_CLK	 : std_logic;

	signal MEMCLK    : std_logic;
	signal MEMDATA   : std_logic_vector(31 downto 0);
	signal MEMADDR   : std_logic_vector(31 downto 0);
	signal MEM_DINA	 : std_logic_vector(31 downto 0);
	signal MEM_FLAG	 : std_logic;
	signal MEM_WEA	 : std_logic_vector(3 downto 0);
	signal INC_MEM_ADD : std_logic;

	signal PLL_DESER_FB : std_logic;
	signal PLL_DESER_LOCKED : std_logic;
	signal IO_CLK_BANK2 : std_logic;
	signal BUFPLL_LOCKED_BANK2 : std_logic;
	signal SERDESSTROBE_BANK2 : std_logic;
	signal CLOCK_DESER_1BIT : std_logic;
	signal CLOCK_DESER_6BIT : std_logic;
	signal CLOCK_DESER_WORD : std_logic; 

	signal DESER_DATA_G0 : std_logic_vector(15 downto 0);
	signal DESER_DATA_G1 : std_logic_vector(15 downto 0);
	signal DESER_DATA_G2 : std_logic_vector(15 downto 0);
	signal DESER_DATA_G3 : std_logic_vector(15 downto 0);
	signal DESER_DATA_G4 : std_logic_vector(15 downto 0);
	signal DESER_DATA_G5 : std_logic_vector(15 downto 0);
	signal DESER_DATA_G6 : std_logic_vector(15 downto 0);
	signal DESER_DATA_G7 : std_logic_vector(15 downto 0);
	signal IMAGE_DATA_OUT: std_logic_vector(15 downto 0);
	signal CLOCK_COUNT_OBUFDS : std_logic;
	signal CLOCK_DIGIF_OBUFDS : std_logic;
	signal FVAL_SEQ  : std_logic;
	signal LVAL_SEQ  : std_logic;
	signal LVAL_SEQ_OLD :std_logic;
	signal LVAL_DLY  : std_logic_vector(7 downto 0);
	signal FVAL_OUT	 : std_logic;
	signal LVAL_OUT  : std_logic;
	signal ROW_NEXT  : std_logic;
	signal LSBDAT	 : std_logic;
	signal MSBDAT	 : std_logic;
	signal LSBDAT_N	 : std_logic;
	signal MSBDAT_N	 : std_logic;

--|--------------------------|
--| UART Testbench Constants |
--|--------------------------|
--	-- Test Bench uses a 100 MHz Clock
--	constant c_CLK_PERIOD : time := 10 ns;
--	
--	-- Want to interface to 2400 baud UART
--	-- 25000000 / 2400 = 10417 Clocks Per Bit.
--	constant c_CLKS_PER_BIT : integer := 10417;
--	
--	-- 1/2400:
--	constant c_BIT_PERIOD : time := 416.666 us;
--	
--	signal Test_RX_Serial : std_logic := '1';
--	
--	
--	-- Low-level byte-write
--	procedure UART_WRITE_BYTE (
--	  i_Data_In       : in  std_logic_vector(7 downto 0);
--	  signal o_Serial : out std_logic) is
--	begin
--	
--	  -- Send Start Bit
--	  o_Serial <= '0';
--	  wait for c_BIT_PERIOD;
--	
--	  -- Send Data Byte
--	  for ii in 0 to 7 loop
--	    o_Serial <= i_Data_In(ii);
--	    wait for c_BIT_PERIOD;
--	  end loop;  -- ii
--	
--	  -- Send Stop Bit
--	  o_Serial <= '1';
--	  wait for c_BIT_PERIOD;
--	end UART_WRITE_BYTE;
 
begin

--|----------------------|
--| Instantiate PLL Core |
--|----------------------|

--	RESET_BUFFER : IBUFG
--	port map (
--	O => RESET,
--	I => RESET_IN
--	);

--	RST_PROC : process(CLOCK_I)
--	begin
--		if (rising_edge(CLOCK_I)) then
--			RESET_IMM <= RESET_IN;
--		end if;
--	end process;
--	
--	RESET <= RESET_IMM or RESET_IN;

	PAD_CLOCK_BUFFER : IBUFG
	port map (
			 O => CLOCK_I,
			 I => CLOCK
		 );

	PLL_250_INST: PLL_F250
	port map (
			 CLK_IN1           => CLOCK_I,
	-- Clock out ports
			 CLK_OUT1          => CLOCK_100,
			 CLK_OUT2          => CLOCK_250,
			 CLK_OUT3	   => CLOCK_200
		 );


	PLL_FX3_INST: PLL_FX3
	port map (
			 CLK_IN1         => GPIFII_PCLK_IN, 
	  -- Clock out ports
			 CLK_OUT1        => FX3_CLK
		 );
	--	FX3_CLK <= GPIFII_PCLK_IN;

	PLL_DESER_INST: PLL_DESER
	port map (-- Clock in ports
			 CLK_IN1 => CLOCK_I,
			 CLKFB_IN => PLL_DESER_FB,
	-- Clock out ports
			 CLK_OUT1 => CLOCK_DESER_1BIT,
			 CLK_OUT2 => CLOCK_DESER_6BIT,
			 CLKFB_OUT => PLL_DESER_FB,
	-- Status and control signals
			 RESET  => '0',
			 LOCKED => PLL_DESER_LOCKED
		 );

	CLOCK_DESER_WORD <= CLOCK_DESER_6BIT;

	-- End of PLL Core instantiation

	I_BUFPLL_BANK2: BUFPLL
	generic map (
	    		DIVIDE                      => 6)
	port map (
			IOCLK                       => IO_CLK_BANK2,	-- Deser 1bit output clock
			LOCK                        => BUFPLL_LOCKED_BANK2, -- Synchr Lock output
			SERDESSTROBE                => SERDESSTROBE_BANK2, -- SERDES Strobe signal
			GCLK                        => CLOCK_DESER_6BIT,
			LOCKED                      => PLL_DESER_LOCKED,
			PLLIN                       => CLOCK_DESER_1BIT
		 );

   -- End BUFPLL Core instantiation

--|---------------------------------|
--| Test LVDS drivers and Receivers |
--|---------------------------------|

	ODDR2_LSBDATTX_INST : ODDR2
	generic map(
			 DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1" 
			 INIT => '0', -- Sets initial state of the Q output to '0' or '1'
			 SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
	port map (
			 Q  => CLOCK_DIGIF_OBUFDS, -- 1-bit output data
			 C0 => LSBDAT, -- 1-bit clock input
			 C1 => LSBDAT_N, -- 1-bit clock input
			 CE => '1',   -- 1-bit clock enable input
			 D0 => '0',   -- 1-bit data input (associated with C0)
			 D1 => '1',   -- 1-bit data input (associated with C1)
			 R => RESET,  -- 1-bit reset input
			 S => '0'     -- 1-bit set input
		 ); 

	OBUFDS_LSBDAT_TX : OBUFDS
	generic map (
			 IOSTANDARD => "LVDS_33")
	port map (
			 O => SRX_N,     -- Diff_p output (connect directly to top-level port)
			 OB => SRX_P,    -- Diff_n output (connect directly to top-level port)
			 I => CLOCK_DIGIF_OBUFDS  -- Buffer input
		 );


--|------------------------------------------------|
--| OBUFDS: Differential Output Count Clock Buffer |
--|------------------------------------------------|

	ODDR2_LVDS_CLOC_BUFFER_OUT_INST : ODDR2
	generic map(
			 DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1" 
			 INIT => '0', -- Sets initial state of the Q output to '0' or '1'
			 SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
	port map (
			 Q  => CLOCK_COUNT_OBUFDS, -- 1-bit output data
			 C0 => MSBDAT, -- 1-bit clock input
			 C1 => MSBDAT_N, -- 1-bit clock input
			 CE => '1',   -- 1-bit clock enable input
			 D0 => '0',   -- 1-bit data input (associated with C0)
			 D1 => '1',   -- 1-bit data input (associated with C1)
			 R => RESET,  -- 1-bit reset input
			 S => '0'     -- 1-bit set input
		 );

	OBUFDS_COUNT_CLK : OBUFDS
	generic map (
			 IOSTANDARD => "LVDS_33")
	port map (
			 O => COUNT_CLK_N,     -- Diff_p output (connect directly to top-level port)
			 OB => COUNT_CLK_P,    -- Diff_n output (connect directly to top-level port)
			 I => CLOCK_COUNT_OBUFDS -- Buffer input 
		 );

-- End of OBUFDS_inst instantiation

--|----------------------------------------------------|
--| OBUFDS: Differential Digif Serializer Clock Buffer |
--|----------------------------------------------------|

--  ODDR2_LVDS_CLOC_DIGIF_BUFFER_OUT_INST : ODDR2
--  generic map(
--     DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1" 
--     INIT => '0', -- Sets initial state of the Q output to '0' or '1'
--     SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
--  port map (
--     Q  => CLOCK_DIGIF_OBUFDS, -- 1-bit output data
--     C0 => CLOCK_100, -- 1-bit clock input
--     C1 => not CLOCK_100, -- 1-bit clock input
--     CE => '1',   -- 1-bit clock enable input
--     D0 => '0',   -- 1-bit data input (associated with C0)
--     D1 => '1',   -- 1-bit data input (associated with C1)
--     R => RESET,  -- 1-bit reset input
--     S => '0'     -- 1-bit set input
--  ); 
--
--  OBUFDS_DIGIF_CLK : OBUFDS
--  generic map (
--     IOSTANDARD => "LVDS_33")
--  port map (
--     O => SRX_N,     -- Diff_p output (connect directly to top-level port)
--     OB => SRX_P,    -- Diff_n output (connect directly to top-level port)
--     I => CLOCK_DIGIF_OBUFDS  -- Buffer input
--  );

-- End of OBUFDS_inst instantiation

--|--------------------|
--| GROUP 0 DATA IBUFF |
--|--------------------|

--   IBUFDS_DIGIF_LSB_G0 : IBUFGDS
--   generic map (
--      DIFF_TERM => TRUE, -- Differential Termination 
--      IBUF_LOW_PWR => FALSE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
--      IOSTANDARD => "LVDS_33")
--   port map (
--      O 		=> G0LTX,  -- Buffer output
--      I 		=> G0LTX_P,
--      IB 		=> G0LTX_N
--   );
-- 
--   IBUFDS_DIGIF_MSB_G0 : IBUFGDS
--   generic map (
--      DIFF_TERM => TRUE, -- Differential Termination 
--      IBUF_LOW_PWR => FALSE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
--      IOSTANDARD => "LVDS_33")
--   port map (
--      O 		=> G0HTX,  -- Buffer output
--      I 		=> G0HTX_P,
--      IB 		=> G0HTX_N
--   );


--|----------------------------|
--| Instantiating SREG_CONTROL |
--|----------------------------|

--	TEST_PROC : process
--	begin
--	wait until rising_edge(CLOCK_100);
--	wait for 10 us;
--		UART_WRITE_BYTE(X"AE", Test_RX_Serial);
--	wait for 500 us;
--		UART_WRITE_BYTE(X"01", Test_RX_Serial);
--	wait for 500 us;
--		UART_WRITE_BYTE(X"02", Test_RX_Serial);
--	wait for 500 us;
--		UART_WRITE_BYTE(X"03", Test_RX_Serial);
--	wait for 500 us;
--		UART_WRITE_BYTE(X"04", Test_RX_Serial);
--	wait for 500 us;
--		UART_WRITE_BYTE(X"05", Test_RX_Serial);
--	wait for 500 us;
--		UART_WRITE_BYTE(X"06", Test_RX_Serial);
--	wait for 500 us;
--		UART_WRITE_BYTE(X"07", Test_RX_Serial);
--	wait for 500 us;
--		UART_WRITE_BYTE(X"08", Test_RX_Serial);
--	wait for 500 us;
--		UART_WRITE_BYTE(X"09", Test_RX_Serial);
--	wait for 500 us;
--		UART_WRITE_BYTE(X"10", Test_RX_Serial);
--	wait for 500 us;
--		UART_WRITE_BYTE(X"11", Test_RX_Serial);
--	wait for 500 us;
--		UART_WRITE_BYTE(X"12", Test_RX_Serial);
--	wait for 500 us;
--		UART_WRITE_BYTE(X"13", Test_RX_Serial);
--	wait for 500 us;
--		UART_WRITE_BYTE(X"14", Test_RX_Serial);
--	wait for 500 us;
--		UART_WRITE_BYTE(X"15", Test_RX_Serial);
--	wait for 500 us;
--		UART_WRITE_BYTE(X"16", Test_RX_Serial);
--	wait for 500 us;
--		UART_WRITE_BYTE(X"AF", Test_RX_Serial);
--	wait for 10 us;
--	wait until rising_edge(CLOCK_100);
--	end process;

	SREG_CONTROL_INST: SREG_CONTROL
	port map (
			 RX => RX, --Test_RX_Serial, --RX,
			 TX => TX,
			 CLOCK => CLOCK_100,
			 RESET => RESET,
			 SPI_SEN => SPI_SEN,
			 SPI_SCK => SPI_SCK,
			 SPI_SDA => SPI_SDA,
			 SPI_DAC_SCK => SPI_DAC_SCK,
			 SPI_DAC_SDA => SPI_DAC_SDA,
			 SPI_DAC_A_SYNC => SPI_DAC_A_SYNC,
			 SPI_DAC_B_SYNC => SPI_DAC_B_SYNC,
			 MEM_FLAG => MEM_FLAG,
			 MEM_DATA => MEM_DINA,
			 INC_MEM_ADD => INC_MEM_ADD,
			 DEBUG_PIN => GPIO1,
			 DEBUG_PIN2 => GPIO2
		 );

-- End of SREG_CONTROL instantiation

--|-------------------------|
--| Instantiating SEQUENCER |
--|-------------------------|

	MEM_WEA <= MEM_FLAG & MEM_FLAG & MEM_FLAG & MEM_FLAG;

	BLOCKMEM_INST : BLOCKMEM
	port map (
			 clka => MEMCLK,
			 rsta => RESET,
			 ena  => '1',
			 wea => MEM_WEA,
			 addra => MEMADDR,
			 dina => MEM_DINA,
			 douta => MEMDATA
		 );


	BLOCKMEM_CTRL_INST : BLOCKMEM_CTRL

	port map ( 
			 CLOCK => CLOCK_100,
			 RESET => RESET,
			 MEM_FLAG => MEM_FLAG,
			 INC_MEM_ADD => INC_MEM_ADD,
			 MEMCLK => MEMCLK,
			 MEMADDR => MEMADDR
		 );

	d_row_rs <= MEMDATA(31);
	d_row_rst <= MEMDATA(30);
	d_row_tx <= MEMDATA(29);
	d_col_vln_sh <= MEMDATA(28);
	ROW_NEXT <= MEMDATA(27);
	d_shr <= MEMDATA(26);
	d_shs <= MEMDATA(25);
	d_ads <= MEMDATA(24);
	d_adr <= MEMDATA(23);
	d_comp_bias_sh <= MEMDATA(22);
	d_comp_dyn_pon <= MEMDATA(21);
	d_count_en <= MEMDATA(20);
	d_count_rst <= MEMDATA(19);
	d_count_inv_clk <= MEMDATA(18);
	d_count_hold <= MEMDATA(17);
	d_count_updn <= MEMDATA(16);
	d_count_inc_one <= MEMDATA(15);
	d_count_jc_shift_en <= MEMDATA(14);
	d_count_lsb_en <= MEMDATA(13);
	d_count_lsb_clk <= MEMDATA(12);
	d_count_mem_wr <= MEMDATA(11);
	d_ref_vref_ramp_rst <= MEMDATA(10);
	d_ref_vref_sh <= MEMDATA(9);
	d_ref_vref_clamp_en <= MEMDATA(8);
	d_ref_vref_ramp_ota_dyn_pon <= MEMDATA(7);
--	d_digif_serial_rst <= MEMDATA(6);
	FVAL_SEQ <= MEMDATA(5);
	LVAL_SEQ <= MEMDATA(4);
	d_row_addr(7 downto 0) <= "00000000";

	GENERATE_DIGIF_RST_LVAL_PROC: process(RESET, CLOCK_100)
		variable digif_rst_cnt: integer range 0 to 1023 :=0;
		variable stflag: integer range 0 to 1 :=0;
		variable skip_clks: integer range 0 to 127 :=0;
		constant sdrat : integer := 3; -- serial f/3
		begin
		if RESET = '1' then
			digif_rst_cnt := 0;
			d_digif_serial_rst <= '1';
			stflag := 0;
			LVAL_DLY <= (others => '0');
			skip_clks :=0;
		elsif (rising_edge(CLOCK_100)) then

			if (LVAL_SEQ = '1' and LVAL_SEQ_OLD = '0') or (stflag = 1) then
				if digif_rst_cnt = ((134*sdrat)+2) then	-- 134-6=128 words + offset 2
					digif_rst_cnt := 0;
					d_digif_serial_rst <= '1';
					stflag := 0;
					LVAL_DLY <= (others => '0');
					skip_clks := 0;
				else
					d_digif_serial_rst <= '0';
					digif_rst_cnt := digif_rst_cnt + 1;
					stflag := 1;
				end if;

				if skip_clks = ((6*sdrat)+2) then	-- skip 6 words, fill deser + imageout pipeline + offset
					LVAL_DLY <= (others => '1');
				else
				skip_clks := skip_clks + 1;
				end if;
			end if;
			LVAL_SEQ_OLD <= LVAL_SEQ;
		end if;
	end process;

--|-----------------|
--| MOCK SERIALIZER |
--|-----------------|

	DIGIF_INST : DIGIF
	port map ( 
			 d_digif_sck => CLOCK_200,
			 d_digif_rst => d_digif_serial_rst,
			 RESET    => RESET,
			 d_digif_msb_data => MSBDAT,
			 d_digif_lsb_data => LSBDAT);
	MSBDAT_N <= not MSBDAT;
	LSBDAT_N <= not LSBDAT;

--|---------------|
--| DESERIALIZERS |
--|---------------|

	G0TX_DESER_INST : OPTO_SEG_IF
	generic map (
		 G_SIMULATION           => false,			-- simulation mode
		 C_TP                   => x"D3D3D3D3")			-- training pattern
	port map (
		 G_INVERT_MSB           => false,			-- invert MSB sensor data
		 G_INVERT_LSB           => false,			-- invert LSB sensor data
	 	-- system signals
		 RESET                  => RESET,  -- async. reset
		 ENABLE                 => '1',				-- module activation
		 IO_CLK                 => IO_CLK_BANK2,		-- bit clock
		 DIV_CLK                => CLOCK_DESER_6BIT,		-- bit clock / 6
		 BYTE_CLK               => CLOCK_DESER_WORD,		-- word clock
		 SERDESSTROBE_IN        => SERDESSTROBE_BANK2,		-- strobe to ISERDES
									-- serial interconnect
		 DIGIF_MSB_P            => G0HTX_P,			-- MS-Byte (LVDS+)
		 DIGIF_MSB_N            => G0HTX_N,			-- MS-Byte (LVDS-)
		 DIGIF_LSB_P            => G0LTX_P,			-- LS-Byte (LVDS+)
		 DIGIF_LSB_N            => G0LTX_N,			-- LS-Byte (LVDS+)
	       -- image data interface
		 DATA                   => DESER_DATA_G0,		-- data output
		 DATA_EN                => open,			-- DATA_IN data valid
		 -- bitslip
		 I_BIT_SLIP_AUTO	=> '1',
		 I_BIT_SLIP_POS		=> "00",
		 PREAMBLE		=> "101011",
		 d_digif_serial_rst	=> d_digif_serial_rst,
		 CLOCK_RSTDLY		=> CLOCK_100,
	       -- debug
		 DIV_CLK_CS             => open,
		 DEBUG_IN               => "00000000", --DEBUG_OPTO_SEG_IF,
		 DEBUG_OUT              => open);

	G1TX_DESER_INST : OPTO_SEG_IF
	generic map (
		 G_SIMULATION           => false,			-- simulation mode
		 C_TP                   => x"D3D3D3D3")			-- training pattern
	port map (
		 G_INVERT_MSB           => false,			-- invert MSB sensor data
		 G_INVERT_LSB           => false,			-- invert LSB sensor data
	 	-- system signals
		 RESET                  => RESET,  -- async. reset
		 ENABLE                 => '1',				-- module activation
		 IO_CLK                 => IO_CLK_BANK2,		-- bit clock
		 DIV_CLK                => CLOCK_DESER_6BIT,		-- bit clock / 6
		 BYTE_CLK               => CLOCK_DESER_WORD,		-- word clock
		 SERDESSTROBE_IN        => SERDESSTROBE_BANK2,		-- strobe to ISERDES
									-- serial interconnect
		 DIGIF_MSB_P            => G1HTX_P,			-- MS-Byte (LVDS+)
		 DIGIF_MSB_N            => G1HTX_N,			-- MS-Byte (LVDS-)
		 DIGIF_LSB_P            => G1LTX_P,			-- LS-Byte (LVDS+)
		 DIGIF_LSB_N            => G1LTX_N,			-- LS-Byte (LVDS+)
	       -- image data interface
		 DATA                   => DESER_DATA_G1,		-- data output
		 DATA_EN                => open,			-- DATA_IN data valid
		 -- bitslip
		 I_BIT_SLIP_AUTO	=> '1',
		 I_BIT_SLIP_POS		=> "00",
		 PREAMBLE		=> "101011",
		 d_digif_serial_rst	=> d_digif_serial_rst,
		 CLOCK_RSTDLY		=> CLOCK_100,
	       -- debug
		 DIV_CLK_CS             => open,
		 DEBUG_IN               => "00000000", --DEBUG_OPTO_SEG_IF,
		 DEBUG_OUT              => open);

	G2TX_DESER_INST : OPTO_SEG_IF
	generic map (
		 G_SIMULATION           => false,			-- simulation mode
		 C_TP                   => x"D3D3D3D3")			-- training pattern
	port map (
		 G_INVERT_MSB           => false,			-- invert MSB sensor data
		 G_INVERT_LSB           => false,			-- invert LSB sensor data
	 	-- system signals
		 RESET                  => RESET,  -- async. reset
		 ENABLE                 => '1',				-- module activation
		 IO_CLK                 => IO_CLK_BANK2,		-- bit clock
		 DIV_CLK                => CLOCK_DESER_6BIT,		-- bit clock / 6
		 BYTE_CLK               => CLOCK_DESER_WORD,		-- word clock
		 SERDESSTROBE_IN        => SERDESSTROBE_BANK2,		-- strobe to ISERDES
									-- serial interconnect
		 DIGIF_MSB_P            => G2HTX_P,			-- MS-Byte (LVDS+)
		 DIGIF_MSB_N            => G2HTX_N,			-- MS-Byte (LVDS-)
		 DIGIF_LSB_P            => G2LTX_P,			-- LS-Byte (LVDS+)
		 DIGIF_LSB_N            => G2LTX_N,			-- LS-Byte (LVDS+)
	       -- image data interface
		 DATA                   => DESER_DATA_G2,		-- data output
		 DATA_EN                => open,			-- DATA_IN data valid
		 -- bitslip
		 I_BIT_SLIP_AUTO	=> '1',
		 I_BIT_SLIP_POS		=> "00",
		 PREAMBLE		=> "101011",
		 d_digif_serial_rst	=> d_digif_serial_rst,
		 CLOCK_RSTDLY		=> CLOCK_100,
	       -- debug
		 DIV_CLK_CS             => open,
		 DEBUG_IN               => "00000000", --DEBUG_OPTO_SEG_IF,
		 DEBUG_OUT              => open);

	G3TX_DESER_INST : OPTO_SEG_IF
	generic map (
		 G_SIMULATION           => false,			-- simulation mode
		 C_TP                   => x"D3D3D3D3")			-- training pattern
	port map (
		 G_INVERT_MSB           => false,			-- invert MSB sensor data
		 G_INVERT_LSB           => false,			-- invert LSB sensor data
	 	-- system signals
		 RESET                  => RESET,  -- async. reset
		 ENABLE                 => '1',				-- module activation
		 IO_CLK                 => IO_CLK_BANK2,		-- bit clock
		 DIV_CLK                => CLOCK_DESER_6BIT,		-- bit clock / 6
		 BYTE_CLK               => CLOCK_DESER_WORD,		-- word clock
		 SERDESSTROBE_IN        => SERDESSTROBE_BANK2,		-- strobe to ISERDES
									-- serial interconnect
		 DIGIF_MSB_P            => G3HTX_P,			-- MS-Byte (LVDS+)
		 DIGIF_MSB_N            => G3HTX_N,			-- MS-Byte (LVDS-)
		 DIGIF_LSB_P            => G3LTX_P,			-- LS-Byte (LVDS+)
		 DIGIF_LSB_N            => G3LTX_N,			-- LS-Byte (LVDS+)
	       -- image data interface
		 DATA                   => DESER_DATA_G3,		-- data output
		 DATA_EN                => open,			-- DATA_IN data valid
		 -- bitslip
		 I_BIT_SLIP_AUTO	=> '1',
		 I_BIT_SLIP_POS		=> "00",
		 PREAMBLE		=> "101011",
		 d_digif_serial_rst	=> d_digif_serial_rst,
		 CLOCK_RSTDLY		=> CLOCK_100,
	       -- debug
		 DIV_CLK_CS             => open,
		 DEBUG_IN               => "00000000", --DEBUG_OPTO_SEG_IF,
		 DEBUG_OUT              => open);

	G4TX_DESER_INST : OPTO_SEG_IF
	generic map (
		 G_SIMULATION           => false,			-- simulation mode
		 C_TP                   => x"D3D3D3D3")			-- training pattern
	port map (
		 G_INVERT_MSB           => false,			-- invert MSB sensor data
		 G_INVERT_LSB           => false,			-- invert LSB sensor data
	 	-- system signals
		 RESET                  => RESET,  -- async. reset
		 ENABLE                 => '1',				-- module activation
		 IO_CLK                 => IO_CLK_BANK2,		-- bit clock
		 DIV_CLK                => CLOCK_DESER_6BIT,		-- bit clock / 6
		 BYTE_CLK               => CLOCK_DESER_WORD,		-- word clock
		 SERDESSTROBE_IN        => SERDESSTROBE_BANK2,		-- strobe to ISERDES
									-- serial interconnect
		 DIGIF_MSB_P            => G4HTX_P,			-- MS-Byte (LVDS+)
		 DIGIF_MSB_N            => G4HTX_N,			-- MS-Byte (LVDS-)
		 DIGIF_LSB_P            => G4LTX_P,			-- LS-Byte (LVDS+)
		 DIGIF_LSB_N            => G4LTX_N,			-- LS-Byte (LVDS+)
	       -- image data interface
		 DATA                   => DESER_DATA_G4,		-- data output
		 DATA_EN                => open,			-- DATA_IN data valid
		 -- bitslip
		 I_BIT_SLIP_AUTO	=> '1',
		 I_BIT_SLIP_POS		=> "00",
		 PREAMBLE		=> "101011",
		 d_digif_serial_rst	=> d_digif_serial_rst,
		 CLOCK_RSTDLY		=> CLOCK_100,
	       -- debug
		 DIV_CLK_CS             => open,
		 DEBUG_IN               => "00000000", --DEBUG_OPTO_SEG_IF,
		 DEBUG_OUT              => open);

	G5TX_DESER_INST : OPTO_SEG_IF
	generic map (
		 G_SIMULATION           => false,			-- simulation mode
		 C_TP                   => x"D3D3D3D3")			-- training pattern
	port map (
		 G_INVERT_MSB           => false,			-- invert MSB sensor data
		 G_INVERT_LSB           => false,			-- invert LSB sensor data
	 	-- system signals
		 RESET                  => RESET,  -- async. reset
		 ENABLE                 => '1',				-- module activation
		 IO_CLK                 => IO_CLK_BANK2,		-- bit clock
		 DIV_CLK                => CLOCK_DESER_6BIT,		-- bit clock / 6
		 BYTE_CLK               => CLOCK_DESER_WORD,		-- word clock
		 SERDESSTROBE_IN        => SERDESSTROBE_BANK2,		-- strobe to ISERDES
									-- serial interconnect
		 DIGIF_MSB_P            => G5HTX_P,			-- MS-Byte (LVDS+)
		 DIGIF_MSB_N            => G5HTX_N,			-- MS-Byte (LVDS-)
		 DIGIF_LSB_P            => G5LTX_P,			-- LS-Byte (LVDS+)
		 DIGIF_LSB_N            => G5LTX_N,			-- LS-Byte (LVDS+)
	       -- image data interface
		 DATA                   => DESER_DATA_G5,		-- data output
		 DATA_EN                => open,			-- DATA_IN data valid
		 -- bitslip
		 I_BIT_SLIP_AUTO	=> '1',
		 I_BIT_SLIP_POS		=> "00",
		 PREAMBLE		=> "101011",
		 d_digif_serial_rst	=> d_digif_serial_rst,
		 CLOCK_RSTDLY		=> CLOCK_100,
	       -- debug
		 DIV_CLK_CS             => open,
		 DEBUG_IN               => "00000000", --DEBUG_OPTO_SEG_IF,
		 DEBUG_OUT              => open);

	G6TX_DESER_INST : OPTO_SEG_IF
	generic map (
		 G_SIMULATION           => false,			-- simulation mode
		 C_TP                   => x"D3D3D3D3")			-- training pattern
	port map (
		 G_INVERT_MSB           => false,			-- invert MSB sensor data
		 G_INVERT_LSB           => false,			-- invert LSB sensor data
	 	-- system signals
		 RESET                  => RESET,  -- async. reset
		 ENABLE                 => '1',				-- module activation
		 IO_CLK                 => IO_CLK_BANK2,		-- bit clock
		 DIV_CLK                => CLOCK_DESER_6BIT,		-- bit clock / 6
		 BYTE_CLK               => CLOCK_DESER_WORD,		-- word clock
		 SERDESSTROBE_IN        => SERDESSTROBE_BANK2,		-- strobe to ISERDES
									-- serial interconnect
		 DIGIF_MSB_P            => G6HTX_P,			-- MS-Byte (LVDS+)
		 DIGIF_MSB_N            => G6HTX_N,			-- MS-Byte (LVDS-)
		 DIGIF_LSB_P            => G6LTX_P,			-- LS-Byte (LVDS+)
		 DIGIF_LSB_N            => G6LTX_N,			-- LS-Byte (LVDS+)
	       -- image data interface
		 DATA                   => DESER_DATA_G6,		-- data output
		 DATA_EN                => open,			-- DATA_IN data valid
		 -- bitslip
		 I_BIT_SLIP_AUTO	=> '1',
		 I_BIT_SLIP_POS		=> "00",
		 PREAMBLE		=> "101011",
		 d_digif_serial_rst	=> d_digif_serial_rst,
		 CLOCK_RSTDLY		=> CLOCK_100,
	       -- debug
		 DIV_CLK_CS             => open,
		 DEBUG_IN               => "00000000", --DEBUG_OPTO_SEG_IF,
		 DEBUG_OUT              => open);

	G7TX_DESER_INST : OPTO_SEG_IF
	generic map (
		 G_SIMULATION           => false,			-- simulation mode
		 C_TP                   => x"D3D3D3D3")			-- training pattern
	port map (
		 G_INVERT_MSB           => false,			-- invert MSB sensor data
		 G_INVERT_LSB           => false,			-- invert LSB sensor data
	 	-- system signals
		 RESET                  => RESET,  -- async. reset
		 ENABLE                 => '1',				-- module activation
		 IO_CLK                 => IO_CLK_BANK2,		-- bit clock
		 DIV_CLK                => CLOCK_DESER_6BIT,		-- bit clock / 6
		 BYTE_CLK               => CLOCK_DESER_WORD,		-- word clock
		 SERDESSTROBE_IN        => SERDESSTROBE_BANK2,		-- strobe to ISERDES
									-- serial interconnect
		 DIGIF_MSB_P            => G7HTX_P,			-- MS-Byte (LVDS+)
		 DIGIF_MSB_N            => G7HTX_N,			-- MS-Byte (LVDS-)
		 DIGIF_LSB_P            => G7LTX_P,			-- LS-Byte (LVDS+)
		 DIGIF_LSB_N            => G7LTX_N,			-- LS-Byte (LVDS+)
	       -- image data interface
		 DATA                   => DESER_DATA_G7,		-- data output
		 DATA_EN                => open,			-- DATA_IN data valid
		 -- bitslip
		 I_BIT_SLIP_AUTO	=> '1',
		 I_BIT_SLIP_POS		=> "00",
		 PREAMBLE		=> "101011",
		 d_digif_serial_rst	=> d_digif_serial_rst,
		 CLOCK_RSTDLY		=> CLOCK_100,
	       -- debug
		 DIV_CLK_CS             => open,
		 DEBUG_IN               => "00000000", --DEBUG_OPTO_SEG_IF,
		 DEBUG_OUT              => open);

--|------------|
--| Frame FIFO |
--|------------|

	I_DUAL_FIFO_LINE_COMBINE : DUAL_FIFO_LINE_COMBINE
	generic map (
         	G_NBR_DATA_SEG 		=> 8)	-- Number of data segment fifo pairs
        port map (
	  	RESET			=> RESET,             
          	FIFO_ENABLE		=> '1', -- active when the sensor becomes active
          --
		WRITE_CLOCK		=> CLOCK_DESER_WORD,
		DATA_SEG(0)		=> DESER_DATA_G0,
		DATA_SEG(1)		=> "0000000000000001", -- DESER_DATA_G1,
		DATA_SEG(2)		=> "0000000000000010", -- DESER_DATA_G2,
		DATA_SEG(3)		=> "0000000000000100", -- DESER_DATA_G3,
		DATA_SEG(4)		=> "0000000000001000", -- DESER_DATA_G4,
		DATA_SEG(5)		=> "0000000000010000", -- DESER_DATA_G5,
		DATA_SEG(6)		=> "0000000000100000", -- DESER_DATA_G6,
		DATA_SEG(7)		=> "0000000001000000", -- DESER_DATA_G7,
		LVAL_IN			=> LVAL_DLY,
	--
		READ_CLOCK		=> CLOCK_100,
		DATA_LINE_OUT		=> IMAGE_DATA_OUT,
		FVAL_OUT		=> FVAL_OUT,
		LVAL_OUT		=> LVAL_OUT,
		DEBUG_OUT		=> open
		);

--|----------------------------------------|
--| Instantiating IMAGE_OUT and FX3 DRIVER |
--|----------------------------------------|

	FX3_SLAVE_INST : FX3_SLAVE 
	port map (	
			 CLOCK 			=> FX3_CLK,
			 RESET 			=> RESET,
			 CLOCK_IMG		=> CLOCK_100, --CLOCK_DESER_WORD,
			 LED   			=> open,
			 FVAL_IN 		=> FVAL_SEQ,
			 LVAL_IN		=> LVAL_OUT,
			 DATA_IN		=> IMAGE_DATA_OUT,
		     -- FX3 GPIFII Interface
			 GPIFII_PCLK		=> open, --GPIFII_PCLK,	-- fx3 interface clock
			 GPIFII_D		=> GPIFII_D,		-- fx3 data bus
			 GPIFII_ADDR		=> GPIFII_ADDR,		-- fx3 fifo address
			 GPIFII_SLCS_N		=> GPIFII_SLCS_N,	-- fx3 fifo chip select
			 GPIFII_SLRD_N		=> GPIFII_SLRD_N,	-- fx3 fifo read enable
			 GPIFII_SLWR_N		=> GPIFII_SLWR_N,	-- fx3 fifo write enable
			 GPIFII_SLOE_N		=> GPIFII_SLOE_N,	-- fx3 fifo output enable
			 GPIFII_PKTEND_N	=> GPIFII_PKTEND_N,	-- fx3 fifo packet end flag
			 GPIFII_EPSWITCH	=> GPIFII_EPSWITCH,	-- fx3 endpoint switch
			 GPIFII_FLAGA		=> GPIFII_FLAGA,	-- fx3 fifo flag
			 GPIFII_FLAGB		=> GPIFII_FLAGB		-- fx3 fifo flag
		 );

-- Feeding out USB PCLK (GPIFII_PCLK)

--	CLOCK_100_BUFG : BUFG
--	port map (
--			 O	=> CLOCK_100_PCLK,
--			 I	=> CLOCK_100);
	CLOCK_100_PCLK <= CLOCK_100;

	CLOCK_100_PCLK_N <= not CLOCK_100_PCLK;

	ODDR2_GPIFII_PCLK : ODDR2
	generic map(
			   DDR_ALIGNMENT => "C0", -- Sets output alignment to "NONE", "C0", "C1" 
			   INIT => '0', -- Sets initial state of the Q output to '0' or '1'
			   SRTYPE => "ASYNC") -- Specifies "SYNC" or "ASYNC" set/reset
	port map (
			 Q  => GPIFII_PCLK, -- 1-bit output data
			 C0 => CLOCK_100_PCLK, -- 1-bit clock input
			 C1 => CLOCK_100_PCLK_N, -- 1-bit clock input
			 CE => '1',   -- 1-bit clock enable input
			 D0 => '1',   -- 1-bit data input (associated with C0)
			 D1 => '0',   -- 1-bit data input (associated with C1)
			 R => '0',  -- 1-bit reset input
			 S => '0'     -- 1-bit set input
		 ); 	


--|-------------------|
--| STATIC SIGNALLING |
--|-------------------|

	--GPIO2 <= '0'; --not CLOCK_100; -- scope triggering clock
	GPIO3 <= '0';
	GPIO4 <= '0';
	SHUTDOWN_VDD <= '0';
	SHUTDOWN_VDA <= '0';
	SPI_ADC_CS   <= '0';
	SPI_ADC_MOSI <= '0';
	SPI_ADC_CLK  <= '0';
	--SPI_ADC_MISO <= '0';

end Behavioral;
