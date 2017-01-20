--------------------------------------------------------------
--
-- (C) Copyright Kutu Pty. Ltd. 2014.
--
-- file: axi4_lite_test.vhd
--
-- author: Greg Smart
--
--------------------------------------------------------------
--------------------------------------------------------------
--
-- This module is a simple interface that tests the axi4_lite
-- controller.
--
--------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- synopsys translate_off
library unisim;
use unisim.vcomponents.all;
-- synopsys translate_on

entity axi4_lite_test is
   port (
      resetn               : in std_logic;
      clk                  : in std_logic; 

      -- write interface from system
      sys_wraddr           : in std_logic_vector(12 downto 2);                      -- address for reads/writes
      sys_wrdata           : in std_logic_vector(31 downto 0);                      -- data/no. bytes
      sys_wr_cmd           : in std_logic;                                          -- write strobe

      sys_rdaddr           : in std_logic_vector(12 downto 2);                      -- address for reads/writes
      sys_rddata           : out std_logic_vector(31 downto 0);                     -- input data port for read operation
      sys_rd_cmd           : in std_logic;                                          -- read strobe
      sys_rd_endcmd        : out std_logic;                                         -- input read strobe

      -- led output
      gpio_led             : out std_logic_vector(3 downto 0)
   );
end axi4_lite_test;


architecture RTL of axi4_lite_test is

   signal   data_register        : std_logic_vector(31 downto 0);
   signal   reset                : std_logic;
   signal   sys_rd_end           : std_logic;

begin

   gpio_led       <= data_register(3 downto 0);
   sys_rd_endcmd  <= sys_rd_end and sys_rd_cmd;
   reset          <= not resetn;

   process (clk)
   begin
      if rising_edge(clk) then
         if reset = '1' then
            sys_rddata     <= X"00000000";
            sys_rd_end     <= '0';
            data_register  <= X"fffffffa";
         else
            if sys_wr_cmd = '1' then
               data_register <= X"00" & "000" & sys_wraddr(12 downto 2) & "00" & sys_wrdata(7 downto 0);
            end if;

            if sys_rd_cmd = '1' then 
               sys_rddata <= sys_rdaddr(11 downto 4) & data_register(23 downto 0);
            end if;

            -- This will be more complex in most cases
            if sys_rd_cmd = '1' then
               sys_rd_end <= '1';
            elsif sys_rd_cmd = '0' then 
               sys_rd_end <= '0';
            end if;

         end if;
      end if;
   end process;

 end RTL;



