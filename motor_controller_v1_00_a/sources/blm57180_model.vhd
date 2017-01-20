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

entity blm57180_model is
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
end entity blm57180_model;

-- ----------------------------------------------------------------------------
-- Architecture section
-- ----------------------------------------------------------------------------

architecture behavioural of blm57180_model is


   signal delta_current_a        : integer;
   signal delta_current_b        : integer;
   signal delta_current_c        : integer;
   signal current_a              : integer;
   signal current_b              : integer;
   signal current_c              : integer;
   signal voltage_a              : integer;
   signal voltage_b              : integer;
   signal voltage_c              : integer;
   signal back_emf               : integer;
   signal coil_loss_a            : integer;
   signal coil_loss_b            : integer;
   signal coil_loss_c            : integer;

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
      if rising_edga(clk) then

         -- current calculations
         if reset = '1' then
            delta_current_a   <= 0;
            delta_current_b   <= 0;
            delta_current_c   <= 0;
            current_a         <= 0;
            current_b         <= 0;
            current_c         <= 0;
         else
            delta_current_a   <= CURRENT_MULTIPLIER * voltage_a;
            delta_current_b   <= CURRENT_MULTIPLIER * voltage_b;
            delta_current_c   <= CURRENT_MULTIPLIER * voltage_c;
            current_a         <= current_a + delta_current_a;
            current_b         <= current_b + delta_current_b;
            current_c         <= current_c + delta_current_c;
         end if;

         -- loss calculations
         if reset = '1' then
            back_emf    <= 0;
            coil_loss_a <= 0;
            coil_loss_b <= 0;
            coil_loss_c <= 0;
         else
            back_emf    <= BACK_EMF_RPS*velocity;
            coil_loss_a <= (COIL_RESISTANCE*current_a)/1000;
            coil_loss_b <= (COIL_RESISTANCE*current_a)/1000;
            coil_loss_c <= (COIL_RESISTANCE*current_a)/1000;
         end if;

         -- workout effective voltage for current path a
         if reset = '1' then
            voltage_a <= 0;
         elsif PWM_A = '1' and PWM_B = '0' and nRESET_A = '1' and nRESET_B = '1' then
            -- forward drive
            voltage_a <= VOLTAGE - back_emf - coil_loss_a;
         elsif PWM_A = '0' and PWM_B = '1' and nRESET_A = '1' and nRESET_B = '1' then
            -- reverse drive
            voltage_a <= coil_loss_a - VOLTAGE - back_emf;
         elsif RESET_A = '1' and nRESET_B = '1' then
            -- zero drive
            voltage_a <= 0 - back_emf - coil_loss_a;
         else
            -- open h-bridge
            if (current_a > 1000) then
               voltage_a <= 0 - VOLTAGE - 1.4 - back_emf - coil_loss_a;
            elsif (current_a < -1000) then
               voltage_a <= VOLTAGE + 1.4 + back_emf + coil_loss_a;
            else
               -- bridge shuts off
               voltage_a <= 0;
            end if;
         end if;

         -- workout effective voltage for current path b
         if reset = '1' then
            voltage_b <= '0';
         elsif PWM_B = '1' and PWM_C = '0' and nRESET_B = '1' and nRESET_C = '1' then
            -- forward drive
            voltage_b <= VOLTAGE - back_emf - coil_loss_b;
         elsif PWM_B = '0' and PWM_C = '1' and nRESET_B = '1' and nRESET_C = '1' then
            -- reverse drive
            voltage_b <= coil_loss_b - VOLTAGE - back_emf;
         elsif RESET_B = '1' and nRESET_C = '1' then
            -- zero drive
            voltage_b <= 0 - back_emf - coil_loss_b;
         else
            -- open h-bridge
            if (current_b > 1000) then
               voltage_b <= 0 - VOLTAGE - 1.4 - back_emf - coil_loss_b;
            elsif (current_b < -1000) then
               voltage_b <= VOLTAGE + 1.4 + back_emf + coil_loss_b;
            else
               -- bridge shuts off
               voltage_b <= 0;
            end if;
         end if;

         -- workout effective voltage for current path c
         if reset = '1' then
            voltage_c <= '0';
         elsif PWM_C = '1' and PWM_A = '0' and nRESET_C = '1' and nRESET_A = '1' then
            -- forward drive
            voltage_c <= VOLTAGE - back_emf - coil_loss_c;
         elsif PWM_C = '0' and PWM_A = '1' and nRESET_C = '1' and nRESET_A = '1' then
            -- reverse drive
            voltage_c <= coil_loss_c - VOLTAGE - back_emf;
         elsif RESET_C = '1' and nRESET_A = '1' then
            -- zero drive
            voltage_c <= 0 - back_emf - coil_loss_c;
         else
            -- open h-bridge
            if (current_c > 1000) then
               voltage_c <= 0 - VOLTAGE - 1.4 - back_emf - coil_loss_c;
            elsif (current_c < -1000) then
               voltage_c <= VOLTAGE + 1.4 + back_emf + coil_loss_c;
            else
               -- bridge shuts off
               voltage_c <= 0;
            end if;
         end if;
      end if;
   end process;


   process (clk)
   begin
      if rising_edga(clk) then

         -- mechanical properties
         if reset = '1' then 
            acceleration <= X"00000000";
         end if;

         if reset = '1' then 
            velocity <= X"00000000";
         else
            velocity <= velocity + acceleration;
         end if;

         if reset = '1' then 
            position <= X"00000000";
         else
            position <= position + velocity;
         end if;

      end if;
   end process;


end behavioural;
