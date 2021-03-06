library IEEE, UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VCOMPONENTS.ALL;


entity FX3_SLAVE_IF is
  generic (
    G_WRDAT_W:                  positive:= 32);                                 -- FIFO WRDAT width
  port ( 
    -- system signals
    RESET:                      in    std_logic;
    FX3_CLK:                    in    std_logic;
    CLOCK:                      in    std_logic;
    FIFO_ENABLE:                in    std_logic_vector(7 downto 0);
    --fifo interfaces
    FIFO_WR_CLK:                in    std_logic;
    FIFO0_WRDAT_I:              in    std_logic_vector(G_WRDAT_W-1 downto 0);
    FIFO0_WREN_I:               in    std_logic;
    FIFO0_FULL_O:               out   std_logic;
    FIFO_RD_CLK:                in    std_logic;
    FIFO_RDEN_I:                in    std_logic;
    FIFO_EMPTY_O:               out   std_logic;
    FIFO_RDDAT_O:               out   std_logic_vector(7 downto 0);
    -- GPIFII interface
    GPIFII_PCLK:                out   std_logic;
    GPIFII_D:                   inout std_logic_vector(31 downto 0);
    GPIFII_ADDR:                out   std_logic_vector(4 downto 0);
    GPIFII_SLCS_N:              out   std_logic;
    GPIFII_SLRD_N:              out   std_logic;
    GPIFII_SLWR_N:              out   std_logic;
    GPIFII_SLOE_N:              out   std_logic;
    GPIFII_PKTEND_N:            out   std_logic;
    GPIFII_EPSWITCH:            out   std_logic;
    GPIFII_FLAGA:               in    std_logic;                                -- Current thread DMA ready
    GPIFII_FLAGB:               in    std_logic);                               -- Current thread DMA watermark
end entity FX3_SLAVE_IF;


architecture RTL of FX3_SLAVE_IF is

component DATA_TO_GPIFII_FIFO is
  port (
    RST:                        in  std_logic;
    WR_CLK:                     in  std_logic;
    RD_CLK:                     in  std_logic;
    DIN:                        in  std_logic_vector(31 downto 0);
    WR_EN:                      in  std_logic;
    RD_EN:                      in  std_logic;
    DOUT:                       out std_logic_vector(31 downto 0);
    FULL:                       out std_logic;
    ALMOST_FULL:                out std_logic;
    RD_DATA_COUNT:              out std_logic_vector(13 downto 0);
    EMPTY:                      out std_logic;
    PROG_EMPTY:                 out std_logic;
    ALMOST_EMPTY:               out std_logic);
end component DATA_TO_GPIFII_FIFO;
 
component DATA_FROM_GPIFII_FIFO is
  port (
    RST:                        in  std_logic;
    WR_CLK:                     in  std_logic;
    RD_CLK:                     in  std_logic;
    DIN:                        in  std_logic_vector(31 downto 0);
    WR_EN:                      in  std_logic;
    RD_EN:                      in  std_logic;
    DOUT:                       out std_logic_vector(7 downto 0);
    FULL:                       out std_logic;
    ALMOST_FULL:                out std_logic;
    EMPTY:                      out std_logic;
    ALMOST_EMPTY:               out std_logic);
end component DATA_FROM_GPIFII_FIFO;
    
    

constant C_FLAG_LATENCY:        unsigned(7 downto 0):=x"05";




type T_STATES is (IDLE,WR_ADDR_PHASE,WRITE,READ,TERMINATE1,TERMINATE2,TERMINATE3,TERMINATE4,TERMINATE5,TERMINATE6,TERMINATE7,TERMINATE8,TERMINATE9,TERMINATE10);

signal I_PRESENT_STATE:         T_STATES:=IDLE;
signal I_LAST_STATE:            T_STATES:=IDLE;

signal I_FIFO_EMPTY:            std_logic;
signal I_FIFO_RDEN:             std_logic;
signal I_FIFO_RDEN1:            std_logic:='0';
signal I_FIFO_DOUT:             std_logic_vector(31 downto 0);       
signal I_GPIFII_FLAGA:          std_logic:='0';
signal I_GPIFII_FLAGA1:         std_logic:='0';
signal I_GPIFII_FLAGB:          std_logic:='0';
signal I_GPIFII_OUTEN1:         std_logic;
signal I_GPIFII_OUTEN2:         std_logic;
signal I_GPIFII_DOUT:           std_logic_vector(31 downto 0);
signal I_GPIFII_DOUT1:          std_logic_vector(31 downto 0);
signal I_GPIFII_DIN:            std_logic_vector(31 downto 0);
signal I_GPIFII_ADDR:           unsigned(4 downto 0):=(others => '0');
signal I_GPIFII_SLCS_N:         std_logic:='1';
signal I_GPIFII_SLRD_N:         std_logic:='1';
signal I_GPIFII_SLRD_N1:        std_logic:='1';
signal I_GPIFII_SLRD_N2:        std_logic:='1';
signal I_GPIFII_SLRD_N3:        std_logic:='1';
signal I_GPIFII_SLWR_N:         std_logic:='1';
signal I_GPIFII_SLWR_N1:        std_logic:='1';
signal I_GPIFII_SLWR_N2:        std_logic:='1';
signal I_GPIFII_SLOE_N:         std_logic:='1';
signal I_GPIFII_PKTEND_N:       std_logic:='1';
signal I_GPIFII_EPSWITCH:       std_logic:='1';
signal I_FX3_CLK_N:             std_logic;
signal I_CLOCK_N:               std_logic;
signal I_TX_CNT:                unsigned(15 downto 0):=(others => '0');  
signal I_FIFO_WREN:             std_logic;
signal I_FIFO_RDDAT_O:          std_logic_vector(7 downto 0);
signal I_FIFO_FULL:             std_logic;


begin
--------------------------------------------------------------------------------
-- FIFO 0, DATA -> GPIFII
--------------------------------------------------------------------------------
I0_DATA_TO_GPIFII_FIFO: DATA_TO_GPIFII_FIFO
  port map (
    RST                         => RESET,
    WR_CLK                      => FIFO_WR_CLK,
    RD_CLK                      => CLOCK,
    DIN                         => FIFO0_WRDAT_I,
    WR_EN                       => FIFO0_WREN_I,
    RD_EN                       => I_FIFO_RDEN1,
    DOUT                        => I_FIFO_DOUT,
    FULL                        => I_FIFO_FULL,
    ALMOST_FULL                 => open,
    EMPTY                       => open,
    PROG_EMPTY                  => I_FIFO_EMPTY,
    RD_DATA_COUNT               => open,
    ALMOST_EMPTY                => open);

FIFO0_FULL_O <= I_FIFO_FULL;

    
--------------------------------------------------------------------------------
-- FIFO, DATA <- GPIFII
--------------------------------------------------------------------------------
I_FIFO_WREN <= not I_GPIFII_SLRD_N3 and I_GPIFII_FLAGA;
 
I_DATA_FROM_GPIFII_FIFO: DATA_FROM_GPIFII_FIFO
  port map (
    RST                         => RESET,
    WR_CLK                      => CLOCK,
    RD_CLK                      => FIFO_RD_CLK,
    DIN                         => I_GPIFII_DIN,
    WR_EN                       => I_FIFO_WREN,
    RD_EN                       => FIFO_RDEN_I,
    DOUT                        => I_FIFO_RDDAT_O,
    FULL                        => open,
    ALMOST_FULL                 => open,
    EMPTY                       => FIFO_EMPTY_O, 
    ALMOST_EMPTY                => open);    

FIFO_RDDAT_O <= I_FIFO_RDDAT_O;

--------------------------------------------------------------------------------
-- sampling of the GPIFII flags
--------------------------------------------------------------------------------
FLAG_SAMPLING: process(CLOCK)
begin
  if (rising_edge(CLOCK)) then
    I_GPIFII_FLAGA  <= GPIFII_FLAGA;
    I_GPIFII_FLAGA1 <= I_GPIFII_FLAGA;
    I_GPIFII_FLAGB  <= GPIFII_FLAGB;
  end if;
end process FLAG_SAMPLING;    
  
  
--------------------------------------------------------------------------------
-- FSM
--------------------------------------------------------------------------------    
FSM_EVAL: process(CLOCK)
begin
  if (rising_edge(CLOCK)) then
    I_LAST_STATE <= I_PRESENT_STATE;
    case I_PRESENT_STATE is  
--------------------------------------------------------------------------------
-- IDLE: depending on the decision of the arbiter a write or read is performed
--------------------------------------------------------------------------------  
      when IDLE =>
        if ((I_FIFO_EMPTY = '0') and (I_GPIFII_FLAGB = '1')) then
          I_PRESENT_STATE <= WR_ADDR_PHASE;
        elsif (I_GPIFII_FLAGA = '1') then
          I_PRESENT_STATE <= READ;
        end if;  
--------------------------------------------------------------------------------
-- WR_ADDR_PHASE: set GPIFII_SLCS_N and GPIFII_ADDR
--------------------------------------------------------------------------------  
      when WR_ADDR_PHASE => 
        I_PRESENT_STATE <= WRITE;
--------------------------------------------------------------------------------
-- WRITE: write to selected socket until the corresponding flag is raised or
--        the source fifo is empty
--------------------------------------------------------------------------------  
      when WRITE => 
        if (I_TX_CNT = x"0fff") then
            I_PRESENT_STATE <= TERMINATE1;
        end if;       
--------------------------------------------------------------------------------
-- READ: read from selected socket
--------------------------------------------------------------------------------        
      when READ => 
        if (I_GPIFII_FLAGA = '0') then
          I_PRESENT_STATE <= TERMINATE10;
        end if; 
--------------------------------------------------------------------------------
-- TERMINATE1: wait cycle
--------------------------------------------------------------------------------        
      when TERMINATE1 =>
        I_PRESENT_STATE <= TERMINATE2;
--------------------------------------------------------------------------------
-- TERMINATE2: wait cycle
--------------------------------------------------------------------------------        
      when TERMINATE2 =>
        I_PRESENT_STATE <= TERMINATE3;
--------------------------------------------------------------------------------
-- TERMINATE3: wait cycle
--------------------------------------------------------------------------------        
      when TERMINATE3 =>
        I_PRESENT_STATE <= TERMINATE4;
--------------------------------------------------------------------------------
-- TERMINATE4: wait cycle
--------------------------------------------------------------------------------        
      when TERMINATE4 =>
        I_PRESENT_STATE <= TERMINATE5;   
      when TERMINATE5 =>
        I_PRESENT_STATE <= TERMINATE6;           
      when TERMINATE6 =>
        I_PRESENT_STATE <= TERMINATE7;           
      when TERMINATE7 =>
        I_PRESENT_STATE <= TERMINATE8;   
      when TERMINATE8 =>
        I_PRESENT_STATE <= TERMINATE9;           
      when TERMINATE9 =>
        I_PRESENT_STATE <= TERMINATE10;         
--------------------------------------------------------------------------------
-- TERMINATE4: wait cycle
--------------------------------------------------------------------------------        
      when TERMINATE10 =>
        I_PRESENT_STATE <= IDLE;          
    end case;
  end if;
end process FSM_EVAL;
      


TX_CNT_EVAL: process(CLOCK)
begin
  if (rising_edge(CLOCK)) then    
    if (I_PRESENT_STATE = WRITE) then
      I_TX_CNT <= I_TX_CNT + 1;
    else
      I_TX_CNT <= (others => '0');
    end if;
  end if;
end process TX_CNT_EVAL;


RD_EN_EVAL: process(I_PRESENT_STATE)
begin
  if (I_PRESENT_STATE = WRITE) then
    I_FIFO_RDEN <= '1';
  else
    I_FIFO_RDEN <= '0';
  end if;
end process RD_EN_EVAL;


--------------------------------------------------------------------------------
-- delay I_FIFO_RDEN
--------------------------------------------------------------------------------
RD_EN_DLY: process(CLOCK)
begin
  if (rising_edge(CLOCK)) then
    I_FIFO_RDEN1 <= I_FIFO_RDEN;
  end if;
end process RD_EN_DLY;
     

--------------------------------------------------------------------------------
-- generate GPIFII signals
--------------------------------------------------------------------------------
GPIFII_OUTPUTS: process(CLOCK)
begin
  if (rising_edge(CLOCK)) then
    I_GPIFII_SLWR_N1 <= I_GPIFII_SLWR_N;
    I_GPIFII_SLWR_N2 <= I_GPIFII_SLWR_N1;
    I_GPIFII_OUTEN1  <= not I_GPIFII_SLWR_N;
    I_GPIFII_OUTEN2  <= I_GPIFII_OUTEN1;
    case I_PRESENT_STATE is
      when IDLE =>
        I_GPIFII_ADDR     <= "00001"; 
        I_GPIFII_SLCS_N   <= '0';
        I_GPIFII_SLRD_N   <= '1';
        I_GPIFII_SLWR_N   <= '1';
        I_GPIFII_SLOE_N   <= '1';
        I_GPIFII_PKTEND_N <= '1';
        I_GPIFII_EPSWITCH <= '1';   
      when WR_ADDR_PHASE => 
        I_GPIFII_ADDR <= "00011"; --"10100" + I_CURRENT_FIFO;
        I_GPIFII_SLCS_N   <= '0';
        I_GPIFII_SLRD_N   <= '1';
        I_GPIFII_SLWR_N   <= '1';
        I_GPIFII_SLOE_N   <= '1';
        I_GPIFII_PKTEND_N <= '1';
        I_GPIFII_EPSWITCH <= '0';            
      when WRITE =>
        I_GPIFII_ADDR     <= "00011";
        I_GPIFII_SLCS_N   <= '0';
        I_GPIFII_SLRD_N   <= '1';
        I_GPIFII_SLWR_N   <= '0';
        I_GPIFII_SLOE_N   <= '1';
        I_GPIFII_PKTEND_N <= '1';
        I_GPIFII_EPSWITCH <= '1';              
      when READ => 
        I_GPIFII_ADDR     <= "00001";
        I_GPIFII_SLCS_N   <= '0';
        I_GPIFII_SLRD_N   <= '0';
        I_GPIFII_SLWR_N   <= '1';
        I_GPIFII_SLOE_N   <= '0';
        I_GPIFII_PKTEND_N <= '1';
        I_GPIFII_EPSWITCH <= '1'; 
      when TERMINATE1 | TERMINATE2 | TERMINATE3 | TERMINATE4 | TERMINATE5 | TERMINATE6 | TERMINATE7 | TERMINATE8 | TERMINATE9 | TERMINATE10 => 
        I_GPIFII_ADDR     <= I_GPIFII_ADDR;
        I_GPIFII_SLCS_N   <= '0';
        I_GPIFII_SLRD_N   <= '1';
        I_GPIFII_SLWR_N   <= '1';
        I_GPIFII_SLOE_N   <= '1';
        I_GPIFII_PKTEND_N <= '1';
        I_GPIFII_EPSWITCH <= '1';    
    end case;
  end if;
end process GPIFII_OUTPUTS;


--------------------------------------------------------------------------------
-- data output register
--------------------------------------------------------------------------------
DOUT_REG: process(CLOCK)
begin
  if (rising_edge(CLOCK)) then  
    I_GPIFII_DOUT  <= I_FIFO_DOUT; 
    I_GPIFII_DOUT1 <= I_GPIFII_DOUT;
  end if;
end process DOUT_REG;


--------------------------------------------------------------------------------
-- data input register
--------------------------------------------------------------------------------
DIN_REG: process(CLOCK)
begin
  if (rising_edge(CLOCK)) then  
    I_GPIFII_DIN(31 downto 24) <= GPIFII_D(7 downto 0);
    I_GPIFII_DIN(23 downto 16) <= GPIFII_D(15 downto 8);
    I_GPIFII_DIN(15 downto 8)  <= GPIFII_D(23 downto 16);
    I_GPIFII_DIN(7 downto 0)   <= GPIFII_D(31 downto 24);
  end if;
end process DIN_REG;


--------------------------------------------------------------------------------
-- GPIFII signal assignments
--------------------------------------------------------------------------------
GPIFII_D(31 downto 24) <= I_GPIFII_DOUT(7 downto 0)   when (I_GPIFII_OUTEN2 = '1') else (others => 'Z');
GPIFII_D(23 downto 16) <= I_GPIFII_DOUT(15 downto 8)  when (I_GPIFII_OUTEN2 = '1') else (others => 'Z');
GPIFII_D(15 downto 8)  <= I_GPIFII_DOUT(23 downto 16) when (I_GPIFII_OUTEN2 = '1') else (others => 'Z');
GPIFII_D(7 downto 0)   <= I_GPIFII_DOUT(31 downto 24) when (I_GPIFII_OUTEN2 = '1') else (others => 'Z');

GPIFII_ADDR     <= std_logic_vector(I_GPIFII_ADDR);
GPIFII_SLCS_N   <= I_GPIFII_SLCS_N;
GPIFII_SLRD_N   <= I_GPIFII_SLRD_N;
GPIFII_SLWR_N   <= I_GPIFII_SLWR_N2;
GPIFII_SLOE_N   <= I_GPIFII_SLOE_N;
GPIFII_PKTEND_N <= I_GPIFII_PKTEND_N;
GPIFII_EPSWITCH <= '1'; --I_GPIFII_EPSWITCH;
    
    
--------------------------------------------------------------------------------
-- clock output to FX3
--------------------------------------------------------------------------------
I_FX3_CLK_N <= not FX3_CLK;

I_ODDR2: ODDR2
  generic map (
    DDR_ALIGNMENT               => "NONE",                                      -- Sets output alignment to "NONE", "C0", "C1" 
    INIT                        => '0',                                         -- Sets initial state of the Q output to '0' or '1'
    SRTYPE                      => "SYNC")                                      -- Specifies "SYNC" or "ASYNC" set/reset
  port map (                                                                    
    Q                           => GPIFII_PCLK,                                 -- 1-bit output data
    C0                          => FX3_CLK,                                     -- 1-bit clock input
    C1                          => I_FX3_CLK_N,                                 -- 1-bit clock input
    CE                          => '1',                                         -- 1-bit clock enable input
    D0                          => '1',                                         -- 1-bit data input (associated with C0)
    D1                          => '0',                                         -- 1-bit data input (associated with C1)
    R                           => '0',                                         -- 1-bit reset input
    S                           => '0');                                        -- 1-bit set input
  

--------------------------------------------------------------------------------
-- delay I_GPIFII_SLRD_N
-------------------------------------------------------------------------------- 
DELAY_SLRD_EVAL: process(CLOCK)
begin
  if (rising_edge(CLOCK)) then
    I_GPIFII_SLRD_N1 <= I_GPIFII_SLRD_N; 
    I_GPIFII_SLRD_N2 <= I_GPIFII_SLRD_N1;
    I_GPIFII_SLRD_N3 <= I_GPIFII_SLRD_N2;
  end if;
end process DELAY_SLRD_EVAL;


end RTL;

