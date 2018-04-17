--------------------------------------------------------------
--
-- (C) Copyright Kutu Pty. Ltd. 2015.
--
-- file: adc_interface_tb1.vhd
--
-- author: Greg Smart
--
--------------------------------------------------------------
--------------------------------------------------------------
--
-- This is the test bench for testing the ADC interface
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

component TDMS_encoder
   Port
   (
      clk     : in  STD_LOGIC;
      data    : in  STD_LOGIC_VECTOR (7 downto 0);
      c       : in  STD_LOGIC_VECTOR (1 downto 0);
      blank   : in  STD_LOGIC;
      encoded : out  STD_LOGIC_VECTOR (9 downto 0)
   );
end component;

component TDMS_encoder_orig
   Port
   (
      clk     : in  STD_LOGIC;
      data    : in  STD_LOGIC_VECTOR (7 downto 0);
      c       : in  STD_LOGIC_VECTOR (1 downto 0);
      blank   : in  STD_LOGIC;
      encoded : out  STD_LOGIC_VECTOR (9 downto 0)
   );
end component;

   constant tCK            : time   := 5000 ps;


   signal clk              : std_logic;
   signal data_in          : std_logic_vector(11 downto 0);

   signal data             : std_logic_vector(7 downto 0);
   signal blank            : std_logic;
   signal c                : std_logic_vector(1 downto 0);

   signal encoded          : std_logic_vector(9 downto 0);
   signal encoded_compare  : std_logic_vector(9 downto 0);
   signal encoded_ref      : std_logic_vector(9 downto 0);

   signal errors           : integer;

begin


   UUT: TDMS_encoder
   port map (
      clk     => clk,
      data    => data,
      c       => c,
      blank   => blank,
      encoded => encoded
   );

   UUT_ref: TDMS_encoder_orig
   port map (
      clk     => clk,
      data    => data,
      c       => c,
      blank   => blank,
      encoded => encoded_ref
   );

   data  <= data_in(7 downto 0);
   c     <= data_in(9 downto 8);
   blank <= not data_in(10);

   process  -- process for clk
   begin
      loop
         clk   <= '1';
         wait for tCK/2;
         clk   <= '0';
         wait for tCK/2;
      end loop;
   end process;



   process  -- process for generating input data
   begin
      data_in         <= X"3f0";
      wait for tCK;

      loop

         data_in  <= transport data_in + 1 after 100 ps;

         wait for tCK;
      end loop;
   end process;


   encoded_compare <= transport encoded_ref after 2*tCK;

   process  -- process for testing output data
   begin
      errors <= 0;
      wait until clk = '1';
      wait until clk = '0';
      loop
         wait until clk = '1';
         wait until clk = '0';
            if (encoded /= encoded_compare) then
               errors <= errors + 1;
            end if;
      end loop;
   end process;

   process  -- process for generating test
   variable tx_str   : String(1 to 4096);
   variable tx_loc   : LINE;

   begin

      wait for 10000 * tCK;

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
