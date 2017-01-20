--------------------------------------------------------------
--
-- (C) Copyright Kutu Pty. Ltd. 2014.
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
      C_S_AXI_DATA_WIDTH   : integer  range 32 to 32       := 32;
      C_S_AXI_ADDR_WIDTH   : integer  range 8 to 32        := 32;
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

   signal   timeout              : std_logic_vector(3 downto 0);
   signal   kill_read            : std_logic;
   signal   sys_rd_cmd_sig       : std_logic;


   signal   S_AXI_LITE_WREADY_sig      : std_logic;
   signal   S_AXI_LITE_AWREADY_sig     : std_logic;
   signal   S_AXI_LITE_ARREADY_sig     : std_logic;
   signal   S_AXI_LITE_RVALID_sig      : std_logic;

begin

   S_AXI_LITE_BRESP     <= RESP_OKAY;
   S_AXI_LITE_RRESP     <= RESP_OKAY;
   S_AXI_LITE_RDATA     <= sys_rddata;
   sys_wr_cmd           <= S_AXI_LITE_WREADY_sig;

   clk                  <= S_AXI_LITE_ACLK;
   sys_clk              <= S_AXI_LITE_ACLK;
   reset                <= not S_AXI_LITE_ARESETN;

   process (clk)
   begin
      if rising_edge(clk) then
         if reset = '1' then
            write_addr_active <= '0';
         else
            if S_AXI_LITE_AWVALID = '1' then
               write_addr_active <= '1';
            else
               write_addr_active <= '0';
            end if;

         end if;
      end if;
   end process;

   -- process to write address
   process (clk)
   begin
      if rising_edge(clk) then
         if reset = '1' then
            sys_wraddr  <= (others => '0');
            sys_rdaddr  <= (others => '0');
            sys_wrdata  <= (others => '0');
         else
            -- read has priority
            if S_AXI_LITE_ARVALID = '1' then
               sys_rdaddr <= S_AXI_LITE_ARADDR(C_SYS_ADDR_WIDTH-1 downto 2);
            end if;

            if S_AXI_LITE_AWVALID = '1' then
               sys_wraddr <= S_AXI_LITE_AWADDR(C_SYS_ADDR_WIDTH-1 downto 2);
            end if;

            if S_AXI_LITE_WVALID = '1' then
               sys_wrdata <= S_AXI_LITE_WDATA;
            end if;

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
            S_AXI_LITE_AWREADY_sig <= S_AXI_LITE_WVALID and S_AXI_LITE_AWVALID and write_addr_active and not S_AXI_LITE_AWREADY_sig;
            S_AXI_LITE_WREADY_sig  <= S_AXI_LITE_WVALID and S_AXI_LITE_AWVALID and write_addr_active and not S_AXI_LITE_WREADY_sig;
            S_AXI_LITE_BVALID      <= S_AXI_LITE_WREADY_sig;
         end if;
      end if;
   end process;

   -- process for read acknowledge signals
   S_AXI_LITE_ARREADY   <= S_AXI_LITE_ARREADY_sig;
   sys_rd_cmd           <= sys_rd_cmd_sig;
   process (clk)
   begin
      if rising_edge(clk) then
         if reset = '1' then
            sys_rd_cmd_sig          <= '0';
            S_AXI_LITE_RVALID       <= '0';
            S_AXI_LITE_ARREADY_sig  <= '0';
         else
            sys_rd_cmd_sig          <= S_AXI_LITE_ARVALID and S_AXI_LITE_RREADY;
            S_AXI_LITE_RVALID       <= S_AXI_LITE_ARREADY_sig and S_AXI_LITE_RREADY;
            S_AXI_LITE_ARREADY_sig  <= (sys_rd_endcmd or kill_read) and S_AXI_LITE_ARVALID and S_AXI_LITE_RREADY and not S_AXI_LITE_ARREADY_sig;
         end if;
      end if;
   end process;

   -- process for read timeout
   process (clk)
   begin
      if rising_edge(clk) then
         if reset = '1' then
            timeout     <= "0000";
            kill_read   <= '0';
         else
            if sys_rd_endcmd = '1' or sys_rd_cmd_sig = '0' then
               timeout <= "0000";
            else
               timeout <= timeout + 1;
            end if;

            if timeout = "1110" and sys_rd_endcmd = '0' then
               kill_read   <= '1';
            else
               kill_read   <= '0';
            end if;
         end if;
      end if;
   end process;

end RTL;



