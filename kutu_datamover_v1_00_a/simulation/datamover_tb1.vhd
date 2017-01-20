--------------------------------------------------------------
--
-- (C) Copyright Kutu Pty. Ltd. 2014.
--
-- file: axi4_lite_tb1.vhd
--
-- author: Greg Smart
--
--------------------------------------------------------------
--------------------------------------------------------------
--
-- This is a simple test bench for testing the the axi4 interface
--
--------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library ieee;
use ieee.std_logic_textio.all;
use std.textio.all;

entity testbench is
end testbench;

architecture testbench_arch of testbench is

   FILE RESULTS: TEXT OPEN WRITE_MODE IS "results.txt";

   constant tCK               : time   := 5000 ps;
   constant cmd_tCK           : time   := 3600 ps;

   signal reset               : std_logic;
   signal clk200              : std_logic;
   signal cmd_clk             : std_logic;
   signal start_test          : std_logic;

   -- output leds
   signal reset_led           : std_logic;
   signal run_led             : std_logic;
   signal alive_led           : std_logic;
   signal error_led           : std_logic;
   signal mm2s_err            : std_logic;
   signal s2mm_err            : std_logic;

   component datamover_tester
   port (
      reset             : in std_logic;
      clk200            : in std_logic;
      cmd_clk           : in std_logic;
      start_test        : in std_logic;

      -- output leds
      reset_led         : out std_logic;
      run_led           : out std_logic;
      alive_led         : out std_logic;
      error_led         : out std_logic;
      mm2s_err          : out std_logic;
      s2mm_err          : out std_logic
   );
   end component;

begin

   UUT: datamover_tester
   port map (
      reset       => reset,
      clk200      => clk200,
      cmd_clk     => cmd_clk,
      start_test  => start_test,

      -- output leds
      reset_led   => reset_led,
      run_led     => run_led,
      alive_led   => alive_led,
      error_led   => error_led,
      mm2s_err    => mm2s_err,
      s2mm_err    => s2mm_err
   );

   process  -- process for clk
   begin
      loop
         clk200 <= '1';
         wait for tCK/2;
         clk200 <= '0';
         wait for tCK/2;
      end loop;
   end process;

   process  -- process for clk
   begin
      loop
         cmd_clk <= '1';
         wait for cmd_tCK/2;
         cmd_clk <= '0';
         wait for cmd_tCK/2;
      end loop;
   end process;


   process  -- process for generating test
   variable tx_str   : String(1 to 4096);
   variable tx_loc   : LINE;

   begin

      reset <= '1';
      start_test <= '0';
      wait for tCK*5;

      reset <= '0';
      wait for tCK*5; -- wait for 5 clock cycles

      wait for tCK*100;
      start_test <= '1';

      -- cycle reset
      wait for tCK*100;
      start_test <= '0';

      wait until error_led = '1';

      wait for 1000 us;

      if (error_led = '0') then
         ASSERT (FALSE) REPORT
         "Simulation successful (not a failure).  No problems detected. "
         SEVERITY FAILURE;
      else
         ASSERT (FALSE) REPORT
         "Simulation failed.  Check the errors. "
         SEVERITY FAILURE;
      end if;

   end process;

end testbench_arch;

configuration top_cfg of testbench is
	for testbench_arch
	end for;
end top_cfg;
