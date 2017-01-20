-------------------------------------------------------------------------------
-- kutu_datamover_sfifo_autord.vhd - entity/architecture pair

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
-- Filename:        kutu_datamover_sfifo_autord.vhd
-- Version:         initial
-- Description:
--    This file contains the logic to generate a CoreGen call to create a
-- synchronous FIFO as part of the synthesis process of XST. This eliminates
-- the need for multiple fixed netlists for various sizes and widths of FIFOs.
--
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;

-------------------------------------------------------------------------------

entity kutu_datamover_sfifo_autord is
  generic (
     C_DWIDTH                : integer := 32;
       -- Sets the width of the FIFO Data

     C_DEPTH                 : integer := 128;
       -- Sets the depth of the FIFO

     C_DATA_CNT_WIDTH        : integer := 8;
       -- Sets the width of the FIFO Data Count output

     C_NEED_ALMOST_EMPTY     : Integer range 0 to 1 := 0;
       -- Indicates the need for an almost empty flag from the internal FIFO

     C_NEED_ALMOST_FULL      : Integer range 0 to 1 := 0;
       -- Indicates the need for an almost full flag from the internal FIFO

     C_USE_BLKMEM            : Integer range 0 to 1 := 1;
       -- Sets the type of memory to use for the FIFO
       -- 0 = Distributed Logic
       -- 1 = Block Ram

     C_FAMILY                : String  := "virtex7"
       -- Specifies the target FPGA Family

    );
  port (

    -- FIFO Inputs ------------------------------------------------------------------
     SFIFO_Sinit             : In  std_logic;                                      --
     SFIFO_Clk               : In  std_logic;                                      --
     SFIFO_Wr_en             : In  std_logic;                                      --
     SFIFO_Din               : In  std_logic_vector(C_DWIDTH-1 downto 0);          --
     SFIFO_Rd_en             : In  std_logic;                                      --
     SFIFO_Clr_Rd_Data_Valid : In  std_logic;                                      --
     --------------------------------------------------------------------------------

    -- FIFO Outputs -----------------------------------------------------------------
     SFIFO_DValid            : Out std_logic;                                      --
     SFIFO_Dout              : Out std_logic_vector(C_DWIDTH-1 downto 0);          --
     SFIFO_Full              : Out std_logic;                                      --
     SFIFO_Empty             : Out std_logic;                                      --
     SFIFO_Almost_full       : Out std_logic;                                      --
     SFIFO_Almost_empty      : Out std_logic;                                      --
     SFIFO_Rd_count          : Out std_logic_vector(C_DATA_CNT_WIDTH-1 downto 0);  --
     SFIFO_Rd_count_minus1   : Out std_logic_vector(C_DATA_CNT_WIDTH-1 downto 0);  --
     SFIFO_Wr_count          : Out std_logic_vector(C_DATA_CNT_WIDTH-1 downto 0);  --
     SFIFO_Rd_ack            : Out std_logic                                       --
     --------------------------------------------------------------------------------

    );
end entity kutu_datamover_sfifo_autord;

-----------------------------------------------------------------------------
-- Architecture section
-----------------------------------------------------------------------------

architecture imp of kutu_datamover_sfifo_autord is
  attribute DowngradeIPIdentifiedWarnings: string;
  attribute DowngradeIPIdentifiedWarnings of imp : architecture is "yes";


-- Constant declarations

   -- none
   constant D_ARRAY_WIDTH           : integer := integer(C_DWIDTH/72) * 72 + 72;

-- Signal declarations

   signal raw_data_cnt_lil_end       : std_logic_vector(C_DATA_CNT_WIDTH-1 downto 0) := (others => '0');
   signal raw_data_count_int         : natural := 0;
   signal raw_data_count_corr        : std_logic_vector(C_DATA_CNT_WIDTH-1 downto 0) := (others => '0');
   signal raw_data_count_corr_minus1 : std_logic_vector(C_DATA_CNT_WIDTH-1 downto 0) := (others => '0');
   Signal corrected_empty            : std_logic := '0';
   Signal corrected_almost_empty     : std_logic := '0';
   Signal sig_SFIFO_empty            : std_logic := '0';

   -- backend fifo read ack sample and hold
   Signal sig_rddata_valid           : std_logic := '0';
   Signal hold_ff_q                  : std_logic := '0';
   Signal ored_ack_ff_reset          : std_logic := '0';
   Signal autoread                   : std_logic := '0';
   Signal sig_sfifo_rdack            : std_logic := '0';
   Signal fifo_read_enable           : std_logic := '0';

--   signal datain                     : std_logic_vector(D_ARRAY_WIDTH-1 downto 0);
--   signal dataout                    : std_logic_vector(D_ARRAY_WIDTH-1 downto 0);
   signal datain                     : std_logic_vector(575 downto 0);
   signal dataout                    : std_logic_vector(575 downto 0);
   signal empty_sig                  : std_logic;
   signal reset                      : std_logic;

begin


      -- Other port usages and assignments
      SFIFO_Rd_ack          <= sig_sfifo_rdack;

      SFIFO_Empty           <= empty_sig;

      SFIFO_Wr_count        <= raw_data_cnt_lil_end;

      SFIFO_Rd_count        <= raw_data_count_corr;

      SFIFO_Rd_count_minus1 <= raw_data_count_corr_minus1;




         SFIFO_Dout                    <= dataout(C_DWIDTH -1 downto 0);
         SFIFO_DValid                  <= not empty_sig;

         reset                         <= SFIFO_Sinit or SFIFO_Clr_Rd_Data_Valid;
         datain(C_DWIDTH-1 downto 0)   <= SFIFO_Din;

         FIFO36E1_1 : FIFO36E1
         generic map (
            ALMOST_EMPTY_OFFSET        => X"0008",                -- Sets the almost empty threshold
            ALMOST_FULL_OFFSET         => X"0080",                -- Sets almost full threshold
            DATA_WIDTH                 => 72,                     -- Sets data width to 4-72
            DO_REG                     => 1,                      -- Enable output register (1-0) Must be 1 if EN_SYN = FALSE
            EN_ECC_READ                => FALSE,                  -- Enable ECC decoder, FALSE, TRUE
            EN_ECC_WRITE               => FALSE,                  -- Enable ECC encoder, FALSE, TRUE
            EN_SYN                     => FALSE,                   -- Specifies FIFO as Asynchronous (FALSE) or Synchronous (TRUE)
            FIFO_MODE                  => "FIFO36_72",            -- Sets mode to "FIFO36" or "FIFO36_72"
            FIRST_WORD_FALL_THROUGH    => TRUE,                   -- Sets the FIFO FWFT to FALSE, TRUE
            INIT                       => X"000000000000000000",  -- Initial values on output port
            SIM_DEVICE                 => "7SERIES",              -- Must be set to "7SERIES" for simulation behavior
            SRVAL                      => X"000000000000000000"   -- Set/Reset value for output port
         )
         port map (
            DO             => dataout(63 downto 0),             -- 64-bit output: Data output
            DOP            => dataout(71 downto 64),             -- 8-bit output: parity output
            EMPTY          => empty_sig,           -- 1-bit output: Empty flag
            ALMOSTEMPTY    => SFIFO_Almost_empty,
            FULL           => SFIFO_Full,          -- 1-bit output: Full flag
            ALMOSTFULL     => SFIFO_Almost_full,   -- 1-bit output: Full flag
            INJECTDBITERR  => '0',                 -- 1-bit input: Inject a double bit error input
            INJECTSBITERR  => '0',
            RDCLK          => SFIFO_Clk,           -- 1-bit input: Read clock
            RDEN           => SFIFO_Rd_en,         -- 1-bit input: Read enable
            REGCE          => SFIFO_Rd_en,         -- 1-bit input: Clock enable
            RST            => reset,               -- 1-bit input: Reset
            RSTREG         => reset,               -- 1-bit input: Output register set/reset
            WRCLK          => SFIFO_Clk,           -- 1-bit input: Rising edge write clock.
            WREN           => SFIFO_Wr_en,         -- 1-bit input: Write enable
            DI             => datain(63 downto 0), -- 64-bit input: Data input
            DIP            => datain(71 downto 64)  -- 8-bit input: Parity input
         );


         FIFO36E1_128 : if (C_DWIDTH > 72) generate

         begin
            FIFO36E1_2 : FIFO36E1
            generic map (
               ALMOST_EMPTY_OFFSET        => X"0008",                -- Sets the almost empty threshold
               ALMOST_FULL_OFFSET         => X"0080",                -- Sets almost full threshold
               DATA_WIDTH                 => 72,                     -- Sets data width to 4-72
               DO_REG                     => 1,                      -- Enable output register (1-0) Must be 1 if EN_SYN = FALSE
               EN_ECC_READ                => FALSE,                  -- Enable ECC decoder, FALSE, TRUE
               EN_ECC_WRITE               => FALSE,                  -- Enable ECC encoder, FALSE, TRUE
               EN_SYN                     => FALSE,                   -- Specifies FIFO as Asynchronous (FALSE) or Synchronous (TRUE)
               FIFO_MODE                  => "FIFO36_72",            -- Sets mode to "FIFO36" or "FIFO36_72"
               FIRST_WORD_FALL_THROUGH    => TRUE,                   -- Sets the FIFO FWFT to FALSE, TRUE
               INIT                       => X"000000000000000000",  -- Initial values on output port
               SIM_DEVICE                 => "7SERIES",              -- Must be set to "7SERIES" for simulation behavior
               SRVAL                      => X"000000000000000000"   -- Set/Reset value for output port
            )
            port map (
               DO             => dataout(135 downto 72),             -- 64-bit output: Data output
               DOP            => dataout(143 downto 136),             -- 8-bit output: parity output
               EMPTY          => open,           -- 1-bit output: Empty flag
               ALMOSTEMPTY    => open,
               FULL           => open,          -- 1-bit output: Full flag
               ALMOSTFULL     => open,   -- 1-bit output: Full flag
               INJECTDBITERR  => '0',                 -- 1-bit input: Inject a double bit error input
               INJECTSBITERR  => '0',
               RDCLK          => SFIFO_Clk,           -- 1-bit input: Read clock
               RDEN           => SFIFO_Rd_en,         -- 1-bit input: Read enable
               REGCE          => SFIFO_Rd_en,         -- 1-bit input: Clock enable
               RST            => reset,               -- 1-bit input: Reset
               RSTREG         => reset,               -- 1-bit input: Output register set/reset
               WRCLK          => SFIFO_Clk,           -- 1-bit input: Rising edge write clock.
               WREN           => SFIFO_Wr_en,         -- 1-bit input: Write enable
               DI             => datain(135 downto 72), -- 64-bit input: Data input
               DIP            => datain(143 downto 136)  -- 8-bit input: Parity input
            );
         end generate;

         FIFO36E1_216 : if (C_DWIDTH > 144) generate

         begin
            FIFO36E1_3 : FIFO36E1
            generic map (
               ALMOST_EMPTY_OFFSET        => X"0008",                -- Sets the almost empty threshold
               ALMOST_FULL_OFFSET         => X"0080",                -- Sets almost full threshold
               DATA_WIDTH                 => 72,                     -- Sets data width to 4-72
               DO_REG                     => 1,                      -- Enable output register (1-0) Must be 1 if EN_SYN = FALSE
               EN_ECC_READ                => FALSE,                  -- Enable ECC decoder, FALSE, TRUE
               EN_ECC_WRITE               => FALSE,                  -- Enable ECC encoder, FALSE, TRUE
               EN_SYN                     => FALSE,                   -- Specifies FIFO as Asynchronous (FALSE) or Synchronous (TRUE)
               FIFO_MODE                  => "FIFO36_72",            -- Sets mode to "FIFO36" or "FIFO36_72"
               FIRST_WORD_FALL_THROUGH    => TRUE,                   -- Sets the FIFO FWFT to FALSE, TRUE
               INIT                       => X"000000000000000000",  -- Initial values on output port
               SIM_DEVICE                 => "7SERIES",              -- Must be set to "7SERIES" for simulation behavior
               SRVAL                      => X"000000000000000000"   -- Set/Reset value for output port
            )
            port map (
               DO             => dataout(207 downto 144),             -- 64-bit output: Data output
               DOP            => dataout(215 downto 208),             -- 8-bit output: parity output
               EMPTY          => open,           -- 1-bit output: Empty flag
               ALMOSTEMPTY    => open,
               FULL           => open,          -- 1-bit output: Full flag
               ALMOSTFULL     => open,   -- 1-bit output: Full flag
               INJECTDBITERR  => '0',                 -- 1-bit input: Inject a double bit error input
               INJECTSBITERR  => '0',
               RDCLK          => SFIFO_Clk,           -- 1-bit input: Read clock
               RDEN           => SFIFO_Rd_en,         -- 1-bit input: Read enable
               REGCE          => SFIFO_Rd_en,         -- 1-bit input: Clock enable
               RST            => reset,               -- 1-bit input: Reset
               RSTREG         => reset,               -- 1-bit input: Output register set/reset
               WRCLK          => SFIFO_Clk,           -- 1-bit input: Rising edge write clock.
               WREN           => SFIFO_Wr_en,         -- 1-bit input: Write enable
               DI             => datain(207 downto 144), -- 64-bit input: Data input
               DIP            => datain(215 downto 208)  -- 8-bit input: Parity input
            );
          end generate;


         FIFO36E1_288 : if (C_DWIDTH > 216) generate

         begin
               FIFO36E1_4 : FIFO36E1
            generic map (
               ALMOST_EMPTY_OFFSET        => X"0008",                -- Sets the almost empty threshold
               ALMOST_FULL_OFFSET         => X"0080",                -- Sets almost full threshold
               DATA_WIDTH                 => 72,                     -- Sets data width to 4-72
               DO_REG                     => 1,                      -- Enable output register (1-0) Must be 1 if EN_SYN = FALSE
               EN_ECC_READ                => FALSE,                  -- Enable ECC decoder, FALSE, TRUE
               EN_ECC_WRITE               => FALSE,                  -- Enable ECC encoder, FALSE, TRUE
               EN_SYN                     => FALSE,                   -- Specifies FIFO as Asynchronous (FALSE) or Synchronous (TRUE)
               FIFO_MODE                  => "FIFO36_72",            -- Sets mode to "FIFO36" or "FIFO36_72"
               FIRST_WORD_FALL_THROUGH    => TRUE,                   -- Sets the FIFO FWFT to FALSE, TRUE
               INIT                       => X"000000000000000000",  -- Initial values on output port
               SIM_DEVICE                 => "7SERIES",              -- Must be set to "7SERIES" for simulation behavior
               SRVAL                      => X"000000000000000000"   -- Set/Reset value for output port
            )
            port map (
               DO             => dataout(279 downto 216),             -- 64-bit output: Data output
               DOP            => dataout(287 downto 280),             -- 8-bit output: parity output
               EMPTY          => open,           -- 1-bit output: Empty flag
               ALMOSTEMPTY    => open,
               FULL           => open,          -- 1-bit output: Full flag
               ALMOSTFULL     => open,   -- 1-bit output: Full flag
               INJECTDBITERR  => '0',                 -- 1-bit input: Inject a double bit error input
               INJECTSBITERR  => '0',
               RDCLK          => SFIFO_Clk,           -- 1-bit input: Read clock
               RDEN           => SFIFO_Rd_en,         -- 1-bit input: Read enable
               REGCE          => SFIFO_Rd_en,         -- 1-bit input: Clock enable
               RST            => reset,               -- 1-bit input: Reset
               RSTREG         => reset,               -- 1-bit input: Output register set/reset
               WRCLK          => SFIFO_Clk,           -- 1-bit input: Rising edge write clock.
               WREN           => SFIFO_Wr_en,         -- 1-bit input: Write enable
               DI             => datain(279 downto 216), -- 64-bit input: Data input
               DIP            => datain(287 downto 280)  -- 8-bit input: Parity input
            );

         end generate;

         FIFO36E1_360 : if (C_DWIDTH > 288) generate

         begin
            FIFO36E1_4 : FIFO36E1
            generic map (
               ALMOST_EMPTY_OFFSET        => X"0008",                -- Sets the almost empty threshold
               ALMOST_FULL_OFFSET         => X"0080",                -- Sets almost full threshold
               DATA_WIDTH                 => 72,                     -- Sets data width to 4-72
               DO_REG                     => 1,                      -- Enable output register (1-0) Must be 1 if EN_SYN = FALSE
               EN_ECC_READ                => FALSE,                  -- Enable ECC decoder, FALSE, TRUE
               EN_ECC_WRITE               => FALSE,                  -- Enable ECC encoder, FALSE, TRUE
               EN_SYN                     => FALSE,                   -- Specifies FIFO as Asynchronous (FALSE) or Synchronous (TRUE)
               FIFO_MODE                  => "FIFO36_72",            -- Sets mode to "FIFO36" or "FIFO36_72"
               FIRST_WORD_FALL_THROUGH    => TRUE,                   -- Sets the FIFO FWFT to FALSE, TRUE
               INIT                       => X"000000000000000000",  -- Initial values on output port
               SIM_DEVICE                 => "7SERIES",              -- Must be set to "7SERIES" for simulation behavior
               SRVAL                      => X"000000000000000000"   -- Set/Reset value for output port
            )
            port map (
               DO             => dataout(351 downto 288),             -- 64-bit output: Data output
               DOP            => dataout(359 downto 352),             -- 8-bit output: parity output
               EMPTY          => open,           -- 1-bit output: Empty flag
               ALMOSTEMPTY    => open,
               FULL           => open,          -- 1-bit output: Full flag
               ALMOSTFULL     => open,   -- 1-bit output: Full flag
               INJECTDBITERR  => '0',                 -- 1-bit input: Inject a double bit error input
               INJECTSBITERR  => '0',
               RDCLK          => SFIFO_Clk,           -- 1-bit input: Read clock
               RDEN           => SFIFO_Rd_en,         -- 1-bit input: Read enable
               REGCE          => SFIFO_Rd_en,         -- 1-bit input: Clock enable
               RST            => reset,               -- 1-bit input: Reset
               RSTREG         => reset,               -- 1-bit input: Output register set/reset
               WRCLK          => SFIFO_Clk,           -- 1-bit input: Rising edge write clock.
               WREN           => SFIFO_Wr_en,         -- 1-bit input: Write enable
               DI             => datain(351 downto 288), -- 64-bit input: Data input
               DIP            => datain(359 downto 352)  -- 8-bit input: Parity input
            );
         end generate;

         FIFO36E1_432 : if (C_DWIDTH > 360) generate

         begin

            FIFO36E1_5 : FIFO36E1
            generic map (
               ALMOST_EMPTY_OFFSET        => X"0008",                -- Sets the almost empty threshold
               ALMOST_FULL_OFFSET         => X"0080",                -- Sets almost full threshold
               DATA_WIDTH                 => 72,                     -- Sets data width to 4-72
               DO_REG                     => 1,                      -- Enable output register (1-0) Must be 1 if EN_SYN = FALSE
               EN_ECC_READ                => FALSE,                  -- Enable ECC decoder, FALSE, TRUE
               EN_ECC_WRITE               => FALSE,                  -- Enable ECC encoder, FALSE, TRUE
               EN_SYN                     => FALSE,                   -- Specifies FIFO as Asynchronous (FALSE) or Synchronous (TRUE)
               FIFO_MODE                  => "FIFO36_72",            -- Sets mode to "FIFO36" or "FIFO36_72"
               FIRST_WORD_FALL_THROUGH    => TRUE,                   -- Sets the FIFO FWFT to FALSE, TRUE
               INIT                       => X"000000000000000000",  -- Initial values on output port
               SIM_DEVICE                 => "7SERIES",              -- Must be set to "7SERIES" for simulation behavior
               SRVAL                      => X"000000000000000000"   -- Set/Reset value for output port
            )
            port map (
               DO             => dataout(423 downto 360),             -- 64-bit output: Data output
               DOP            => dataout(431 downto 424),             -- 8-bit output: parity output
               EMPTY          => open,           -- 1-bit output: Empty flag
               ALMOSTEMPTY    => open,
               FULL           => open,          -- 1-bit output: Full flag
               ALMOSTFULL     => open,   -- 1-bit output: Full flag
               INJECTDBITERR  => '0',                 -- 1-bit input: Inject a double bit error input
               INJECTSBITERR  => '0',
               RDCLK          => SFIFO_Clk,           -- 1-bit input: Read clock
               RDEN           => SFIFO_Rd_en,         -- 1-bit input: Read enable
               REGCE          => SFIFO_Rd_en,         -- 1-bit input: Clock enable
               RST            => reset,               -- 1-bit input: Reset
               RSTREG         => reset,               -- 1-bit input: Output register set/reset
               WRCLK          => SFIFO_Clk,           -- 1-bit input: Rising edge write clock.
               WREN           => SFIFO_Wr_en,         -- 1-bit input: Write enable
               DI             => datain(423 downto 360), -- 64-bit input: Data input
               DIP            => datain(431 downto 424)  -- 8-bit input: Parity input
            );
         end generate;

         FIFO36E1_504 : if (C_DWIDTH > 432) generate

         begin

            FIFO36E1_6 : FIFO36E1
            generic map (
               ALMOST_EMPTY_OFFSET        => X"0008",                -- Sets the almost empty threshold
               ALMOST_FULL_OFFSET         => X"0080",                -- Sets almost full threshold
               DATA_WIDTH                 => 72,                     -- Sets data width to 4-72
               DO_REG                     => 1,                      -- Enable output register (1-0) Must be 1 if EN_SYN = FALSE
               EN_ECC_READ                => FALSE,                  -- Enable ECC decoder, FALSE, TRUE
               EN_ECC_WRITE               => FALSE,                  -- Enable ECC encoder, FALSE, TRUE
               EN_SYN                     => FALSE,                   -- Specifies FIFO as Asynchronous (FALSE) or Synchronous (TRUE)
               FIFO_MODE                  => "FIFO36_72",            -- Sets mode to "FIFO36" or "FIFO36_72"
               FIRST_WORD_FALL_THROUGH    => TRUE,                   -- Sets the FIFO FWFT to FALSE, TRUE
               INIT                       => X"000000000000000000",  -- Initial values on output port
               SIM_DEVICE                 => "7SERIES",              -- Must be set to "7SERIES" for simulation behavior
               SRVAL                      => X"000000000000000000"   -- Set/Reset value for output port
            )
            port map (
               DO             => dataout(495 downto 432),             -- 64-bit output: Data output
               DOP            => dataout(503 downto 496),             -- 8-bit output: parity output
               EMPTY          => open,           -- 1-bit output: Empty flag
               ALMOSTEMPTY    => open,
               FULL           => open,          -- 1-bit output: Full flag
               ALMOSTFULL     => open,   -- 1-bit output: Full flag
               INJECTDBITERR  => '0',                 -- 1-bit input: Inject a double bit error input
               INJECTSBITERR  => '0',
               RDCLK          => SFIFO_Clk,           -- 1-bit input: Read clock
               RDEN           => SFIFO_Rd_en,         -- 1-bit input: Read enable
               REGCE          => SFIFO_Rd_en,         -- 1-bit input: Clock enable
               RST            => reset,               -- 1-bit input: Reset
               RSTREG         => reset,               -- 1-bit input: Output register set/reset
               WRCLK          => SFIFO_Clk,           -- 1-bit input: Rising edge write clock.
               WREN           => SFIFO_Wr_en,         -- 1-bit input: Write enable
               DI             => datain(495 downto 432), -- 64-bit input: Data input
               DIP            => datain(503 downto 496)  -- 8-bit input: Parity input
            );
         end generate;

         FIFO36E1_576 : if (C_DWIDTH > 504) generate

         begin

            FIFO36E1_7 : FIFO36E1
            generic map (
               ALMOST_EMPTY_OFFSET        => X"0008",                -- Sets the almost empty threshold
               ALMOST_FULL_OFFSET         => X"0080",                -- Sets almost full threshold
               DATA_WIDTH                 => 72,                     -- Sets data width to 4-72
               DO_REG                     => 1,                      -- Enable output register (1-0) Must be 1 if EN_SYN = FALSE
               EN_ECC_READ                => FALSE,                  -- Enable ECC decoder, FALSE, TRUE
               EN_ECC_WRITE               => FALSE,                  -- Enable ECC encoder, FALSE, TRUE
               EN_SYN                     => FALSE,                   -- Specifies FIFO as Asynchronous (FALSE) or Synchronous (TRUE)
               FIFO_MODE                  => "FIFO36_72",            -- Sets mode to "FIFO36" or "FIFO36_72"
               FIRST_WORD_FALL_THROUGH    => TRUE,                   -- Sets the FIFO FWFT to FALSE, TRUE
               INIT                       => X"000000000000000000",  -- Initial values on output port
               SIM_DEVICE                 => "7SERIES",              -- Must be set to "7SERIES" for simulation behavior
               SRVAL                      => X"000000000000000000"   -- Set/Reset value for output port
            )
            port map (
               DO             => dataout(567 downto 504),             -- 64-bit output: Data output
               DOP            => dataout(575 downto 568),             -- 8-bit output: parity output
               EMPTY          => open,           -- 1-bit output: Empty flag
               ALMOSTEMPTY    => open,
               FULL           => open,          -- 1-bit output: Full flag
               ALMOSTFULL     => open,   -- 1-bit output: Full flag
               INJECTDBITERR  => '0',                 -- 1-bit input: Inject a double bit error input
               INJECTSBITERR  => '0',
               RDCLK          => SFIFO_Clk,           -- 1-bit input: Read clock
               RDEN           => SFIFO_Rd_en,         -- 1-bit input: Read enable
               REGCE          => SFIFO_Rd_en,         -- 1-bit input: Clock enable
               RST            => reset,               -- 1-bit input: Reset
               RSTREG         => reset,               -- 1-bit input: Output register set/reset
               WRCLK          => SFIFO_Clk,           -- 1-bit input: Rising edge write clock.
               WREN           => SFIFO_Wr_en,         -- 1-bit input: Write enable
               DI             => datain(567 downto 504), -- 64-bit input: Data input
               DIP            => datain(575 downto 568)  -- 8-bit input: Parity input
            );

          end generate;







   -------------------------------------------------------------------------------






   -------------------------------------------------------------------------------
   -- Read Ack assert & hold logic Needed because....
   -------------------------------------------------------------------------------
   --     1) The CoreGen Sync FIFO has to be read once to get valid
   --        data to the read data port.
   --     2) The Read ack from the fifo is only asserted for 1 clock.
   --     3) A signal is needed that indicates valid data is at the read
   --        port of the FIFO and has not yet been used. This signal needs
   --        to be held until the next read operation occurs or a clear
   --        signal is received.


    ored_ack_ff_reset  <=  fifo_read_enable or
                           SFIFO_Sinit or
                           SFIFO_Clr_Rd_Data_Valid;

    sig_rddata_valid   <=  hold_ff_q or
                           sig_sfifo_rdack;




    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: IMP_ACK_HOLD_FLOP
    --
    -- Process Description:
    --  Flop for registering the hold flag
    --
    -------------------------------------------------------------
    IMP_ACK_HOLD_FLOP : process (SFIFO_Clk)
       begin
         if (SFIFO_Clk'event and SFIFO_Clk = '1') then
           if (ored_ack_ff_reset = '1') then
             hold_ff_q  <= '0';
           else
             hold_ff_q  <= sig_rddata_valid;
           end if;
         end if;
       end process IMP_ACK_HOLD_FLOP;



    -- generate auto-read enable. This keeps fresh data at the output
    -- of the FIFO whenever it is available.
    autoread <= '1'                     -- create a read strobe when the
      when (sig_rddata_valid = '0' and  -- output data is NOT valid
            sig_SFIFO_empty = '0')      -- and the FIFO is not empty
      Else '0';


    raw_data_count_int <=  CONV_INTEGER(raw_data_cnt_lil_end);





end imp;
