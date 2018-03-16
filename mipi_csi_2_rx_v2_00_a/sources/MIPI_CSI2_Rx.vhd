--------------------------------------------------------------
--
-- (C) Copyright Kutu Pty. Ltd. 2018.
--
-- file: sync_fifo.vhd
--
-- author: Greg Smart
--
--------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library mipi_csi_2_rx_v2_0_0;
use mipi_csi_2_rx_v2_0_0.LLP;
use mipi_csi_2_rx_v2_0_0.LM;
use mipi_csi_2_rx_v2_0_0.SyncAsync;
use mipi_csi_2_rx_v2_0_0.ResetBridge;

entity MIPI_CSI2_Rx is
   Generic (
      kTargetDT : string := "RAW10";
      kDebug : boolean := true;
      --PPI
      kLaneCount : natural range 1 to 4 := 2; --[1,2,4]
      --Video Format
      C_M_AXIS_COMPONENT_WIDTH : natural := 10; -- [8,10]
      C_M_AXIS_TDATA_WIDTH : natural := 40;
      C_M_MAX_SAMPLES_PER_CLOCK : natural := 4
   );
   Port (
      --PPI
      RxByteClkHS : in STD_LOGIC;
      aClkStopstate : in std_logic;
      aRxClkActiveHS : in std_logic;

      rbRxDataHS : in STD_LOGIC_VECTOR (8 * kLaneCount - 1 downto 0);
      rbRxSyncHS : in STD_LOGIC_VECTOR (kLaneCount - 1 downto 0);
      rbRxValidHS : in STD_LOGIC_VECTOR (kLaneCount - 1 downto 0);
      rbRxActiveHS : in STD_LOGIC_VECTOR (kLaneCount - 1 downto 0);
      aDEnable : out STD_LOGIC_VECTOR (kLaneCount - 1 downto 0);
      aClkEnable : out STD_LOGIC;

      --axi stream signals
      m_axis_video_tdata    : out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
      m_axis_video_tvalid   : out std_logic;
      m_axis_video_tready   : in std_logic;
      m_axis_video_tlast    : out std_logic;
      m_axis_video_tuser    : out std_logic_vector(0 downto 0);

      video_aresetn        : in std_logic;
      video_aclk           : in std_logic;
      vEnable              : in std_logic  --TODO proper buffer flushing on disable, perhaps waiting on active transfer to end
    );
end MIPI_CSI2_Rx;

architecture Behavioral of MIPI_CSI2_Rx is

      -- VHDL-2008 back-port
   function orv(vec : std_logic_vector) return std_logic is
      variable result : std_logic := '0';
   begin
      for i in vec'range loop
         result := result or vec(i);
      end loop;
      return result;
   end orv;
   -- VHDL-2008 back-port
   function andv(vec : std_logic_vector) return std_logic is
      variable result : std_logic := '1';
   begin
      for i in vec'range loop
         result := result and vec(i);
      end loop;
      return result;
   end andv;

   constant kMaxLaneCount : natural := 4;


   signal rbLMAxisTdata : std_logic_vector(8 * kMaxLaneCount - 1 downto 0);
   signal rbLMAxisTkeep : std_logic_vector(kMaxLaneCount - 1 downto 0);
   signal rbLMAxisTvalid, rbLMAxisTlast : std_logic;
   signal rbLMErrOvf, rbLMErrSkew : std_logic;
   signal rbLLPAxisTready : std_logic;
   signal rbRst_n, rbRst, rbEn : std_logic;
   signal vTready, vRst : std_logic;
   signal rbRxClkTrigOut, vRxClkTrigOut, vTrigIn, vTrigInAck, rbTrigInAck : std_logic;
   signal rbRxClkLaneTrigOut, vRxClkLaneTrigOut : std_logic_vector(kMaxLaneCount - 1 downto 0);
   signal aClkEnableInt : std_logic;
   signal aDEnableInt : std_logic_vector(kMaxLaneCount - 1 downto 0);
begin

rbRst <= rbRst_n;

-- Synchronize video_aresetn into the RxByteClkHS domain
SyncReset: entity mipi_csi_2_rx_v2_0_0.ResetBridge
   generic map (
      kPolarity => '0')
   port map (
      aRst => video_aresetn,
      OutClk => RxByteClkHS,
      oRst => rbRst_n);

-- Synchronize vEnable into the RxByteClkHS domain
SyncAsyncEnable: entity mipi_csi_2_rx_v2_0_0.SyncAsync
   generic map (
      kResetTo => '0',
      kStages => 2, --use double FF synchronizer
      kResetPolarity => '0')
   port map (
      aReset => rbRst_n,
      aIn => vEnable,
      OutClk => RxByteClkHS,
      oOut => rbEn);

GlitchFree_vRst: process(video_aclk)
begin
   if Rising_Edge(video_aclk) then
      vRst <= not video_aresetn;
   end if;
end process;

PPI_Clock_Enable: process(video_aclk)
begin
   if Rising_Edge(video_aclk) then
      aClkEnableInt <= vEnable and video_aresetn;
      aDEnableInt <= (others => vEnable and video_aresetn);
   end if;
end process;

aClkEnable <= aClkEnableInt;

-- Initially data lanes were only enabled when the LLP module below doing
-- data buffering was ready to receive data. However, this was problematic for
-- two reasons:
-- 1. not all lanes (clock and data) were enabled simultaneously and
-- 2. since LLP requires a few RxByteClkHS clock cycles to assert ready on its
-- slave port, the data lanes were only enabled after the clock lane was already
-- transmitting clock. The data lanes still needed Stop state of T_INIT long
-- at least to complete initialization after enablement, resulting in loss of
-- the first data packets.
-- Instead, we rely on LM to do a limited buffering upon exit from reset and
-- on T_CLK_PRE
--PPI_Data_Enable: process(video_aclk)
--begin
--   if Rising_Edge(video_aclk) then
--      if (video_aresetn = '0') then
--         aDEnableInt    <= (others => '0');
--      else
--         if (vEnable = '0') then
--            aDEnableInt    <= (others => '0');
--         elsif (vTready = '1') then --LLP buffer should be ready to receive data before enabling the PHY
--            aDEnableInt    <= (others => '1');
--         end if;
--      end if;
--   end if;
--end process;

aDEnable <= aDEnableInt(kLaneCount-1 downto 0);

SyncAsyncTready: entity work.SyncAsync
   generic map (
      kResetTo => '0',
      kStages => 2, --use double FF synchronizer
      kResetPolarity => '0')
   port map (
      aReset => video_aresetn,
      aIn => rbLLPAxisTready,
      OutClk => video_aclk,
      oOut => vTready);

-- Lane merger compacts the CSI-2 lane into a wide AXI-Stream bus
-- Both the input and output interfaces are synchronous to RxByteClkHS
-- and it does not buffer data
LM_inst:   entity mipi_csi_2_rx_v2_0_0.LM
   Generic Map(
      kMaxLaneCount  => kMaxLaneCount,
      kLaneCount     => kLaneCount
   )
   Port Map(
      RxByteClkHS    => RxByteClkHS,
      RxDataHS       => rbRxDataHS,
      RxSyncHS       => rbRxSyncHS,
      RxValidHS      => rbRxValidHS,
      RxActiveHS     => rbRxActiveHS,

      rbMAxisTdata   => rbLMAxisTdata,
      rbMAxisTkeep   => rbLMAxisTkeep,
      rbMAxisTvalid  => rbLMAxisTvalid,
      rbMAxisTready  => rbLLPAxisTready,
      rbMAxisTlast   => rbLMAxisTlast,

      rbErrSkew      => rbLMErrSkew,
      rbErrOvf       => rbLMErrOvf,

      rbEn           => rbEn,
      rbRst          => rbRst
   );

-- Link-level protocol decodes short and long packets into frames, lines
-- and pixels. It synchronizes data from the MIPI clock domain (RxByteClkHS)
-- to the video pipeline domain video_aclk. It does error detection
-- and correction, filters data according to the target data type and
-- formats it according to UG934, ready to source a video processing
-- pipeline.
LLP_inst: entity mipi_csi_2_rx_v2_0_0.LLP
   Generic map (
      kMaxLaneCount => kMaxLaneCount,
      --PPI
      kLaneCount => kLaneCount, --[1,2,4]
      kTargetDT => kTargetDT
   )
   Port map (
      SAxisClk => RxByteClkHS,
      --Slave AXI-Stream
      sAxisTdata => rbLMAxisTdata,
      sAxisTkeep => rbLMAxisTkeep,
      sAxisTvalid => rbLMAxisTvalid,
      sAxisTready => rbLLPAxisTready,
      sAxisTlast => rbLMAxisTlast,

      MAxisClk => video_aclk,
      --Master AXI-Stream
      mAxisTdata => m_axis_video_tdata,
      mAxisTvalid => m_axis_video_tvalid,
      mAxisTready => m_axis_video_tready,
      mAxisTlast => m_axis_video_tlast,
      mAxisTuser => m_axis_video_tuser,

      aRst => vRst,
      sOverflow => open
   );

----------------------------------------------------------------------------------
-- Debug modules
----------------------------------------------------------------------------------


end Behavioral;
