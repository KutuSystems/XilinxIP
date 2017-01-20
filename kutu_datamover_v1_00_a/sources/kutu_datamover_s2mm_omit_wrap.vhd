  -------------------------------------------------------------------------------
  -- kutu_datamover_s2mm_omit_wrap.vhd
  -------------------------------------------------------------------------------
  --
  -- *************************************************************************
  --
--  (c) Copyright 2010-2011 Xilinx, Inc. All rights reserved.
--
--  This file contains confidential and proprietary information
--  of Xilinx, Inc. and is protected under U.S. and
--  international copyright and other intellectual property
--  laws.
--
--  DISCLAIMER
--  This disclaimer is not a license and does not grant any
--  rights to the materials distributed herewith. Except as
--  otherwise provided in a valid license issued to you by
--  Xilinx, and to the maximum extent permitted by applicable
--  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
--  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
--  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
--  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
--  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
--  (2) Xilinx shall not be liable (whether in contract or tort,
--  including negligence, or under any other theory of
--  liability) for any loss or damage of any kind or nature
--  related to, arising under or in connection with these
--  materials, including for any direct, or any indirect,
--  special, incidental, or consequential loss or damage
--  (including loss of data, profits, goodwill, or any type of
--  loss or damage suffered as a result of any action brought
--  by a third party) even if such damage or loss was
--  reasonably foreseeable or Xilinx had been advised of the
--  possibility of the same.
--
--  CRITICAL APPLICATIONS
--  Xilinx products are not designed or intended to be fail-
--  safe, or for use in any application requiring fail-safe
--  performance, such as life-support or safety devices or
--  systems, Class III medical devices, nuclear facilities,
--  applications related to the deployment of airbags, or any
--  other applications that could lead to death, personal
--  injury, or severe property or environmental damage
--  (individually and collectively, "Critical
--  Applications"). Customer assumes the sole risk and
--  liability of any use of Xilinx products in Critical
--  Applications, subject only to applicable laws and
--  regulations governing limitations on product liability.
--
--  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
--  PART OF THIS FILE AT ALL TIMES.
  --
  -- *************************************************************************
  --
  -------------------------------------------------------------------------------
  -- Filename:        kutu_datamover_s2mm_omit_wrap.vhd
  --
  -- Description:
  --    This file implements the DataMover MM2S Omit Wrapper.
  --
  --
  --
  --
  -- VHDL-Standard:   VHDL'93
  -------------------------------------------------------------------------------
  -------------------------------------------------------------------------------
  library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;




  -------------------------------------------------------------------------------

  entity kutu_datamover_s2mm_omit_wrap is
    generic (

      C_S2MM_ID_WIDTH    : Integer range 1 to  8 :=  4;
         -- Specifies the width of the S2MM ID port

      C_S2MM_ADDR_WIDTH  : Integer range 32 to  64 :=  32;
         -- Specifies the width of the MMap Read Address Channel
         -- Address bus

      C_S2MM_MDATA_WIDTH : Integer range 32 to 1024 :=  32;
         -- Specifies the width of the MMap Read Data Channel
         -- data bus

      C_S2MM_SDATA_WIDTH : Integer range 8 to 1024 :=  32;
         -- Specifies the width of the S2MM Master Stream Data
         -- Channel data bus

      C_ENABLE_CACHE_USER    : Integer range 0 to 1 := 0

   );
    port (


      -- S2MM Primary Clock and reset inputs -----------------------
      s2mm_aclk         : in  std_logic;                          --
         -- Primary synchronization clock for the Master side     --
         -- interface and internal logic. It is also used         --
         -- for the User interface synchronization when           --
         -- C_STSCMD_IS_ASYNC = 0.                                --
                                                                  --
      -- S2MM Primary Reset input                                 --
      s2mm_aresetn      : in  std_logic;                          --
         -- Reset used for the internal master logic              --
      --------------------------------------------------------------

      s2mm_err          : Out std_logic;  -- Composite Error indication
      s2mm_xfer_cmplt   : Out std_logic;  -- Command complete indication

      -- Optional S2MM Command/Status Clock and Reset Inputs -------
      -- Only used if C_S2MM_STSCMD_IS_ASYNC = 1                  --
      s2mm_cmdsts_awclk       : in  std_logic;                    --
      -- Secondary Clock input for async CMD/Status interface     --
                                                                  --
      s2mm_cmdsts_aresetn     : in  std_logic;                    --
        -- Secondary Reset input for async CMD/Status interface   --
      --------------------------------------------------------------


      -- User Command Interface Ports (AXI Stream) -----------------------------------------------------
      s2mm_cmd_wvalid         : in  std_logic;                                                        --
      s2mm_cmd_wready         : out std_logic;                                                        --
      s2mm_cmd_wdata          : in  std_logic_vector(((8*C_ENABLE_CACHE_USER)+C_S2MM_ADDR_WIDTH+32)-1 downto 0);  --
      --------------------------------------------------------------------------------------------------

      -- S2MM AXI Address Channel I/O  --------------------------------------
      s2mm_awid     : out std_logic_vector(C_S2MM_ID_WIDTH-1 downto 0);    --
         -- AXI Address Channel ID output                                  --
                                                                           --
      s2mm_awaddr   : out std_logic_vector(C_S2MM_ADDR_WIDTH-1 downto 0);  --
         -- AXI Address Channel Address output                             --
                                                                           --
      s2mm_awlen    : out std_logic_vector(7 downto 0);                    --
         -- AXI Address Channel LEN output                                 --
         -- Sized to support 256 data beat bursts                          --
                                                                           --
      s2mm_awsize   : out std_logic_vector(2 downto 0);                    --
         -- AXI Address Channel SIZE output                                --
                                                                           --
      s2mm_awburst  : out std_logic_vector(1 downto 0);                    --
         -- AXI Address Channel BURST output                               --
                                                                           --
      s2mm_awprot   : out std_logic_vector(2 downto 0);                    --
         -- AXI Address Channel PROT output                                --
                                                                           --
      s2mm_awcache  : out std_logic_vector(3 downto 0);                    --
         -- AXI Address Channel PROT output                                --

      s2mm_awuser  : out std_logic_vector(3 downto 0);                    --
         -- AXI Address Channel PROT output                                --
                                                                           --
      s2mm_awvalid  : out std_logic;                                       --
         -- AXI Address Channel VALID output                               --
                                                                           --
      s2mm_awready  : in  std_logic;                                       --
         -- AXI Address Channel READY input                                --
      -----------------------------------------------------------------------


      -- S2MM AXI MMap Write Data Channel I/O  ----------------------------------------------
      s2mm_wdata              : Out  std_logic_vector(C_S2MM_MDATA_WIDTH-1 downto 0);      --
      s2mm_wstrb              : Out  std_logic_vector((C_S2MM_MDATA_WIDTH/8)-1 downto 0);  --
      s2mm_wlast              : Out  std_logic;                                            --
      s2mm_wvalid             : Out  std_logic;                                            --
      s2mm_wready             : In   std_logic;                                            --
      ---------------------------------------------------------------------------------------


      -- S2MM AXI MMap Write response Channel I/O  ------------------------------------------
      s2mm_bresp              : In   std_logic_vector(1 downto 0);                         --
      s2mm_bvalid             : In   std_logic;                                            --
      s2mm_bready             : Out  std_logic;                                            --
      ---------------------------------------------------------------------------------------


      -- S2MM AXI Master Stream Channel I/O  ------------------------------------------------
      s2mm_strm_wdata         : In  std_logic_vector(C_S2MM_SDATA_WIDTH-1 downto 0);       --
      s2mm_strm_wstrb         : In  std_logic_vector((C_S2MM_SDATA_WIDTH/8)-1 downto 0);   --
      s2mm_strm_wlast         : In  std_logic;                                             --
      s2mm_strm_wvalid        : In  std_logic;                                             --
      s2mm_strm_wready        : Out std_logic                                              --
      ---------------------------------------------------------------------------------------

      );

  end entity kutu_datamover_s2mm_omit_wrap;


  architecture implementation of kutu_datamover_s2mm_omit_wrap is
  attribute DowngradeIPIdentifiedWarnings: string;
  attribute DowngradeIPIdentifiedWarnings of implementation : architecture is "yes";









  begin --(architecture implementation)



    -- Just tie off output ports

      s2mm_err             <=  '0'            ;
      s2mm_xfer_cmplt      <=  '0';
      s2mm_cmd_wready      <=  '0'            ;
      s2mm_awid            <=  (others => '0');
      s2mm_awaddr          <=  (others => '0');
      s2mm_awlen           <=  (others => '0');
      s2mm_awsize          <=  (others => '0');
      s2mm_awburst         <=  (others => '0');
      s2mm_awprot          <=  (others => '0');
      s2mm_awcache         <=  (others => '0');
      s2mm_awuser          <=  (others => '0');
      s2mm_awvalid         <=  '0'            ;
      s2mm_wdata           <=  (others => '0');
      s2mm_wstrb           <=  (others => '0');
      s2mm_wlast           <=  '0'            ;
      s2mm_wvalid          <=  '0'            ;
      s2mm_bready          <=  '0'            ;
      s2mm_strm_wready     <=  '0'            ;


    -- Input ports are ignored




  end implementation;
