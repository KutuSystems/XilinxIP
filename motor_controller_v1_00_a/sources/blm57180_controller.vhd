--------------------------------------------------------------
--
-- (C) Copyright Kutu Pty. Ltd. 2016.
--
-- file: blm57180_model.vhd
--
-- author: Greg Smart
--
--------------------------------------------------------------
--------------------------------------------------------------
--
-- This module provides glue logic between a datamover interface
-- and a Xilinx dsc_bypass interface
--
--------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

entity blm57180_controller is
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
end entity blm57180_controller;

-- ----------------------------------------------------------------------------
-- Architecture section
-- ----------------------------------------------------------------------------

architecture behavioural of blm57180_controller is


   signal sys_PWM                : std_logic;

   signal delta_current_a        : integer;
   signal delta_current_b        : integer;
   signal delta_current_c        : integer;
   signal current_a              : integer;
   signal current_b              : integer;
   signal current_c              : integer;
   signal volt_a_sig             : integer;
   signal volt_b_sig             : integer;
   signal volt_c_sig             : integer;

   signal velocity               : integer; -- velocity in RPS/1000

   constant CURRENT_DECAY        : integer := 1000;  -- current in nA

   constant INDUCTANCE_INV       : integer := 500;  -- 1/L in Henry's

   constant BACK_EMF_RPS         : integer := 534;  -- mV per RPS, i.e 26.7V@50RPS, or 3000RPM

   constant COIL_RESISTANCE      : integer := 900;  -- resistance in milliohms

   constant TIME_CONST           : integer := 5;  -- sample time in nS

   constant CURRENT_MULTIPLIER   : integer := INDUCTANCE_INV * TIME_CONST;
begin


   process (clk)
   begin
      if rising_edge(clk) then

         if reset = '1' then 
            sys_PWM             <= '0';
         else
            sys_PWM             <= '0';
         end if; 

         -- mechanical properties
         if reset = '1' then 
            PWM_A             <= '0';
            nRESET_A          <= '0';
            PWM_B             <= '0';
            nRESET_B          <= '0';
            PWM_C             <= '0';
            nRESET_C          <= '0';
         else
            if hallA = '1' and hallB = '0' then
               PWM_A <= sys_PWM;
            elsif hallA = '0' and hallB = '1' then
               PWM_A <= not sys_PWM;
            else
               PWM_A <= '0';
            end if;

            if hallB = '1' and hallC = '0' then
               PWM_B <= sys_PWM;
            elsif hallB = '0' and hallC = '1' then
               PWM_B <= not sys_PWM;
            else
               PWM_B <= '0';
            end if;

            if hallC = '1' and hallA = '0' then
               PWM_C <= sys_PWM;
            elsif hallC = '0' and hallA = '1' then
               PWM_C <= not sys_PWM;
            else
               PWM_C <= '0';
            end if;

            if hallA = '1' and hallB = '1' then
               nRESET_A <= '0';
            elsif hallA = '0' and hallB = '0' then
               nRESET_A <= '0';
            else
               nRESET_A <= '1';
            end if;

            if hallB = '1' and hallC = '1' then
               nRESET_B <= '0';
            elsif hallB = '0' and hallC = '0' then
               nRESET_B <= '0';
            else
               nRESET_B <= '1';
            end if;

            if hallC = '1' and hallA = '1' then
               nRESET_C <= '0';
            elsif hallC = '0' and hallA = '0' then
               nRESET_C <= '0';
            else
               nRESET_C <= '1';
            end if;

         end if;

      end if;
   end process;


end behavioural;
