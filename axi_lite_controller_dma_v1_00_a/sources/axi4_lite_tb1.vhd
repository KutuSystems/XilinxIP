--------------------------------------------------------------
--
-- (C) Copyright Kutu Pty. Ltd. 2014.
--
-- file: axi4_lite_tb1.vhd
--
-- author: Greg Smart
--
--------------------------------------------------------------
--------------------------------------------------------------
--
-- This is a simple test bench for testing the the axi4 interface
--
--------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.axi_sim_pkg.all;

library ieee;
use ieee.std_logic_textio.all;
use std.textio.all;

entity testbench is
end testbench;

architecture testbench_arch of testbench is

FILE RESULTS: TEXT OPEN WRITE_MODE IS "results.txt";

   component axi4_lite_controller
   generic (
      C_S_AXI_DATA_WIDTH   : integer  range 32 to 32       := 32;
      C_S_AXI_ADDR_WIDTH   : integer  range 32 to 32       := 32;
      C_SYS_ADDR_WIDTH     : integer  range 8 to 24        := 13;
      C_S_AXI_MIN_SIZE     : std_logic_vector(31 downto 0) := X"00001FFF";
      C_USE_WSTRB          : integer := 0;
      C_DPHASE_TIMEOUT     : integer range 0 to 512        := 8;
      C_BASEADDR           : std_logic_vector              := X"7000_0000";
      C_HIGHADDR           : std_logic_vector              := X"7000_FFFF"
   );
   port (
      -- AXI bus signals
      S_AXI_LITE_ACLK      : in  std_logic;
      S_AXI_LITE_ARESETN   : in  std_logic;
      S_AXI_LITE_AWADDR    : in  std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto 0);
      S_AXI_LITE_AWVALID   : in  std_logic;
      S_AXI_LITE_AWREADY   : out std_logic;
      S_AXI_LITE_WDATA     : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      S_AXI_LITE_WSTRB     : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
      S_AXI_LITE_WVALID    : in  std_logic;
      S_AXI_LITE_WREADY    : out std_logic;
      S_AXI_LITE_BRESP     : out std_logic_vector(1 downto 0);
      S_AXI_LITE_BVALID    : out std_logic;
      S_AXI_LITE_BREADY    : in  std_logic;
      S_AXI_LITE_ARADDR    : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      S_AXI_LITE_ARVALID   : in  std_logic;
      S_AXI_LITE_ARREADY   : out std_logic;
      S_AXI_LITE_RDATA     : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      S_AXI_LITE_RRESP     : out std_logic_vector(1 downto 0);
      S_AXI_LITE_RVALID    : out std_logic;
      S_AXI_LITE_RREADY    : in  std_logic;

      -- write interface to system
      sys_clk              : out std_logic;                                         -- system clk (same as AXI clock
      sys_wraddr           : out std_logic_vector(C_SYS_ADDR_WIDTH-1 downto 2);   -- address for reads/writes
      sys_wrdata           : out std_logic_vector(31 downto 0);                     -- data/no. bytes
      sys_wr_cmd           : out std_logic;                                         -- write strobe

      sys_rdaddr           : out std_logic_vector(C_SYS_ADDR_WIDTH-1 downto 2);   -- address for reads/writes
      sys_rddata           : in std_logic_vector(31 downto 0);                      -- input data port for read operation
      sys_rd_cmd           : out std_logic;                                         -- read strobe
      sys_rd_endcmd        : in std_logic                                           -- input read strobe
   );
   end component;

   component axi4_lite_test
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
   end component;

   constant tCK            : time   := 10000 ps;
--   constant ref_tCK        : time   := 7100 ps;

   constant C_S_AXI_DATA_WIDTH    : integer := 32;
   constant C_S_AXI_ADDR_WIDTH    : integer := 32;
   constant C_SYS_ADDR_WIDTH      : integer := 13;

--   signal ref_clk          : std_logic;
--   signal clk              : std_logic;
   signal S_AXI_ACLK       : std_logic;
   signal S_AXI_ARESETN    : std_logic;
   signal S_AXI_AWADDR     : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
   signal S_AXI_AWVALID    : std_logic;
   signal S_AXI_WDATA      : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
   signal S_AXI_WSTRB      : std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
   signal S_AXI_WVALID     : std_logic;
   signal S_AXI_BREADY     : std_logic;
   signal S_AXI_ARADDR     : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
   signal S_AXI_ARVALID    : std_logic;
   signal S_AXI_RREADY     : std_logic;
   signal S_AXI_ARREADY    : std_logic;
   signal S_AXI_RDATA      : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
   signal S_AXI_RRESP      : std_logic_vector(1 downto 0);
   signal S_AXI_RVALID     : std_logic;
   signal S_AXI_WREADY     : std_logic;
   signal S_AXI_BRESP      : std_logic_vector(1 downto 0);
   signal S_AXI_BVALID     : std_logic;
   signal S_AXI_AWREADY    : std_logic;
 
   signal sys_clk          : std_logic;                                         -- system clk (same as AXI clock
   signal sys_wraddr       : std_logic_vector(C_SYS_ADDR_WIDTH-1 downto 2);      -- address for reads/writes
   signal sys_wrdata       : std_logic_vector(31 downto 0);                     -- data/no. bytes
   signal sys_wr_cmd       : std_logic;                                         -- write strobe

   signal sys_rdaddr       : std_logic_vector(C_SYS_ADDR_WIDTH-1 downto 2);      -- address for reads/writes
   signal sys_rddata       : std_logic_vector(31 downto 0);                      -- input data port for read operation
   signal sys_rd_cmd       : std_logic;                                          -- read strobe
   signal sys_rd_endcmd    : std_logic;                                           -- input read strobe

   signal read_data        : std_logic_vector(31 downto 0); 
   signal data_active      : std_logic;
   
   signal gpio_led         : std_logic_vector(3 downto 0); 

   signal errors           : integer;

begin
   
   UUT:axi4_lite_controller
   generic map
   (
      C_S_AXI_DATA_WIDTH   => C_S_AXI_DATA_WIDTH,
      C_S_AXI_ADDR_WIDTH   => C_S_AXI_ADDR_WIDTH,
      C_SYS_ADDR_WIDTH     => C_SYS_ADDR_WIDTH,
      C_S_AXI_MIN_SIZE     => X"00001FFF",
      C_USE_WSTRB          => 0,
      C_DPHASE_TIMEOUT     => 8,
      C_BASEADDR           => X"70000000",
      C_HIGHADDR           => X"7000FFFF"
   )
   port map
   (
      S_AXI_LITE_ACLK      => S_AXI_ACLK,
      S_AXI_LITE_ARESETN   => S_AXI_ARESETN,
      S_AXI_LITE_AWADDR    => S_AXI_AWADDR,
      S_AXI_LITE_AWVALID   => S_AXI_AWVALID,
      S_AXI_LITE_AWREADY   => S_AXI_AWREADY,
      S_AXI_LITE_WDATA     => S_AXI_WDATA,
      S_AXI_LITE_WSTRB     => S_AXI_WSTRB,
      S_AXI_LITE_WVALID    => S_AXI_WVALID,
      S_AXI_LITE_WREADY    => S_AXI_WREADY,
      S_AXI_LITE_BRESP     => S_AXI_BRESP,
      S_AXI_LITE_BVALID    => S_AXI_BVALID,
      S_AXI_LITE_BREADY    => S_AXI_BREADY,
      S_AXI_LITE_ARADDR    => S_AXI_ARADDR,
      S_AXI_LITE_ARVALID   => S_AXI_ARVALID,
      S_AXI_LITE_ARREADY   => S_AXI_ARREADY,
      S_AXI_LITE_RDATA     => S_AXI_RDATA,
      S_AXI_LITE_RRESP     => S_AXI_RRESP,
      S_AXI_LITE_RVALID    => S_AXI_RVALID,
      S_AXI_LITE_RREADY    => S_AXI_RREADY,

      -- write interface to system
      sys_clk              => sys_clk,             -- system clk (same as AXI clock
      sys_wraddr           => sys_wraddr,          -- address for reads/writes
      sys_wrdata           => sys_wrdata,          -- data/no. bytes
      sys_wr_cmd           => sys_wr_cmd,          -- write strobe

      -- read interface to system
      sys_rdaddr           => sys_rdaddr,          -- address for reads/writes
      sys_rddata           => sys_rddata,          -- input data port for read operation
      sys_rd_cmd           => sys_rd_cmd,          -- read strobe
      sys_rd_endcmd        => sys_rd_endcmd        -- input read strobe
   );

   UUT_test : axi4_lite_test
   port map (
      resetn               => S_AXI_ARESETN,
      clk                  => sys_clk,             -- system clk (same as AXI clock

      -- write interface from system
      sys_wraddr           => sys_wraddr,          -- address for reads/writes
      sys_wrdata           => sys_wrdata,          -- data/no. bytes
      sys_wr_cmd           => sys_wr_cmd,          -- write strobe

      sys_rdaddr           => sys_rdaddr,          -- address for reads/writes
      sys_rddata           => sys_rddata,          -- input data port for read operation
      sys_rd_cmd           => sys_rd_cmd,          -- read strobe
      sys_rd_endcmd        => sys_rd_endcmd,       -- input read strobe

      -- led output
      gpio_led             => gpio_led
   );


   process  -- process for clk
   begin
      loop
         S_AXI_ACLK   <= '1';
         wait for tCK/2;
         S_AXI_ACLK   <= '0';
         wait for tCK/2;
      end loop;
   end process;

 
   process  -- process for generating test
   variable tx_str   : String(1 to 4096);
   variable tx_loc   : LINE;
   
   begin
      errors               <= 0;

      S_AXI_AWADDR         <= X"00000000";
      S_AXI_AWVALID        <= '0';
      S_AXI_WDATA          <= X"00000000";
      S_AXI_WSTRB          <= "0000";
      S_AXI_WVALID         <= '0';
      S_AXI_BREADY         <= '0';
      S_AXI_ARADDR         <= X"00000000";
      S_AXI_ARVALID        <= '0';
      S_AXI_RREADY         <= '0';
      
      S_AXI_ARESETN        <= '0';

      wait for tCK*5;
  
      -- basic startup test
      wait for tCK*5; -- wait for 5 clock cycles
      S_AXI_ARESETN   <= '1';
      wait for tCK*5; -- wait for 5 clock cycles

      wait for 1000 * tCK;  
      

      axi_lite_write(   -- write to 32 register width process
         clk_in               => S_AXI_ACLK,
         addr_in              => X"00000058",
         data_in              => X"abcdef01",
         S_AXI_LITE_AWADDR    => S_AXI_AWADDR,
         S_AXI_LITE_AWVALID   => S_AXI_AWVALID,
         S_AXI_LITE_AWREADY   => S_AXI_AWREADY,
         S_AXI_LITE_WDATA     => S_AXI_WDATA,
         S_AXI_LITE_WSTRB     => S_AXI_WSTRB,
         S_AXI_LITE_WVALID    => S_AXI_WVALID,
         S_AXI_LITE_WREADY    => S_AXI_WREADY,
         S_AXI_LITE_BVALID    => S_AXI_BVALID,
         S_AXI_LITE_BREADY    => S_AXI_BREADY
      );

      wait for 10 * tCK;  

      axi_lite_read(   -- write to 32 register width process
         clk_in               => S_AXI_ACLK,
         addr_in              => X"00000074",
         data_active          => data_active,
         read_data            => read_data,
         S_AXI_LITE_ARADDR    => S_AXI_ARADDR,
         S_AXI_LITE_ARVALID   => S_AXI_ARVALID,
         S_AXI_LITE_ARREADY   => S_AXI_ARREADY,
         S_AXI_LITE_RDATA     => S_AXI_RDATA,
         S_AXI_LITE_RVALID    => S_AXI_RVALID,
         S_AXI_LITE_RREADY    => S_AXI_RREADY
      );

      wait for 1000 * tCK;  

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

