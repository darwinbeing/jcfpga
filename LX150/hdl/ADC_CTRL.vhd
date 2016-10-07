--|-------------------------------------------------------------------------------------------------|
--| Sensor Control Module                                                                           |
--|-------------------------------------------------------------------------------------------------|
--| Version B, Ported to LX150 Version, Author: Deyan Levski, deyan.levski@eng.ox.ac.uk, 09.09.2016 |
--|-------------------------------------------------------------------------------------------------|
--|-+-|
--
--


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

entity ADC_CTRL is
    Port ( RX : in  STD_LOGIC;
           TX : out  STD_LOGIC;
           CLOCK : in  STD_LOGIC;
           RESET : in  STD_LOGIC;
           SPI_SEN : inout  STD_LOGIC;
           SPI_SCK : inout  STD_LOGIC;
           SPI_SDA : inout  STD_LOGIC;
	   SPI_DAC_SCK : inout STD_LOGIC;
	   SPI_DAC_SDA : inout STD_LOGIC;
	   SPI_DAC_A_SYNC : inout STD_LOGIC;
	   SPI_DAC_B_SYNC : inout STD_LOGIC;
           DEBUG_PIN : out  STD_LOGIC;
    	   SYNC_CLOCK : out STD_LOGIC;
    	   COUNT_CLK_P : out STD_LOGIC;
	   COUNT_CLK_N : out STD_LOGIC;
           d_adc_shr_shs : inout  STD_LOGIC;
           d_shs : inout  STD_LOGIC;
           d_shr : inout  STD_LOGIC;
           d_ads : inout  STD_LOGIC;
           d_adr : inout  STD_LOGIC;
           d_comp_bias_sh : inout  STD_LOGIC;
           d_comp_dyn_pon : inout  STD_LOGIC;
           d_count_rst : inout  STD_LOGIC;
           d_count_inv_clk : inout  STD_LOGIC;
           d_count_hold : inout  STD_LOGIC;
           d_count_updn : inout  STD_LOGIC;
           d_count_inc_one : inout  STD_LOGIC;
           d_count_jc_shift_en : inout  STD_LOGIC;
           d_count_lsb_en : inout  STD_LOGIC;
           d_count_lsb_clk : inout  STD_LOGIC;
           d_count_mem_wr : inout  STD_LOGIC;
           d_count_en : inout  STD_LOGIC;
           d_digif_serial_rst : inout  STD_LOGIC;
           d_ref_vref_ramp_rst : inout  STD_LOGIC;
           d_ref_vref_sh : inout  STD_LOGIC;
           d_ref_vref_clamp_en : inout  STD_LOGIC;
           d_ref_vref_ramp_ota_dyn_pon : inout  STD_LOGIC;

	   -- FX3 GPIFII Interface
	   GPIFII_PCLK			: out   std_logic;			-- fx3 interface clock
	   GPIFII_D			: inout std_logic_vector(31 downto 0);	-- fx3 data bus
	   GPIFII_ADDR			: out   std_logic_vector(4 downto 0);	-- fx3 fifo address
	   GPIFII_SLCS_N		: out   std_logic;			-- fx3 fifo chip select
	   GPIFII_SLRD_N		: out   std_logic;			-- fx3 fifo read enable
	   GPIFII_SLWR_N		: out   std_logic;			-- fx3 fifo write enable
	   GPIFII_SLOE_N		: out   std_logic;			-- fx3 fifo output enable
	   GPIFII_PKTEND_N		: out   std_logic;			-- fx3 fifo packet end flag
	   GPIFII_EPSWITCH		: out   std_logic;			-- fx3 endpoint switch
	   GPIFII_FLAGA			: in    std_logic;			-- fx3 fifo flag
	   GPIFII_FLAGB			: in    std_logic			-- fx3 fifo flag
   );
end ADC_CTRL;

architecture Behavioral of ADC_CTRL is

	component PLL_F250 is
		port (
		CLK_IN1           : in     std_logic;
		-- Clock out ports
		CLK_OUT1          : out    std_logic;
		CLK_OUT2          : out    std_logic
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
    	   	DEBUG_PIN : out STD_LOGIC
	);
	end component;

	component SEQUENCER is
		port (
		CLOCK			: in  STD_LOGIC;
		RESET			: in  STD_LOGIC;

		d_adc_shr_shs		: inout STD_LOGIC;

		d_shs			: inout STD_LOGIC;
		d_shr			: inout STD_LOGIC;
		d_ads			: inout STD_LOGIC;
		d_adr			: inout STD_LOGIC;
		
		d_comp_bias_sh		: inout STD_LOGIC;
		d_comp_dyn_pon		: inout STD_LOGIC;
		
		d_count_rst		: inout STD_LOGIC;
		d_count_inv_clk		: inout STD_LOGIC;
		d_count_hold		: inout STD_LOGIC;
		d_count_updn		: inout STD_LOGIC;
		d_count_inc_one		: inout STD_LOGIC;
		d_count_jc_shift_en	: inout STD_LOGIC;
		d_count_lsb_en		: inout STD_LOGIC;
		d_count_lsb_clk		: inout STD_LOGIC;
		d_count_mem_wr		: inout STD_LOGIC;
		d_count_en		: inout STD_LOGIC;
		
		d_digif_serial_rst	: inout std_logic;
		
		d_ref_vref_ramp_rst	: inout std_logic;
		d_ref_vref_sh		: inout std_logic;
		d_ref_vref_clamp_en	: inout std_logic;
		d_ref_vref_ramp_ota_dyn_pon: inout std_logic
	);
	end component;

	component FX3_SLAVE is
	port (	CLOCK : in  STD_LOGIC;
	        RESET : in  STD_LOGIC;
	        LED   : out STD_LOGIC;
	        -- FX3 GPIFII Interface
	        GPIFII_PCLK		: out   std_logic;			-- fx3 interface clock
	        GPIFII_D		: inout std_logic_vector(31 downto 0);	-- fx3 data bus
	        GPIFII_ADDR		: out   std_logic_vector(4 downto 0);	-- fx3 fifo address
	        GPIFII_SLCS_N		: out   std_logic;			-- fx3 fifo chip select
	        GPIFII_SLRD_N		: out   std_logic;			-- fx3 fifo read enable
	        GPIFII_SLWR_N		: out   std_logic;			-- fx3 fifo write enable
	        GPIFII_SLOE_N		: out   std_logic;			-- fx3 fifo output enable
	        GPIFII_PKTEND_N		: out   std_logic;			-- fx3 fifo packet end flag
	        GPIFII_EPSWITCH		: out   std_logic;			-- fx3 endpoint switch
	        GPIFII_FLAGA		: in    std_logic;			-- fx3 fifo flag
	        GPIFII_FLAGB		: in    std_logic			-- fx3 fifo flag
       );
	end component;

	signal CLOCK_100 : std_logic;
	signal CLOCK_250 : std_logic;

begin

--|----------------------|
--| Instantiate PLL Core |
--|----------------------|

	PLL_250_INST: PLL_F250
	port map (
	CLK_IN1           => CLOCK,
	-- Clock out ports
	CLK_OUT1          => CLOCK_100,
	CLK_OUT2          => CLOCK_250
	);

   -- End of PLL Core instantiation

--|------------------------------------------------|
--| OBUFDS: Differential Output Count Clock Buffer |
--|------------------------------------------------|
   
   OBUFDS_COUNT_CLK : OBUFDS
   generic map (
      IOSTANDARD => "LVDS_33")
   port map (
      O => COUNT_CLK_P,     -- Diff_p output (connect directly to top-level port)
      OB => COUNT_CLK_N,    -- Diff_n output (connect directly to top-level port)
      I => CLOCK_250        -- Buffer input 
   );
  
   -- End of OBUFDS_inst instantiation

--|----------------------------|
--| Instantiating SREG_CONTROL |
--|----------------------------|

	SREG_CONTROL_INST: SREG_CONTROL
	port map (
	RX => RX,
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
	DEBUG_PIN => DEBUG_PIN
	);

   -- End of SREG_CONTROL instantiation

--|-------------------------|
--| Instantiating SEQUENCER |
--|-------------------------|

	SEQUENCER_INST: SEQUENCER
	port map (
		CLOCK			=>	  CLOCK_250, -- should use CLOCK_250, using CLOCK_100 for scope testing
		RESET			=>	  RESET,

		d_adc_shr_shs		=>	  d_adc_shr_shs,
									  
		d_shs			=>	  d_shs,
		d_shr			=>	  d_shr,
		d_ads			=>	  d_ads,
		d_adr			=>	  d_adr,
						  
		d_comp_bias_sh		=>	  d_comp_bias_sh,
		d_comp_dyn_pon		=>	  d_comp_dyn_pon,
						  
		d_count_rst		=>	  d_count_rst,
		d_count_inv_clk		=>	  d_count_inv_clk,
		d_count_hold		=>	  d_count_hold,
		d_count_updn		=>	  d_count_updn,
		d_count_inc_one		=>	  d_count_inc_one,
		d_count_jc_shift_en	=>	  d_count_jc_shift_en,
		d_count_lsb_en		=>	  d_count_lsb_en,
		d_count_lsb_clk		=>	  d_count_lsb_clk,
		d_count_mem_wr		=>	  d_count_mem_wr,
		d_count_en		=>	  d_count_en,
						  
		d_digif_serial_rst	=>	  d_digif_serial_rst,
						  
		d_ref_vref_ramp_rst	=>	  d_ref_vref_ramp_rst,
		d_ref_vref_sh		=>	  d_ref_vref_sh,
		d_ref_vref_clamp_en	=>	  d_ref_vref_clamp_en,
		d_ref_vref_ramp_ota_dyn_pon =>	  d_ref_vref_ramp_ota_dyn_pon
		 );

   -- End of SEQUENCER instantiation

-- |----------------------------------------|
-- | Instantiating IMAGE_OUT and FX3 DRIVER |
-- |----------------------------------------|

	FX3_SLAVE_INST : FX3_SLAVE 
	port map (	
		CLOCK 			=> CLOCK_100,
	        RESET 			=> RESET,
	        LED   			=> open,
	        -- FX3 GPIFII Interface
	        GPIFII_PCLK		=> GPIFII_PCLK,		-- fx3 interface clock
	        GPIFII_D		=> GPIFII_D,		-- fx3 data bus
	        GPIFII_ADDR		=> GPIFII_ADDR,		-- fx3 fifo address
	        GPIFII_SLCS_N		=> GPIFII_SLCS_N,	-- fx3 fifo chip select
	        GPIFII_SLRD_N		=> GPIFII_SLRD_N,	-- fx3 fifo read enable
	        GPIFII_SLWR_N		=> GPIFII_SLWR_N,	-- fx3 fifo write enable
	        GPIFII_SLOE_N		=> GPIFII_SLOE_N,	-- fx3 fifo output enable
	        GPIFII_PKTEND_N		=> GPIFII_PKTEND_N,	-- fx3 fifo packet end flag
	        GPIFII_EPSWITCH		=> GPIFII_EPSWITCH,	-- fx3 endpoint switch
	        GPIFII_FLAGA		=> GPIFII_FLAGA,	-- fx3 fifo flag
	        GPIFII_FLAGB		=> GPIFII_FLAGB		-- fx3 fifo flag
       );


SYNC_CLOCK <= not CLOCK_100; -- scope triggering clock
end Behavioral;
