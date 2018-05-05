--------------------------------------------------------------
--
-- (C) Copyright Kutu Pty. Ltd. 2018.
--
-- file: clock_gen.vhd
--
-- author: Greg Smart
--
--------------------------------------------------------------
--------------------------------------------------------------
--
-- This module generates a 742.5MHz clock from a 200MHz
-- reference clock.  Actual output frequency is 742.85MHz.
-- This results in a frame rate of 60.02Hz. Clock jitter is
-- 99ps, or about 0.16UI @ 1.485GHz.  The clock uses a BUFIO
-- which is out of spec, so will cause a timing violation, but
-- it still works.
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
use IEEE.NUMERIC_STD.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

entity clock_gen is
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

      clk742            : out std_logic;
      clk148            : out std_logic;
      clk               : out std_logic;
      locked            : out std_logic
   );
end clock_gen;

architecture RTL of clock_gen is


   function funct_calc_mult (
      in_clk : integer;
      out_clk : integer
   ) return real is
   begin
      if ((in_clk = 100) and (out_clk = 118)) then
         return(11.875);
      elsif ((in_clk = 100) and (out_clk = 148)) then
         return(37.125);
      elsif ((in_clk = 100) and (out_clk = 150)) then
         return(7.5);
      elsif ((in_clk = 125) and (out_clk = 118)) then
         return(9.5);
      elsif ((in_clk = 125) and (out_clk = 148)) then
         return(11.875);
      elsif ((in_clk = 125) and (out_clk = 150)) then
         return(6.0);
      elsif ((in_clk = 148) and (out_clk = 118)) then
         return(8.0);
      elsif ((in_clk = 148) and (out_clk = 148)) then
         return(5.0);
      else
         return(5.0);
      end if;
   end function funct_calc_mult;

   function funct_calc_divclk (
      in_clk : integer;
      out_clk : integer
   ) return integer is
   begin
      if ((in_clk = 100) and (out_clk = 118)) then
         return(1);
      elsif ((in_clk = 100) and (out_clk = 148)) then
         return(5);
      elsif ((in_clk = 100) and (out_clk = 150)) then
         return(1);
      elsif ((in_clk = 125) and (out_clk = 118)) then
         return(1);
      elsif ((in_clk = 125) and (out_clk = 148)) then
         return(2);
      elsif ((in_clk = 125) and (out_clk = 150)) then
         return(1);
      elsif ((in_clk = 148) and (out_clk = 118)) then
         return(1);
      elsif ((in_clk = 148) and (out_clk = 148)) then
         return(1);
      else
         return(1);
      end if;
   end function funct_calc_divclk;

   function funct_calc_outclk (
      in_clk : integer;
      out_clk : integer
   ) return integer is
   begin
      if ((in_clk = 100) and (out_clk = 118)) then
         return(2);
      elsif ((in_clk = 100) and (out_clk = 148)) then
         return(1);
      elsif ((in_clk = 100) and (out_clk = 150)) then
         return(1);
      elsif ((in_clk = 125) and (out_clk = 118)) then
         return(2);
      elsif ((in_clk = 125) and (out_clk = 148)) then
         return(1);
      elsif ((in_clk = 125) and (out_clk = 150)) then
         return(1);
      elsif ((in_clk = 148) and (out_clk = 118)) then
         return(2);
      elsif ((in_clk = 148) and (out_clk = 148)) then
         return(1);
      else
         return(1);
      end if;
   end function funct_calc_outclk;

   signal clkfb         : std_logic;
   signal bufr_clk      : std_logic;
   signal bufg_clk      : std_logic;
   signal clk742_buf    : std_logic;
   signal clk148_buf    : std_logic;
   signal pll_locked    : std_logic;
   signal locked_n      : std_logic;

   constant CLKFBOUT_MULT_VAL : real      := funct_calc_mult (REFERENCE_CLOCK,OUTPUT_PIXEL_RATE);
   constant DIVCLK_DIVIDE_VAL : integer   := funct_calc_divclk (REFERENCE_CLOCK,OUTPUT_PIXEL_RATE);
   constant OUTCLK_DIVIDE_VAL : integer   := funct_calc_outclk (REFERENCE_CLOCK,OUTPUT_PIXEL_RATE);

begin

MMCME2_BASE_inst : MMCME2_BASE
   generic map (
      BANDWIDTH            => "OPTIMIZED",
      DIVCLK_DIVIDE        => DIVCLK_DIVIDE_VAL,
      CLKFBOUT_MULT_F      => CLKFBOUT_MULT_VAL,
      CLKFBOUT_PHASE       => 0.0,
      CLKIN1_PERIOD        => 10.0,
      CLKOUT0_DIVIDE_F     => 1.0,
      CLKOUT1_DIVIDE       => OUTCLK_DIVIDE_VAL,
      CLKOUT2_DIVIDE       => OUTCLK_DIVIDE_VAL*5,
      CLKOUT3_DIVIDE       => OUTCLK_DIVIDE_VAL*5,
      CLKOUT4_DIVIDE       => 1,
      CLKOUT5_DIVIDE       => 1,
      CLKOUT6_DIVIDE       => 1,
      CLKOUT0_DUTY_CYCLE   => 0.5,
      CLKOUT1_DUTY_CYCLE   => 0.5,
      CLKOUT2_DUTY_CYCLE   => 0.5,
      CLKOUT3_DUTY_CYCLE   => 0.5,
      CLKOUT4_DUTY_CYCLE   => 0.5,
      CLKOUT5_DUTY_CYCLE   => 0.5,
      CLKOUT6_DUTY_CYCLE   => 0.5,
      CLKOUT0_PHASE        => 0.0,
      CLKOUT1_PHASE        => 0.0,
      CLKOUT2_PHASE        => 0.0,
      CLKOUT3_PHASE        => 0.0,
      CLKOUT4_PHASE        => 0.0,
      CLKOUT5_PHASE        => 0.0,
      CLKOUT6_PHASE        => 0.0,
      CLKOUT4_CASCADE      => FALSE,
      REF_JITTER1          => 0.010,
      STARTUP_WAIT         => FALSE
   )
   port map (
      -- Clock Outputs: 1-bit (each) output: User configurable clock outputs
      CLKOUT0   => open,
      CLKOUT0B  => open,
      CLKOUT1   => clk742_buf,
      CLKOUT1B  => open,
      CLKOUT2   => clk148_buf,
      CLKOUT2B  => open,
      CLKOUT3   => bufg_clk,
      CLKOUT3B  => open,
      CLKOUT4   => open,
      CLKOUT5   => open,
      CLKOUT6   => open,
      CLKFBOUT  => clkfb,
      CLKFBOUTB => open,
      LOCKED    => pll_locked,
      CLKIN1    => ref_clk,
      PWRDWN    => '0',
      RST       => reset,
      CLKFBIN   => clkfb
   );

   locked   <= pll_locked;
   locked_n <= not pll_locked;

   BUFIO_inst : BUFIO
   port map
   (
      O     => clk742,
      I     => clk742_buf
   );

   BUFR_inst : BUFR
   generic map
   (
      BUFR_DIVIDE => "BYPASS",   -- Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8"
      SIM_DEVICE  => "7SERIES"  -- Must be set to "7SERIES"
   )
   port map
   (
      O     => bufr_clk,
      CE    => '1',
      CLR   => locked_n,
      I     => clk148_buf
   );
   clk148 <= bufr_clk;

   BUFG_inst : BUFG
   port map
   (
      O     => clk,
      I     => bufg_clk
   );

end RTL;
