--------------------------------------------------------------
--
-- (C) Copyright Kutu Pty. Ltd. 2018.
--
-- file: serializer.vhd
--
-- author: Greg Smart
--
--------------------------------------------------------------
--------------------------------------------------------------
--
-- This module generates a 742.5MHz clock from a 200MHz
-- reference clock.  Actual output frequency is 742.85MHz.
-- This results in a frame rate of 60.02Hz. Clock jitter is
-- 99ps, or about 0.16UI @ 1.485GHz
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
library UNISIM;
use UNISIM.VComponents.all;

entity serializer is
   Port
   (
      reset       : in std_logic;
      clk         : in std_logic;
      clk_x5      : in std_logic;

      data        : in std_logic_vector(9 downto 0);

      DOUT_P      : out  std_logic;
      DOUT_N      : out  std_logic
   );
end serializer;

architecture RTL of serializer is

    signal shift1      : std_logic := '0';
    signal shift2      : std_logic := '0';
    signal serial      : std_logic := '0';
    signal ce_reg      : std_logic := '0';
    signal reset_reg   : std_logic := '1';
    signal reset_delay : std_logic_vector(7 downto 0) := (others => '0');

begin


master_serdes : OSERDESE2
   generic map
   (
      DATA_RATE_OQ      => "DDR",
      DATA_RATE_TQ      => "DDR",
      DATA_WIDTH        => 10,
      INIT_OQ           => '1',
      INIT_TQ           => '1',
      SERDES_MODE       => "MASTER",
      SRVAL_OQ          => '0',
      SRVAL_TQ          => '0',
      TBYTE_CTL         => "FALSE",
      TBYTE_SRC         => "FALSE",
      TRISTATE_WIDTH    => 1
   )
   port map (
      OFB               => open,
      OQ                => serial,
      SHIFTOUT1         => open,
      SHIFTOUT2         => open,
      TBYTEOUT          => open,
      TFB               => open,
      TQ                => open,
      CLK               => clk_x5,
      CLKDIV            => clk,

      -- D1 - D8: 1-bit (each) input: Parallel data inputs (1-bit each)
      D1                => data(0),
      D2                => data(1),
      D3                => data(2),
      D4                => data(3),
      D5                => data(4),
      D6                => data(5),
      D7                => data(6),
      D8                => data(7),
      OCE               => ce_reg,
      RST               => reset_reg,

      -- SHIFTIN1 / SHIFTIN2: 1-bit (each) input: Data input expansion (1-bit each)
      SHIFTIN1          => shift1,
      SHIFTIN2          => shift2,

      -- T1 - T4: 1-bit (each) input: Parallel 3-state inputs
      T1                => '0',
      T2                => '0',
      T3                => '0',
      T4                => '0',
      TBYTEIN           => '0',
      TCE               => '0'
   );

slave_serdes : OSERDESE2
   generic map (
      DATA_RATE_OQ      => "DDR",
      DATA_RATE_TQ      => "DDR",
      DATA_WIDTH        => 10,
      INIT_OQ           => '1',
      INIT_TQ           => '1',
      SERDES_MODE       => "SLAVE",
      SRVAL_OQ          => '0',
      SRVAL_TQ          => '0',
      TBYTE_CTL         => "FALSE",
      TBYTE_SRC         => "FALSE",
      TRISTATE_WIDTH    => 1
   )
   port map (
      OFB               => open,
      OQ                => open,

      -- SHIFTOUT1 / SHIFTOUT2: 1-bit (each) output: Data output expansion (1-bit each)
      SHIFTOUT1         => shift1,
      SHIFTOUT2         => shift2,

      TBYTEOUT          => open,
      TFB               => open,
      TQ                => open,
      CLK               => clk_x5,
      CLKDIV            => clk,

      -- D1 - D8: 1-bit (each) input: Parallel data inputs (1-bit each)
      D1                => '0',
      D2                => '0',
      D3                => data(8),
      D4                => data(9),
      D5                => '0',
      D6                => '0',
      D7                => '0',
      D8                => '0',
      OCE               => ce_reg,
      RST               => reset_reg,

      -- SHIFTIN1 / SHIFTIN2: 1-bit (each) input: Data input expansion (1-bit each)
      SHIFTIN1          => '0',
      SHIFTIN2          => '0',

      -- T1 - T4: 1-bit (each) input: Parallel 3-state inputs
      T1                => '0',
      T2                => '0',
      T3                => '0',
      T4                => '0',
      TBYTEIN           => '0',
      TCE               => '0'
   );

   obuf: OBUFDS
   generic map
   (
      IOSTANDARD        => "TMDS_33",
      SLEW              => "FAST"
   )
   port map
   (
      O                 => DOUT_P,
      OB                => DOUT_N,
      I                 => serial
   );



   process(clk)
   begin
      if rising_edge(clk) then
         if reset = '1' then
            ce_reg      <= '0';
            reset_delay <= X"ff";
            reset_reg   <= '1';
         else
            reset_delay <= reset_delay(6 downto 0) & '0';
            reset_reg   <= reset_delay(3);
            ce_reg      <= not reset_delay(7);

      end if;
      end if;
   end process;

end RTL;
