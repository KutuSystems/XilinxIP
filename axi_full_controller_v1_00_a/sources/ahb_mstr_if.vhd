-------------------------------------------------------------------------------
-- ahb_mstr_if.vhd - entity/architecture pair
-------------------------------------------------------------------------------
--
--
--  *******************************************************************
--  ** (c) Copyright [2007] - [2012] Xilinx, Inc. All rights reserved.*
--  **                                                                *
--  ** This file contains confidential and proprietary information    *
--  ** of Xilinx, Inc. and is protected under U.S. and                *
--  ** international copyright and other intellectual property        *
--  ** laws.                                                          *
--  **                                                                *
--  ** DISCLAIMER                                                     *
--  ** This disclaimer is not a license and does not grant any        *
--  ** rights to the materials distributed herewith. Except as        *
--  ** otherwise provided in a valid license issued to you by         *
--  ** Xilinx, and to the maximum extent permitted by applicable      *
--  ** law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND        *
--  ** WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES    *
--  ** AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING      *
--  ** BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-         *
--  ** INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and       *
--  ** (2) Xilinx shall not be liable (whether in contract or tort,   *
--  ** including negligence, or under any other theory of             *
--  ** liability) for any loss or damage of any kind or nature        *
--  ** related to, arising under or in connection with these          *
--  ** materials, including for any direct, or any indirect,          *
--  ** special, incidental, or consequential loss or damage           *
--  ** (including loss of data, profits, goodwill, or any type of     *
--  ** loss or damage suffered as a result of any action brought      *
--  ** by a third party) even if such damage or loss was              *
--  ** reasonably foreseeable or Xilinx had been advised of the       *
--  ** possibility of the same.                                       *
--  **                                                                *
--  ** CRITICAL APPLICATIONS                                          *
--  ** Xilinx products are not designed or intended to be fail-       *
--  ** safe, or for use in any application requiring fail-safe        *
--  ** performance, such as life-support or safety devices or         *
--  ** systems, Class III medical devices, nuclear facilities,        *
--  ** applications related to the deployment of airbags, or any      *
--  ** other applications that could lead to death, personal          *
--  ** injury, or severe property or environmental damage             *
--  ** (individually and collectively, "Critical                      *
--  ** Applications"). Customer assumes the sole risk and             *
--  ** liability of any use of Xilinx products in Critical            *
--  ** Applications, subject only to applicable laws and              *
--  ** regulations governing limitations on product liability.        *
--  **                                                                *
--  ** THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS       *
--  ** PART OF THIS FILE AT ALL TIMES.                                *
--  *******************************************************************
--
-------------------------------------------------------------------------------
-- Filename     :   ahb_mstr_if.vhd
-- Version      :   v1.01a
-- Description  :   The AHB Master Interface module provides a bi-directional
--                  AHB master interface on the AHB Lite. 
--                  The AHB data bus width can be 32/64-bits.
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Structure:
--           -- axi_ahblite_bridge.vhd
--              -- axi_slv_if.vhd
--              -- ahb_mstr_if.vhd
--              -- time_out.vhd
-------------------------------------------------------------------------------
-- Author:     NLR 
-- History:
--   NLR      12/15/2010   Initial version
-- ^^^^^^^
-- ~~~~~~~
--   NLR      04/10/2012    Added the strobe support for single data transfers
-- ^^^^^^^
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*N"
--      clock signals:                          "clk", "clk_div#", "clk_#x"
--      reset signals:                          "rst", "rst_n"
--      generics:                               "C_*"
--      user defined types:                     "*_TYPE"
--      state machine next state:               "*_ns"
--      state machine current state:            "*_cs"
--      counter signals:                        "*cntr*", "*count*"
--      ports:                                  - Names in Uppercase
--      processes:                              "*_REG", "*_CMB"
--      component instantiations:               "<ENTITY_>MODULE<#|_FUNC>
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ahb_mstr_if is    
  generic (
    C_M_AHB_ADDR_WIDTH   : integer range 32 to 32   := 32;
    C_M_AHB_DATA_WIDTH   : integer := 32;
    C_S_AXI_DATA_WIDTH   : integer := 32;
    C_S_AXI_SUPPORTS_NARROW_BURST : integer range 0 to 1 := 0 
    );
  port (

  -- AHB Signals
    AHB_HCLK           : in std_logic;    
    AHB_HRESETN        : in std_logic;

    M_AHB_HADDR        : out std_logic_vector(C_M_AHB_ADDR_WIDTH-1 downto 0);
    M_AHB_HWRITE       : out std_logic;
    M_AHB_HSIZE        : out std_logic_vector(2 downto 0);
    M_AHB_HBURST       : out std_logic_vector(2 downto 0);
    M_AHB_HPROT        : out std_logic_vector(3 downto 0);
    M_AHB_HTRANS       : out std_logic_vector(1 downto 0);
    M_AHB_HMASTLOCK    : out std_logic;
    M_AHB_HWDATA       : out std_logic_vector(C_M_AHB_DATA_WIDTH-1 downto 0);
    
    M_AHB_HREADY       : in  std_logic;
    M_AHB_HRDATA       : in  std_logic_vector(C_M_AHB_DATA_WIDTH-1 downto 0);
    M_AHB_HRESP        : in  std_logic;

  -- Signals from/to other modules
    ahb_rd_request     : in  std_logic;
    ahb_wr_request     : in  std_logic;
    axi_lock           : in  std_logic;
    rd_data            : out std_logic_vector(C_M_AHB_DATA_WIDTH-1 downto 0);
    slv_err_resp       : out std_logic;
    axi_prot           : in  std_logic_vector(2 downto 0);
    axi_cache          : in  std_logic_vector(3 downto 0);
    axi_wdata          : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    axi_size           : in  std_logic_vector(2 downto 0);
    axi_length         : in  std_logic_vector(7 downto 0);
    axi_address        : in  std_logic_vector(C_M_AHB_ADDR_WIDTH-1 downto 0);
    axi_burst          : in  std_logic_vector(1 downto 0);
    single_ahb_wr_xfer : in  std_logic;
    single_ahb_rd_xfer : in  std_logic;
    send_wvalid        : out std_logic;
    send_ahb_wr        : in  std_logic;
    axi_wvalid         : in  std_logic;
    send_bresp         : out std_logic;
    send_rvalid        : out std_logic;
    send_rlast         : out std_logic;
    axi_rready         : in  std_logic;
    timeout_inprogress : in std_logic;
    load_cntr          : out std_logic;
    cntr_enable        : out std_logic
    );

end entity ahb_mstr_if;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------

architecture RTL of ahb_mstr_if is
-------------------------------------------------------------------------------
-- PRAGMAS
-------------------------------------------------------------------------------

attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of RTL : architecture is "yes";

-------------------------------------------------------------------------------
-- State Machine TYPE Declarations
-------------------------------------------------------------------------------

    type  AHB_SM_TYPE is (AHB_IDLE,
                          AHB_RD_ADDR,
                          AHB_RD_SINGLE,
                          AHB_RD_DATA_INCR,
                          AHB_RD_LAST,
                          AHB_RD_WAIT,
                          AHB_WR_ADDR,
                          AHB_WR_SINGLE,
                          AHB_WR_WAIT,
                          AHB_WR_INCR,
                          AHB_INCR_ADDR,
                          AHB_LAST_ADDR,
                          AHB_ONEKB_LAST,
                          AHB_LAST_WAIT,
                          AHB_LAST
                         );

-------------------------------------------------------------------------------
-- constant declarations
-------------------------------------------------------------------------------

    constant IDLE   : std_logic_vector := "00";
    constant BUSY   : std_logic_vector := "01";
    constant NONSEQ : std_logic_vector := "10";
    constant SEQ    : std_logic_vector := "11";

-------------------------------------------------------------------------------
-- Signal declarations
-------------------------------------------------------------------------------

    signal ahb_wr_rd_ns   : AHB_SM_TYPE;
    signal ahb_wr_rd_cs   : AHB_SM_TYPE;

    signal HWRITE_i       : std_logic;
    signal HWDATA_i       : std_logic_vector(C_M_AHB_DATA_WIDTH-1 downto 0);
    signal HADDR_i        : std_logic_vector(C_M_AHB_ADDR_WIDTH-1 downto 0);
    signal HPROT_i        : std_logic_vector(3 downto 0);
    signal HBURST_i       : std_logic_vector(2 downto 0);
    signal HSIZE_i        : std_logic_vector(2 downto 0);
    signal HLOCK_i        : std_logic;

    signal ahb_hslverr    : std_logic;
    signal ahb_hready     : std_logic;
    signal ahb_hrdata     : std_logic_vector(C_M_AHB_DATA_WIDTH-1 downto 0);
    signal ahb_write_sm   : std_logic;
    signal wrap_brst_count: std_logic_vector(7 downto 0);
    signal burst_ready    : std_logic;
    signal wrap_brst_last : std_logic;
    signal ahb_burst      : std_logic_vector(2 downto 0);
    signal send_wr_data   : std_logic;
    signal incr_addr      : std_logic;
    signal load_counter   : std_logic;
    signal load_counter_sm: std_logic;
    signal wrap_brst_one  : std_logic;
    signal send_trans_seq : std_logic;
    signal send_trans_nonseq : std_logic;
    signal send_trans_idle   : std_logic;
    signal send_trans_busy   : std_logic;
    signal send_wrap_burst   : std_logic;
    
    signal wrap_in_progress  : std_logic;
    signal send_rlast_sm     : std_logic;
    signal send_bresp_sm     : std_logic;
    signal one_kb_cross      : std_logic;

    signal addr_all_ones      : std_logic;
    signal one_kb_in_progress : std_logic;
    signal one_kb_splitted    : std_logic;
    signal wrap_2_in_progress : std_logic;
    signal axi_len_les_eq_sixteen : std_logic;
    signal axi_end_address    : std_logic_vector(11 downto 0);    
    signal axi_length_burst   : std_logic_vector(11 downto 0); 
    signal onekb_cross_access : std_logic;    
    signal fixed_burst_access : std_logic;
    signal incr_burst_access  : std_logic;
    signal wrap_burst_access  : std_logic;
    signal wrap_four          : std_logic;
    signal wrap_eight         : std_logic;
    signal wrap_sixteen       : std_logic;
    signal onekb_brst_add     : std_logic;
    signal single_ahb_wr      : std_logic;
begin

-------------------------------------------------------------------------------
-- Begin architecture logic
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- AHB I/O signal assignments
-------------------------------------------------------------------------------

    M_AHB_HADDR           <= HADDR_i;
    M_AHB_HWRITE          <= HWRITE_i;
    M_AHB_HWDATA          <= HWDATA_i;
    M_AHB_HPROT           <= HPROT_i;
    M_AHB_HMASTLOCK       <= HLOCK_i;
    M_AHB_HSIZE           <= HSIZE_i;
    M_AHB_HBURST          <= HBURST_i;
    
-------------------------------------------------------------------------------
-- Internal signal assignments
-------------------------------------------------------------------------------

    ahb_hslverr        <= M_AHB_HRESP;
    ahb_hready         <= M_AHB_HREADY;
    ahb_hrdata         <= M_AHB_HRDATA;
    send_rlast         <= send_rlast_sm;
    send_bresp         <= send_bresp_sm;

--*****************************************************************************
-- Combinational logic to generate a fixed burst access signal when AXI 
-- initiated the Fixed burst
--*****************************************************************************

   fixed_burst_access <= '1' when axi_burst = "00" else '0';

--*****************************************************************************
-- Combinational logic to generate a incr burst access signal when AXI
-- initiated the incr burst
--*****************************************************************************

   incr_burst_access <= '1' when axi_burst = "01" else '0';

--*****************************************************************************
-- Combinational logic to generate a wrap burst access signal when AXI
-- initiated the wrap burst
--*****************************************************************************

   wrap_burst_access <= '1' when axi_burst = "10" else '0';

--*****************************************************************************
-- Combinational logic to generate wrap_four, wrap_eight,wrap_sixteen signals
-- These signals are used in the address generation logic
--*****************************************************************************

   wrap_four <= '1' when axi_length(3 downto 0) ="0011" and 
                         wrap_in_progress = '1' else '0';

   wrap_eight <= '1' when axi_length(3 downto 0) ="0111" and
                         wrap_in_progress = '1' else '0';
   
   wrap_sixteen <= '1' when axi_length(3 downto 0) ="1111" and
                         wrap_in_progress = '1' else '0';

-- ****************************************************************************
-- This process is used for driving the AHB write data when the control signal
-- is sent from AHB state machine
-- ****************************************************************************

       AHB_WDATA_REG : process(AHB_HCLK) is
       begin
          if (AHB_HCLK'event and AHB_HCLK = '1') then
              if (AHB_HRESETN = '0') then
                  HWDATA_i <= (others => '0');
              else
                  if (send_wr_data = '1') then
                     HWDATA_i <= axi_wdata;                       
                  end if;
             end if;
          end if;
       end process AHB_WDATA_REG;

-- ****************************************************************************
-- This process is used for driving the AHB TRANS signal. Depending on the
-- control signals from AHB state machine, the type of transfer is sent.
-- If timeout occurs and AXI timeout transfer is in progress then
-- sending the IDLE on M_AHB_HTRANS.
-- ****************************************************************************

       AHB_TRANS_REG : process(AHB_HCLK) is
       begin
         if (AHB_HCLK'event and AHB_HCLK = '1') then
            if (AHB_HRESETN = '0') then
               M_AHB_HTRANS <= (others => '0');
            else
               if (send_trans_nonseq = '1' and timeout_inprogress = '0') then
                  M_AHB_HTRANS <= NONSEQ;                       
               elsif (send_trans_seq = '1' and timeout_inprogress = '0') then
                  M_AHB_HTRANS <= SEQ;                       
               elsif (send_trans_idle = '1' and timeout_inprogress = '0') then
                  M_AHB_HTRANS <= IDLE;                       
               elsif (send_trans_busy = '1' and timeout_inprogress = '0') then
                  M_AHB_HTRANS <= BUSY;       
               elsif(timeout_inprogress = '1') then
                  M_AHB_HTRANS <= IDLE;                
               end if;
            end if;
         end if;
       end process AHB_TRANS_REG;

-- ****************************************************************************
-- This process is used for driving the AHB WRITE control signal.
-- ****************************************************************************

       AHB_WRITE_REG : process(AHB_HCLK) is
       begin
          if (AHB_HCLK'event and AHB_HCLK = '1') then
              if (AHB_HRESETN = '0') then
                 HWRITE_i <= '0';
              else
                 if (ahb_rd_request = '1') then 
                       HWRITE_i <= '0';                       
                 elsif (ahb_wr_request = '1') then 
                       HWRITE_i <= '1';                       
                 end if;
              end if;
          end if;
       end process AHB_WRITE_REG;

-- ****************************************************************************
-- This process is used for generating the control signal that says WRAP 
-- transfer is in progress. This is used in AHB state machine for driving
-- the kind of AHB transfer type.
-- ****************************************************************************

       AHB_WRAP_REG : process(AHB_HCLK) is
       begin
          if (AHB_HCLK'event and AHB_HCLK = '1') then
              if (AHB_HRESETN = '0') then
                 wrap_in_progress <= '0';
              else
                 if (send_wrap_burst = '1') then 
                       wrap_in_progress <= '1';                       
                 elsif (send_rlast_sm = '1' or send_bresp_sm = '1') then 
                       wrap_in_progress <= '0';                       
                 end if;
              end if;
          end if;
       end process AHB_WRAP_REG;

-- ****************************************************************************
-- This combo is used for generating the control signal that says WRAP 2
-- transfer is in progress. This is used in AHB state machine for converting
-- WRAP 2 on AXI to 2 single transfers on AHB since WRAP2 is not available 
-- on AHB
-- ****************************************************************************
     
     wrap_2_in_progress <= '1' when (wrap_in_progress = '1') and 
                               (axi_length(3 downto 0) = "0001")
                               else
                           '0';
-- ****************************************************************************
-- This process is used for driving the AHB address signal for 32-bit AHB data
-- and when Narrow burst enabled. Either 8/16/32 data bits can be tranferred in
-- each beat when C_M_AHB_DATA_WIDTH=32 and C_S_AXI_SUPPORTS_NARROW_BURST=1
-- ****************************************************************************

    GEN_32_DATA_WIDTH_NARROW: if (C_M_AHB_DATA_WIDTH = 32  and  
                              C_S_AXI_SUPPORTS_NARROW_BURST = 1) generate

    begin
    
-- ****************************************************************************
-- This process is used for driving the AHB address signal AHB_HADDR 
-- address will be incremented or wrapped depending on the control signal from
-- the AHB state machine.
-- ****************************************************************************

       AHB_ADDRESS_REG : process(AHB_HCLK) is
       begin
          if (AHB_HCLK'event and AHB_HCLK = '1') then
              if (AHB_HRESETN = '0') then
                 HADDR_i <= (others => '0');
              else
                 if (ahb_wr_request = '1' or ahb_rd_request = '1') then
                     if(axi_size = "010") then
                        HADDR_i(31 downto 2) <= axi_address(31 downto 2);
                        HADDR_i(1 downto 0)  <= "00";
                     elsif(axi_size = "001" ) then
                        HADDR_i(31 downto 1) <= axi_address(31 downto 1);
                        HADDR_i(0)           <= '0'; 
                     else
                        HADDR_i              <= axi_address;
                     end if;
                 elsif (incr_addr = '1' and fixed_burst_access = '0' ) then
                     case axi_size is
                     when "000" => -- 8-bit access
                       if(wrap_2_in_progress = '1') then
                         HADDR_i(31 downto 1) <= HADDR_i(31 downto 1);
                         HADDR_i(0) <= not (HADDR_i(0)); 
                       elsif(wrap_four = '1') then
                         HADDR_i(31 downto 2) <= HADDR_i(31 downto 2);
                         HADDR_i(1 downto 0) <= HADDR_i(1 downto 0) + "01";
                       elsif(wrap_eight = '1') then
                         HADDR_i(31 downto 3) <= HADDR_i(31 downto 3);
                         HADDR_i(2 downto 0) <= HADDR_i(2 downto 0) + "001";
                       elsif(wrap_sixteen = '1') then
                         HADDR_i(31 downto 4) <= HADDR_i(31 downto 4);
                         HADDR_i(3 downto 0) <= HADDR_i(3 downto 0) + "0001";
                       else
                         HADDR_i <= HADDR_i + "0001";
                       end if;
                     when "001" => -- 16-bit access
                       if(wrap_2_in_progress = '1') then
                         HADDR_i(31 downto 2) <= HADDR_i(31 downto 2);
                         HADDR_i(1 downto 0) <= HADDR_i(1 downto 0) + "10";
                       elsif(wrap_four = '1') then
                         HADDR_i(31 downto 3) <= HADDR_i(31 downto 3);
                         HADDR_i(2 downto 0) <= HADDR_i(2 downto 0) + "010";
                       elsif(wrap_eight = '1') then
                         HADDR_i(31 downto 4) <= HADDR_i(31 downto 4);
                         HADDR_i(3 downto 0) <= HADDR_i(3 downto 0) + "0010";
                       elsif(wrap_sixteen = '1') then
                         HADDR_i(31 downto 5) <= HADDR_i(31 downto 5);
                         HADDR_i(4 downto 0) <= HADDR_i(4 downto 0) + "00010";
                       else
                         HADDR_i <= HADDR_i + "0010";
                       end if;
                     when "010" => -- 32-bit access
                       if(wrap_2_in_progress = '1') then
                          HADDR_i(31 downto 3) <= HADDR_i(31 downto 3);
                          HADDR_i(2 downto 0)<=HADDR_i(2 downto 0) + "100";
                       elsif(wrap_four = '1') then
                          HADDR_i(31 downto 4) <= HADDR_i(31 downto 4);
                          HADDR_i(3 downto 0)<=HADDR_i(3 downto 0) + "0100";
                       elsif(wrap_eight = '1') then
                          HADDR_i(31 downto 5) <= HADDR_i(31 downto 5);
                          HADDR_i(4 downto 0)<=HADDR_i(4 downto 0) + "00100";
                       elsif(wrap_sixteen = '1') then
                          HADDR_i(31 downto 6) <= HADDR_i(31 downto 6);
                          HADDR_i(5 downto 0)<=HADDR_i(5 downto 0) + "000100";
                       else
                          HADDR_i <= HADDR_i + "0100";
                       end if;
                     -- coverage off
                     when others => 
                       HADDR_i <= HADDR_i;
                     -- coverage on
                     end case;
                 else
                       HADDR_i <= HADDR_i;
                 end if;
              end if;
          end if;
       end process AHB_ADDRESS_REG;

    end generate GEN_32_DATA_WIDTH_NARROW;
    
-- ****************************************************************************
-- This process is used for driving the AHB address signal for 64-bit AHB data
-- and when Narrow burst enabled.Either 8/16/32/64data bits can be tranferred in
-- each beat when C_M_AHB_DATA_WIDTH=64 and C_S_AXI_SUPPORTS_NARROW_BURST=1
-- ****************************************************************************

    GEN_64_DATA_WIDTH_NARROW : if (C_M_AHB_DATA_WIDTH = 64 and  
                              C_S_AXI_SUPPORTS_NARROW_BURST = 1) generate

    begin
    
-- ****************************************************************************
-- This process is used for driving the AHB address signal AHB_HADDR. The
-- address will be incremented or wrapped depending on the control signal from
-- the AHB state machine.
-- ****************************************************************************

       AHB_ADDRESS_REG : process(AHB_HCLK) is
       begin
          if (AHB_HCLK'event and AHB_HCLK = '1') then
              if (AHB_HRESETN = '0') then
                 HADDR_i <= (others => '0');
              else
                 if (ahb_wr_request = '1' or ahb_rd_request = '1') then
                       if(axi_size = "011") then
                         HADDR_i(31 downto 3) <= axi_address(31 downto 3);
                         HADDR_i(2 downto 0)  <= "000";
                       elsif(axi_size = "010") then
                         HADDR_i(31 downto 2) <= axi_address(31 downto 2);
                         HADDR_i(1 downto 0)  <= "00";
                       elsif(axi_size = "001") then
                         HADDR_i(31 downto 1) <= axi_address(31 downto 1);
                         HADDR_i(0)           <= '0';
                       else
                         HADDR_i              <= axi_address;
                       end if;
                 elsif (incr_addr = '1' and fixed_burst_access = '0') then
                   case axi_size is
                     when "000" =>   -- 8-bit access
                        if(wrap_2_in_progress = '1') then
                           HADDR_i(31 downto 1) <= HADDR_i(31 downto 1);
                           HADDR_i(0) <= not (HADDR_i(0)) ;
                        elsif( wrap_four = '1') then
                           HADDR_i(31 downto 2) <= HADDR_i(31 downto 2);
                           HADDR_i(1 downto 0) <= HADDR_i(1 downto 0) + "01";
                        elsif(wrap_eight = '1') then
                           HADDR_i(31 downto 3) <= HADDR_i(31 downto 3);
                           HADDR_i(2 downto 0) <= HADDR_i(2 downto 0) + "001";
                        elsif(wrap_sixteen = '1') then
                           HADDR_i(31 downto 4) <= HADDR_i(31 downto 4);
                           HADDR_i(3 downto 0) <= HADDR_i(3 downto 0) + "0001";
                        else
                           HADDR_i <= HADDR_i + "0001";
                        end if;
                     when "001" =>  --16 -bit access
                         if(wrap_2_in_progress = '1') then
                            HADDR_i(31 downto 2) <= HADDR_i(31 downto 2);
                            HADDR_i(1 downto 0) <= HADDR_i(1 downto 0) + "10";
                         elsif(wrap_four = '1') then
                            HADDR_i(31 downto 3) <= HADDR_i(31 downto 3);
                            HADDR_i(2 downto 0) <= HADDR_i(2 downto 0) + "010";
                         elsif(wrap_eight = '1') then
                            HADDR_i(31 downto 4) <= HADDR_i(31 downto 4);
                            HADDR_i(3 downto 0) <= HADDR_i(3 downto 0) + "0010";
                         elsif(wrap_sixteen = '1') then
                            HADDR_i(31 downto 5) <= HADDR_i(31 downto 5);
                            HADDR_i(4 downto 0)<=HADDR_i(4 downto 0) + "00010";
                         else
                            HADDR_i <= HADDR_i + "0010";
                         end if;
                      when "010" => -- 32-bit access
                         if(wrap_2_in_progress = '1') then
                           HADDR_i(31 downto 3) <= HADDR_i(31 downto 3);
                           HADDR_i(2 downto 0)<=HADDR_i(2 downto 0) + "100";
                         elsif(wrap_four = '1') then
                           HADDR_i(31 downto 4) <= HADDR_i(31 downto 4);
                           HADDR_i(3 downto 0)<=HADDR_i(3 downto 0) + "0100";
                         elsif(wrap_eight = '1') then
                           HADDR_i(31 downto 5) <= HADDR_i(31 downto 5);
                           HADDR_i(4 downto 0)<=HADDR_i(4 downto 0) + "00100";
                         elsif(wrap_sixteen = '1') then
                           HADDR_i(31 downto 6) <= HADDR_i(31 downto 6);
                           HADDR_i(5 downto 0)<=HADDR_i(5 downto 0) + "000100";
                         else
                            HADDR_i <= HADDR_i + "0100";
                         end if;
                      when "011" => -- 64-bit access
                         if(wrap_2_in_progress = '1') then
                           HADDR_i(31 downto 4) <= HADDR_i(31 downto 4);
                           HADDR_i(3 downto 0)  <= HADDR_i(3 downto 0) + "1000";
                         elsif(wrap_four = '1') then
                           HADDR_i(31 downto 5) <= HADDR_i(31 downto 5);
                           HADDR_i(4 downto 0)  <= HADDR_i(4 downto 0) + "01000";
                         elsif(wrap_eight = '1') then
                           HADDR_i(31 downto 6) <= HADDR_i(31 downto 6);
                           HADDR_i(5 downto 0)  <= HADDR_i(5 downto 0) + "001000";
                         elsif(wrap_sixteen = '1') then
                           HADDR_i(31 downto 7) <= HADDR_i(31 downto 7);
                           HADDR_i(6 downto 0)  <= HADDR_i(6 downto 0) + "0001000";
                         else
                            HADDR_i <= HADDR_i + "1000";
                       end if;

                       -- coverage off
                      when others => 
                          HADDR_i <= HADDR_i;
                       -- coverage on
                     end case;
                 else
                       HADDR_i <= HADDR_i;
                 end if;
              end if;
          end if;
       end process AHB_ADDRESS_REG;

    end generate GEN_64_DATA_WIDTH_NARROW;


-- ****************************************************************************
-- This process is used for driving the AHB address signal for 32-bit AHB data
-- width with out narrow burst transfers
-- ****************************************************************************

    GEN_32_DATA_WIDTH : if (C_M_AHB_DATA_WIDTH = 32 and  
                              C_S_AXI_SUPPORTS_NARROW_BURST = 0) generate

    begin
    
-- ****************************************************************************
-- This process is used for driving the AHB address signal AHB_HADDR. The
-- address will be incremented or wrapped depending on the control signal from
-- the AHB state machine.
-- ****************************************************************************

       AHB_ADDRESS_REG : process(AHB_HCLK) is
       begin
          if (AHB_HCLK'event and AHB_HCLK = '1') then
              if (AHB_HRESETN = '0') then
                 HADDR_i <= (others => '0');
              else
                 if (ahb_wr_request = '1' or ahb_rd_request = '1') then
                       HADDR_i(31 downto 2) <= axi_address(31 downto 2);
                       HADDR_i(1 downto 0) <= "00";
                 elsif (incr_addr = '1' and fixed_burst_access = '0' ) then
                     if (wrap_2_in_progress = '1') then
                        HADDR_i(31 downto 3) <= HADDR_i(31 downto 3);
                        HADDR_i(2 downto 0) <= HADDR_i(2 downto 0) + "100";
                     elsif( wrap_four = '1') then
                        HADDR_i(31 downto 4) <= HADDR_i(31 downto 4);
                        HADDR_i(3 downto 0) <= HADDR_i(3 downto 0) + "0100";
                     elsif(wrap_eight = '1') then
                        HADDR_i(31 downto 5) <= HADDR_i(31 downto 5);
                        HADDR_i(4 downto 0) <= HADDR_i(4 downto 0) + "00100";
                     elsif(wrap_sixteen = '1') then
                        HADDR_i(31 downto 6) <= HADDR_i(31 downto 6);
                        HADDR_i(5 downto 0) <= HADDR_i(5 downto 0) + "000100";
                     else
                        HADDR_i <= HADDR_i + "0100";
                     end if;
                 else
                       HADDR_i <= HADDR_i;
                 end if;
              end if;
          end if;
       end process AHB_ADDRESS_REG;

    end generate GEN_32_DATA_WIDTH;
    
-- ****************************************************************************
-- This process is used for driving the AHB address signal for 64-bit AHB data
-- width with out narrow burst transfers
-- ****************************************************************************

    GEN_64_DATA_WIDTH : if (C_M_AHB_DATA_WIDTH = 64 and  
                              C_S_AXI_SUPPORTS_NARROW_BURST = 0) generate

    begin
    
-- ****************************************************************************
-- This process is used for driving the AHB address signal AHB_HADDR. The
-- address will be incremented or wrapped depending on the control signal from
-- the AHB state machine.
-- ****************************************************************************

       AHB_ADDRESS_REG : process(AHB_HCLK) is
       begin
          if (AHB_HCLK'event and AHB_HCLK = '1') then
              if (AHB_HRESETN = '0') then
                 HADDR_i <= (others => '0');
              else
                 if (ahb_wr_request = '1' or ahb_rd_request = '1') then
                       HADDR_i(31 downto 3) <= axi_address(31 downto 3);
                       HADDR_i(2 downto 0) <= "000";
                 elsif (incr_addr = '1' and fixed_burst_access = '0') then
                     if (wrap_2_in_progress = '1') then
                        HADDR_i(31 downto 4) <= HADDR_i(31 downto 4);
                        HADDR_i(3 downto 0) <= HADDR_i(3 downto 0) + "1000";
                     elsif(wrap_four = '1') then
                        HADDR_i(31 downto 5) <= HADDR_i(31 downto 5);
                        HADDR_i(4 downto 0) <= HADDR_i(4 downto 0) + "01000";
                     elsif(wrap_eight = '1') then
                        HADDR_i(31 downto 6) <= HADDR_i(31 downto 6);
                        HADDR_i(5 downto 0) <= HADDR_i(5 downto 0) + "001000";
                     elsif(wrap_sixteen = '1') then
                        HADDR_i(31 downto 7) <= HADDR_i(31 downto 7);
                        HADDR_i(6 downto 0) <= HADDR_i(6 downto 0) + "0001000";
                     else
                        HADDR_i <= HADDR_i + "1000";
                     end if;
                 else
                       HADDR_i <= HADDR_i;
                 end if;
              end if;
          end if;
       end process AHB_ADDRESS_REG;

    end generate GEN_64_DATA_WIDTH;

-- ****************************************************************************
-- This process is used for driving the AHB PROT when a write or a read
-- is requested.default value "0011" is driving on to HPROT_i as per the
-- ARM recommendation. There is no cacheble in AXI always sending non_cacheble
-- transaction on AHB. 
-- ****************************************************************************

       AHB_PROT_REG : process(AHB_HCLK) is
       begin
          if (AHB_HCLK'event and AHB_HCLK = '1') then
              if (AHB_HRESETN = '0') then
                 HPROT_i <= "0011";
              else
                 if (ahb_wr_request = '1' or ahb_rd_request = '1') then
                       HPROT_i(3) <= '0';
                       HPROT_i(2) <= axi_cache(0) and not(axi_cache(2)) and
                                     not(axi_cache(3));
                       HPROT_i(1) <= axi_prot(0);
                       HPROT_i(0) <= not axi_prot(2);
                 end if;
              end if;
          end if;
       end process AHB_PROT_REG;
       
-------------------------------------------------------------------------------
-- Counter for generating the count for INCR/WRAP burst transfers. Same counter
-- is used for both WRAP and INCR burst transfers.
-------------------------------------------------------------------------------

   WRAP_BURST_COUNTER_REG : process(AHB_HCLK) is
   begin
      if (AHB_HCLK'event and AHB_HCLK = '1') then
          if (AHB_HRESETN = '0') then
            wrap_brst_count <= (others => '0');
          else
              if (load_counter = '1' ) then
                  wrap_brst_count <= axi_length +  1;
              elsif (burst_ready = '1' ) then
                  wrap_brst_count <= wrap_brst_count - 1;
              end if;
          end if;
      end if;
   end process WRAP_BURST_COUNTER_REG;

-------------------------------------------------------------------------------
-- Control signals to generate the last signal of burst transfers. This logic
-- Uses the wrap_brst_count generated by the WRAP_BURST_COUNTER_REG process
-------------------------------------------------------------------------------

   wrap_brst_last <= '1' when wrap_brst_count = "0000001" else '0';
   wrap_brst_one <= '1' when wrap_brst_count = "0000010" else '0';

-------------------------------------------------------------------------------
-- Control signal generated when the axi length less than or equal to 16. This
-- Control signal is used in generating the ahb_burst signal generation
-------------------------------------------------------------------------------

   axi_len_les_eq_sixteen <= '1' when axi_length(7 downto 4) = "0000" else '0';

-------------------------------------------------------------------------------
-- This combinational process generates the AHB BURST type signal
-- Based on axi_length, wrap/incr burst access and onekb_cross_access the
-- ahb_burst is generated.
-------------------------------------------------------------------------------

   onekb_brst_add <= axi_end_address(10) or axi_end_address(11);

   AHB_BURST_LENGTH_CMB : process(incr_burst_access, axi_length(3 downto 0),
                                  axi_len_les_eq_sixteen,onekb_brst_add,
                                  wrap_burst_access) is
   begin
     if(axi_length(3 downto 0) = "1111" and axi_len_les_eq_sixteen = '1') then
         if(wrap_burst_access = '1' ) then
            ahb_burst <= "110";
         elsif(incr_burst_access = '1' and onekb_brst_add = '0' ) then
            ahb_burst <= "111";
         elsif(incr_burst_access = '1' and onekb_brst_add = '1' ) then
            ahb_burst <= "001";
         else
            ahb_burst <= "000";
         end if;
     elsif(axi_length(2 downto 0) = "111" and axi_len_les_eq_sixteen='1') then
         if(wrap_burst_access = '1' ) then
            ahb_burst <= "100";
         elsif(incr_burst_access = '1'  and onekb_brst_add = '0') then
            ahb_burst <= "101";
         elsif(incr_burst_access = '1'  and onekb_brst_add = '1') then
            ahb_burst <= "001";
         else
            ahb_burst <= "000";
         end if;
     elsif(axi_length(3 downto 0) = "0011" and axi_len_les_eq_sixteen='1') then
         if (wrap_burst_access = '1' ) then
            ahb_burst <= "010";
         elsif(incr_burst_access = '1' and onekb_brst_add = '0' ) then
            ahb_burst <= "011";
         elsif(incr_burst_access = '1'  and onekb_brst_add = '1') then
            ahb_burst <= "001";
         else
            ahb_burst <= "000";
         end if;
     else
         if(incr_burst_access = '1' and axi_length(3 downto 0) = "0000" and
            axi_len_les_eq_sixteen = '1') then
           ahb_burst <= "000";
         elsif(incr_burst_access = '1') then
           ahb_burst <= "001";
         else
           ahb_burst <= "000";
         end if;
     end if;
   end process AHB_BURST_LENGTH_CMB;

-- ****************************************************************************
-- This process is used for registering the AHB HBURST. 
-- ****************************************************************************

   AHB_BURST_REG : process(AHB_HCLK) is
   begin
        if (AHB_HCLK'event and AHB_HCLK = '1') then
           if (AHB_HRESETN = '0') then
               HBURST_i <= (others => '0');
           else
               HBURST_i <= ahb_burst;
           end if;
        end if;
   end process AHB_BURST_REG;
   
-- ****************************************************************************
-- This process is used for registering the axi_size. 
-- ****************************************************************************
   
   AHB_SIZE_REG : process(AHB_HCLK) is
      begin
           if (AHB_HCLK'event and AHB_HCLK = '1') then
              if (AHB_HRESETN = '0') then
                  HSIZE_i <= (others => '0');
              else 
                  HSIZE_i <= axi_size;
              end if;
           end if;
   end process AHB_SIZE_REG;
   
-- ****************************************************************************
-- This process is used for registering the axi_lock. 
-- ****************************************************************************
      
      AHB_LOCK_REG : process(AHB_HCLK) is
      begin
            if (AHB_HCLK'event and AHB_HCLK = '1') then
               if (AHB_HRESETN = '0') then
                   HLOCK_i <= '0';
               else
                   HLOCK_i <= axi_lock;
               end if;
            end if;
   end process AHB_LOCK_REG;
   
-------------------------------------------------------------------------------
-- process to register the single write transfer during start of each access
-------------------------------------------------------------------------------

  SINGLE_WRITE_REG : process(AHB_HCLK) is
     begin
       if (AHB_HCLK'event and AHB_HCLK = '1') then
          if (AHB_HRESETN = '0') then
            single_ahb_wr <= '0';
          else
            if(ahb_wr_request = '1') then
              single_ahb_wr <= single_ahb_wr_xfer; 
            end if;
          end if;
       end if;
   end process SINGLE_WRITE_REG;

-- ****************************************************************************
-- AHB State Machine -- START
-- This state machine generates the read and write control signals for
-- transferring the data to/from AHB slave.M_AHB_HTRANS i.e.i AHB transfer type
-- signal is also driven by the control signal generated in this state machine 
-- ****************************************************************************

   AHB_WR_RD_SM   : process (ahb_wr_rd_cs,
                             ahb_wr_request,
                             ahb_rd_request,
                             ahb_hslverr,
                             ahb_hready,
                             ahb_hrdata,
                             axi_burst,
                             fixed_burst_access,
                             single_ahb_wr,
                             single_ahb_rd_xfer,
                             wrap_brst_last,
                             send_ahb_wr,
                             axi_wvalid,
                             wrap_brst_one,
                             axi_rready,
                             one_kb_cross,
                             one_kb_in_progress,
                             wrap_2_in_progress,
                             timeout_inprogress
                            ) is
   begin

     ahb_wr_rd_ns <= ahb_wr_rd_cs;
     rd_data      <= (others => '0');
     slv_err_resp <= '0';
     burst_ready  <= '0';
     send_wr_data <= '0';
     send_wvalid  <= '0';
     incr_addr    <= '0';
     ahb_write_sm <= '0';
     send_bresp_sm     <= '0';
     load_counter_sm   <= '0';
     send_rvalid       <= '0';
     send_rlast_sm     <= '0';
     send_trans_nonseq <= '0';
     send_trans_seq  <= '0';
     send_trans_idle <= '0';
     send_trans_busy <= '0';
     send_wrap_burst <= '0';
     one_kb_splitted <= '0';
     load_cntr       <= '0';
     cntr_enable     <= '0';

      case ahb_wr_rd_cs is

           when AHB_IDLE =>
                if(ahb_wr_request = '1' ) then
                   send_wrap_burst   <= axi_burst(1) and (not axi_burst(0));                        
                   load_counter_sm   <= '1';
                   load_cntr         <= '1';
                   send_trans_nonseq <= '1';
                   ahb_wr_rd_ns <= AHB_WR_ADDR;
                elsif (ahb_rd_request = '1') then
                   send_trans_nonseq <= '1';
                   load_cntr         <= '1';
                   if (single_ahb_rd_xfer = '1') then
                      ahb_wr_rd_ns   <= AHB_RD_SINGLE;
                   elsif(axi_burst(1) = '0') then
                      load_counter_sm <= '1';
                      ahb_wr_rd_ns    <= AHB_RD_ADDR;
                   elsif(axi_burst = "10" ) then
                      send_wrap_burst <= '1';
                      load_counter_sm <= '1';
                      ahb_wr_rd_ns    <= AHB_RD_ADDR;
                   end if;
                end if;

           when AHB_WR_SINGLE =>
                cntr_enable <= '1';
                if(ahb_hready = '1' or timeout_inprogress = '1') then
                   cntr_enable   <= timeout_inprogress;
                   load_cntr     <= not timeout_inprogress;
                   send_bresp_sm <= '1';
                   slv_err_resp  <= ahb_hslverr;
                   burst_ready   <= '1';
                   ahb_wr_rd_ns  <= AHB_IDLE;
                end if;                
           
           when AHB_WR_WAIT =>
                if(send_ahb_wr = '1') then
                   if (one_kb_in_progress = '1' and one_kb_cross = '0') then
                      send_trans_nonseq <= '1';
                      one_kb_splitted   <= '1';
                   elsif(fixed_burst_access = '1') then
                      send_trans_nonseq <= '1';
                   else
                      send_trans_seq    <= '1';
                   end if;                              
                   ahb_wr_rd_ns <= AHB_INCR_ADDR;
                else
                   send_trans_idle <= fixed_burst_access;
                end if;

           when AHB_INCR_ADDR =>
                cntr_enable <= '1';
                if(ahb_hready = '1' or timeout_inprogress = '1') then
                   cntr_enable  <= timeout_inprogress;
                   load_cntr    <= not timeout_inprogress;
                   send_wr_data <= '1';
                   incr_addr    <= '1';
                   if(one_kb_in_progress='1' or fixed_burst_access='1') then
                      send_trans_idle <= '1';
                   else
                      send_trans_busy <= '1';
                   end if;
                   ahb_wr_rd_ns <= AHB_WR_INCR; 
                end if;                

           when AHB_LAST_ADDR =>
                cntr_enable <= '1';
                if(ahb_hready = '1' or timeout_inprogress = '1') then
                   cntr_enable     <= timeout_inprogress;
                   load_cntr       <= not timeout_inprogress;     
                   send_wr_data    <= '1';
                   send_trans_idle <= '1';
                   ahb_wr_rd_ns    <= AHB_WR_INCR;
                end if;                
           
           when AHB_LAST_WAIT =>
                if(send_ahb_wr = '1') then
                  if(one_kb_in_progress = '1' and one_kb_cross = '0') then
                     send_trans_nonseq <= '1';
                     one_kb_splitted   <= '1';
                  elsif(fixed_burst_access='1' or wrap_2_in_progress='1' ) then
                     send_trans_nonseq <= '1';
                  else
                     send_trans_seq <= '1';
                  end if;
                  ahb_wr_rd_ns <= AHB_LAST_ADDR;
                elsif(one_kb_in_progress = '1' and one_kb_cross  = '0') then
                  ahb_wr_rd_ns <= AHB_ONEKB_LAST;
                end if;
           when AHB_LAST =>
                if(send_ahb_wr = '1') then
                  if(fixed_burst_access='1' or wrap_2_in_progress='1' ) then
                     send_trans_nonseq <= '1';
                  else
                     send_trans_seq <= '1';
                  end if;
                  ahb_wr_rd_ns <= AHB_LAST_ADDR;
                end if;
           when AHB_ONEKB_LAST =>
                if(send_ahb_wr = '1') then
                   send_trans_nonseq <= '1';
                   one_kb_splitted <= '1';
                   ahb_wr_rd_ns <= AHB_LAST_ADDR;
                end if;                
           when AHB_WR_INCR =>
                cntr_enable <= '1';
                if(ahb_hready = '1' or timeout_inprogress = '1') then
                  cntr_enable  <= timeout_inprogress;
                  load_cntr    <= not timeout_inprogress;
                  burst_ready  <= '1';
                  send_wvalid  <= '1';
                  slv_err_resp <= ahb_hslverr;                     
                  if(wrap_brst_last = '1') then
                    send_bresp_sm   <= '1';
                    send_trans_idle <= '1';
                    ahb_wr_rd_ns    <= AHB_IDLE;
                  elsif (wrap_brst_one = '1') then
                    if(axi_wvalid = '1') then
                      if(one_kb_in_progress = '1' and one_kb_cross = '0') then
                        send_trans_nonseq <= '1';
                        one_kb_splitted   <= '1';
                      elsif(fixed_burst_access='1' or 
                            wrap_2_in_progress='1') then
                        send_trans_nonseq <= '1';
                      else
                        send_trans_seq <= '1';
                      end if;
                      ahb_wr_rd_ns <= AHB_LAST_ADDR;
                    else
                      if((one_kb_in_progress = '1' and one_kb_cross = '0') or
                         fixed_burst_access='1' or wrap_2_in_progress='1') then
                         send_trans_idle <= '1';
                         ahb_wr_rd_ns <= AHB_LAST_WAIT;
                      else
                         send_trans_busy <= '1';
                         ahb_wr_rd_ns <= AHB_LAST;
                      end if;
                  end if;  
                  else                             
                    if(axi_wvalid = '1') then
                      if(one_kb_in_progress = '1' and one_kb_cross = '0') then
                        send_trans_nonseq <= '1';
                        one_kb_splitted <= '1';
                      elsif(fixed_burst_access = '1') then
                        send_trans_nonseq <= '1';
                      else
                        send_trans_seq <= '1';
                      end if;
                      ahb_wr_rd_ns <= AHB_INCR_ADDR;                              
                    else
                      send_trans_idle <= fixed_burst_access;
                      ahb_wr_rd_ns    <= AHB_WR_WAIT;
                    end if;
                  end if;
                end if;                           

           when AHB_WR_ADDR =>
                cntr_enable <= '1';
                if(ahb_hready = '1' or timeout_inprogress = '1') then
                   cntr_enable  <= timeout_inprogress;
                   load_cntr    <= not timeout_inprogress;
                   send_wr_data <= '1';
                   if (single_ahb_wr = '1') then
                      send_trans_idle <= '1';
                      ahb_wr_rd_ns    <= AHB_WR_SINGLE;
                   elsif (wrap_2_in_progress = '1' or fixed_burst_access = '1'
                          or one_kb_in_progress = '1' or one_kb_cross='1') then
                      send_trans_idle <= '1';
                      incr_addr       <= '1';
                      ahb_wr_rd_ns    <= AHB_WR_INCR;   
                   else                      
                      incr_addr       <= '1';
                      send_trans_busy <= '1';
                      ahb_wr_rd_ns    <= AHB_WR_INCR;                     
                   end if;               
                end if;                

           when AHB_RD_SINGLE =>
                cntr_enable <= '1';
                if(ahb_hready = '1' or timeout_inprogress = '1') then
                   cntr_enable     <= timeout_inprogress;
                   load_cntr       <= not timeout_inprogress;
                   send_trans_idle <= '1';
                   ahb_wr_rd_ns    <= AHB_RD_LAST;
                end if;

           when AHB_RD_LAST =>
                cntr_enable <= '1';
                if(ahb_hready = '1' or timeout_inprogress = '1') then
                   cntr_enable   <= timeout_inprogress;
                   load_cntr     <= not timeout_inprogress;
                   burst_ready   <= '1';
                   slv_err_resp  <= ahb_hslverr;
                   rd_data       <= ahb_hrdata;
                   send_rvalid   <= '1';
                   send_rlast_sm <= '1';
                   ahb_wr_rd_ns  <= AHB_IDLE;
                end if;
           
           when AHB_RD_ADDR =>
                cntr_enable <= '1';
                if(ahb_hready = '1' or timeout_inprogress = '1') then
                   cntr_enable <= timeout_inprogress;
                   load_cntr   <= not timeout_inprogress; 
                   if (wrap_brst_last = '1') then                         
                       send_trans_idle <= '1';
                       ahb_wr_rd_ns    <= AHB_RD_LAST;
                   elsif (wrap_2_in_progress = '1' or fixed_burst_access = '1'
                          or one_kb_in_progress = '1' or one_kb_cross='1') then
                       send_trans_idle <= '1';
                       incr_addr       <= '1';
                       ahb_wr_rd_ns    <= AHB_RD_DATA_INCR;                     
                   else 
                       incr_addr       <= '1';
                       send_trans_busy <= '1';
                       ahb_wr_rd_ns    <= AHB_RD_DATA_INCR;
                   end if;
                end if;

           when AHB_RD_WAIT =>
                if(axi_rready = '1') then
                  if (one_kb_in_progress = '1' and one_kb_cross = '0') then
                      send_trans_nonseq <= '1';
                      one_kb_splitted   <= '1';
                  elsif(fixed_burst_access='1' or wrap_2_in_progress='1') then
                      send_trans_nonseq <= '1';
                  else
                      send_trans_seq    <= '1';
                  end if; 
                  ahb_wr_rd_ns <= AHB_RD_ADDR;
                end if;
          
           when AHB_RD_DATA_INCR =>
                cntr_enable <= '1';
                if(ahb_hready = '1' or timeout_inprogress = '1') then
                   cntr_enable  <= timeout_inprogress;
                   load_cntr    <= not timeout_inprogress;
                   burst_ready  <= '1';
                   slv_err_resp <= ahb_hslverr;
                   rd_data      <= ahb_hrdata;
                   send_rvalid  <= '1';
                   if (axi_rready = '1') then
                      if (one_kb_in_progress = '1' and one_kb_cross = '0') then
                          send_trans_nonseq <= '1';
                          one_kb_splitted   <= '1';
                      elsif(wrap_2_in_progress='1' or
                            fixed_burst_access='1') then
                          send_trans_nonseq <= '1';
                      else
                          send_trans_seq <= '1';
                      end if;                              
                      ahb_wr_rd_ns <= AHB_RD_ADDR;
                   else
                      ahb_wr_rd_ns <= AHB_RD_WAIT;
                   end if;
                end if;                

          -- coverage off
            when others =>
                ahb_wr_rd_ns <= AHB_IDLE;
          -- coverage on

       end case;

   end process AHB_WR_RD_SM;

-------------------------------------------------------------------------------
-- Registering the current state and load_counter signals generated from the 
-- AHB state machine
-------------------------------------------------------------------------------

   AHB_WR_RD_SM_REG : process(AHB_HCLK) is
   begin
      if (AHB_HCLK'event and AHB_HCLK = '1') then
         if (AHB_HRESETN = '0') then
             ahb_wr_rd_cs <= AHB_IDLE;
             load_counter <= '0';
         else
             ahb_wr_rd_cs <= ahb_wr_rd_ns;
             load_counter <= load_counter_sm;
         end if;
      end if;
   end process AHB_WR_RD_SM_REG;
   
  
-------------------------------------------------------------------------------
-- 1 KB Crossing logic
-- Based on axi_address, axi_length and axi_size the axi_end_address
-- signal is generated at the the start of access and this signal is used
-- for generating the AHB_HBURST and in the AHB write read statemachine
-------------------------------------------------------------------------------

  axi_end_address <= "00"&axi_address(9 downto 0)+axi_length_burst;

  axi_length_burst <= "000"&axi_length&'0' when axi_size = "001" else
                    "00"&axi_length&"00" when axi_size = "010" else
                     '0'&axi_length&"000" when axi_size = "011" else
                     "0000"&axi_length;

-------------------------------------------------------------------------------
-- process to register the onekb_cross_access during start of each access
-- This is calculated based on axi_end_address
-------------------------------------------------------------------------------

  ONEKB_CROSS_ACCESS_REG : process(AHB_HCLK) is
     begin
       if (AHB_HCLK'event and AHB_HCLK = '1') then
          if (AHB_HRESETN = '0') then
            onekb_cross_access <= '0';
          else
            if(ahb_wr_request = '1' or ahb_rd_request = '1') then
              onekb_cross_access <= axi_end_address(10) or axi_end_address(11);
            elsif(wrap_brst_last = '1') then
              onekb_cross_access <= '0';
            end if;
          end if;
       end if;
   end process ONEKB_CROSS_ACCESS_REG;
  
-------------------------------------------------------------------------------
-- The registered onekb_cross_access along with the current AHB address
-- one_kb_cross is generated.
-------------------------------------------------------------------------------

  addr_all_ones <= '1' when (HADDR_i(9 downto 2) = "11111111" and 
                     HSIZE_i = "010") or (HADDR_i(9 downto 1) = "111111111" and 
                     HSIZE_i = "001") or (HADDR_i(9 downto 3) = "1111111" and 
                     HSIZE_i = "011") or (HADDR_i(9 downto 0) = "1111111111"
                     and HSIZE_i = "000") else
                 '0';
                        
  one_kb_cross <= onekb_cross_access and addr_all_ones and 
                (not wrap_in_progress) and (not fixed_burst_access);

-- ****************************************************************************
-- This process is used for generating the control signal that reflects the
-- one KB crossing is in progress.
-- ****************************************************************************

   ONE_KB_CROSS_REG : process(AHB_HCLK) is
   begin
      if (AHB_HCLK'event and AHB_HCLK = '1') then
         if (AHB_HRESETN = '0') then
             one_kb_in_progress <= '0';
         else
             if (one_kb_cross = '1') then 
                 one_kb_in_progress <= '1';                       
             elsif (one_kb_splitted = '1' or wrap_brst_last = '1') then 
                 one_kb_in_progress <= '0';   
             end if;
          end if;
       end if;
   end process ONE_KB_CROSS_REG;

end architecture RTL;
