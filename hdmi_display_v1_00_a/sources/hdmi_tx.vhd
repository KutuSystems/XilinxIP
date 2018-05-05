--------------------------------------------------------------
--
-- (C) Copyright Kutu Pty. Ltd. 2018.
--
-- file: hdmi_tx.vhd
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

library hdmi_display_v1_00_a;
use hdmi_display_v1_00_a.clock_gen;
use hdmi_display_v1_00_a.TMDS_encoder;
use hdmi_display_v1_00_a.serializer;


entity hdmi_tx is
   generic
   (
      -- PLLE2 parameters
      REFERENCE_CLOCK      : integer := 125;
      OUTPUT_PIXEL_RATE    : integer := 148
   );
   port
   (
      reset             : in  std_logic;
      ref_clk           : in  std_logic;

      video_clk         : out std_logic;
      locked            : out std_logic;

      --VGA input frame
      hsync             : in  std_logic;
      vsync             : in  std_logic;
      de                : in  std_logic;
      red               : in  std_logic_vector(7 downto 0);
      green             : in  std_logic_vector(7 downto 0);
      blue              : in  std_logic_vector(7 downto 0);

      debug_tmds_red    : out std_logic_vector(9 downto 0);
      debug_tmds_green  : out std_logic_vector(9 downto 0);
      debug_tmds_blue   : out std_logic_vector(9 downto 0);

      --HDMI output stream
      HDMI_CLK_P        : out std_logic;
      HDMI_CLK_N        : out std_logic;
      HDMI_D2_P         : out std_logic;
      HDMI_D2_N         : out std_logic;
      HDMI_D1_P         : out std_logic;
      HDMI_D1_N         : out std_logic;
      HDMI_D0_P         : out std_logic;
      HDMI_D0_N         : out std_logic
   );
end hdmi_tx;

architecture RTL of hdmi_tx is

   signal PXL_CLK_1X    : std_logic;
   signal PXL_CLK_5X    : std_logic;

   signal clk           : std_logic;
   signal pll_locked    : std_logic := '0';
   signal reset200      : std_logic := '1';
   signal reset_reclock : std_logic := '1';
   signal reset_reg     : std_logic := '1';
   signal c             : std_logic_vector(1 downto 0);
   signal blank         : std_logic;

   signal tmds_red      : std_logic_vector(9 downto 0);
   signal tmds_green    : std_logic_vector(9 downto 0);
   signal tmds_blue     : std_logic_vector(9 downto 0);

begin

   video_clk         <= clk;

   debug_tmds_red    <= tmds_red;
   debug_tmds_green  <= tmds_green;
   debug_tmds_blue   <= tmds_blue;

   clock_gen_1 : entity hdmi_display_v1_00_a.clock_gen
   generic map
   (
      REFERENCE_CLOCK   => REFERENCE_CLOCK,
      OUTPUT_PIXEL_RATE => OUTPUT_PIXEL_RATE
   )
   port map
   (
      reset    => reset,
      ref_clk  => ref_clk,

      clk742   => PXL_CLK_5X,
      clk148   => PXL_CLK_1X,
      clk      => clk,
      locked   => pll_locked
   );

   process (ref_clk)
   begin
      if rising_edge(ref_clk) then
         if reset = '1' then
            reset200   <= '1';
         elsif reset_reg = '1' then
            reset200   <= '0';
         end if;
      end if;
   end process;

   -- synchronous reset for BUFR
   process (clk)
   begin
      if rising_edge(clk) then

         locked         <= pll_locked;
         reset_reclock  <= reset or reset200 or not pll_locked;
         reset_reg <= reset_reclock or reset or reset200 or not pll_locked;

      end if;
   end process;


   -- TMDS Encoders
   c     <= vsync & hsync;
   blank <= not de;

	TMDS_encoder_red: entity hdmi_display_v1_00_a.TMDS_encoder
   port map
   (
      reset    => reset_reg,
      clk      => clk,
      data     => red,
      c        => "00",
      blank    => blank,
      encoded  => tmds_red
   );

	TMDS_encoder_green: entity hdmi_display_v1_00_a.TMDS_encoder
   port map
   (
      reset    => reset_reg,
      clk      => clk,
      data     => green,
      c        => "00",
      blank    => blank,
      encoded  => tmds_green
   );

	TMDS_encoder_blue: entity hdmi_display_v1_00_a.TMDS_encoder
   port map
   (
      reset    => reset_reg,
      clk      => clk,
      data     => blue,
      c        => c,
      blank    => blank,
      encoded  => tmds_blue
   );

   -- I/O serializers
   ser_ch0: entity hdmi_display_v1_00_a.serializer
   port map
   (
      reset    => reset_reg,
      clk      => PXL_CLK_1X,
      clk_x5   => PXL_CLK_5X,
      data     => tmds_blue,
      DOUT_P   => HDMI_D0_P,
      DOUT_N   => HDMI_D0_N
   );

   ser_ch1: entity hdmi_display_v1_00_a.serializer
   port map
   (
      reset    => reset_reg,
      clk      => PXL_CLK_1X,
      clk_x5   => PXL_CLK_5X,
      data     => tmds_green,
      DOUT_P   => HDMI_D1_P,
      DOUT_N   => HDMI_D1_N
   );

   ser_ch2: entity hdmi_display_v1_00_a.serializer
   port map
   (
      reset    => reset_reg,
      clk      => PXL_CLK_1X,
      clk_x5   => PXL_CLK_5X,
      data     => tmds_red,
      DOUT_P   => HDMI_D2_P,
      DOUT_N   => HDMI_D2_N
   );

   ser_ch3: entity hdmi_display_v1_00_a.serializer
   port map
   (
      reset    => reset_reg,
      clk      => PXL_CLK_1X,
      clk_x5   => PXL_CLK_5X,
      data     => "0000011111",
      DOUT_P   => HDMI_CLK_P,
      DOUT_N   => HDMI_CLK_N
   );

end RTL;
