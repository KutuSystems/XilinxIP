--------------------------------------------------------------
--
-- (C) Copyright Kutu Pty. Ltd. 2013.
-- (C) Copyright Hawk Measurement Pty. Ltd. 2013.
--
-- file: uart_tb1.vhd
--
-- author: Greg Smart
--
--------------------------------------------------------------
--------------------------------------------------------------
--
-- This is a simple test bench for testing the the UART
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

   component uart
   port (
      reset             : in  std_logic;                    -- global system reset
      clk               : in  std_logic;                    -- 200MHz system clock
      fast              : in  std_logic;                    -- 0 = 115k, 1 = 921k

      -- external interface
      uart_tx           : out std_logic;                    -- rs232 tx output
      uart_rx           : in  std_logic;                    -- rs232 rx input

      -- external interface to system
      tx_data           : in  std_logic_vector(7 downto 0); -- output word to write
      tx_write          : in  std_logic;                    -- write data to output fifo 
      tx_full           : out std_logic;                    -- output to indicate fifo is full
      rx_data           : out std_logic_vector(7 downto 0); -- input word from serial port
      rx_write          : out std_logic                     -- rx write data signal
   );
   end component;

   component axi_clkgen
   generic
   (
      C_S_AXI_DATA_WIDTH    : integer := 32;
      C_S_AXI_ADDR_WIDTH    : integer := 32;
      C_S_AXI_MIN_SIZE      : std_logic_vector := X"000001FF";
      C_USE_WSTRB           : integer := 0;
      C_DPHASE_TIMEOUT      : integer := 8;
      C_BASEADDR            : std_logic_vector := X"FFFFFFFF";
      C_HIGHADDR            : std_logic_vector := X"00000000";
      C_FAMILY              : string := "virtex6";
      C_NUM_REG             : integer := 1;
      C_NUM_MEM             : integer := 1;
      C_SLV_AWIDTH          : integer := 32;
      C_SLV_DWIDTH          : integer := 32;
      C_MMCM_TYPE           : integer := 0
   );
   port
   (
      ref_clk               : in  std_logic;
      clk                   : out std_logic;
      S_AXI_ACLK            : in  std_logic;
      S_AXI_ARESETN         : in  std_logic;
      S_AXI_AWADDR          : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      S_AXI_AWVALID         : in  std_logic;
      S_AXI_WDATA           : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      S_AXI_WSTRB           : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
      S_AXI_WVALID          : in  std_logic;
      S_AXI_BREADY          : in  std_logic;
      S_AXI_ARADDR          : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      S_AXI_ARVALID         : in  std_logic;
      S_AXI_RREADY          : in  std_logic;
      S_AXI_ARREADY         : out std_logic;
      S_AXI_RDATA           : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      S_AXI_RRESP           : out std_logic_vector(1 downto 0);
      S_AXI_RVALID          : out std_logic;
      S_AXI_WREADY          : out std_logic;
      S_AXI_BRESP           : out std_logic_vector(1 downto 0);
      S_AXI_BVALID          : out std_logic;
      S_AXI_AWREADY         : out std_logic
   );
   end component;


   constant tCK            : time   := 10000 ps;
   constant ref_tCK        : time   := 7100 ps;

   constant C_S_AXI_DATA_WIDTH    : integer := 32;
   constant C_S_AXI_ADDR_WIDTH    : integer := 32;

   signal ref_clk          : std_logic;
   signal clk              : std_logic;
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
 
   signal data_active      : std_logic;
   signal read_data        : std_logic_vector(31 downto 0);

   signal errors           : integer;

begin
   
   UUT: axi_clkgen
   generic map
   (
      C_S_AXI_DATA_WIDTH   => C_S_AXI_DATA_WIDTH,
      C_S_AXI_ADDR_WIDTH   => C_S_AXI_ADDR_WIDTH,
      C_S_AXI_MIN_SIZE     => X"000001FF",
      C_USE_WSTRB          => 0,
      C_DPHASE_TIMEOUT     => 8,
      C_BASEADDR           => X"70000000",
      C_HIGHADDR           => X"7000FFFF",
      C_FAMILY             => "virtex6",
      C_NUM_REG            => 1,
      C_NUM_MEM            => 1,
      C_SLV_AWIDTH         => 32,
      C_SLV_DWIDTH         => 32,
      C_MMCM_TYPE          => 0
   )
   port map
   (
      ref_clk              => ref_clk,
      clk                  => clk,
      S_AXI_ACLK           => S_AXI_ACLK,
      S_AXI_ARESETN        => S_AXI_ARESETN,
      S_AXI_AWADDR         => S_AXI_AWADDR,
      S_AXI_AWVALID        => S_AXI_AWVALID,
      S_AXI_WDATA          => S_AXI_WDATA,
      S_AXI_WSTRB          => S_AXI_WSTRB,
      S_AXI_WVALID         => S_AXI_WVALID,
      S_AXI_BREADY         => S_AXI_BREADY,
      S_AXI_ARADDR         => S_AXI_ARADDR,
      S_AXI_ARVALID        => S_AXI_ARVALID,
      S_AXI_RREADY         => S_AXI_RREADY,
      S_AXI_ARREADY        => S_AXI_ARREADY,
      S_AXI_RDATA          => S_AXI_RDATA,
      S_AXI_RRESP          => S_AXI_RRESP,
      S_AXI_RVALID         => S_AXI_RVALID,
      S_AXI_WREADY         => S_AXI_WREADY,
      S_AXI_BRESP          => S_AXI_BRESP,
      S_AXI_BVALID         => S_AXI_BVALID,
      S_AXI_AWREADY        => S_AXI_AWREADY
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

   process  -- process for reference clk
   begin
      loop
         ref_clk   <= '1';
         wait for ref_tCK/2;
         ref_clk   <= '0';
         wait for ref_tCK/2;
      end loop;
   end process;

 
   process  -- process for generating test
   variable tx_str   : String(1 to 4096);
   variable tx_loc   : LINE;
   
   begin
      errors               <= 0;
      data_active          <= '0';
      read_data            <= X"00000000";

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
         addr_in              => X"ffffffff",
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
         addr_in              => X"ffffffff",
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

