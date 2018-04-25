--------------------------------------------------------------
--
-- (C) Copyright Kutu Pty. Ltd. 2018.
--
-- file: hdmi_display_tb1.vhd
--
-- author: Greg Smart
--
--------------------------------------------------------------
--------------------------------------------------------------
--
-- This is the test bench for testing the hdmi_display module
--
--------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library ieee;
use ieee.std_logic_textio.all;
use std.textio.all;

library hdmi_display_v1_00_a;
use hdmi_display_v1_00_a.hdmi_display;
use hdmi_display_v1_00_a.test_pattern;

entity testbench is
end testbench;

architecture testbench_arch of testbench is

FILE RESULTS: TEXT OPEN WRITE_MODE IS "results.txt";


   constant tCK            : time   := 8000 ps;

   signal reset                : std_logic;
   signal clk125               : std_logic;

   -- AXI-Stream port from VDMA
   signal s_axis_mm2s_aresetn	: std_logic;
   signal s_axis_mm2s_aclk	   : std_logic;
   signal s_axis_mm2s_tready	: std_logic;
   signal s_axis_mm2s_tdata	: std_logic_vector(31 downto 0);
   signal s_axis_mm2s_tkeep	: std_logic_vector(3 downto 0);
   signal s_axis_mm2s_tlast	: std_logic;
   signal s_axis_mm2s_tvalid	: std_logic;

   -- VDMA Signals
   signal fsync               : std_logic;

   -- HDMI output
   signal HDMI_CLK_P          :  std_logic;
   signal HDMI_CLK_N          :  std_logic;
   signal HDMI_D2_P           :  std_logic;
   signal HDMI_D2_N           :  std_logic;
   signal HDMI_D1_P           :  std_logic;
   signal HDMI_D1_N           :  std_logic;
   signal HDMI_D0_P           :  std_logic;
   signal HDMI_D0_N           :  std_logic;

   -- debug signals
   signal debug_tmds_red      : std_logic_vector(9 downto 0);
   signal debug_tmds_green    : std_logic_vector(9 downto 0);
   signal debug_tmds_blue     : std_logic_vector(9 downto 0);
   signal debug_hcount        : std_logic_vector(11 downto 0);
   signal debug_vcount        : std_logic_vector(11 downto 0);
   signal debug_vga_active    : std_logic;
   signal debug_vga_running   : std_logic;
   signal debug_hsync         : std_logic;
   signal debug_vsync         : std_logic;
   signal debug_de            : std_logic;
   signal debug_red           : std_logic_vector(7 downto 0);
   signal debug_green         : std_logic_vector(7 downto 0);
   signal debug_blue          : std_logic_vector(7 downto 0);
   signal debug_c             : std_logic_vector(1 downto 0);
   signal debug_blank         : std_logic;

   signal test_blue           : std_logic_vector(7 downto 0);
   signal test_tmds_blue      : std_logic_vector(9 downto 0);

   signal errors              : integer;

begin


   UUT : entity hdmi_display_v1_00_a.hdmi_display
   generic map
   (
      -- Video frame parameters
      USR_HSIZE            => 192,
      USR_VSIZE            => 108,
      USR_HFRONT_PORCH     => 8,
      USR_HBACK_PORCH      => 14,
      USR_HPOLARITY        => 1,
      USR_HMAX             => 240,
      USR_VFRONT_PORCH     => 4,
      USR_VBACK_PORCH      => 8,
      USR_VPOLARITY        => 1,
      USR_VMAX             => 125,

      -- default colour
      USR_RED              => 85,
      USR_GREEN            => 255,
      USR_BLUE             => 1
   )
   port map
   (
      reset                => reset,
      clk125               => clk125,
      s_axis_mm2s_aresetn	=> s_axis_mm2s_aresetn,
      s_axis_mm2s_aclk	   => s_axis_mm2s_aclk,
      s_axis_mm2s_tready	=> s_axis_mm2s_tready,
      s_axis_mm2s_tdata	   => s_axis_mm2s_tdata,
      s_axis_mm2s_tkeep	   => s_axis_mm2s_tkeep,
      s_axis_mm2s_tlast	   => s_axis_mm2s_tlast,
      s_axis_mm2s_tvalid	=> s_axis_mm2s_tvalid,
      fsync                => fsync,
      HDMI_CLK_P           => HDMI_CLK_P,
      HDMI_CLK_N           => HDMI_CLK_N,
      HDMI_D2_P            => HDMI_D2_P,
      HDMI_D2_N            => HDMI_D2_N,
      HDMI_D1_P            => HDMI_D1_P,
      HDMI_D1_N            => HDMI_D1_N,
      HDMI_D0_P            => HDMI_D0_P,
      HDMI_D0_N            => HDMI_D0_N,

      debug_tmds_red       => debug_tmds_red,
      debug_tmds_green     => debug_tmds_green,
      debug_tmds_blue      => debug_tmds_blue,
      debug_hcount         => debug_hcount,
      debug_vcount         => debug_vcount,
      debug_vga_active     => debug_vga_active,
      debug_vga_running    => debug_vga_running,
      debug_hsync          => debug_hsync,
      debug_vsync          => debug_vsync,
      debug_de             => debug_de,
      debug_red            => debug_red,
      debug_green          => debug_green,
      debug_blue           => debug_blue
   );

   test_pattern_1 : entity hdmi_display_v1_00_a.test_pattern
   generic map
   (
         -- Video frame parameters
      USR_HSIZE            => 192,
      USR_VSIZE            => 108
   )
   port map
   (
      reset                => reset,
      fsync                => fsync,

         -- simulating AXI-Stream port from VDMA
      s_axis_mm2s_aresetn  => s_axis_mm2s_aresetn,
      s_axis_mm2s_aclk     => s_axis_mm2s_aclk,
      s_axis_mm2s_tready   => s_axis_mm2s_tready,
      s_axis_mm2s_tdata    => s_axis_mm2s_tdata,
      s_axis_mm2s_tkeep    => s_axis_mm2s_tkeep,
      s_axis_mm2s_tlast    => s_axis_mm2s_tlast,
      s_axis_mm2s_tvalid   => s_axis_mm2s_tvalid
   );

   debug_c     <= debug_vsync & debug_hsync;
   debug_blank <= not debug_de;

   process  -- process for clk
   begin
      loop
         clk125   <= '1';
         wait for tCK/2;
         clk125   <= '0';
         wait for tCK/2;
      end loop;
   end process;


   -- generate test data
   process (s_axis_mm2s_aclk)
   begin
      if rising_edge(s_axis_mm2s_aclk) then
         if reset = '1' then
            test_blue      <= X"00";
         else

            -- blue increments horizontally
            if debug_hsync = '1' or debug_vga_active = '0' then
               test_blue <= X"00";
            elsif debug_de = '1' then
               test_blue <= test_blue + 1;
            end if;
         end if;
      end if;
   end process;

   TMDS_encoder_blue: entity hdmi_display_v1_00_a.TMDS_encoder
   port map
   (
      reset    => reset,
      clk      => s_axis_mm2s_aclk,
      data     => test_blue,
      c        => debug_c,
      blank    => debug_blank,
      encoded  => test_tmds_blue
   );



   -- process for comparing output stream (blue only)
   process
   begin
      errors <= 0;

      wait for tCK;

      -- wait for pll lock
      while  debug_vga_running = '0' loop
         wait for tCK;
      end loop;

      -- wait until pipeline clears
      wait for 5*tCK;
      wait until s_axis_mm2s_aclk = '1';
      wait until s_axis_mm2s_aclk = '0';
      loop

         if debug_de = '1' then
            if test_blue /= debug_blue then
               errors <= errors + 1;
            end if;
         end if;

         if test_tmds_blue /= debug_tmds_blue then
            errors <= errors + 1;
         end if;

         wait until s_axis_mm2s_aclk = '1';
         wait until s_axis_mm2s_aclk = '0';

      end loop;
   end process;




   process  -- process for generating test
   variable tx_str   : String(1 to 4096);
   variable tx_loc   : LINE;

   begin

      reset <= '1';
      wait for 10 * tCK;
      reset <= '0';

      -- test over 3 frames
      wait until fsync = '1';
      wait until fsync = '0';
      wait until fsync = '1';
      wait until fsync = '0';
      wait until fsync = '1';
      wait until fsync = '0';


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
