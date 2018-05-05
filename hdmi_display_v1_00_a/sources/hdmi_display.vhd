--------------------------------------------------------------
--
-- (C) Copyright Kutu Pty. Ltd. 2018.
--
-- file: hdmi_display.vhd
--
-- author: Greg Smart
--
--------------------------------------------------------------
--------------------------------------------------------------
--
-- This module generates a 1.485GHz hdmi stream from a 200MHz
-- reference clock. This module expects an input stream with a
-- frame structure of 1920x1080 (actual size 2200x1125) This
-- results in a frame rate of 60.02Hz. Any frame size can be
-- used if clock_gen module is adjusted.
-- The 2 submodules are the encoder and the connector function.
--
--------------------------------------------------------------
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

library hdmi_display_v1_00_a;
use hdmi_display_v1_00_a.frame_gen;
use hdmi_display_v1_00_a.hdmi_tx;
use hdmi_display_v1_00_a.test_pattern;

entity hdmi_display is
   generic
   (
      USE_TEST_PATTERN     : integer := 0;
      DEBUG_OUTPUTS        : integer := 0;

      -- Video frame parameters
      USR_HSIZE            : integer := 1920;
      USR_VSIZE            : integer := 1080;
      USR_HFRONT_PORCH     : integer := 88;
      USR_HBACK_PORCH      : integer := 148;
      USR_HPOLARITY        : integer := 1;
      USR_HMAX             : integer := 2200;
      USR_VFRONT_PORCH     : integer := 4;
      USR_VBACK_PORCH      : integer := 36;
      USR_VPOLARITY        : integer := 1;
      USR_VMAX             : integer := 1125;

      -- default colour
      USR_RED              : integer := 0;
      USR_GREEN            : integer := 0;
      USR_BLUE             : integer := 0;

      -- PLLE2 parameters
      REFERENCE_CLOCK      : integer := 125;
      OUTPUT_PIXEL_RATE    : integer := 148
   );
   port
   (
      reset                : in std_logic;
      ref_clk              : in std_logic;
      ref_aresetn          : in std_logic;

      -- AXI-Stream port from VDMA
      s_axis_mm2s_aclk     : out std_logic;
      s_axis_mm2s_tready   : out std_logic;
      s_axis_mm2s_tdata	   : in std_logic_vector(31 downto 0);
      s_axis_mm2s_tkeep	   : in std_logic_vector(3 downto 0);
      s_axis_mm2s_tlast	   : in std_logic;
      s_axis_mm2s_tvalid   : in std_logic;

      -- VDMA Signals
      dcm_locked           : out std_logic;
      fsync                : out std_logic;

      -- HDMI output
      HDMI_CLK_P           : out  std_logic;
      HDMI_CLK_N           : out  std_logic;
      HDMI_D2_P            : out  std_logic;
      HDMI_D2_N            : out  std_logic;
      HDMI_D1_P            : out  std_logic;
      HDMI_D1_N            : out  std_logic;
      HDMI_D0_P            : out  std_logic;
      HDMI_D0_N            : out  std_logic;

      -- debug signals
      debug_tmds_red       : out std_logic_vector(9 downto 0);
      debug_tmds_green     : out std_logic_vector(9 downto 0);
      debug_tmds_blue      : out std_logic_vector(9 downto 0);
      debug_hcount         : out std_logic_vector(11 downto 0);
      debug_vcount         : out std_logic_vector(11 downto 0);
      debug_vga_active     : out std_logic;
      debug_vga_running    : out std_logic;
      debug_hsync          : out std_logic;
      debug_vsync          : out std_logic;
      debug_de             : out std_logic;
      debug_red            : out std_logic_vector(7 downto 0);
      debug_green          : out std_logic_vector(7 downto 0);
      debug_blue           : out std_logic_vector(7 downto 0)
   );
end hdmi_display;

architecture RTL of hdmi_display is

   signal pxl_clk                   : std_logic;
   signal locked                    : std_logic := '0';
   signal reset_sig                 : std_logic;

   signal locked_count              : std_logic_vector(4 downto 0) := (others => '0');

   signal s_axis_mm2s_aresetn_sig   : std_logic;
   signal s_axis_mm2s_tready_sig    : std_logic;
   signal s_axis_mm2s_tdata_sig     : std_logic_vector(31 downto 0);
   signal s_axis_mm2s_tkeep_sig     : std_logic_vector(3 downto 0);
   signal s_axis_mm2s_tlast_sig     : std_logic;
   signal s_axis_mm2s_tvalid_sig    : std_logic;
   signal fsync_sig                 : std_logic;

   signal s_axis_mm2s_aresetn_reg   : std_logic;

   signal hsync                     : std_logic;
   signal vsync                     : std_logic;
   signal de                        : std_logic;
   signal red                       : std_logic_vector(7 downto 0);
   signal green                     : std_logic_vector(7 downto 0);
   signal blue                      : std_logic_vector(7 downto 0);

begin

   debug_hsync    <= hsync;
   debug_vsync    <= vsync;
   debug_de       <= de;
   debug_red      <= red;
   debug_green    <= green;
   debug_blue     <= blue;


   s_axis_mm2s_aclk <= pxl_clk;


   process (ref_clk)
   begin
      if rising_edge(ref_clk) then
         s_axis_mm2s_aresetn_reg <= ref_aresetn;

         if locked = '0' then
            locked_count <= (others => '0');
         elsif locked_count(4) = '0' then
            locked_count <= locked_count + 1;
         end if;
         dcm_locked <= locked_count(4);
      end if;
   end process;

   -- Instantiation of display controller
   frame_gen_1 : entity hdmi_display_v1_00_a.frame_gen
   generic map
   (
      -- Video frame parameters
      USR_HSIZE         => USR_HSIZE,
      USR_VSIZE         => USR_VSIZE,
      USR_HFRONT_PORCH  => USR_HFRONT_PORCH,
      USR_HBACK_PORCH   => USR_HBACK_PORCH,
      USR_HPOLARITY     => USR_HPOLARITY,
      USR_HMAX          => USR_HMAX,
      USR_VFRONT_PORCH  => USR_VFRONT_PORCH,
      USR_VBACK_PORCH   => USR_VBACK_PORCH,
      USR_VPOLARITY     => USR_VPOLARITY,
      USR_VMAX          => USR_VMAX,
      USR_RED           => USR_RED,
      USR_GREEN         => USR_GREEN,
      USR_BLUE          => USR_BLUE
   )
   port map (
      reset             => reset,
      pxl_clk           => pxl_clk,
      locked            => locked_count(4),

      -- Ports of Axi Slave Bus Interface S_AXIS_MM2S
      s_axis_aresetn    => s_axis_mm2s_aresetn_sig,
      s_axis_tready     => s_axis_mm2s_tready_sig,
      s_axis_tdata      => s_axis_mm2s_tdata_sig,
      s_axis_tkeep      => s_axis_mm2s_tkeep_sig,
      s_axis_tlast      => s_axis_mm2s_tlast_sig,
      s_axis_tvalid     => s_axis_mm2s_tvalid_sig,

      fsync             => fsync_sig,
      hsync             => hsync,
      vsync             => vsync,
      de                => de,
      red               => red,
      green             => green,
      blue              => blue,

      -- Debug Signals
      debug_hcount      => debug_hcount,
      debug_vcount      => debug_vcount,
      debug_vga_active  => debug_vga_active,
      debug_vga_running => debug_vga_running
   );

   ENABLE_TEST : if USE_TEST_PATTERN = 1 generate
      test_pattern_1 : entity hdmi_display_v1_00_a.test_pattern
      generic map
      (
      -- Video frame parameters
         USR_HSIZE            => USR_HSIZE,
         USR_VSIZE            => USR_VSIZE
      )
      port map
      (
         reset                => reset_sig,
         fsync                => fsync_sig,

         -- simulating AXI-Stream port from VDMA
         s_axis_mm2s_aresetn  => s_axis_mm2s_aresetn_sig,
         s_axis_mm2s_aclk     => pxl_clk,
         s_axis_mm2s_tready   => s_axis_mm2s_tready_sig,
         s_axis_mm2s_tdata    => s_axis_mm2s_tdata_sig,
         s_axis_mm2s_tkeep    => s_axis_mm2s_tkeep_sig,
         s_axis_mm2s_tlast    => s_axis_mm2s_tlast_sig,
         s_axis_mm2s_tvalid   => s_axis_mm2s_tvalid_sig
      );

      s_axis_mm2s_tready   <= '0';
      fsync                <= '0';
      reset_sig            <= not s_axis_mm2s_aresetn_reg;

   end generate;

   DISABLE_TEST : if USE_TEST_PATTERN = 0 generate
      s_axis_mm2s_aresetn_sig <= s_axis_mm2s_aresetn_reg;
      s_axis_mm2s_tready      <= s_axis_mm2s_tready_sig;
      s_axis_mm2s_tdata_sig   <= s_axis_mm2s_tdata;
      s_axis_mm2s_tkeep_sig   <= s_axis_mm2s_tkeep;
      s_axis_mm2s_tlast_sig   <= s_axis_mm2s_tlast;
      s_axis_mm2s_tvalid_sig  <= s_axis_mm2s_tvalid;
      fsync                   <= fsync_sig;
   end generate;


   hdmi_tx_1 : entity hdmi_display_v1_00_a.hdmi_tx
   generic map
   (
      REFERENCE_CLOCK   => REFERENCE_CLOCK,
      OUTPUT_PIXEL_RATE => OUTPUT_PIXEL_RATE
   )
   port map (
      reset             => reset,
      ref_clk           => ref_clk,

      video_clk         => pxl_clk,
      locked            => locked,

      -- VGA
      hsync             => hsync,
      vsync             => vsync,
      de                => de,
      red               => red,
      green             => green,
      blue              => blue,

      debug_tmds_red    => debug_tmds_red,
      debug_tmds_green  => debug_tmds_green,
      debug_tmds_blue   => debug_tmds_blue,
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
