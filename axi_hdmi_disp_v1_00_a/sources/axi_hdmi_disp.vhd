--------------------------------------------------------------------------------
--
--  File:
--      axi_dispctrl_v1_0.vhd
--
--  Module:
--      AXIS Display Controller
--
--  Author:
--      Tinghui Wang (Steve)
--		Sam Bobrowicz
--
--  Description:
--      Wrapper for AXI Display Controller
--
--  Additional Notes:
--      TODO - 1) Add Parameter to select whether to use a PLL or MMCM
--             2) Add Parameter to use external pixel clock (no MMCM or PLL)
--             3) Add Hot-plug detect and EDID control, selectable with parameter
--             4) Add feature detect register, for determining enabled parameters from software
--
--  Copyright notice:
--      Copyright (C) 2014 Digilent Inc.
--
--  License:
--      This program is free software; distributed under the terms of 
--      BSD 3-clause license ("Revised BSD License", "New BSD License", or "Modified BSD License")
--
--      Redistribution and use in source and binary forms, with or without modification,
--      are permitted provided that the following conditions are met:
--
--      1.    Redistributions of source code must retain the above copyright notice, this
--             list of conditions and the following disclaimer.
--      2.    Redistributions in binary form must reproduce the above copyright notice,
--             this list of conditions and the following disclaimer in the documentation
--             and/or other materials provided with the distribution.
--      3.    Neither the name(s) of the above-listed copyright holder(s) nor the names
--             of its contributors may be used to endorse or promote products derived
--             from this software without specific prior written permission.
--
--      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
--      ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
--      WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
--      IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
--      INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
--      BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
--      DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
--      LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
--      OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
--      OF THE POSSIBILITY OF SUCH DAMAGE.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library UNISIM;
use UNISIM.VComponents.all;

entity axi_hdmi_disp is
generic (
   -- Users to add parameters here
   C_RED_WIDTH          : integer   := 8;
   C_GREEN_WIDTH        : integer   := 8;
   C_BLUE_WIDTH         : integer   := 8;
   -- User parameters ends
   -- Do not modify the parameters beyond this line

   -- Parameters of Axi Slave Bus Interface S_AXI
   C_S_AXI_DATA_WIDTH	: integer   := 32;
   C_S_AXI_ADDR_WIDTH	: integer   := 6;

              -- Parameters of Axi Slave Bus Interface S_AXIS_MM2S
   C_S_AXIS_MM2S_TDATA_WIDTH	: integer	:= 32
);
port (
   -- Users to add ports here
   -- Clock Signals
   REF_CLK_I            : in  std_logic;
   FSYNC_O              : out std_logic;

   -- HDMI output
   HDMI_CLK_P           : out  std_logic;
   HDMI_CLK_N           : out  std_logic;
   HDMI_D2_P            : out  std_logic;
   HDMI_D2_N            : out  std_logic;
   HDMI_D1_P            : out  std_logic;
   HDMI_D1_N            : out  std_logic;
   HDMI_D0_P            : out  std_logic;
   HDMI_D0_N            : out  std_logic;

   -- User ports ends
   -- Do not modify the ports beyond this line

   -- Ports of Axi Slave Bus Interface S_AXI
   s_axi_aclk	        : in std_logic;
   s_axi_aresetn	: in std_logic;
   s_axi_awaddr	        : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
   s_axi_awprot	        : in std_logic_vector(2 downto 0);
   s_axi_awvalid	: in std_logic;
   s_axi_awready	: out std_logic;
   s_axi_wdata	        : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
   s_axi_wstrb	        : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
   s_axi_wvalid	        : in std_logic;
   s_axi_wready	        : out std_logic;
   s_axi_bresp	        : out std_logic_vector(1 downto 0);
   s_axi_bvalid	        : out std_logic;
   s_axi_bready	        : in std_logic;
   s_axi_araddr	        : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
   s_axi_arprot	        : in std_logic_vector(2 downto 0);
   s_axi_arvalid	: in std_logic;
   s_axi_arready	: out std_logic;
   s_axi_rdata	        : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
   s_axi_rresp	        : out std_logic_vector(1 downto 0);
   s_axi_rvalid	        : out std_logic;
   s_axi_rready	        : in std_logic;

   -- Ports of Axi Slave Bus Interface S_AXIS_MM2S
   s_axis_mm2s_aclk	: out std_logic;
   s_axis_mm2s_aresetn	: in std_logic;
   s_axis_mm2s_tready	: out std_logic;
   s_axis_mm2s_tdata	: in std_logic_vector(C_S_AXIS_MM2S_TDATA_WIDTH-1 downto 0);
   s_axis_mm2s_tkeep	: in std_logic_vector((C_S_AXIS_MM2S_TDATA_WIDTH/8)-1 downto 0);
   s_axis_mm2s_tlast	: in std_logic;
   s_axis_mm2s_tvalid	: in std_logic
);
end axi_hdmi_disp;

architecture RTL of axi_hdmi_disp is

   component axi_dispctrl
   generic (
      -- Users to add parameters here
      C_RED_WIDTH : integer   := 8;
      C_GREEN_WIDTH : integer  := 8;
      C_BLUE_WIDTH : integer  := 8;
      -- User parameters ends
      -- Do not modify the parameters beyond this line

      -- Parameters of Axi Slave Bus Interface S_AXI
      C_S_AXI_DATA_WIDTH	: integer	:= 32;
      C_S_AXI_ADDR_WIDTH	: integer	:= 6;

      -- Parameters of Axi Slave Bus Interface S_AXIS_MM2S
      C_S_AXIS_MM2S_TDATA_WIDTH	: integer	:= 32
   );
   port (
      -- Users to add ports here
      -- Clock Signals
      REF_CLK_I                     : in  std_logic;
      PXL_CLK_O                     : out std_logic;
      PXL_CLK_5X_O		    : out std_logic;
      LOCKED_O                      : out std_logic;
        
      -- Display Signals
      FSYNC_O                       : out std_logic;
      HSYNC_O                       : out std_logic;
      VSYNC_O                       : out std_logic;
      DE_O                          : out std_logic;
      RED_O                         : out std_logic_vector(C_RED_WIDTH-1 downto 0);
      GREEN_O                       : out std_logic_vector(C_GREEN_WIDTH-1 downto 0);
      BLUE_O                        : out std_logic_vector(C_BLUE_WIDTH-1 downto 0);
                
      -- Debug Signals
      DEBUG_O                       : out std_logic_vector(31 downto 0); 
      -- User ports ends
      -- Do not modify the ports beyond this line

      -- Ports of Axi Slave Bus Interface S_AXI
      s_axi_aclk	: in std_logic;
      s_axi_aresetn	: in std_logic;
      s_axi_awaddr	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      s_axi_awprot	: in std_logic_vector(2 downto 0);
      s_axi_awvalid	: in std_logic;
      s_axi_awready	: out std_logic;
      s_axi_wdata	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      s_axi_wstrb	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
      s_axi_wvalid	: in std_logic;
      s_axi_wready	: out std_logic;
      s_axi_bresp	: out std_logic_vector(1 downto 0);
      s_axi_bvalid	: out std_logic;
      s_axi_bready	: in std_logic;
      s_axi_araddr	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      s_axi_arprot	: in std_logic_vector(2 downto 0);
      s_axi_arvalid	: in std_logic;
      s_axi_arready	: out std_logic;
      s_axi_rdata	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      s_axi_rresp	: out std_logic_vector(1 downto 0);
      s_axi_rvalid	: out std_logic;
      s_axi_rready	: in std_logic;

      -- Ports of Axi Slave Bus Interface S_AXIS_MM2S
      s_axis_mm2s_aclk	   : in std_logic;
      s_axis_mm2s_aresetn  : in std_logic;
      s_axis_mm2s_tready   : out std_logic;
      s_axis_mm2s_tdata	   : in std_logic_vector(C_S_AXIS_MM2S_TDATA_WIDTH-1 downto 0);
      s_axis_mm2s_tstrb    : in std_logic_vector((C_S_AXIS_MM2S_TDATA_WIDTH/8)-1 downto 0);
      s_axis_mm2s_tlast    : in std_logic;
      s_axis_mm2s_tvalid   : in std_logic
   );
   end component;

   component hdmi_tx
   generic (
      C_RED_WIDTH : integer   := 8;
      C_GREEN_WIDTH : integer  := 8;
      C_BLUE_WIDTH : integer  := 8
   );    
   Port (
      PXLCLK_I : in std_logic;
      PXLCLK_5X_I : in std_logic;
      LOCKED_I : in std_logic;
      RST_I : in std_logic;

      -- VGA
      VGA_HS : in std_logic;
      VGA_VS : in std_logic;
      VGA_DE : in std_logic;
      VGA_R : in std_logic_vector(C_RED_WIDTH-1 downto 0);
      VGA_G : in std_logic_vector(C_GREEN_WIDTH-1 downto 0);
      VGA_B : in std_logic_vector(C_BLUE_WIDTH-1 downto 0);

      -- HDMI
      HDMI_CLK_P : out  std_logic;
      HDMI_CLK_N : out  std_logic;
      HDMI_D2_P : out  std_logic;
      HDMI_D2_N : out  std_logic;
      HDMI_D1_P : out  std_logic;
      HDMI_D1_N : out  std_logic;
      HDMI_D0_P : out  std_logic;
      HDMI_D0_N : out  std_logic
   );
   end component;

   signal pxl_clk                   : std_logic;
   signal pxl_clk_5x                : std_logic;
   signal locked                    : std_logic;

   signal hsync                     : std_logic;
   signal vsync                     : std_logic;
   signal de                        : std_logic;

   signal red                       : std_logic_vector(C_RED_WIDTH-1 downto 0);
   signal green                     : std_logic_vector(C_GREEN_WIDTH-1 downto 0);
   signal blue                      : std_logic_vector(C_BLUE_WIDTH-1 downto 0);

begin
   
   s_axis_mm2s_aclk <= pxl_clk;

   -- Instantiation of display controller
   axi_dispctrl_1 : axi_dispctrl
   generic map (
      -- Users to add parameters here
      C_RED_WIDTH          => C_RED_WIDTH,
      C_GREEN_WIDTH        => C_GREEN_WIDTH,
      C_BLUE_WIDTH         => C_BLUE_WIDTH,
      -- User parameters ends

      -- Parameters of Axi Slave Bus Interface S_AXI
      C_S_AXI_DATA_WIDTH   => C_S_AXI_DATA_WIDTH,
      C_S_AXI_ADDR_WIDTH   => C_S_AXI_ADDR_WIDTH,

      -- Parameters of Axi Slave Bus Interface S_AXIS_MM2S
      C_S_AXIS_MM2S_TDATA_WIDTH => C_S_AXIS_MM2S_TDATA_WIDTH
   )
   port map (
      -- Users to add ports here
      -- Clock Signals
      REF_CLK_I         => REF_CLK_I,
      PXL_CLK_O         => pxl_clk,
      PXL_CLK_5X_O      => pxl_clk_5x,
      LOCKED_O          => locked,
        
      -- Display Signals
      FSYNC_O           => FSYNC_O,
      HSYNC_O           => hsync,
      VSYNC_O           => vsync,
      DE_O              => de,
      RED_O             => red,
      GREEN_O           => green,
      BLUE_O            => blue,

      -- Debug Signals
      DEBUG_O           => open,
      -- User ports ends
      -- Do not modify the ports beyond this line

      -- Ports of Axi Slave Bus Interface S_AXI
      s_axi_aclk	   => s_axi_aclk,
      s_axi_aresetn	   => s_axi_aresetn,
      s_axi_awaddr	   => s_axi_awaddr,
      s_axi_awprot	   => s_axi_awprot,
      s_axi_awvalid	   => s_axi_awvalid,
      s_axi_awready	   => s_axi_awready,
      s_axi_wdata	   => s_axi_wdata,
      s_axi_wstrb	   => s_axi_wstrb,
      s_axi_wvalid	   => s_axi_wvalid,
      s_axi_wready	   => s_axi_wready,
      s_axi_bresp	   => s_axi_bresp,
      s_axi_bvalid	   => s_axi_bvalid,
      s_axi_bready	   => s_axi_bready,
      s_axi_araddr	   => s_axi_araddr,
      s_axi_arprot	   => s_axi_arprot,
      s_axi_arvalid	   => s_axi_arvalid,
      s_axi_arready	   => s_axi_arready,
      s_axi_rdata	   => s_axi_rdata,
      s_axi_rresp          => s_axi_rresp,
      s_axi_rvalid         => s_axi_rvalid,
      s_axi_rready         => s_axi_rready,

      -- Ports of Axi Slave Bus Interface S_AXIS_MM2S
      s_axis_mm2s_aclk     => pxl_clk,
      s_axis_mm2s_aresetn  => s_axis_mm2s_aresetn,
      s_axis_mm2s_tready   => s_axis_mm2s_tready,
      s_axis_mm2s_tdata    => s_axis_mm2s_tdata,
      s_axis_mm2s_tstrb    => s_axis_mm2s_tkeep,
      s_axis_mm2s_tlast    => s_axis_mm2s_tlast,
      s_axis_mm2s_tvalid   => s_axis_mm2s_tvalid
   );

   hdmi_tx_1 : hdmi_tx
   generic map (
      C_RED_WIDTH       => C_RED_WIDTH,
      C_GREEN_WIDTH     => C_GREEN_WIDTH,
      C_BLUE_WIDTH      => C_BLUE_WIDTH
   )    
   port map (
      PXLCLK_I          => pxl_clk,
      PXLCLK_5X_I       => pxl_clk_5x,
      LOCKED_I          => locked,
      RST_I             => '0',
     
      -- VGA
      VGA_HS            => hsync,
      VGA_VS            => vsync,
      VGA_DE            => de,
      VGA_R             => red,
      VGA_G             => green,
      VGA_B             => blue,

      -- HDMI output
      HDMI_CLK_P        => HDMI_CLK_P,
      HDMI_CLK_N        => HDMI_CLK_N,
      HDMI_D2_P         => HDMI_D2_P,
      HDMI_D2_N         => HDMI_D2_N,
      HDMI_D1_P         => HDMI_D1_P,
      HDMI_D1_N         => HDMI_D1_N,
      HDMI_D0_P         => HDMI_D0_P,
      HDMI_D0_N         => HDMI_D0_N
   );
   
end RTL;
