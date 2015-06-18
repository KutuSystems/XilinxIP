-------------------------------------------------------------------------------
-- axi_ahblite_bridge.vhd - entity/architecture pair
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
-- **                                                                *
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
-------------------------------------------------------------------------------
-- Filename:        axi_ahblite_bridge.vhd
-- Version:         v1.01a
-- Description:     The AXI to External AHB  Slave Connector translates AXI
--                  transactions into AHB  transactions. It functions as a
--                  AXI slave on the AXI port and an AHB master on
--                  the AHB Lite interface.
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--           -- axi_ahblite_bridge.vhd
--              -- axi_slv_if.vhd
--              -- ahb_mstr_if.vhd 
--              -- time_out.vhd
--
-------------------------------------------------------------------------------
-- Author:     NLR 
-- History:
--   NLR      12/15/2010   Initial version
-- ^^^^^^^
--   NLR      04/10/2012   Added the strobe support for single transfers
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

-- synopsys translate_off
library unisim;
use unisim.vcomponents.all;
-- synopsys translate_on

-------------------------------------------------------------------------------
-- Generics and Port Declaration
-------------------------------------------------------------------------------
--
-- Definition of Generics
--
-- System Parameters
--
-- C_FAMILY                 -- FPGA Family for which the axi_ahblite_bridge is
--                          -- targeted
-- C_INSTANCE               -- Instance name of the axi_ahblite_bridge in system
--
-- AXI Parameters
--
-- C_S_AXI_ADDR_WIDTH       -- Width of the AXI address bus (in bits)
--                             fixed to 32
-- C_S_AXI_DATA_WIDTH       -- Width of the AXI data bus (in bits)
--                             Either 32 or 64 
-- C_S_AXI_SUPPORTS_NARROW_BURST  -- Support for the Narrow burst access 
--                                   1 supports and 0 does not support
-- C_S_AXI_PROTOCOL         -- AXI Protocol Version i.e. AXI4
--                             fixed to AXI4
-- C_S_AXI_ID_WIDTH         -- Width of AXI ID     
-- C_BASEADDR               -- AXI base address for address range 1
-- C_HIGHADDR               -- AXI high address for address range 1
-- C_DPHASE_TIMEOUT         -- Time out value
--
-- AHB Parameters
--
-- C_M_AHB_ADDR_WIDTH       -- Width of the AHB address bus (in bits)
--                             fixed to 32
-- C_M_AHB_DATA_WIDTH       -- Width of the AHB data bus (in bits)
--                             Either 32 or 64 
-- Definition of Ports
--
-- System signals
-- s_axi_aclk               -- AXI Clock
-- s_axi_aresetn            -- AXI Reset Signal - active low
--
-- axi write address channel signals
--
-- s_axi_awaddr             -- Write address bus - The write address bus gives
--                             the address of the first transfer in a write
--                             burst transaction - fixed to 32
-- s_axi_awprot             -- Protection type - This signal indicates the
--                             normal, privileged, or secure protection level
--                             of the transaction and whether the transaction
--                             is a data access or an instruction access
-- s_axi_awvalid            -- Write address valid - This signal indicates
--                             that valid write address & control information
--                             are available
-- s_axi_awready            -- Write address ready - This signal indicates
--                             that the slave is ready to accept an address
--                             and associated control signals
-- s_axi_awid               -- Write address ID. This signal is the identification 
--                             tag for the write address group of signals
-- s_axi_awlen              -- Burst length. The burst length gives the exact 
--                             number of transfers in a burst 
-- s_axi_awsize             -- Burst size. This signal indicates the size of 
--                             each transfer in the burst.
-- s_axi_awburst            -- Burst type. The burst type, coupled with the size 
--                             information, details how the address for
--                             each transfer within the burst is calculated. 
-- s_axi_awcache            -- Cache type. This signal indicates the bufferable, 
--                             cacheable, write-through, write-back, and
--                             allocate attributes of the transaction.
-- s_axi_awlock             -- Lock type. This signal provides additional information 
--                             about the atomic characteristics of the transfer
--
-- axi write data channel signals
--
-- s_axi_wdata             -- Write data bus - Supports 32/64
-- s_axi_wstrb             -- Write strobes - These signals indicates which
--                            byte lanes to update in memory
-- s_axi_wlast             -- Write last. This signal indicates the last transfer 
--                            in a write burst
-- s_axi_wvalid            -- Write valid - This signal indicates that valid
--                            write data and strobes are available
-- s_axi_wready            -- Write ready - This signal indicates that the
--                            slave can accept the write data
--
-- axi write response channel signals
--
-- s_axi_bid                -- Response ID. The identification tag of the write 
--                             response. 
-- s_axi_bresp              -- Write response - This signal indicates the
--                             status of the write transaction
-- s_axi_bvalid             -- Write response valid - This signal indicates
--                             that a valid write response is available
-- s_axi_bready             -- Response ready - This signal indicates that
--                             the master can accept the response information
--
-- axi read address channel signals
--
-- s_axi_arid              -- Read address ID. This signal is the identification 
--                            tag for the read address group of signals
-- s_axi_araddr            -- Read address - The read address bus gives the
--                            initial address of a read burst transaction
-- s_axi_arprot            -- Protection type - This signal provides
--                            protection unit information for the transaction
-- s_axi_arcache           -- Cache type. This signal provides additional 
--                            information about the cacheable
--                            characteristics of the transfer
-- s_axi_arvalid           -- Read address valid - This signal indicates,
--                            when HIGH, that the read address and control
--                            information is valid and will remain stable
--                            until the address acknowledge signal,ARREADY,
--                            is high.
-- s_axi_arlen             -- Burst length. The burst length gives the exact 
--                            number of transfers in a burst.
-- s_axi_arsize            -- Burst size.This signal indicates the size of each 
--                            transfer in the burst
-- s_axi_arburst           -- Burst type.The burst type, coupled with the size 
--                            information, details how the address for each
--                            transfer within the burst is calculated
-- s_axi_arlock            -- Lock type.This signal provides additional  
--                            information about the atomic characteristics 
--                            of the transfer
-- s_axi_arready           -- Read address ready.This signal indicates
--                            that the slave is ready to accept an address
--                            and associated control signals:
--
-- axi read data channel signals
--
-- s_axi_rid               -- Read ID tag. This signal is the ID tag of the 
--                            read data group of signals  
-- s_axi_rdata             -- Read data bus - Either 32/64
-- s_axi_rresp             -- Read response - This signal indicates the
--                            status of the read transfer
-- s_axi_rvalid            -- Read valid - This signal indicates that the
--                            required read data is available and the read
--                            transfer can complete
-- s_axi_rready            -- Read ready - This signal indicates that the
--                            master can accept the read data and response
--                            information
-- s_axi_rlast             -- Read last. This signal indicates the last 
--                            transfer in a read burst.
-- AHB signals
--
-- m_ahb_hclk             -- AHB Clock
-- m_ahb_hresetn          -- AHB Reset Signal - active low
-- m_ahb_haddr            -- AHB address bus
-- m_ahb_hwrite           -- Direction indicates an AHB write access when
--                           high and an AHB read access when low
-- m_ahb_hsize            -- Indicates the size of the transfer
-- m_ahb_hburst           -- Indicates if the transfer forms part of a burst
--                           Four,eight and sixteen beat bursts are supported
--                           and the burst may be either incrementing or 
--                           wrapping.
-- m_ahb_htrans           -- Indicates the type of the current transfer, 
--                           which can be NONSEQUENTIAL, SEQUENTIAL, IDLE 
--                           or BUSY.
-- m_ahb_hmastlock        -- Indicates that the current master is performing a 
--                           locked sequence of transfers. 
-- m_ahb_hwdata           -- AHB write data
-- m_ahb_hready           -- Ready, the AHB slave uses this signal to
--                           extend an AHB transfer
-- m_ahb_hrdata           -- AHB read data driven by slave 1
-- m_ahb_pslverr          -- This signal indicates transfer failure
-- m_ahb_hprot            -- This signal indicates the normal,
--                           privileged, or secure protection level of the
--                           transaction and whether the transaction is a
--                           data access or an instruction access.
-------------------------------------------------------------------------------

entity axi_full_controller is
  generic (
    C_S_AXI_ADDR_WIDTH            : integer range 32 to 32    := 32;
    C_S_AXI_DATA_WIDTH            : integer                   := 32;
    C_S_AXI_SUPPORTS_NARROW_BURST : integer range 0 to 1      := 0;
    C_S_AXI_ID_WIDTH              : integer range 1 to 16     := 4;
    C_M_AHB_ADDR_WIDTH            : integer range 32 to 32    := 32;
    C_M_AHB_DATA_WIDTH            : integer                   := 32;
    C_DPHASE_TIMEOUT              : integer                   := 0
    );
  port (
  -- AXI signals
    s_axi_aclk         : in  std_logic;
    s_axi_aresetn      : in  std_logic := '1';

--   -- AXI Write Address Channel Signals
    s_axi_awid         : in  std_logic_vector (C_S_AXI_ID_WIDTH-1 downto 0);
    s_axi_awlen        : in  std_logic_vector (7 downto 0);
    s_axi_awsize       : in  std_logic_vector (2 downto 0);
    s_axi_awburst      : in  std_logic_vector (1 downto 0);
    s_axi_awcache      : in  std_logic_vector (3 downto 0);
    s_axi_awaddr       : in  std_logic_vector(31 downto 0);
    s_axi_awprot       : in  std_logic_vector(2 downto 0);
    s_axi_awvalid      : in  std_logic;
    s_axi_awready      : out std_logic;
    s_axi_awlock       : in  std_logic;
--   -- AXI Write Channel Signals
    s_axi_wdata        : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    s_axi_wstrb        : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    s_axi_wlast        : in  std_logic;
    s_axi_wvalid       : in  std_logic;
    s_axi_wready       : out std_logic;
    
--   -- AXI Write Response Channel Signals
    s_axi_bid          : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    s_axi_bresp        : out std_logic_vector(1 downto 0);
    s_axi_bvalid       : out std_logic;
    s_axi_bready       : in  std_logic;

--   -- AXI Read Address Channel Signals
    s_axi_arid         : in  std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    s_axi_araddr       : in  std_logic_vector(31 downto 0);
    s_axi_arprot       : in  std_logic_vector(2 downto 0);
    s_axi_arcache      : in  std_logic_vector(3 downto 0);
    s_axi_arvalid      : in  std_logic;
    s_axi_arlen        : in  std_logic_vector(7 downto 0);
    s_axi_arsize       : in  std_logic_vector(2 downto 0);
    s_axi_arburst      : in  std_logic_vector(1 downto 0);
    s_axi_arlock       : in  std_logic;
    s_axi_arready      : out std_logic;
--   -- AXI Read Data Channel Signals
    s_axi_rid          : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    s_axi_rdata        : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    s_axi_rresp        : out std_logic_vector(1 downto 0);
    s_axi_rvalid       : out std_logic;
    s_axi_rlast        : out std_logic;
    s_axi_rready       : in  std_logic;

-- AHB signals
    
--    m_ahb_hclk         : out  std_logic; removing to address cr 734467
--    m_ahb_hresetn      : out  std_logic;
    
    m_ahb_haddr        : out std_logic_vector(31 downto 0);
    m_ahb_hwrite       : out std_logic;
    m_ahb_hsize        : out std_logic_vector(2 downto 0);
    m_ahb_hburst       : out std_logic_vector(2 downto 0);
    m_ahb_hprot        : out std_logic_vector(3 downto 0);
    m_ahb_htrans       : out std_logic_vector(1 downto 0);
    m_ahb_hmastlock    : out std_logic;
    m_ahb_hwdata       : out std_logic_vector(C_M_AHB_DATA_WIDTH-1 downto 0);
    
    m_ahb_hready       : in  std_logic;
    m_ahb_hrdata       : in  std_logic_vector(C_M_AHB_DATA_WIDTH-1 downto 0);
    m_ahb_hresp        : in  std_logic
    );

-------------------------------------------------------------------------------
-- Attributes
-------------------------------------------------------------------------------

   -- Fan-Out attributes for XST

   ATTRIBUTE MAX_FANOUT                    : string;
   ATTRIBUTE MAX_FANOUT   of s_axi_aclk    : signal is "10000";
   ATTRIBUTE MAX_FANOUT   of s_axi_aresetn : signal is "10000";

end entity axi_full_controller;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------

architecture RTL of axi_full_controller is
-------------------------------------------------------------------------------
-- PRAGMAS
-------------------------------------------------------------------------------

attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of RTL : architecture is "yes";


-------------------------------------------------------------------------------
 -- Signal declarations
-------------------------------------------------------------------------------

   signal axi_address         : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
   signal ahb_rd_request      : std_logic;
   signal ahb_wr_request      : std_logic;
   signal rd_data             : std_logic_vector(C_M_AHB_DATA_WIDTH-1 downto 0);
   signal slv_err_resp        : std_logic;
   signal axi_lock            : std_logic;
   signal axi_prot            : std_logic_vector(2 downto 0);
   signal axi_cache           : std_logic_vector(3 downto 0);
   signal axi_size            : std_logic_vector(2 downto 0);
   signal axi_burst           : std_logic_vector(1 downto 0);
   signal axi_length          : std_logic_vector(7 downto 0);
   signal axi_wdata           : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
   signal send_wvalid         : std_logic;
   signal send_ahb_wr         : std_logic;
   signal axi_wvalid          : std_logic;
   signal send_bresp          : std_logic;
   signal send_rvalid         : std_logic;
   signal send_rlast          : std_logic;
   signal axi_rready          : std_logic;
   signal single_ahb_wr_xfer  : std_logic;
   signal single_ahb_rd_xfer  : std_logic;
   signal load_cntr           : std_logic;
   signal cntr_enable         : std_logic;
   signal timeout_s           : std_logic;
   signal timeout_inprogress  : std_logic; 

   component axi_slv_if
   generic (
      C_S_AXI_ID_WIDTH        : integer range 1 to 16    := 4;
      C_S_AXI_ADDR_WIDTH      : integer range 32 to 32   := 32;
      C_S_AXI_DATA_WIDTH      : integer := 32;
      C_DPHASE_TIMEOUT        : integer := 0
   );
   port (
      -- AXI Signals
      S_AXI_ACLK        : in  std_logic;
      S_AXI_ARESETN     : in  std_logic;

      S_AXI_AWID        : in  std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      S_AXI_AWADDR      : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      S_AXI_AWPROT      : in  std_logic_vector(2 downto 0);
      S_AXI_AWCACHE     : in  std_logic_vector(3 downto 0);
      S_AXI_AWLEN       : in  std_logic_vector(7 downto 0);
      S_AXI_AWSIZE      : in  std_logic_vector(2 downto 0);
      S_AXI_AWBURST     : in  std_logic_vector(1 downto 0);
      S_AXI_AWLOCK      : in  std_logic;
      S_AXI_AWVALID     : in  std_logic;
      S_AXI_AWREADY     : out std_logic;
      S_AXI_WDATA       : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      S_AXI_WSTRB       : in  std_logic_vector(C_S_AXI_DATA_WIDTH/8-1 downto 0);
      S_AXI_WVALID      : in  std_logic;
      S_AXI_WLAST       : in  std_logic;
      S_AXI_WREADY      : out std_logic;
    
      S_AXI_BID         : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      S_AXI_BRESP       : out std_logic_vector(1 downto 0);
      S_AXI_BVALID      : out std_logic;
      S_AXI_BREADY      : in  std_logic;

      S_AXI_ARID        : in  std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      S_AXI_ARADDR      : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      S_AXI_ARVALID     : in  std_logic;
      S_AXI_ARPROT      : in  std_logic_vector(2 downto 0);
      S_AXI_ARCACHE     : in  std_logic_vector(3 downto 0);
      S_AXI_ARLEN       : in  std_logic_vector(7 downto 0);
      S_AXI_ARSIZE      : in  std_logic_vector(2 downto 0);
      S_AXI_ARBURST     : in  std_logic_vector(1 downto 0);
      S_AXI_ARLOCK      : in  std_logic;
      S_AXI_ARREADY     : out std_logic;

      S_AXI_RID         : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      S_AXI_RDATA       : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      S_AXI_RRESP       : out std_logic_vector(1 downto 0);
      S_AXI_RVALID      : out std_logic;
      S_AXI_RLAST       : out std_logic;
      S_AXI_RREADY      : in  std_logic;

      -- Signals from other modules
      axi_prot          : out std_logic_vector(2 downto 0);
      axi_cache         : out std_logic_vector(3 downto 0);
      axi_size          : out std_logic_vector(2 downto 0);
      axi_lock          : out std_logic;
      axi_wdata         : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      ahb_rd_request    : out std_logic;
      ahb_wr_request    : out std_logic;
      slv_err_resp      : in  std_logic;
      rd_data           : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      axi_address       : out std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      axi_burst         : out std_logic_vector(1 downto 0);
      axi_length        : out std_logic_vector(7 downto 0);
      send_wvalid       : in  std_logic;
      send_ahb_wr       : out std_logic;
      axi_wvalid        : out std_logic;
      single_ahb_wr_xfer : out std_logic;
      single_ahb_rd_xfer : out std_logic;
      send_bresp        : in std_logic;
      send_rvalid       : in std_logic;
      send_rlast        : in std_logic;
      axi_rready        : out std_logic;
      timeout_i         : in std_logic;
      timeout_inprogress : out std_logic
   );
   end component;

   component ahb_mstr_if  
   generic (
      C_M_AHB_ADDR_WIDTH   : integer range 32 to 32   := 32;
      C_M_AHB_DATA_WIDTH   : integer := 32;
      C_S_AXI_DATA_WIDTH   : integer := 32;
      C_S_AXI_SUPPORTS_NARROW_BURST : integer range 0 to 1 := 0 
   );
   port (
      -- AHB Signals
      AHB_HCLK             : in std_logic;    
      AHB_HRESETN          : in std_logic;

      M_AHB_HADDR          : out std_logic_vector(C_M_AHB_ADDR_WIDTH-1 downto 0);
      M_AHB_HWRITE         : out std_logic;
      M_AHB_HSIZE          : out std_logic_vector(2 downto 0);
      M_AHB_HBURST         : out std_logic_vector(2 downto 0);
      M_AHB_HPROT          : out std_logic_vector(3 downto 0);
      M_AHB_HTRANS         : out std_logic_vector(1 downto 0);
      M_AHB_HMASTLOCK      : out std_logic;
      M_AHB_HWDATA         : out std_logic_vector(C_M_AHB_DATA_WIDTH-1 downto 0);

      M_AHB_HREADY         : in  std_logic;
      M_AHB_HRDATA         : in  std_logic_vector(C_M_AHB_DATA_WIDTH-1 downto 0);
      M_AHB_HRESP          : in  std_logic;

      -- Signals from/to other modules
      ahb_rd_request       : in  std_logic;
      ahb_wr_request       : in  std_logic;
      axi_lock             : in  std_logic;
      rd_data              : out std_logic_vector(C_M_AHB_DATA_WIDTH-1 downto 0);
      slv_err_resp         : out std_logic;
      axi_prot             : in  std_logic_vector(2 downto 0);
      axi_cache            : in  std_logic_vector(3 downto 0);
      axi_wdata            : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      axi_size             : in  std_logic_vector(2 downto 0);
      axi_length           : in  std_logic_vector(7 downto 0);
      axi_address          : in  std_logic_vector(C_M_AHB_ADDR_WIDTH-1 downto 0);
      axi_burst            : in  std_logic_vector(1 downto 0);
      single_ahb_wr_xfer   : in  std_logic;
      single_ahb_rd_xfer   : in  std_logic;
      send_wvalid          : out std_logic;
      send_ahb_wr          : in  std_logic;
      axi_wvalid           : in  std_logic;
      send_bresp           : out std_logic;
      send_rvalid          : out std_logic;
      send_rlast           : out std_logic;
      axi_rready           : in  std_logic;
      timeout_inprogress   : in std_logic;
      load_cntr            : out std_logic;
      cntr_enable          : out std_logic
   );
   end component;

   component time_out
   generic (
      C_DPHASE_TIMEOUT      : integer   := 0
   );
   port (
      -- AXI Signals
      S_AXI_ACLK       : in  std_logic;
      S_AXI_ARESETN    : in  std_logic;
      --AHB Signal
      M_AHB_HREADY     : in std_logic;
      --AHB Master Interface and AXI Slave Interface signals
      load_cntr        : in std_logic;
      cntr_enable      : in std_logic;
      timeout_o        : out std_logic
   );
   end component;

begin

-------------------------------------------------------------------------------
-- Begin architecture logic
-------------------------------------------------------------------------------
    
-------------------------------------------------------------------------------
-- AHB clock and reset assignments
-- AXI clock and AXI reset are assigned to the AHB clock and AHB reset
-- Respectively
-------------------------------------------------------------------------------

--    M_AHB_HCLK    <= s_axi_aclk;
    
--    M_AHB_HRESETN <= s_axi_aresetn;

-------------------------------------------------------------------------------
-- Instantiation of the AXI Slave Interface module
-------------------------------------------------------------------------------

   AXI_SLV_IF_MODULE : axi_slv_if
   generic map(
      C_S_AXI_ID_WIDTH           => C_S_AXI_ID_WIDTH,
      C_S_AXI_ADDR_WIDTH         => C_S_AXI_ADDR_WIDTH,
      C_S_AXI_DATA_WIDTH         => C_S_AXI_DATA_WIDTH,
      C_DPHASE_TIMEOUT           => C_DPHASE_TIMEOUT
   )
   port map(
      S_AXI_ACLK                 => s_axi_aclk,
      S_AXI_ARESETN              => s_axi_aresetn,

      S_AXI_AWID                 => s_axi_awid,
      S_AXI_AWADDR               => s_axi_awaddr,
      S_AXI_AWPROT               => s_axi_awprot,
      S_AXI_AWCACHE              => s_axi_awcache,
      S_AXI_AWLEN                => s_axi_awlen,
      S_AXI_AWSIZE               => s_axi_awsize,
      S_AXI_AWBURST              => s_axi_awburst,
      S_AXI_AWVALID              => s_axi_awvalid,
      S_AXI_AWLOCK               => s_axi_awlock,
      S_AXI_AWREADY              => s_axi_awready,
      S_AXI_WDATA                => s_axi_wdata,
      S_AXI_WSTRB                => s_axi_wstrb,
      S_AXI_WVALID               => s_axi_wvalid,
      S_AXI_WLAST                => s_axi_wlast,
      S_AXI_WREADY               => s_axi_wready,
      S_AXI_BID                  => s_axi_bid,
      S_AXI_BRESP                => s_axi_bresp,
      S_AXI_BVALID               => s_axi_bvalid,
      S_AXI_BREADY               => s_axi_bready,

      S_AXI_ARID                 => s_axi_arid,
      S_AXI_ARADDR               => s_axi_araddr,
      S_AXI_ARVALID              => s_axi_arvalid,
      S_AXI_ARPROT               => s_axi_arprot,
      S_AXI_ARCACHE              => s_axi_arcache,
      S_AXI_ARLEN                => s_axi_arlen,
      S_AXI_ARSIZE               => s_axi_arsize,
      S_AXI_ARBURST              => s_axi_arburst,
      S_AXI_ARLOCK               => s_axi_arlock,
      S_AXI_ARREADY              => s_axi_arready,
      S_AXI_RID                  => s_axi_rid,
      S_AXI_RDATA                => s_axi_rdata,
      S_AXI_RRESP                => s_axi_rresp,
      S_AXI_RVALID               => s_axi_rvalid,
      S_AXI_RLAST                => s_axi_rlast,
      S_AXI_RREADY               => s_axi_rready,

      axi_prot                   => axi_prot,
      axi_cache                  => axi_cache,
      axi_wdata                  => axi_wdata,
      axi_size                   => axi_size,
      axi_lock                   => axi_lock,
      axi_address                => axi_address,
      ahb_rd_request             => ahb_rd_request,
      ahb_wr_request             => ahb_wr_request,
      slv_err_resp               => slv_err_resp,
      rd_data                    => rd_data,
      axi_burst                  => axi_burst,
      axi_length                 => axi_length,
      send_wvalid                => send_wvalid,
      send_ahb_wr                => send_ahb_wr,
      single_ahb_wr_xfer         => single_ahb_wr_xfer,
      single_ahb_rd_xfer         => single_ahb_rd_xfer,
      send_bresp                 => send_bresp,
      axi_wvalid                 => axi_wvalid,
      send_rvalid                => send_rvalid,
      send_rlast                 => send_rlast,
      axi_rready                 => axi_rready,
      timeout_i                  => timeout_s,
      timeout_inprogress         => timeout_inprogress
   );

-------------------------------------------------------------------------------
-- Instantiation of the AHB Master Interface module
-------------------------------------------------------------------------------

   AHB_MSTR_IF_MODULE : ahb_mstr_if
   generic map(
      C_M_AHB_ADDR_WIDTH               => C_M_AHB_ADDR_WIDTH,
      C_M_AHB_DATA_WIDTH               => C_M_AHB_DATA_WIDTH,
      C_S_AXI_DATA_WIDTH               => C_S_AXI_DATA_WIDTH,
      C_S_AXI_SUPPORTS_NARROW_BURST    => C_S_AXI_SUPPORTS_NARROW_BURST 
   )
   port map(
      AHB_HCLK                         => s_axi_aclk,
      AHB_HRESETN                      => s_axi_aresetn,
      M_AHB_HADDR                      => m_ahb_haddr,
      M_AHB_HWRITE                     => m_ahb_hwrite,
      M_AHB_HSIZE                      => m_ahb_hsize,
      M_AHB_HBURST                     => m_ahb_hburst,
      M_AHB_HPROT                      => m_ahb_hprot,
      M_AHB_HTRANS                     => m_ahb_htrans,
      M_AHB_HMASTLOCK                  => m_ahb_hmastlock,
      M_AHB_HWDATA                     => m_ahb_hwdata,
      M_AHB_HREADY                     => m_ahb_hready,
      M_AHB_HRDATA                     => m_ahb_hrdata,
      M_AHB_HRESP                      => m_ahb_hresp,

      ahb_rd_request                   => ahb_rd_request,
      ahb_wr_request                   => ahb_wr_request,
      axi_lock                         => axi_lock,
      rd_data                          => rd_data,
      slv_err_resp                     => slv_err_resp,
      axi_prot                         => axi_prot,
      axi_wdata                        => axi_wdata,
      axi_cache                        => axi_cache,
      axi_size                         => axi_size,
      axi_address                      => axi_address,
      axi_burst                        => axi_burst,
      axi_length                       => axi_length,
      send_wvalid                      => send_wvalid,
      send_ahb_wr                      => send_ahb_wr,
      single_ahb_wr_xfer               => single_ahb_wr_xfer,
      single_ahb_rd_xfer               => single_ahb_rd_xfer,
      send_bresp                       => send_bresp,
      axi_wvalid                       => axi_wvalid,
      send_rvalid                      => send_rvalid,
      send_rlast                       => send_rlast,
      axi_rready                       => axi_rready,
      timeout_inprogress               => timeout_inprogress,
      load_cntr                        => load_cntr,
      cntr_enable                      => cntr_enable
   );

-------------------------------------------------------------------------------
-- Instantiation of the timeout module
-------------------------------------------------------------------------------

   TIME_OUT_MODULE : time_out
   generic map (
      C_DPHASE_TIMEOUT  => C_DPHASE_TIMEOUT
   )
   port map (
      S_AXI_ACLK        => s_axi_aclk, 
      S_AXI_ARESETN     => s_axi_aresetn, 

      M_AHB_HREADY      => m_ahb_hready, 

      load_cntr         => load_cntr, 
      cntr_enable       => cntr_enable, 
      timeout_o         => timeout_s 
   );

end architecture RTL;
