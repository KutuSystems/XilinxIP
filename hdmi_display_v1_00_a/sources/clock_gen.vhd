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
      PLL_MULTIPLY      : integer := 52;
      PLL_DIVIDE        : integer := 7;
      CLK_DIVIDE        : integer := 2
   );
   port
   (
      reset             : in  std_logic;
      clk200            : in  std_logic;

      clk742            : out std_logic;
      clk148            : out std_logic;
      clk               : out std_logic;
      locked            : out std_logic
   );
end clock_gen;

architecture RTL of clock_gen is

   signal clkfb         : std_logic;
   signal clk_buf       : std_logic;

begin

   plle2_adv_inst : PLLE2_ADV
   generic map
   (
      BANDWIDTH            => "HIGH",
      CLKFBOUT_MULT        => PLL_MULTIPLY,
      CLKFBOUT_PHASE       => 0.000000,
      CLKIN1_PERIOD        => 5.000000,
      CLKIN2_PERIOD        => 5.000000,
      CLKOUT0_DIVIDE       => CLK_DIVIDE,
      CLKOUT0_DUTY_CYCLE   => 0.500000,
      CLKOUT0_PHASE        => 0.000000,
      CLKOUT1_DIVIDE       => 5*CLK_DIVIDE,
      CLKOUT1_DUTY_CYCLE   => 0.500000,
      CLKOUT1_PHASE        => 0.000000,
      CLKOUT2_DIVIDE       => 5*CLK_DIVIDE,
      CLKOUT2_DUTY_CYCLE   => 0.500000,
      CLKOUT2_PHASE        => 0.000000,
      CLKOUT3_DIVIDE       => 1,
      CLKOUT3_DUTY_CYCLE   => 0.500000,
      CLKOUT3_PHASE        => 0.000000,
      CLKOUT4_DIVIDE       => 1,
      CLKOUT4_DUTY_CYCLE   => 0.500000,
      CLKOUT4_PHASE        => 0.000000,
      CLKOUT5_DIVIDE       => 1,
      CLKOUT5_DUTY_CYCLE   => 0.500000,
      CLKOUT5_PHASE        => 0.000000,
      COMPENSATION         => "ZHOLD",
      DIVCLK_DIVIDE        => PLL_DIVIDE,
      REF_JITTER1          => 0.010000,
      REF_JITTER2          => 0.010000,
      STARTUP_WAIT         => "FALSE"
   )
   port map
   (
      CLKFBIN           => clkfb,
      CLKFBOUT          => clkfb,
      CLKIN1            => clk200,
      CLKIN2            => '0',
      CLKINSEL          => '1',
      CLKOUT0           => clk742,
      CLKOUT1           => clk148,
      CLKOUT2           => clk_buf,
      CLKOUT3           => open,
      CLKOUT4           => open,
      CLKOUT5           => open,
      DADDR(6 downto 0) => "0000000",
      DCLK              => '0',
      DEN               => '0',
      DI(15 downto 0)   => X"0000",
--      DO(15 downto 0)   => do_reg,
      DRDY              => open,
      DWE               => '0',
      LOCKED            => locked,
      PWRDWN            => '0',
      RST               => reset
   );

   BUFG_inst : BUFG
   port map
   (
      O     => clk,
      I     => clk_buf
   -- 1-bit input: Clock input (connect to an IBUF or BUFMR).
   );

end RTL;
