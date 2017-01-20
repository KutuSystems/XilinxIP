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


   component blm57180_controller
   generic
   (
      VOLTAGE           : integer  range 12000 to 36000         := 24000
   );
   port
   (
      reset             : in std_logic;
      clk               : in std_logic;

      -- command inputs
      cmd_ce            : in  std_logic;
      command           : in  std_logic_vector(7 downto 0);
      data              : in  std_logic_vector(31 downto 0);

      -- feedback inputs
      hallA             : in std_logic;
      hallB             : in std_logic;
      hallC             : in std_logic;

      EA                : in std_logic;
      EB                : in std_logic;

      nOTW              : in std_logic;
      nFAULT            : in std_logic;

      -- control outputs
      PWM_A             : out std_logic;
      nRESET_A          : out std_logic;
      PWM_B             : out std_logic;
      nRESET_B          : out std_logic;
      PWM_C             : out std_logic;
      nRESET_C          : out std_logic
   );
   end component;

   component blm57180_model
   generic
   (
      VOLTAGE           : integer  range 12000 to 36000         := 24000
   );
   port
   (
      reset             : in std_logic;
      clk               : in std_logic;

   -- control inputs
      PWM_A             : in  std_logic;
      nRESET_A          : in  std_logic;
      PWM_B             : in  std_logic;
      nRESET_B          : in  std_logic;
      PWM_C             : in  std_logic;
      nRESET_C          : in  std_logic;

   -- feedback outputs
      hallA             : out std_logic;
      hallB             : out std_logic;
      hallC             : out std_logic;

      EA                : out std_logic;
      EB                : out std_logic;

      nOTW              : out std_logic;
      nFAULT            : out std_logic
   );
   end component;





   constant tCK            : time   := 10000 ps;
--   constant ref_tCK        : time   := 7100 ps;

   constant C_S_AXI_DATA_WIDTH    : integer := 32;
   constant C_S_AXI_ADDR_WIDTH    : integer := 32;
   constant C_SYS_ADDR_WIDTH      : integer := 13;

--   signal ref_clk          : std_logic;
--   signal clk              : std_logic;
   signal clk                    : std_logic;
   signal reset                  : std_logic;

   signal errors                 : integer;

begin

   UUT: blm57180_controller
   generic map
   (
      VOLTAGE           => 24000
   )
   port map
   (
      reset             => reset,
      clk               => clk,

      -- command inputs
      cmd_ce            => cmd_ce,
      command           => command,
      data              => data,

      -- feedback inputs
      hallA             => hallA,
      hallB             => hallB,
      hallC             => hallC,

      EA                => EA,
      EB                => EB,

      nOTW              => nOTW,
      nFAULT            => nFAULT,

      -- control outputs
      PWM_A             => PWM_A,
      nRESET_A          => nRESET_A,
      PWM_B             => PWM_B,
      nRESET_B          => nRESET_B,
      PWM_C             => PWM_C,
      nRESET_C          => nRESET_C
   );

   model_1 : blm57180_model
   generic map
   (
      VOLTAGE           => 24000
   )
   port map
   (
      reset             => reset,
      clk               => clk,

   -- control inputs
      PWM_A             => PWM_A,
      nRESET_A          => nRESET_A,
      PWM_B             => PWM_B,
      nRESET_B          => nRESET_B,
      PWM_C             => PWM_C,
      nRESET_C          => nRESET_C,

   -- feedback outputs
      hallA             => hallA,
      hallB             => hallB,
      hallC             => hallC,

      EA                => EA,
      EB                => EB,

      nOTW              => nOTW,
      nFAULT            => nFAULT

   );

   process  -- process for clk
   begin
      loop
         clk   <= '1';
         wait for tCK/2;
         clk   <= '0';
         wait for tCK/2;
      end loop;
   end process;

 
   process  -- process for generating test
   variable tx_str   : String(1 to 4096);
   variable tx_loc   : LINE;
   
   begin
      errors               <= 0;
      reset                <= '1';

      wait for tCK*5;
  
      -- basic startup test
      wait for tCK*5; -- wait for 5 clock cycles
      reset                <= '0';
      wait for tCK*5; -- wait for 5 clock cycles

      wait for 1000 * tCK;  
      
      wait for 1000 * tCK;  

      if (errors = 0) then
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

