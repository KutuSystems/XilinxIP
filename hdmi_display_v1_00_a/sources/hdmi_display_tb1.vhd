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


   constant tCK            : time   := 5000 ps;

   signal reset                : std_logic;
   signal clk200               : std_logic;

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
      USR_HPOLARITY        => 0,
      USR_HMAX             => 240,
      USR_VFRONT_PORCH     => 4,
      USR_VBACK_PORCH      => 8,
      USR_VPOLARITY        => 0,
      USR_VMAX             => 125,

      -- default colour
      USR_RED              => 85,
      USR_GREEN            => 255,
      USR_BLUE             => 0,

      -- PLLE2 parameters
      PLL_MULTIPLY         => 52,
      PLL_DIVIDE           => 7,
      CLK_DIVIDE           => 2
   )
   port map
   (
      reset                => reset,
      clk200               => clk200,
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


   process  -- process for clk
   begin
      loop
         clk200   <= '1';
         wait for tCK/2;
         clk200   <= '0';
         wait for tCK/2;
      end loop;
   end process;




   process  -- process for generating test
   variable tx_str   : String(1 to 4096);
   variable tx_loc   : LINE;

   begin
      errors <= 0;

      reset <= '1';
      wait for 10 * tCK;
      reset <= '0';

      wait for 10000 * tCK;

      wait;

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
