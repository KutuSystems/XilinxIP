--------------------------------------------------------------
--
-- (C) Copyright Kutu Pty. Ltd. 2013.
-- (C) Copyright Hawk Measurement Pty. Ltd. 2013.
--
-- file: axi4_lite_controller.vhd
--
-- author: Greg Smart
--
--------------------------------------------------------------
--------------------------------------------------------------
--
-- This module receives commands from the UART input and
-- implements a memory mapped interface based on the Modbus 
-- protocol.
--
--------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- synopsys translate_off
library unisim;
use unisim.vcomponents.all;
-- synopsys translate_on

entity axi4_lite_controller is

   generic (
      C_S_AXI_DATA_WIDTH    : integer  range 32 to 32       := 32;
      C_S_AXI_ADDR_WIDTH    : integer  range 13 to 16       := 13;
      C_S_AXI_MIN_SIZE      : std_logic_vector(31 downto 0) := X"0000FFFF";
      C_USE_WSTRB           : integer := 0;
      C_DPHASE_TIMEOUT      : integer range 0 to 512        := 8;
      C_BASEADDR            : std_logic_vector              := X"7000_0000";
      C_HIGHADDR            : std_logic_vector              := X"7000_FFFF"
   );
   port (
      -- AXI bus signals
      S_AXI_ACLK           : in  std_logic;
      S_AXI_ARESETN        : in  std_logic;
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

      -- Interface to system
      sys_clk           : out std_logic;                       -- system clk (same as AXI clock
      sys_addr          : out std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);   -- address for reads/writes
      sys_data          : out std_logic_vector(31 downto 0);   -- data/no. bytes
      sys_indata        : in std_logic_vector(31 downto 0);    -- input data port for read operation
      sys_write_cmd     : out std_logic;                       -- write strobe
      sys_read_cmd      : out std_logic                        -- read strobe
   );
end axi4_lite_controller;


architecture RTL of axi4_lite_controller is

   constant RESP_OKAY         : std_logic_vector(1 downto 0) := "00";
   constant RESP_EXOKAY       : std_logic_vector(1 downto 0) := "01";
   constant RESP_SLVERR       : std_logic_vector(1 downto 0) := "10";
   constant RESP_DECERR       : std_logic_vector(1 downto 0) := "11";
 
--   constant BAR               : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0) := C_BASEADDR;

--   constant ADDR_NOR          : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0) := C_BASEADDR xor C_HIGHADDR;
 
   function Get_Addr_Bits (compare : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0)) return integer is
      
      variable i : integer;

   begin
      for i in C_S_AXI_ADDR_WIDTH-1 downto 0 loop
         if compare(i)= '1' then
            return i;
         end if;
      end loop;
      return(C_S_AXI_ADDR_WIDTH);
   end function Get_Addr_Bits;

--   constant C_AB                 : integer := Get_Addr_Bits(ADDR_NOR);

   signal   reset                : std_logic;
   signal   clk                  : std_logic;
   signal   write_addr_active    : std_logic;
   signal   read_addr_active     : std_logic;
   signal   read_wait1           : std_logic;
   signal   read_wait2           : std_logic;

   signal   S_AXI_LITE_WREADY_sig     : std_logic;
   signal   S_AXI_LITE_AWREADY_sig    : std_logic;
   signal   S_AXI_LITE_RVALID_sig     : std_logic;

begin

   S_AXI_LITE_BRESP     <= RESP_OKAY;
   S_AXI_LITE_RRESP     <= RESP_OKAY;
   S_AXI_LITE_RDATA     <= sys_indata;
   sys_write_cmd        <= S_AXI_LITE_WREADY_sig;
   sys_read_cmd         <= S_AXI_LITE_RVALID_sig;

   clk                  <= S_AXI_ACLK;
   sys_clk              <= S_AXI_ACLK;
   reset                <= not S_AXI_ARESETN;

   -- process to decode read and write chip select
   process (clk)
   begin
      if rising_edge(clk) then
         if reset = '1' then
            write_addr_active <= '0';
            read_addr_active  <= '0';
         else
--            if S_AXI_LITE_AWVALID = '1' and (S_AXI_LITE_AWADDR(C_S_AXI_ADDR_WIDTH-1 downto C_AB) = BAR(C_S_AXI_ADDR_WIDTH-1 downto C_AB)) then
            if S_AXI_LITE_AWVALID = '1' then
               write_addr_active <= '1';
            else
               write_addr_active <= '0';
            end if;

--            if S_AXI_LITE_ARVALID = '1' and (S_AXI_LITE_ARADDR(C_S_AXI_ADDR_WIDTH-1 downto C_AB) = BAR(C_S_AXI_ADDR_WIDTH-1 downto C_AB)) then
            if S_AXI_LITE_ARVALID = '1' then
               read_addr_active <= '1';
            else
               read_addr_active <= '0';
            end if;
         end if;
      end if;
   end process;

   -- process to write address
   process (clk)
   begin
      if rising_edge(clk) then
         if reset = '1' then
            sys_addr <= (others => '0');
            sys_data <= (others => '0');
         else
            -- read has priority
            if S_AXI_LITE_ARVALID = '1' then
               sys_addr <= S_AXI_LITE_ARADDR;
            elsif S_AXI_LITE_AWVALID = '1' then
               sys_addr <= S_AXI_LITE_AWADDR;
            end if;

            sys_data <= S_AXI_LITE_WDATA;
         end if;
      end if;
   end process;

   -- process for write acknowledge signals
   S_AXI_LITE_WREADY   <= S_AXI_LITE_WREADY_sig;
   S_AXI_LITE_AWREADY  <= S_AXI_LITE_AWREADY_sig;
   process (clk)
   begin
      if rising_edge(clk) then
         if reset = '1' then
            S_AXI_LITE_AWREADY_sig  <= '0';
            S_AXI_LITE_WREADY_sig  <= '0';
            S_AXI_LITE_BVALID      <= '0';
         else
            S_AXI_LITE_AWREADY_sig <= S_AXI_LITE_WVALID and S_AXI_LITE_AWVALID and write_addr_active and S_AXI_LITE_BREADY and not S_AXI_LITE_AWREADY_sig;
            S_AXI_LITE_WREADY_sig  <= S_AXI_LITE_WVALID and S_AXI_LITE_AWVALID and write_addr_active and not S_AXI_LITE_WREADY_sig;
            S_AXI_LITE_BVALID      <= S_AXI_LITE_WREADY_sig;
         end if;
      end if;
   end process;

   -- process for read acknowledge signals
   S_AXI_LITE_RVALID <= S_AXI_LITE_RVALID_sig;
   process (clk)
   begin
      if rising_edge(clk) then
         if reset = '1' then
            read_wait1        <= '0';
            read_wait2        <= '0';
            S_AXI_LITE_RVALID_sig  <= '0';
            S_AXI_LITE_ARREADY     <= '0';
         else
            read_wait1        <= S_AXI_LITE_ARVALID and read_addr_active and not S_AXI_LITE_RREADY;
            read_wait2        <= S_AXI_LITE_ARVALID and read_wait1 and not S_AXI_LITE_RVALID_sig;
            S_AXI_LITE_RVALID_sig  <= read_wait2 and S_AXI_LITE_RREADY;
            S_AXI_LITE_ARREADY     <= read_wait2 and S_AXI_LITE_RREADY;
         end if;
      end if;
   end process;

end RTL;



