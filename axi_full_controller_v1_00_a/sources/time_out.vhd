-------------------------------------------------------------------------------
-- time_out.vhd - entity/architecture pair
-------------------------------------------------------------------------------
--
--
-- *******************************************************************
-- ** (c) Copyright [2007] - [2012] Xilinx, Inc. All rights reserved.*
-- **                                                                *
-- ** This file contains confidential and proprietary information    *
-- ** of Xilinx, Inc. and is protected under U.S. and                *
-- ** international copyright and other intellectual property        *
-- ** laws.                                                          *
-- **                                                                *
-- ** DISCLAIMER                                                     *
-- ** This disclaimer is not a license and does not grant any        *
-- ** rights to the materials distributed herewith. Except as        *
-- ** otherwise provided in a valid license issued to you by         *
-- ** Xilinx, and to the maximum extent permitted by applicable      *
-- ** law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND        *
-- ** WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES    *
-- ** AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING      *
-- ** BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-         *
-- ** INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and       *
-- ** (2) Xilinx shall not be liable (whether in contract or tort,   *
-- ** including negligence, or under any other theory of             *
-- ** liability) for any loss or damage of any kind or nature        *
-- ** related to, arising under or in connection with these          *
-- ** materials, including for any direct, or any indirect,          *
-- ** special, incidental, or consequential loss or damage           *
-- ** (including loss of data, profits, goodwill, or any type of     *
-- ** loss or damage suffered as a result of any action brought      *
-- ** by a third party) even if such damage or loss was              *
-- ** reasonably foreseeable or Xilinx had been advised of the       *
-- ** possibility of the same.                                       *
-- **                                              
-- ** CRITICAL APPLICATIONS                                          *
-- ** Xilinx products are not designed or intended to be fail-       *
-- ** safe, or for use in any application requiring fail-safe        *
-- ** performance, such as life-support or safety devices or         *
-- ** systems, Class III medical devices, nuclear facilities,        *
-- ** applications related to the deployment of airbags, or any      *
-- ** other applications that could lead to death, personal          *
-- ** injury, or severe property or environmental damage             *
-- ** (individually and collectively, "Critical                      *
-- ** Applications"). Customer assumes the sole risk and             *
-- ** liability of any use of Xilinx products in Critical            *
-- ** Applications, subject only to applicable laws and              *
-- ** regulations governing limitations on product liability.        *
-- **                                                                *
-- ** THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS       *
-- ** PART OF THIS FILE AT ALL TIMES.                                *
-- *******************************************************************
--
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Filename     :   time_out.vhd
-- Version      :   v1.01a
-- Description  :   The time_out module generates the timeout signal when 
--                  AHB slave is not responding.When C_DPHASE_TIMEOUT is '0'
--                  the timeout signal is always '0' and this module generates
--                  the timeout signal if C_DPHASE_TIMEOUT is nonzero.
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--           -- axi_ahblite_bridge.vhd
--              -- axi_slv_if.vhd 
--              -- ahb_mstr_if.vhd
--              -- time_out.vhd
-------------------------------------------------------------------------------
-- Author:     NLR 
-- History:
--   NLR      12/15/2010   Initial version
-- ^^^^^^^
-- ~~~~~~~
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*N"
--      clock signals:                          "clk", "clk_div#", "clk_#x"
--      reset signals:                          "rst", "rst_n"
--      generics:                               "C_*"
--      user defined types:                     "*_TYPE"
--      state machine next state:               "*_ns"
--      state machine current state:            "*_cs"
--      counter signals:                        "*cntr*","*count*"
--      ports:                                  - Names In Uppercase
--      processes:                              "*_REG", "*_CMB"
--      component instantiations:               "<ENTITY_>MODULE<#|_FUNC>
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- synopsys translate_off
library unisim;
use unisim.vcomponents.all;
-- synopsys translate_on

entity time_out is
   generic (
      C_DPHASE_TIMEOUT      : integer   := 0
   );
   port (
      -- AXI Signals
      S_AXI_ACLK       : in  std_logic;
      S_AXI_ARESETN    : in  std_logic;
      --AHB Signal
      M_AHB_HREADY     : in std_logic;
      --AHB Master Interface and AXI Slave Interface signals
      load_cntr        : in std_logic;
      cntr_enable      : in std_logic;
      timeout_o        : out std_logic
   );
end entity time_out;

architecture RTL of time_out is

--------------------------------------------------------------------------------
-- Function clog2 - returns the integer ceiling of the base 2 logarithm of x,
--                  i.e., the least integer greater than or equal to log2(x).
--------------------------------------------------------------------------------
function clog2(x : positive) return natural is
  variable r  : natural := 0;
  variable rp : natural := 1; -- rp tracks the value 2**r
begin 
  while rp < x loop -- Termination condition T: x <= 2**r
    -- Loop invariant L: 2**(r-1) < x
    r := r + 1;
    if rp > integer'high - rp then exit; end if;  -- If doubling rp overflows
      -- the integer range, the doubled value would exceed x, so safe to exit.
    rp := rp + rp;
  end loop;
  -- L and T  <->  2**(r-1) < x <= 2**r  <->  (r-1) < log2(x) <= r
  return r; --
end clog2;   

   component counter_f is
   generic(
      C_NUM_BITS : integer := 9
   );
   port(
      Clk           : in  std_logic;
      Rst           : in  std_logic;
      Load_In       : in  std_logic_vector(C_NUM_BITS - 1 downto 0);
      Count_Enable  : in  std_logic;
      Count_Load    : in  std_logic;
      Count_Down    : in  std_logic;
      Count_Out     : out std_logic_vector(C_NUM_BITS - 1 downto 0);
      Carry_Out     : out std_logic
   );
   end component;

-------------------------------------------------------------------------------
-- Pragma Added to supress synth warnings
-------------------------------------------------------------------------------
attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of RTL : architecture is "yes";
begin
 -------------------------------------------------------------------------------
   -- This implements the watchdog timeout function.Acknowledge from the 
   -- AHB slave space forces the counter to reload.When the AHB is not 
   -- responding and not generating M_AHB_HREADY within the number of clock 
   -- cycles mentioned in C_DPHASE_TIMEOUT, AXI interface generates ready to
   -- to AXI master so that AXI is not hung. SLVERR response is sent to AXI
   -- when timeout occurs.The below functionality exists when C_DPHASE_TIMEOUT
   -- is nonzero.
   ------------------------------------------------------------------------------- 
    
   GEN_WDT : if (C_DPHASE_TIMEOUT /= 0) generate
    
       constant TIMEOUT_VALUE_TO_USE : integer := C_DPHASE_TIMEOUT;
       constant COUNTER_WIDTH        : Integer := clog2(TIMEOUT_VALUE_TO_USE);
       constant DPTO_LD_VALUE        : std_logic_vector(COUNTER_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(TIMEOUT_VALUE_TO_USE-1,COUNTER_WIDTH));
       signal timeout_i              : std_logic;
       signal cntr_rst               : std_logic;
    
   begin
   
   cntr_rst <= not S_AXI_ARESETN or timeout_i;
   
-- ****************************************************************************
-- Instantiation of counter
-- ****************************************************************************

      I_TO_COUNTER_MODULE : counter_f
      generic map(
         C_NUM_BITS    =>  COUNTER_WIDTH
      )
      port map(
         Clk           =>  S_AXI_ACLK,
         Rst           =>  cntr_rst,
         Load_In       =>  DPTO_LD_VALUE,
         Count_Enable  =>  cntr_enable,
         Count_Load    =>  load_cntr,
         Count_Down    =>  '1',
         Count_Out     =>  open,
         Carry_Out     =>  timeout_i
      );
       
-- ****************************************************************************
-- This process is used for registering timeout
-- This timeout signal is used in generating the ready to AXI to complete
-- the AXI transaction.
-- ****************************************************************************

       TIMEOUT_REG : process(S_AXI_ACLK)
       begin
           if(S_AXI_ACLK'EVENT and S_AXI_ACLK='1')then
               if(S_AXI_ARESETN='0')then
                   timeout_o <= '0';
               else
                   timeout_o <= timeout_i and not (M_AHB_HREADY);
               end if;
           end if;
       end process TIMEOUT_REG;
       
   end generate GEN_WDT;
   
-- ****************************************************************************
-- No timeout logic when C_DPHASE_TIMEOUT = 0
-- ****************************************************************************

   GEN_NO_WDT : if (C_DPHASE_TIMEOUT = 0) generate
   begin
        timeout_o <= '0';
   end generate GEN_NO_WDT;
   
end architecture RTL;
