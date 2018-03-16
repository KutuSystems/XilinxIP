--------------------------------------------------------------
--
-- (C) Copyright Kutu Pty. Ltd. 2018.
--
-- file: sync_fifo.vhd
--
-- author: Greg Smart
--
--------------------------------------------------------------
--------------------------------------------------------------
--
-- This is an 512 element aynchronous fifo for a single clock
-- domain. It provides an external fifo empty and full signal.
-- It uses a single 36kbit block RAM and hw fifo control.
--
--------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;

-------------------------------------------------------------------------------

entity sync_fifo is
   generic (
      C_DWIDTH          : integer range 1 to 576         := 64;
      C_USER_WIDTH      : integer range 1 to 4           := 1;
      C_EMPTY           : bit_vector                     := X"0030"
  );
  port (
      reset             : in std_logic;
      clk               : in std_logic;

      -- input interface
      s_axis_tvalid     : in  std_logic;
      s_axis_tready     : out std_logic;
      s_axis_tdata      : in  std_logic_vector(C_DWIDTH-1 downto 0);
      s_axis_tlast      : in  std_logic;
      s_axis_tuser      : in  std_logic_vector(C_USER_WIDTH - 1 downto 0);

      -- output interface
      m_axis_tvalid     : out std_logic;
      m_axis_tready     : in  std_logic;
      m_axis_tdata      : out std_logic_vector(C_DWIDTH-1 downto 0);
      m_axis_tlast      : out std_logic;
      m_axis_tuser      : out  std_logic_vector(C_USER_WIDTH - 1 downto 0)
   );
end entity sync_fifo;

-----------------------------------------------------------------------------
-- Architecture section
-----------------------------------------------------------------------------

architecture RTL of sync_fifo is

   constant L_WIDTH        : integer := C_DWIDTH + C_USER_WIDTH + 1;

   signal datain_sig       : std_logic_vector(575 downto 0);
   signal dataout_sig      : std_logic_vector(575 downto 0);
   signal empty_sig        : std_logic;
   signal empty_reg        : std_logic;
   signal reset_reg        : std_logic;
   signal reset_r          : std_logic;
   signal wait_for_resetq  : std_logic;
   signal read_sig         : std_logic;
   signal write_sig        : std_logic;
   signal wr_inhibit       : std_logic;
   signal sig_block        : std_logic;
   signal block_dly        : std_logic_vector(7 downto 0);
   signal reset_count      : std_logic_vector(4 downto 0);

begin

   -- read control
   m_axis_tvalid  <= not empty_sig and not empty_reg;
   read_sig       <= m_axis_tready and not empty_sig and not empty_reg;

   -- write control
   s_axis_tready  <= not sig_block and not wr_inhibit;
   write_sig      <= s_axis_tvalid and not sig_block and not wr_inhibit;

   m_axis_tdata   <= dataout_sig(C_DWIDTH -1 downto 0);
   m_axis_tlast   <= dataout_sig(C_DWIDTH);
   m_axis_tuser   <= dataout_sig(L_WIDTH - 1 downto C_DWIDTH + 1);

   datain_sig(L_WIDTH-1 downto 0) <= s_axis_tuser & s_axis_tlast & s_axis_tdata;

   FIFO36E1_1 : FIFO36E1
   generic map (
      ALMOST_EMPTY_OFFSET        => C_EMPTY,
      ALMOST_FULL_OFFSET         => X"0020",
      DATA_WIDTH                 => 72,
      DO_REG                     => 1,
      EN_ECC_READ                => FALSE,
      EN_ECC_WRITE               => FALSE,
      EN_SYN                     => FALSE,
      FIFO_MODE                  => "FIFO36_72",
      FIRST_WORD_FALL_THROUGH    => TRUE,
      INIT                       => X"000000000000000000",
      SIM_DEVICE                 => "7SERIES",
      SRVAL                      => X"000000000000000000"
   )
   port map (
      DO             => dataout_sig(63 downto 0),
      DOP            => dataout_sig(71 downto 64),
      EMPTY          => empty_sig,
      ALMOSTEMPTY    => open,
      FULL           => open,
      ALMOSTFULL     => wr_inhibit,
      INJECTDBITERR  => '0',
      INJECTSBITERR  => '0',
      RDCLK          => clk,
      RDEN           => read_sig,
      REGCE          => read_sig,
      RST            => reset_r,
      RSTREG         => reset_r,
      WRCLK          => clk,
      WREN           => write_sig,
      DI             => datain_sig(63 downto 0),
      DIP            => datain_sig(71 downto 64)
   );


   FIFO36E1_128 : if (L_WIDTH > 72) generate
   begin
      FIFO36E1_2 : FIFO36E1
      generic map (
         ALMOST_EMPTY_OFFSET        => X"0008",
         ALMOST_FULL_OFFSET         => X"0080",
         DATA_WIDTH                 => 72,
         DO_REG                     => 1,
         EN_ECC_READ                => FALSE,
         EN_ECC_WRITE               => FALSE,
         EN_SYN                     => FALSE,
         FIFO_MODE                  => "FIFO36_72",
         FIRST_WORD_FALL_THROUGH    => TRUE,
         INIT                       => X"000000000000000000",
         SIM_DEVICE                 => "7SERIES",
         SRVAL                      => X"000000000000000000"
      )
      port map (
         DO             => dataout_sig(135 downto 72),
         DOP            => dataout_sig(143 downto 136),
         EMPTY          => open,
         ALMOSTEMPTY    => open,
         FULL           => open,
         ALMOSTFULL     => open,
         INJECTDBITERR  => '0',
         INJECTSBITERR  => '0',
         RDCLK          => clk,
         RDEN           => read_sig,
         REGCE          => read_sig,
         RST            => reset_r,
         RSTREG         => reset_r,
         WRCLK          => clk,
         WREN           => write_sig,
         DI             => datain_sig(135 downto 72),
         DIP            => datain_sig(143 downto 136)
      );
   end generate;

   FIFO36E1_216 : if (L_WIDTH > 144) generate
   begin
      FIFO36E1_3 : FIFO36E1
      generic map (
         ALMOST_EMPTY_OFFSET        => X"0008",
         ALMOST_FULL_OFFSET         => X"0080",
         DATA_WIDTH                 => 72,
         DO_REG                     => 1,
         EN_ECC_READ                => FALSE,
         EN_ECC_WRITE               => FALSE,
         EN_SYN                     => FALSE,
         FIFO_MODE                  => "FIFO36_72",
         FIRST_WORD_FALL_THROUGH    => TRUE,
         INIT                       => X"000000000000000000",
         SIM_DEVICE                 => "7SERIES",
         SRVAL                      => X"000000000000000000"
      )
      port map (
         DO             => dataout_sig(207 downto 144),
         DOP            => dataout_sig(215 downto 208),
         EMPTY          => open,
         ALMOSTEMPTY    => open,
         FULL           => open,
         ALMOSTFULL     => open,
         INJECTDBITERR  => '0',
         INJECTSBITERR  => '0',
         RDCLK          => clk,
         RDEN           => read_sig,
         REGCE          => read_sig,
         RST            => reset_r,
         RSTREG         => reset_r,
         WRCLK          => clk,
         WREN           => write_sig,
         DI             => datain_sig(207 downto 144),
         DIP            => datain_sig(215 downto 208)
      );
   end generate;


   FIFO36E1_288 : if (L_WIDTH > 216) generate
   begin
      FIFO36E1_4 : FIFO36E1
      generic map (
         ALMOST_EMPTY_OFFSET        => X"0008",
         ALMOST_FULL_OFFSET         => X"0080",
         DATA_WIDTH                 => 72,
         DO_REG                     => 1,
         EN_ECC_READ                => FALSE,
         EN_ECC_WRITE               => FALSE,
         EN_SYN                     => FALSE,
         FIFO_MODE                  => "FIFO36_72",
         FIRST_WORD_FALL_THROUGH    => TRUE,
         INIT                       => X"000000000000000000",
         SIM_DEVICE                 => "7SERIES",
         SRVAL                      => X"000000000000000000"
      )
      port map (
         DO             => dataout_sig(279 downto 216),
         DOP            => dataout_sig(287 downto 280),
         EMPTY          => open,
         ALMOSTEMPTY    => open,
         FULL           => open,
         ALMOSTFULL     => open,
         INJECTDBITERR  => '0',
         INJECTSBITERR  => '0',
         RDCLK          => clk,
         RDEN           => read_sig,
         REGCE          => read_sig,
         RST            => reset_r,
         RSTREG         => reset_r,
         WRCLK          => clk,
         WREN           => write_sig,
         DI             => datain_sig(279 downto 216),
         DIP            => datain_sig(287 downto 280)
      );

   end generate;

   FIFO36E1_360 : if (L_WIDTH > 288) generate
   begin
      FIFO36E1_4 : FIFO36E1
      generic map (
         ALMOST_EMPTY_OFFSET        => X"0008",
         ALMOST_FULL_OFFSET         => X"0080",
         DATA_WIDTH                 => 72,
         DO_REG                     => 1,
         EN_ECC_READ                => FALSE,
         EN_ECC_WRITE               => FALSE,
         EN_SYN                     => FALSE,
         FIFO_MODE                  => "FIFO36_72",
         FIRST_WORD_FALL_THROUGH    => TRUE,
         INIT                       => X"000000000000000000",
         SIM_DEVICE                 => "7SERIES",
         SRVAL                      => X"000000000000000000"
      )
      port map (
         DO             => dataout_sig(351 downto 288),
         DOP            => dataout_sig(359 downto 352),
         EMPTY          => open,
         ALMOSTEMPTY    => open,
         FULL           => open,
         ALMOSTFULL     => open,
         INJECTDBITERR  => '0',
         INJECTSBITERR  => '0',
         RDCLK          => clk,
         RDEN           => read_sig,
         REGCE          => read_sig,
         RST            => reset_r,
         RSTREG         => reset_r,
         WRCLK          => clk,
         WREN           => write_sig,
         DI             => datain_sig(351 downto 288),
         DIP            => datain_sig(359 downto 352)
      );
   end generate;

   FIFO36E1_432 : if (L_WIDTH > 360) generate
   begin
      FIFO36E1_5 : FIFO36E1
      generic map (
         ALMOST_EMPTY_OFFSET        => X"0008",
         ALMOST_FULL_OFFSET         => X"0080",
         DATA_WIDTH                 => 72,
         DO_REG                     => 1,
         EN_ECC_READ                => FALSE,
         EN_ECC_WRITE               => FALSE,
         EN_SYN                     => FALSE,
         FIFO_MODE                  => "FIFO36_72",
         FIRST_WORD_FALL_THROUGH    => TRUE,
         INIT                       => X"000000000000000000",
         SIM_DEVICE                 => "7SERIES",
         SRVAL                      => X"000000000000000000"
      )
      port map (
         DO             => dataout_sig(423 downto 360),
         DOP            => dataout_sig(431 downto 424),
         EMPTY          => open,
         ALMOSTEMPTY    => open,
         FULL           => open,
         ALMOSTFULL     => open,
         INJECTDBITERR  => '0',
         INJECTSBITERR  => '0',
         RDCLK          => clk,
         RDEN           => read_sig,
         REGCE          => read_sig,
         RST            => reset_r,
         RSTREG         => reset_r,
         WRCLK          => clk,
         WREN           => write_sig,
         DI             => datain_sig(423 downto 360),
         DIP            => datain_sig(431 downto 424)
      );
   end generate;

   FIFO36E1_504 : if (L_WIDTH > 432) generate
   begin
      FIFO36E1_6 : FIFO36E1
      generic map (
         ALMOST_EMPTY_OFFSET        => X"0008",
         ALMOST_FULL_OFFSET         => X"0080",
         DATA_WIDTH                 => 72,
         DO_REG                     => 1,
         EN_ECC_READ                => FALSE,
         EN_ECC_WRITE               => FALSE,
         EN_SYN                     => FALSE,
         FIFO_MODE                  => "FIFO36_72",
         FIRST_WORD_FALL_THROUGH    => TRUE,
         INIT                       => X"000000000000000000",
         SIM_DEVICE                 => "7SERIES",
         SRVAL                      => X"000000000000000000"
      )
      port map (
         DO             => dataout_sig(495 downto 432),
         DOP            => dataout_sig(503 downto 496),
         EMPTY          => open,
         ALMOSTEMPTY    => open,
         FULL           => open,
         ALMOSTFULL     => open,
         INJECTDBITERR  => '0',
         INJECTSBITERR  => '0',
         RDCLK          => clk,
         RDEN           => read_sig,
         REGCE          => read_sig,
         RST            => reset_r,
         RSTREG         => reset_r,
         WRCLK          => clk,
         WREN           => write_sig,
         DI             => datain_sig(495 downto 432),
         DIP            => datain_sig(503 downto 496)
      );
   end generate;

   FIFO36E1_576 : if (L_WIDTH > 504) generate
   begin
      FIFO36E1_7 : FIFO36E1
      generic map (
         ALMOST_EMPTY_OFFSET        => X"0008",
         ALMOST_FULL_OFFSET         => X"0080",
         DATA_WIDTH                 => 72,
         DO_REG                     => 1,
         EN_ECC_READ                => FALSE,
         EN_ECC_WRITE               => FALSE,
         EN_SYN                     => FALSE,
         FIFO_MODE                  => "FIFO36_72",
         FIRST_WORD_FALL_THROUGH    => TRUE,
         INIT                       => X"000000000000000000",
         SIM_DEVICE                 => "7SERIES",
         SRVAL                      => X"000000000000000000"
      )
      port map (
         DO             => dataout_sig(567 downto 504),
         DOP            => dataout_sig(575 downto 568),
         EMPTY          => open,
         ALMOSTEMPTY    => open,
         FULL           => open,
         ALMOSTFULL     => open,
         INJECTDBITERR  => '0',
         INJECTSBITERR  => '0',
         RDCLK          => clk,
         RDEN           => read_sig,
         REGCE          => read_sig,
         RST            => reset_r,
         RSTREG         => reset_r,
         WRCLK          => clk,
         WREN           => write_sig,
         DI             => datain_sig(567 downto 504),
         DIP            => datain_sig(575 downto 568)
      );
   end generate;

   process (clk) is
   begin
      if rising_edge(clk) then

         reset_reg <= reset;

         if reset_reg = '1' then
            reset_r     <= '1';
            reset_count <= "00000";
         else
            if reset_count(4) = '0' then
               reset_count <= reset_count + 1;
            end if;

            reset_r	<=	not reset_count(4);
         end if;
      end if;
   end process;

   process (clk)
   begin
      if rising_edge (clk) then

         if reset_r = '1' then
            sig_block   <= '1';
            block_dly   <= X"ff";
            empty_reg   <= '1';
         else
            block_dly(0)            <= '0';
            block_dly(7 downto 1)   <= block_dly(6 downto 0);
            sig_block               <= block_dly(7);
            empty_reg               <= empty_sig;

         end if;

      end if;
   end process;



end RTL;
