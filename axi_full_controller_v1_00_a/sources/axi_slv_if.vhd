-------------------------------------------------------------------------------
-- axi_slv_if.vhd - entity/architecture pair
-------------------------------------------------------------------------------
--
-- *******************************************************************
-- ** (c) Copyright [2007] - [2012] Xilinx, Inc. All rights reserved.*
-- **                                                                *
-- ** This file contains confidential and proprietary information    *
-- ** of Xilinx, Inc. and is protected under U.S. and                *
-- ** international copyright and other intellectual property        *
-- ** laws.                                                          *
-- **                                                                *
-- ** DISCLAIMER                                                     *
-- ** This disclaimer is not a license and does not grant any        *
-- ** rights to the materials distributed herewith. Except as        *
-- ** otherwise provided in a valid license issued to you by         *
-- ** Xilinx, and to the maximum extent permitted by applicable      *
-- ** law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND        *
-- ** WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES    *
-- ** AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING      *
-- ** BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-         *
-- ** INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and       *
-- ** (2) Xilinx shall not be liable (whether in contract or tort,   *
-- ** including negligence, or under any other theory of             *
-- ** liability) for any loss or damage of any kind or nature        *
-- ** related to, arising under or in connection with these          *
-- ** materials, including for any direct, or any indirect,          *
-- ** special, incidental, or consequential loss or damage           *
-- ** (including loss of data, profits, goodwill, or any type of     *
-- ** loss or damage suffered as a result of any action brought      *
-- ** by a third party) even if such damage or loss was              *
-- ** reasonably foreseeable or Xilinx had been advised of the       *
-- ** possibility of the same.                                       *
-- **                                          
-- ** CRITICAL APPLICATIONS                                          *
-- ** Xilinx products are not designed or intended to be fail-       *
-- ** safe, or for use in any application requiring fail-safe        *
-- ** performance, such as life-support or safety devices or         *
-- ** systems, Class III medical devices, nuclear facilities,        *
-- ** applications related to the deployment of airbags, or any      *
-- ** other applications that could lead to death, personal          *
-- ** injury, or severe property or environmental damage             *
-- ** (individually and collectively, "Critical                      *
-- ** Applications"). Customer assumes the sole risk and             *
-- ** liability of any use of Xilinx products in Critical            *
-- ** Applications, subject only to applicable laws and              *
-- ** regulations governing limitations on product liability.        *
-- **                                                                *
-- ** THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS       *
-- ** PART OF THIS FILE AT ALL TIMES.                                *
-- *******************************************************************
--
--
-------------------------------------------------------------------------------
-- Filename     :   axi_slv_if.vhd
-- Version      :   v2.00a
-- Description  :   The AXI4 Slave Interface module provides a
--                  bi-directional slave interface to the AXI. The AXI data
--                  bus width can be 32/64-bits. When both write and
--                  read transfers are simultaneously requested on AXI4,
--                  read request is given more priority than write request.
--
-- VHDL-Standard:   VHDL'93
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
--   NLR      04/10/2012   Added the strobe support for single tarnsfers
-- ^^^^^^^
-- ~~~~~~~
--   NLR      09/04/2013   Fixed issue when hready is low during last but one
--            data in burst CR#707167 Fix.
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
use ieee.numeric_std.all;
use ieee.std_logic_misc.or_reduce;

entity axi_slv_if is
  generic (
    C_S_AXI_ID_WIDTH      : integer range 1 to 16    := 4;
    C_S_AXI_ADDR_WIDTH    : integer range 32 to 32   := 32;
    C_S_AXI_DATA_WIDTH    : integer := 32;
    C_DPHASE_TIMEOUT      : integer := 0
    );
  port (
  -- AXI Signals
    S_AXI_ACLK       : in  std_logic;
    S_AXI_ARESETN    : in  std_logic;

    S_AXI_AWID       : in  std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_AWADDR     : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_AWPROT     : in  std_logic_vector(2 downto 0);
    S_AXI_AWCACHE    : in  std_logic_vector(3 downto 0);
    S_AXI_AWLEN      : in  std_logic_vector(7 downto 0);
    S_AXI_AWSIZE     : in  std_logic_vector(2 downto 0);
    S_AXI_AWBURST    : in  std_logic_vector(1 downto 0);
    S_AXI_AWLOCK     : in  std_logic;
    S_AXI_AWVALID    : in  std_logic;
    S_AXI_AWREADY    : out std_logic;
    S_AXI_WDATA      : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_WSTRB      : in  std_logic_vector(C_S_AXI_DATA_WIDTH/8-1 downto 0);
    S_AXI_WVALID     : in  std_logic;
    S_AXI_WLAST      : in  std_logic;
    S_AXI_WREADY     : out std_logic;
    
    S_AXI_BID        : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_BRESP      : out std_logic_vector(1 downto 0);
    S_AXI_BVALID     : out std_logic;
    S_AXI_BREADY     : in  std_logic;

    S_AXI_ARID       : in  std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_ARADDR     : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_ARVALID    : in  std_logic;
    S_AXI_ARPROT     : in  std_logic_vector(2 downto 0);
    S_AXI_ARCACHE    : in  std_logic_vector(3 downto 0);
    S_AXI_ARLEN      : in  std_logic_vector(7 downto 0);
    S_AXI_ARSIZE     : in  std_logic_vector(2 downto 0);
    S_AXI_ARBURST    : in  std_logic_vector(1 downto 0);
    S_AXI_ARLOCK     : in  std_logic;
    S_AXI_ARREADY    : out std_logic;

    S_AXI_RID        : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_RDATA      : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP      : out std_logic_vector(1 downto 0);
    S_AXI_RVALID     : out std_logic;
    S_AXI_RLAST      : out  std_logic;
    S_AXI_RREADY     : in  std_logic;

  -- Signals from other modules
    axi_prot         : out std_logic_vector(2 downto 0);
    axi_cache        : out std_logic_vector(3 downto 0);
    axi_size         : out std_logic_vector(2 downto 0);
    axi_lock         : out std_logic;
    axi_wdata        : out  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    ahb_rd_request   : out std_logic;
    ahb_wr_request   : out std_logic;
    slv_err_resp     : in  std_logic;
    rd_data          : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    axi_address      : out std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    axi_burst        : out std_logic_vector(1 downto 0);
    axi_length       : out std_logic_vector(7 downto 0);
    send_wvalid      : in  std_logic;
    send_ahb_wr      : out std_logic;
    axi_wvalid       : out std_logic;
    single_ahb_wr_xfer  : out std_logic;
    single_ahb_rd_xfer  : out std_logic;
    send_bresp          : in std_logic;
    send_rvalid         : in std_logic;
    send_rlast          : in std_logic;
    axi_rready          : out std_logic;
    timeout_i           : in std_logic;
    timeout_inprogress  : out std_logic
    );

end entity axi_slv_if;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------

architecture RTL of axi_slv_if is

-------------------------------------------------------------------------------
-- PRAGMAS
-------------------------------------------------------------------------------

attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of RTL : architecture is "yes";

-------------------------------------------------------------------------------
-- type declarations for the AXI write and read state machines
-------------------------------------------------------------------------------

    type  AXI_WR_SM_TYPE is (AXI_WR_IDLE,
                             AXI_WRITING,
                             AXI_WVALIDS_WAIT,
                             AXI_WVALID_WAIT,
                             AXI_WRITE_LAST,
                             AXI_WR_RESP_WAIT,
                             AXI_WR_RESP
                            );
                            
    type  AXI_RD_SM_TYPE is (AXI_RD_IDLE,
                             AXI_READ_LAST,
                             AXI_READING,
                             AXI_WAIT_RREADY,
                             RD_RESP
                            );
-------------------------------------------------------------------------------
 -- Signal declarations
-------------------------------------------------------------------------------

    signal axi_write_ns     : AXI_WR_SM_TYPE;
    signal axi_write_cs     : AXI_WR_SM_TYPE;
    signal axi_read_ns      : AXI_RD_SM_TYPE;
    signal axi_read_cs      : AXI_RD_SM_TYPE;
    
    signal ARREADY_i        : std_logic;
    signal WREADY_i         : std_logic;
    signal AWREADY_i        : std_logic;
    signal BVALID_i         : std_logic;
    signal BRESP_1_i        : std_logic;
    signal RVALID_i         : std_logic;
    signal RLAST_i          : std_logic;
    signal RRESP_1_i        : std_logic;
    signal write_ready_sm   : std_logic;
    signal wr_addr_ready_sm : std_logic;
    signal rd_addr_ready_sm : std_logic;
    signal BVALID_sm        : std_logic;
    signal RVALID_sm        : std_logic;
    signal RLAST_sm         : std_logic;

    signal wr_request       : std_logic;
    signal rd_request       : std_logic;
    
    signal write_pending    : std_logic;
    signal write_waiting    : std_logic;
    signal write_complete   : std_logic;
    signal BID_i            : std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    signal RID_i            : std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    signal axi_rid          : std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    signal axi_wid          : std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);

    signal single_axi_wr_xfer   : std_logic;
    signal single_axi_rd_xfer   : std_logic;
    signal write_in_progress    : std_logic;
    signal read_in_progress     : std_logic;
    signal write_statrted       : std_logic;
    signal send_rd_data         : std_logic;
    signal wr_err_occured       : std_logic;
   
    signal axi_wlast            : std_logic; 
    signal timeout_inprogress_s : std_logic;
   
    signal byte_transfer        : std_logic;
    signal halfword_transfer    : std_logic;
    signal word_transfer        : std_logic;
    signal doubleword_transfer  : std_logic;
 
-------------------------------------------------------------------------------
-- Begin architecture logic
-------------------------------------------------------------------------------

begin

-------------------------------------------------------------------------------
-- I/O signal assignments
-------------------------------------------------------------------------------

    S_AXI_AWREADY         <= AWREADY_i;
    S_AXI_BID             <= BID_i;
    S_AXI_RID             <= RID_i;

    S_AXI_WREADY          <= WREADY_i;

    S_AXI_BRESP(0)        <= '0';
    S_AXI_BRESP(1)        <= BRESP_1_i;
    S_AXI_BVALID          <= BVALID_i;

    S_AXI_ARREADY         <= ARREADY_i;

    S_AXI_RRESP(0)        <= '0';
    S_AXI_RRESP(1)        <= RRESP_1_i;
    S_AXI_RVALID          <= RVALID_i;
    S_AXI_RLAST           <= RLAST_i;

   timeout_inprogress     <= timeout_inprogress_s;
-------------------------------------------------------------------------------
-- AHB read and write request assignments
-------------------------------------------------------------------------------
    
    axi_wvalid <= S_AXI_WVALID;
    axi_rready <= S_AXI_RREADY;
    
    single_ahb_wr_xfer <= single_axi_wr_xfer;
    single_ahb_rd_xfer <= single_axi_rd_xfer;
    
-- ****************************************************************************
-- byte/halfword/word transfer signal generation
-- When data width is 32 
-- ****************************************************************************

   GEN_32_NARROW: if (C_S_AXI_DATA_WIDTH = 32 ) generate

   begin

     byte_transfer <= '1' when S_AXI_WSTRB = "0001" or S_AXI_WSTRB = "0010" or
                               S_AXI_WSTRB = "0100" or S_AXI_WSTRB = "1000" 
                          else '0';

     halfword_transfer <= '1' when S_AXI_WSTRB = "0011" or S_AXI_WSTRB ="1100" 
                              else '0';

     word_transfer <= '1' when S_AXI_WSTRB = "1111" 
                          else '0';

     doubleword_transfer <= '0';

  end generate GEN_32_NARROW;


-- ******************************************************************************
-- Byte/halfword/word/doubleword transfer assignement
-- When Data width is 64
-- ******************************************************************************

  GEN_64_NARROW: if (C_S_AXI_DATA_WIDTH = 64 ) generate

  begin

    byte_transfer <= '1' when S_AXI_WSTRB = "00000001" or S_AXI_WSTRB = "00000010" or
                              S_AXI_WSTRB = "00000100" or S_AXI_WSTRB = "00001000" or
                              S_AXI_WSTRB = "00010000" or S_AXI_WSTRB = "00100000" or
                              S_AXI_WSTRB = "01000000" or S_AXI_WSTRB = "10000000" 
                         else '0';

    halfword_transfer <= '1' when S_AXI_WSTRB = "00000011" or S_AXI_WSTRB = "00001100" or
                                  S_AXI_WSTRB = "00110000" or S_AXI_WSTRB = "11000000" 
                             else '0';

    word_transfer   <= '1' when S_AXI_WSTRB = "00001111" or S_AXI_WSTRB = "11110000" 
                           else '0';

    doubleword_transfer <= '1' when S_AXI_WSTRB = "11111111" 
                               else '0';

  end generate GEN_64_NARROW;


-- **************************************************************************
-- Read ID assignment
-- **************************************************************************

   RID_REG : process(S_AXI_ACLK) is
   begin
      if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
          if (S_AXI_ARESETN = '0') then
             RID_i <= (others => '0');
          else
             RID_i <= axi_rid;
          end if;
      end if;
   end process RID_REG;

-- ****************************************************************************
-- This process is used for generating the read response on AXI
-- ****************************************************************************

    RD_RESP_REG : process(S_AXI_ACLK) is
    begin
       if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
          if (S_AXI_ARESETN = '0') then
             RRESP_1_i <= '0';
          else
             if (send_rd_data = '1') then
                 RRESP_1_i <= slv_err_resp or timeout_inprogress_s;
             elsif (S_AXI_RREADY = '1') then
                 RRESP_1_i <= '0';
             end if;
          end if;
      end if;
   end process RD_RESP_REG;

-- ****************************************************************************
-- This process is used for generating Read data
-- ****************************************************************************

    RD_DATA_REG : process(S_AXI_ACLK) is
    begin
       if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
          if (S_AXI_ARESETN = '0') then
             S_AXI_RDATA <= (others => '0');
          else
             if (send_rd_data = '1') then
                 S_AXI_RDATA <= rd_data;
             elsif (S_AXI_RREADY = '1') then
                 S_AXI_RDATA <= (others => '0');
             end if;
          end if;
      end if;
   end process RD_DATA_REG;

-------------------------------------------------------------------------------
-- Write BID generation
-------------------------------------------------------------------------------

   BID_REG : process(S_AXI_ACLK) is
   begin
      if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
          if (S_AXI_ARESETN = '0') then
             BID_i <= (others => '0');
          else
             BID_i <= axi_wid;
          end if;
      end if;
   end process BID_REG;

-- ****************************************************************************
-- This process is used for registering the AXI ARID when a read 
-- is requested. 
-- ****************************************************************************

       AXI_RID_REG : process(S_AXI_ACLK) is
       begin
          if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
              if (S_AXI_ARESETN = '0') then
                 axi_rid <= (others => '0');
              else
                 if (rd_addr_ready_sm = '1') then
                       axi_rid <= S_AXI_ARID;
                 end if;
              end if;
          end if;
       end process AXI_RID_REG;

-- ****************************************************************************
-- This process is used for registering the AXI AWID when a write 
-- is requested. 
-- ****************************************************************************

       AXI_WID_REG : process(S_AXI_ACLK) is
       begin
          if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
              if (S_AXI_ARESETN = '0') then
                 axi_wid <= (others => '0');
              else
                 if (wr_addr_ready_sm = '1') then
                       axi_wid <= S_AXI_AWID;
                 end if;
              end if;
          end if;
       end process AXI_WID_REG;

-------------------------------------------------------------------------------
-- Address generation for generating address on ahb
-------------------------------------------------------------------------------

   ADDR_REG : process(S_AXI_ACLK) is
       begin
          if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
              if (S_AXI_ARESETN = '0') then
                 axi_address <= (others => '0');
              else
             if (wr_addr_ready_sm = '1') then
                   axi_address <= S_AXI_AWADDR;
             elsif (rd_addr_ready_sm = '1') then
                   axi_address <= S_AXI_ARADDR;
             end if;
              end if;
          end if;
   end process ADDR_REG;

-- ****************************************************************************
-- This process is used for registering the AXI protection when a write/read 
-- is requested. 
-- ****************************************************************************

       AXI_PROT_REG : process(S_AXI_ACLK) is
       begin
          if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
              if (S_AXI_ARESETN = '0') then
                 axi_prot <= (others => '0');
              else
                 if (wr_addr_ready_sm = '1') then
                       axi_prot <= S_AXI_AWPROT;
                 elsif (rd_addr_ready_sm = '1') then
                       axi_prot <= S_AXI_ARPROT;
                 end if;
              end if;
          end if;
       end process AXI_PROT_REG;

-- ****************************************************************************
-- This process is used for registering the AXI cache when a write/read 
-- is requested. 
-- ****************************************************************************

       AXI_CACHE_REG : process(S_AXI_ACLK) is
       begin
          if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
              if (S_AXI_ARESETN = '0') then
                 axi_cache <= (others => '0');
              else
                 if (wr_addr_ready_sm = '1') then
                       axi_cache <= S_AXI_AWCACHE;
                 elsif (rd_addr_ready_sm = '1') then
                       axi_cache <= S_AXI_ARCACHE;
                 end if;
              end if;
          end if;
       end process AXI_CACHE_REG;

-- ****************************************************************************
-- This process is used for registering the AXI lock when a write/read 
-- is requested. 
-- ****************************************************************************

       AXI_LOCK_REG : process(S_AXI_ACLK) is
       begin
          if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
              if (S_AXI_ARESETN = '0') then
                 axi_lock <= '0';
              else
                 if (wr_addr_ready_sm = '1') then
                       axi_lock <= S_AXI_AWLOCK;
                 elsif (rd_addr_ready_sm = '1') then
                       axi_lock <= S_AXI_ARLOCK;
                 end if;
              end if;
          end if;
       end process AXI_LOCK_REG;

-- ****************************************************************************
-- This process is used for registering the AXI size when a write/read 
-- is requested. 
-- ****************************************************************************

       AXI_SIZE_REG : process(S_AXI_ACLK) is
       begin
          if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
              if (S_AXI_ARESETN = '0') then
                 axi_size <= (others => '0');
              else
                 if (wr_addr_ready_sm = '1') then
                    if(or_reduce(S_AXI_AWLEN) = '0') then
                      if(byte_transfer = '1') then
                        axi_size <= "000";
                      elsif(halfword_transfer = '1') then
                        axi_size <= "001";
                      elsif(word_transfer = '1') then
                        axi_size <= "010";
                      elsif(doubleword_transfer = '1') then
                        axi_size <= "011";
                      else
                        axi_size <= S_AXI_AWSIZE;
                      end if;
                    else
                      axi_size <= S_AXI_AWSIZE;
                    end if;
                 elsif (rd_addr_ready_sm = '1') then
                       axi_size <= S_AXI_ARSIZE;
                 end if;
              end if;
          end if;
       end process AXI_SIZE_REG;

-- ****************************************************************************
-- This process is used for registering the AXI length when a write/read 
-- is requested. 
-- ****************************************************************************

       AXI_LENGTH_REG : process(S_AXI_ACLK) is
       begin
          if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
              if (S_AXI_ARESETN = '0') then
                 axi_length <= (others => '0');
              else
                 if (wr_addr_ready_sm = '1') then
                       axi_length <= S_AXI_AWLEN;
                 elsif (rd_addr_ready_sm = '1') then
                       axi_length <= S_AXI_ARLEN;
                 end if;
              end if;
          end if;
       end process AXI_LENGTH_REG;

-- ****************************************************************************
-- This process is used for registering the AXI burst when a write/read 
-- is requested. 
-- ****************************************************************************

       AXI_BURST_REG : process(S_AXI_ACLK) is
       begin
          if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
              if (S_AXI_ARESETN = '0') then
                 axi_burst <= (others => '0');
              else
                 if (wr_addr_ready_sm = '1') then
                       axi_burst <= S_AXI_AWBURST;
                 elsif (rd_addr_ready_sm = '1') then
                       axi_burst <= S_AXI_ARBURST;
                 end if;
              end if;
          end if;
       end process AXI_BURST_REG;

-- ****************************************************************************
-- This process is used for registering the AXI write data to be sent on AHB.
-- ****************************************************************************

       AXI_WR_DATA_REG : process(S_AXI_ACLK) is
       begin
          if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
              if (S_AXI_ARESETN = '0') then
                 axi_wdata <= (others => '0');
              else
                 if (write_ready_sm = '1') then
                       axi_wdata <= S_AXI_WDATA;
                 end if;
              end if;
          end if;
       end process AXI_WR_DATA_REG;
    

-- ****************************************************************************
-- This process is used for registering Write response
-- SLVERR response is sent to AXI when AHB save ERROR occured or when
-- timeout occurs
-- ****************************************************************************

   WR_RESP_REG : process(S_AXI_ACLK) is
   begin
       if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
          if (S_AXI_ARESETN = '0') then
             BRESP_1_i <= '0';
          else
             if (BVALID_sm = '1') then
                 BRESP_1_i <= wr_err_occured or timeout_inprogress_s;
             elsif (S_AXI_BREADY = '1') then
                 BRESP_1_i <= '0';
             end if;
          end if;
      end if;
   end process WR_RESP_REG;

-- ****************************************************************************
-- This process is used for generating control signal that write transfer is 
-- in progress
-- ****************************************************************************

   WR_PEND_REG : process(S_AXI_ACLK) is
   begin
       if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
          if (S_AXI_ARESETN = '0') then
             write_in_progress <= '0';
          else
             if (write_statrted = '1') then
                 write_in_progress <= '1';
             elsif (write_complete = '1') then
                 write_in_progress <= '0';
             end if;
          end if;
      end if;
   end process WR_PEND_REG;

-- ****************************************************************************
-- This process is used for generating write error has occured on AHB
-- ****************************************************************************

   WR_ERR_REG : process(S_AXI_ACLK) is
   begin
       if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
          if (S_AXI_ARESETN = '0') then
             wr_err_occured <= '0';
          else
             if (send_wvalid = '1' and slv_err_resp = '1') then
                 wr_err_occured <= '1';
             elsif (write_complete = '1') then
                 wr_err_occured <= '0';
             end if;
          end if;
      end if;
   end process WR_ERR_REG;

-- ****************************************************************************
-- This process is used for generating read transfer is in progress
-- ****************************************************************************

   RD_PROGRESS_REG : process(S_AXI_ACLK) is
   begin
       if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
          if (S_AXI_ARESETN = '0') then
             read_in_progress <= '0';
          else
             if (rd_addr_ready_sm = '1') then
                 read_in_progress <= '1';
             elsif (RLAST_sm = '1') then
                 read_in_progress <= '0';
             end if;
          end if;
      end if;
   end process RD_PROGRESS_REG;

-- ****************************************************************************
-- This process is used for generating pending write
-- ****************************************************************************

   WR_PROGRESS_REG : process(S_AXI_ACLK) is
   begin
       if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
          if (S_AXI_ARESETN = '0') then
             write_pending <= '0';
          else
             if (write_waiting = '1') then
                 write_pending  <= '1';
             elsif (BVALID_sm = '1') then
                 write_pending <= '0';
             end if;
          end if;
      end if;
   end process WR_PROGRESS_REG;

-- ****************************************************************************
-- This process is used for generating single write transfer on AXI (length 0)
-- ****************************************************************************

   WR_SINGLE_XFER_REG : process(S_AXI_ACLK) is
   begin
       if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
          if (S_AXI_ARESETN = '0') then
               single_axi_wr_xfer <= '0';
          else
              if (S_AXI_AWVALID = '1') then
                  if (or_reduce(S_AXI_AWLEN) = '0' and 
                      S_AXI_AWBURST(1) = '0') then
                      single_axi_wr_xfer <= '1';
                  else 
                      single_axi_wr_xfer <= '0';
                  end if;
              elsif(BVALID_sm = '1') then
                  single_axi_wr_xfer <= '0';             
             end if;
          end if;
      end if;
   end process WR_SINGLE_XFER_REG;

-- ****************************************************************************
-- This process is used for generating single read transfer on AXI (length 0)
-- ****************************************************************************

   RD_SINGLE_XFER_REG : process(S_AXI_ACLK) is
   begin
       if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
          if (S_AXI_ARESETN = '0') then
             single_axi_rd_xfer <= '0';
          else
             if (S_AXI_ARVALID = '1') then
                if (or_reduce(S_AXI_ARLEN) = '0' and 
                    S_AXI_ARBURST(1) = '0') then
                   single_axi_rd_xfer <= '1';
                else 
                  single_axi_rd_xfer <= '0';
                end if;
             elsif (RLAST_sm = '1') then
                 single_axi_rd_xfer <= '0';
             end if;
          end if;
      end if;
   end process RD_SINGLE_XFER_REG;

-- ****************************************************************************
-- This process is used for registering S_AXI_WLAST
-- This registered S_AXI_WLAST is used in the AXI_WRITE_SM for generating
-- the write_ready_sm for single clock cycle
-- ****************************************************************************

   S_AXI_WLAST_REG: process(S_AXI_ACLK) is
   begin
       if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
          if (S_AXI_ARESETN = '0') then
             axi_wlast <= '0';
          else
             axi_wlast <= S_AXI_WLAST;
          end if;
      end if;
   end process S_AXI_WLAST_REG;

-- ****************************************************************************
-- This process is used to generate timeout_inprogress
-- Once timeout occurs in any beat of the burst the signal timeout_inprogress_s
-- is '1' till the completion of that access/till AXI reset is asserted.
-- ****************************************************************************
   GEN_TIMEOUT_INPROGRESS : if (C_DPHASE_TIMEOUT /= 0) generate
   begin

     TIMEOUT_PROGRESS_REG:process(S_AXI_ACLK) is
     begin
       if(S_AXI_ACLK'event and S_AXI_ACLK = '1') then
         if(S_AXI_ARESETN = '0') then
            timeout_inprogress_s <= '0';
         else
           if(write_in_progress = '0' and read_in_progress = '0') then
              timeout_inprogress_s <= '0';
           elsif(timeout_i = '1' and (write_in_progress = '1' or 
              read_in_progress = '1')) then
              timeout_inprogress_s <= '1';  
           end if;
         end if;
       end if;
     end process TIMEOUT_PROGRESS_REG;

    END generate GEN_TIMEOUT_INPROGRESS;

-- ****************************************************************************
-- Generate statement works when C_DPHASE_TIMEOUT is always '0'
-- timeout_inprogress_s is always '0' if C_DPHASE_TIMEOUT parameter is '0'
-- ****************************************************************************
   GEN_TIMEOUT_NOTINPROGRESS : if (C_DPHASE_TIMEOUT = 0) generate
   begin

     timeout_inprogress_s <= '0';

   END generate GEN_TIMEOUT_NOTINPROGRESS; 

-- ****************************************************************************
-- AXI Write State Machine -- START
-- this state machine generates the control signals to send the write data
-- and write control signals to AHB.This also generates the control signal
-- to send the write response to AXI after last beat of the transfer.
-- ****************************************************************************

   AXI_WRITE_SM   : process (axi_write_cs,
                             S_AXI_AWVALID,
                             S_AXI_ARVALID,
                             S_AXI_WVALID,
                             S_AXI_WLAST,
                             axi_wlast,
                             S_AXI_BREADY,
                             send_bresp,
                             send_wvalid,
                             single_axi_wr_xfer,
                             write_pending,
                             read_in_progress
                             ) is
   begin

      axi_write_ns     <= axi_write_cs;
      write_ready_sm   <= '0';
      wr_addr_ready_sm <= '0';
      wr_request       <= '0';
      BVALID_sm        <= '0';
      write_complete   <= '0';
      send_ahb_wr      <= '0';
      write_statrted   <= '0'; 
      

      case axi_write_cs is

           when AXI_WR_IDLE =>
              if((S_AXI_AWVALID = '1' or S_AXI_WVALID = '1') and
                   ((write_pending = '0' and S_AXI_ARVALID = '0') or
                    (write_pending = '1')) and read_in_progress = '0') then
                     write_statrted <= '1';     
                     axi_write_ns   <= AXI_WVALIDS_WAIT;
                end if;
           when AXI_WVALIDS_WAIT =>
             if(S_AXI_AWVALID = '1' and S_AXI_WVALID = '1') then
                   write_ready_sm   <= '1';
                   wr_addr_ready_sm <= '1';
                   wr_request       <= '1';
                   if (single_axi_wr_xfer = '1') then
                       axi_write_ns <= AXI_WRITE_LAST;
                   else
                       axi_write_ns <= AXI_WRITING;
                   end if;
                end if;
           when AXI_WVALID_WAIT =>
                write_ready_sm <= S_AXI_WVALID;
                send_ahb_wr    <= S_AXI_WVALID;
                if(S_AXI_WVALID = '1') then
                  axi_write_ns <= AXI_WRITING;
                end if;

           when AXI_WRITING =>
                if(S_AXI_WVALID = '1' and S_AXI_WLAST = '1') then
                   write_ready_sm <= send_wvalid;
                   send_ahb_wr    <= send_wvalid;
                   if(send_bresp = '1') then
                      axi_write_ns <= AXI_WR_RESP_WAIT;
                   else
                      axi_write_ns <= AXI_WRITE_LAST;
                   end if;
                elsif(send_wvalid = '1') then
                   write_ready_sm <= S_AXI_WVALID;
                   send_ahb_wr    <= S_AXI_WVALID;
                   if(S_AXI_WVALID = '0') then
                      axi_write_ns <= AXI_WVALID_WAIT;
                   end if;
                end if;
           
           when AXI_WR_RESP_WAIT =>
                BVALID_sm    <= '1';
                axi_write_ns <= AXI_WR_RESP;

           when AXI_WRITE_LAST =>
                send_ahb_wr    <= '1';
                write_ready_sm <= send_wvalid; 
                BVALID_sm      <= send_bresp;
                if(send_bresp = '1') then
                   axi_write_ns <= AXI_WR_RESP;
                   write_ready_sm <= '0'; 
                end if;

           when AXI_WR_RESP =>
                write_complete <= S_AXI_BREADY;
                BVALID_sm      <= not S_AXI_BREADY;
                if (S_AXI_BREADY = '1') then
                    axi_write_ns <= AXI_WR_IDLE;
                end if;

          -- coverage off
           when others =>
                axi_write_ns <= AXI_WR_IDLE;
          -- coverage on

       end case;

   end process AXI_WRITE_SM;

-------------------------------------------------------------------------------
-- Registering the signals generated from the AXI_WRITE_SM state machine
-------------------------------------------------------------------------------

   AXI_WRITE_SM_REG : process(S_AXI_ACLK) is
   begin
      if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
         if (S_AXI_ARESETN = '0') then
             axi_write_cs <= AXI_WR_IDLE;
             WREADY_i     <= '0';
             AWREADY_i    <= '0';
             BVALID_i     <= '0';
         else
             axi_write_cs <= axi_write_ns;
             WREADY_i     <= write_ready_sm;
             AWREADY_i    <= wr_addr_ready_sm;
             BVALID_i     <= BVALID_sm;
         end if;
      end if;
   end process AXI_WRITE_SM_REG;
   
-- ****************************************************************************
-- AXI Read State Machine -- START
-- This state machine generates the control signals to send the read data and
-- read response to AXI from AHB.
-- ****************************************************************************

   AXI_READ_SM   : process (axi_read_cs,
                            write_pending,
                            S_AXI_ARVALID,
                            S_AXI_RREADY,
                            S_AXI_AWVALID,
                            S_AXI_WVALID,
                            send_rlast,
                            send_rvalid,
                            single_axi_rd_xfer,
                            write_in_progress
                           ) is
   begin

      axi_read_ns      <= axi_read_cs;
      rd_request       <= '0';
      RVALID_sm        <= '0';
      RLAST_sm         <= '0';
      rd_addr_ready_sm <= '0';
      write_waiting    <= '0';
      send_rd_data     <= '0';

      case axi_read_cs is

           when AXI_RD_IDLE =>
                if (S_AXI_ARVALID = '1' and
                    write_pending = '0' and write_in_progress = '0') then
                    rd_request <= '1';
                    rd_addr_ready_sm <= '1';
                    if (single_axi_rd_xfer = '1') then
                       axi_read_ns <= AXI_READ_LAST;
                    else
                       axi_read_ns <= AXI_READING;
                    end if;
                end if;

           when AXI_READING =>
                send_rd_data <= send_rlast or send_rvalid;
                RVALID_sm    <= send_rlast or send_rvalid;
                if (send_rlast  = '1') then
                    RLAST_sm    <= '1';
                    axi_read_ns <= RD_RESP;                
                elsif(send_rvalid = '1') then
                    if(S_AXI_RREADY = '0') then   
                       axi_read_ns <= AXI_WAIT_RREADY;
                    end if;
                end if;

           when AXI_WAIT_RREADY =>
                if(S_AXI_RREADY = '1' ) then
                   axi_read_ns <= AXI_READING;
                else
                   RVALID_sm <= '1';
                end if;

           when RD_RESP =>                
                if(S_AXI_RREADY = '1') then
                   if(S_AXI_AWVALID = '1' or S_AXI_WVALID = '1') then
                      write_waiting <= '1';
                   end if;
                   axi_read_ns <= AXI_RD_IDLE;
                else
                   RVALID_sm <= '1';
                   RLAST_sm  <= '1';
                end if;

           when AXI_READ_LAST =>
                if(send_rlast = '1') then
                   send_rd_data <= '1';
                   RLAST_sm <= '1';
                   RVALID_sm <= '1';
                   axi_read_ns <= RD_RESP;
                end if;
          
          -- coverage off
           when others =>
                axi_read_ns <= AXI_RD_IDLE;
          -- coverage on

       end case;

   end process AXI_READ_SM;

-------------------------------------------------------------------------------
-- Registering the signals generated from the AXI_READ_SM state machine
-------------------------------------------------------------------------------

   AXI_READ_SM_REG : process(S_AXI_ACLK) is
   begin
      if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
         if (S_AXI_ARESETN = '0') then
             axi_read_cs <= AXI_RD_IDLE;
             ARREADY_i <= '0';
             RVALID_i <= '0';
             RLAST_i <= '0';
             ahb_rd_request <= '0';
             ahb_wr_request <= '0';
         else
             ahb_rd_request <= rd_request;
             ahb_wr_request <= wr_request;
             axi_read_cs <= axi_read_ns;
             ARREADY_i <= rd_addr_ready_sm;
             RVALID_i <= RVALID_sm;
             RLAST_i <= RLAST_sm;
         end if;
      end if;
   end process AXI_READ_SM_REG;
   
end architecture RTL;
