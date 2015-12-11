--------------------------------------------------------------
--
-- (C) Copyright Kutu Pty. Ltd. 2013.
--
-- file: axi_sim_pkg.vhd
--
-- author: Greg Smart
--
--------------------------------------------------------------
--------------------------------------------------------------
--
-- This is a vhdl package for containing procedures for axi simulation
--------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--use work.system_pkg.all;

library ieee;
use ieee.std_logic_textio.all;
use std.textio.all;

package axi_sim_pkg is

   constant axi_tCK     : time      := 13.300 ns;
 
   function Image(
      In_Image : Std_Logic_Vector
   ) return String;
   
   function HexImage(
      In_Image : Std_Logic_Vector
   ) return String;
   
   procedure wait_for_clk(   -- wait according to clk steps
      signal   clk_in         : in std_logic;
               clocks         : integer
   );

   procedure axi_lite_write(  -- write to 32 register width process
      signal   clk_in               : in  std_logic;
               addr_in              :     std_logic_vector(31 downto 0);
               data_in              :     std_logic_vector(31 downto 0);
      signal   S_AXI_LITE_AWADDR    : out std_logic_vector (31 downto 0);
      signal   S_AXI_LITE_AWVALID   : out std_logic;
      signal   S_AXI_LITE_AWREADY   : in std_logic;
      signal   S_AXI_LITE_WDATA     : out std_logic_vector(31 downto 0);
      signal   S_AXI_LITE_WSTRB     : out std_logic_vector(3 downto 0);
      signal   S_AXI_LITE_WVALID    : out std_logic;
      signal   S_AXI_LITE_WREADY    : in std_logic;
      signal   S_AXI_LITE_BVALID    : in std_logic;
      signal   S_AXI_LITE_BREADY    : out std_logic
   );

   procedure axi_lite_read(   -- read from register process
      signal   clk_in               : in  std_logic;
               addr_in              :     std_logic_vector(31 downto 0);
      signal   data_active          : out std_logic;
      signal   read_data            : out std_logic_vector(31 downto 0);
      signal   S_AXI_LITE_ARADDR    : out  std_logic_vector(31 downto 0);
      signal   S_AXI_LITE_ARVALID   : out  std_logic;
      signal   S_AXI_LITE_ARREADY   : in std_logic;
      signal   S_AXI_LITE_RDATA     : in std_logic_vector(31 downto 0);
      signal   S_AXI_LITE_RVALID    : in std_logic;
      signal   S_AXI_LITE_RREADY    : out  std_logic
   );

end package axi_sim_pkg;

package body axi_sim_pkg is

   function Image(In_Image : Std_Logic_Vector) return String is
      variable L     : Line;   -- access type
      variable W     : String(1 to In_Image'length) := (others => ' ');
      
   begin
      IEEE.Std_Logic_TextIO.WRITE(L, In_Image);
      W(L.all'range) := L.all;
      Deallocate(L);
      return W;
   end Image;

   function HexImage(In_Image : Std_Logic_Vector) return String is
      subtype Int03_Typ is Integer range 0 to 3;
      variable Result   : string(1 to In_Image'length/4) :=(others => '0');
      variable StrTo4   : string(1 to Result'length * 4) :=(others => '0');
      variable MTspace  : Int03_Typ;   -- Empty space to fill in
      variable Str4     : String(1 to 4);
      variable Group_v  : Natural := 0;
      variable InStrg   : String(1 to In_Image'length);

   begin
      InStrg := Image(In_Image);

      MTspace := Result'length * 4  - InStrg'length;
      StrTo4(MTspace + 1 to StrTo4'length) := InStrg;   -- padded with '0'
      for I in Result'range loop
         Group_v := Group_v + 4;  -- identifies end of bit # in a group of 4
         Str4 := StrTo4(Group_v - 3 to Group_v); -- get next 4 characters
         case Str4 is
            when "0000"  => Result(I) := '0';
            when "0001"  => Result(I) := '1';
            when "0010"  => Result(I) := '2';
            when "0011"  => Result(I) := '3';
            when "0100"  => Result(I) := '4';
            when "0101"  => Result(I) := '5';
            when "0110"  => Result(I) := '6';
            when "0111"  => Result(I) := '7';
            when "1000"  => Result(I) := '8';
            when "1001"  => Result(I) := '9';
            when "1010"  => Result(I) := 'A';
            when "1011"  => Result(I) := 'B';
            when "1100"  => Result(I) := 'C';
            when "1101"  => Result(I) := 'D';
            when "1110"  => Result(I) := 'E';
            when "1111"  => Result(I) := 'F';
            when "ZZZZ"  => Result(I) := 'Z';
            when others  => Result(I) := 'X';
         end case;   --  Str4
      end loop ;

      return Result;
   end HexImage;

   procedure wait_for_clk(   -- wait according to clk steps
      signal   clk_in      : in std_logic;
               clocks      : integer
   ) is
   
   begin
      for x in 0 to clocks-1 loop
         wait until rising_edge(clk_in);
     end loop;
   end wait_for_clk;

   procedure axi_lite_write(   -- write to 32 register width process
      signal   clk_in               : in  std_logic;
               addr_in              :     std_logic_vector(31 downto 0);
               data_in              :     std_logic_vector(31 downto 0);
      signal   S_AXI_LITE_AWADDR    : out std_logic_vector (31 downto 0);
      signal   S_AXI_LITE_AWVALID   : out std_logic;
      signal   S_AXI_LITE_AWREADY   : in std_logic;
      signal   S_AXI_LITE_WDATA     : out std_logic_vector(31 downto 0);
      signal   S_AXI_LITE_WSTRB     : out std_logic_vector(3 downto 0);
      signal   S_AXI_LITE_WVALID    : out std_logic;
      signal   S_AXI_LITE_WREADY    : in std_logic;
      signal   S_AXI_LITE_BVALID    : in std_logic;
      signal   S_AXI_LITE_BREADY    : out std_logic
      
   ) is

      variable zero_32bits    : std_logic_vector(31 downto 0):=(others=>'0');
      variable end_write      : integer := 0;
      variable end_access     : integer := 0;

   begin
      -------------------------------------
      -- write command
      -------------------------------------
      S_AXI_LITE_AWVALID   <= transport '1' after 1 ns;
      S_AXI_LITE_AWADDR    <= transport addr_in after 1 ns;
      S_AXI_LITE_WVALID    <= transport '1' after 1 ns;
      S_AXI_LITE_WDATA     <= transport data_in after 1 ns;
      S_AXI_LITE_WSTRB     <= transport (others => '1');
      
      while end_access = 0 loop
         if S_AXI_LITE_AWREADY = '1' then
            S_AXI_LITE_AWVALID   <= transport 'L' after 1 ns;
            S_AXI_LITE_AWADDR    <= transport (others =>'0') after 1 ns;
            S_AXI_LITE_WVALID    <= transport 'L' after 1 ns;
         end if;

         if S_AXI_LITE_WREADY = '1' then
            S_AXI_LITE_WVALID    <= transport '0' after 1 ns;
            S_AXI_LITE_WDATA     <= transport (others =>'0') after 1 ns;
            S_AXI_LITE_WSTRB     <= transport (others => '0');
            end_write            := 1;
            S_AXI_LITE_BREADY    <= transport '1' after 1 ns;
         end if;

         if end_write = 1 and S_AXI_LITE_BVALID = '1' then
            S_AXI_LITE_BREADY   <= transport 'L' after 1 ns; 
            end_access     := 1;
         end if;
         
         wait_for_clk(clk_in,1);
      end loop;
      
   end axi_lite_write;

   procedure axi_lite_read(   -- read from register process
      signal   clk_in               : in  std_logic;
               addr_in              :     std_logic_vector(31 downto 0);
      signal   data_active          : out std_logic;
      signal   read_data            : out std_logic_vector(31 downto 0);
      signal   S_AXI_LITE_ARADDR    : out  std_logic_vector(31 downto 0);
      signal   S_AXI_LITE_ARVALID   : out  std_logic;
      signal   S_AXI_LITE_ARREADY   : in std_logic;
      signal   S_AXI_LITE_RDATA     : in std_logic_vector(31 downto 0);
      signal   S_AXI_LITE_RVALID    : in std_logic;
      signal   S_AXI_LITE_RREADY    : out  std_logic
   ) is  
      
      variable end_read         : integer := 0;

   begin
      -------------------------------------
      -- read command
      -------------------------------------
      S_AXI_LITE_ARVALID   <= transport '1' after 1 ns;
      S_AXI_LITE_ARADDR    <= transport addr_in after 1 ns;
      S_AXI_LITE_RREADY    <= transport '1' after 1 ns;

      data_active          <= transport '0' after 1 ns;

      while end_read = 0 loop
         if S_AXI_LITE_ARREADY = '1' then
            S_AXI_LITE_ARVALID   <= transport 'L' after 1 ns;
            S_AXI_LITE_ARADDR    <= transport (others =>'0') after 1 ns;
            data_active          <= transport '1' after 1 ns;
         end if;

         if S_AXI_LITE_RVALID = '1' then
            S_AXI_LITE_RREADY    <= transport '0' after 1 ns;
            data_active          <= transport '0' after 1 ns;
            read_data            <= transport S_AXI_LITE_RDATA after 1 ns;
--            read_data            <= transport X"12345678" after 1 ns;
            end_read             := 1;
         end if;
         wait_for_clk(clk_in,1);
      end loop;

   end axi_lite_read;


end package body axi_sim_pkg;

