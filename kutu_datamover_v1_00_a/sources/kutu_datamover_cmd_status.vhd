  -------------------------------------------------------------------------------
  -- kutu_datamover_cmd_status.vhd
  -------------------------------------------------------------------------------
  --
  -- *************************************************************************
  --
--  (c) Copyright 2010-2011 Xilinx, Inc. All rights reserved.
--
--  This file contains confidential and proprietary information
--  of Xilinx, Inc. and is protected under U.S. and
--  international copyright and other intellectual property
--  laws.
--
--  DISCLAIMER
--  This disclaimer is not a license and does not grant any
--  rights to the materials distributed herewith. Except as
--  otherwise provided in a valid license issued to you by
--  Xilinx, and to the maximum extent permitted by applicable
--  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
--  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
--  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
--  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
--  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
--  (2) Xilinx shall not be liable (whether in contract or tort,
--  including negligence, or under any other theory of
--  liability) for any loss or damage of any kind or nature
--  related to, arising under or in connection with these
--  materials, including for any direct, or any indirect,
--  special, incidental, or consequential loss or damage
--  (including loss of data, profits, goodwill, or any type of
--  loss or damage suffered as a result of any action brought
--  by a third party) even if such damage or loss was
--  reasonably foreseeable or Xilinx had been advised of the
--  possibility of the same.
--
--  CRITICAL APPLICATIONS
--  Xilinx products are not designed or intended to be fail-
--  safe, or for use in any application requiring fail-safe
--  performance, such as life-support or safety devices or
--  systems, Class III medical devices, nuclear facilities,
--  applications related to the deployment of airbags, or any
--  other applications that could lead to death, personal
--  injury, or severe property or environmental damage
--  (individually and collectively, "Critical
--  Applications"). Customer assumes the sole risk and
--  liability of any use of Xilinx products in Critical
--  Applications, subject only to applicable laws and
--  regulations governing limitations on product liability.
--
--  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
--  PART OF THIS FILE AT ALL TIMES.
  --
  -- *************************************************************************
  --
  -------------------------------------------------------------------------------
  -- Filename:        kutu_datamover_cmd_status.vhd
  --
  -- Description:
  --    This file implements the DataMover Command and Status interfaces.
  --
  --
  --
  --
  -- VHDL-Standard:   VHDL'93
  -------------------------------------------------------------------------------
  -------------------------------------------------------------------------------
  library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

  library kutu_datamover_v5_1_9;
  Use kutu_datamover_v5_1_9.kutu_datamover_fifo;

  -------------------------------------------------------------------------------

  entity kutu_datamover_cmd_status is
    generic (
      C_CMD_WIDTH          : Integer                := 68;   -- Sets the width of the input command
      C_ENABLE_CACHE_USER  : Integer range 0 to 1   :=  0
   );
    port (

      -- Clock inputs ----------------------------------------------------
      primary_aclk           : in  std_logic;                           --
         -- Primary synchronization clock for the Master side           --
         -- interface and internal logic. It is also used               --
         -- for the User interface synchronization when                 --
         -- C_STSCMD_IS_ASYNC = 0.                                      --
                                                                        --
      secondary_awclk        : in  std_logic;                           --
         -- Clock used for the Command and Status User Interface        --
         --  when the User Command and Status interface is Async        --
         -- to the MMap interface. Async mode is set by the assigned    --
         -- value to C_STSCMD_IS_ASYNC = 1.                             --
      --------------------------------------------------------------------


      -- Reset inputs ----------------------------------------------------
      reset                   : in  std_logic;                           --


      -- User Command Stream Ports (AXI Stream) -------------------------------
      cmd_wvalid             : in  std_logic;                                --
      cmd_wready             : out std_logic;                                --
      cmd_wdata              : in  std_logic_vector(C_CMD_WIDTH-1 downto 0); --
      cache_data             : in  std_logic_vector(7 downto 0); --
      -------------------------------------------------------------------------

      -- Internal Command Out Interface -----------------------------------------------
      cmd2mstr_command       : Out std_logic_vector(C_CMD_WIDTH-1 downto 0);         --
         -- The next command value available from the Command FIFO/Register          --

      cache2mstr_command       : Out std_logic_vector(7 downto 0);         --
         -- The cache value available from the FIFO/Register          --

                                                                                     --
      mst2cmd_cmd_valid      : Out std_logic;                                        --
         -- Handshake bit indicating the Command FIFO/Register has at least 1 valid  --
         -- command entry                                                            --
                                                                                     --
      cmd2mstr_cmd_ready     : in  std_logic                                        --
         -- Handshake bit indicating the Command Calculator is ready to accept       --
         -- another command                                                          --
      ---------------------------------------------------------------------------------

      );

  end entity kutu_datamover_cmd_status;


architecture implementation of kutu_datamover_cmd_status is

   signal sig_cmd_fifo_wr_clk    : std_logic := '0';
   signal cmd_ready              : std_logic;
   signal valid                  : std_logic;
   signal new_ready              : std_logic;
   signal clear_valid_dly        : std_logic;

   signal sig_cmd_fifo_rd_clk    : std_logic := '0';
   signal valid_dly              : std_logic;
   signal new_valid              : std_logic;
   signal clear_valid            : std_logic;

begin --(architecture implementation)

   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: GEN_SYNC_RESET
   --
   -- If Generate Description:
   --  This IfGen assigns the clock and reset signals for the
   -- synchronous User interface case
   --

   sig_cmd_fifo_wr_clk   <=  secondary_awclk;
   sig_cmd_fifo_rd_clk   <=  primary_aclk;

   ------------------------------------------------------------
   -- Instance: I_CMD_FIFO
   --
   -- Description:
   -- Instance for the Command FIFO
   -- The User Interface is the Write Side
   -- The Internal Interface is the Read side
   --
   ------------------------------------------------------------

   cmd_wready <= cmd_ready;

   process (reset,sig_cmd_fifo_wr_clk)
   begin

      if reset = '1' then
         cmd2mstr_command  <= (others => '0');
         cmd_ready         <= '0';
         valid             <= '0';
         new_ready         <= '0';
         clear_valid_dly   <= '0';
      elsif rising_edge (sig_cmd_fifo_wr_clk) then
         if cmd_wvalid = '1' and cmd_ready = '1' then
            cmd2mstr_command <= cmd_wdata;
         end if;

         if cmd_wvalid = '1' and cmd_ready = '1' then
            valid <= '1';
         elsif clear_valid = '1' then
            valid <= '0';
         end if;

         if (cmd_wvalid = '1' and cmd_ready = '1') or new_ready = '0' then
            cmd_ready <= '0';
         elsif valid = '0' and new_ready = '1' then
            cmd_ready <= '1';
         end if;

         -- clock synchronise
         new_ready         <= cmd2mstr_cmd_ready;
         clear_valid_dly   <= clear_valid;

      end if;
   end process;

   mst2cmd_cmd_valid <= new_valid;

   process (reset,sig_cmd_fifo_rd_clk)
   begin

      if reset = '1' then
         valid_dly <= '0';
         new_valid <= '0';
         clear_valid  <= '0';
      elsif rising_edge (sig_cmd_fifo_rd_clk) then

         -- clock synchronise
         valid_dly <= valid;

         if (cmd2mstr_cmd_ready = '1' and new_valid = '1') or valid_dly = '0' then
            new_valid <= '0';
         elsif clear_valid = '0' and valid_dly = '1' then
            new_valid <= '1';
         end if;

         if cmd2mstr_cmd_ready = '1' and new_valid = '1' then
            clear_valid <= '1';
         elsif valid_dly = '0' then
            clear_valid  <= '0';
         end if;

      end if;
   end process;


   CACHE_ENABLE : if C_ENABLE_CACHE_USER = 1 generate
   begin

      process (reset,sig_cmd_fifo_wr_clk)
      begin

         if reset = '1' then
            cache2mstr_command <= (others => '0');
         elsif rising_edge (sig_cmd_fifo_wr_clk) then
            if cmd_wvalid = '1' and cmd_ready = '1' then
               cache2mstr_command <= cache_data;
            end if;
         end if;

      end process;

   end generate;


   CACHE_DISABLE : if C_ENABLE_CACHE_USER = 0 generate
   begin

      cache2mstr_command <= (others => '0');

   end generate CACHE_DISABLE;


end implementation;
