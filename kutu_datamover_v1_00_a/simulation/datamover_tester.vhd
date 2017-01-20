--------------------------------------------------------------
--
-- (C) Copyright Kutu Pty. Ltd. 2015.
--
-- file: top.vhd
--
-- author: Greg Smart
--
--------------------------------------------------------------
--------------------------------------------------------------
--
-- This module is the top level module
-- running on an Avnet Microzed board.
--
--------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_ARITH.ALL;
use IEEE.std_logic_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity datamover_tester is
   port (
      reset             : in std_logic;
      clk200            : in std_logic;
      cmd_clk           : in std_logic;
      start_test        : in std_logic;

      -- output leds
      reset_led         : out std_logic;
      run_led           : out std_logic;
      alive_led         : out std_logic;
      error_led         : out std_logic;
      mm2s_err          : out std_logic;
      s2mm_err          : out std_logic
   );
end datamover_tester;

architecture RTL of datamover_tester is

   procedure lfsrAdd32(signal count : in std_logic_vector(31 downto 0);
                     signal countP1 : out std_logic_vector(31 downto 0)) is
   begin
      countP1(1)  <= count(0) xnor count(31);
      countP1(2)  <= count(1) xnor count(31);
      countP1(3)  <= count(2);
      countP1(4)  <= count(3);
      countP1(5)  <= count(4);
      countP1(6)  <= count(5);
      countP1(7)  <= count(6);
      countP1(8)  <= count(7);
      countP1(9)  <= count(8);
      countP1(10) <= count(9);
      countP1(11) <= count(10);
      countP1(12) <= count(11);
      countP1(13) <= count(12);
      countP1(14) <= count(13);
      countP1(15) <= count(14);
      countP1(16) <= count(15);
      countP1(17) <= count(16);
      countP1(18) <= count(17);
      countP1(19) <= count(18);
      countP1(20) <= count(19);
      countP1(21) <= count(20);
      countP1(22) <= count(21) xnor count(31);
      countP1(23) <= count(22);
      countP1(24) <= count(23);
      countP1(25) <= count(24);
      countP1(26) <= count(25);
      countP1(27) <= count(26);
      countP1(28) <= count(27);
      countP1(29) <= count(28);
      countP1(30) <= count(29);
      countP1(31) <= count(30);
      countP1(0)  <= count(31);
   end;

   constant INIT_DATA0              : std_logic_vector(31 downto 0 ) := X"00000001";
   constant INIT_DATA1              : std_logic_vector(31 downto 0 ) := X"00f00001";
   constant INIT_COMMAND            : std_logic_vector(31 downto 0 ) := X"00000000";

   signal m_axis_mm2s_tdata         : std_logic_vector(63 downto 0 );
   signal m_axis_mm2s_tkeep         : std_logic_vector(7 downto 0 );
   signal m_axis_mm2s_tlast         : std_logic;
   signal m_axis_mm2s_tready        : std_logic;
   signal m_axis_mm2s_tvalid        : std_logic;
   signal s_axis_aresetn            : std_logic;
   signal s_axis_mm2s_cmd_aresetn   : std_logic;
   signal s_axis_mm2s_cmd_tdata     : std_logic_vector(63 downto 0 );
   signal s_axis_mm2s_cmd_tready    : std_logic;
   signal s_axis_mm2s_cmd_tvalid    : std_logic;
   signal s_axis_s2mm_cmd_aresetn   : std_logic;
   signal s_axis_s2mm_cmd_tdata     : std_logic_vector(63 downto 0 );
   signal s_axis_s2mm_cmd_tready    : std_logic;
   signal s_axis_s2mm_cmd_tvalid    : std_logic;
   signal s_axis_s2mm_tdata         : std_logic_vector(63 downto 0 );
   signal s_axis_s2mm_tkeep         : std_logic_vector(7 downto 0 );
   signal s_axis_s2mm_tlast         : std_logic;
   signal s_axis_s2mm_tready        : std_logic;
   signal s_axis_s2mm_tvalid        : std_logic;

   signal clk                       : std_logic;
   signal compare0                  : std_logic;
   signal compare1                  : std_logic;
   signal error_detect              : std_logic;
   signal error_sig                 : std_logic;
   signal sync_reset                : std_logic;
   signal resetn                    : std_logic;
   signal cmd_resetn                : std_logic;
   signal count_reg                 : std_logic_vector(27 downto 0 );
   signal data0                     : std_logic_vector(31 downto 0 );
   signal data1                     : std_logic_vector(31 downto 0 );
   signal test0                     : std_logic_vector(31 downto 0 );
   signal test1                     : std_logic_vector(31 downto 0 );

   signal cmd_arbitrate             : std_logic_vector(3 downto 0 );
   signal wr_cmd_count              : std_logic_vector(1 downto 0 );
   signal rd_cmd_count              : std_logic_vector(1 downto 0 );

   signal wr_lfsr_count             : std_logic_vector(5 downto 0 );
   signal rd_lfsr_count             : std_logic_vector(5 downto 0 );
   signal inc_wr_count              : std_logic;
   signal inc_rd_count              : std_logic;
   signal wr_cmd                    : std_logic_vector(31 downto 0 );
   signal rd_cmd                    : std_logic_vector(31 downto 0 );
   signal wr_ok                     : std_logic;
   signal rd_ok                     : std_logic;
   signal running                   : std_logic;

   signal wr_addr                   : std_logic_vector(31 downto 0);
   signal wr_size                   : std_logic_vector(29 downto 0);
   signal rd_addr                   : std_logic_vector(31 downto 0);
   signal rd_size                   : std_logic_vector(29 downto 0);

   component system_top_wrapper
      port (
         m_axis_mm2s_tdata       : out std_logic_vector(63 downto 0 );
         m_axis_mm2s_tkeep       : out std_logic_vector(7 downto 0 );
         m_axis_mm2s_tlast       : out std_logic;
         m_axis_mm2s_tready      : in std_logic;
         m_axis_mm2s_tvalid      : out std_logic;
         mm2s_err                : out std_logic;
         s2mm_err                : out std_logic;
         s_axis_aclk             : in std_logic;
         s_axis_aresetn          : in std_logic;
         s_axis_mm2s_cmd_aclk    : in std_logic;
         s_axis_mm2s_cmd_aresetn : in std_logic;
         s_axis_mm2s_cmd_tdata   : in std_logic_vector(63 downto 0 );
         s_axis_mm2s_cmd_tready  : out std_logic;
         s_axis_mm2s_cmd_tvalid  : in std_logic;
         s_axis_s2mm_cmd_aclk    : in std_logic;
         s_axis_s2mm_cmd_aresetn : in std_logic;
         s_axis_s2mm_cmd_tdata   : in std_logic_vector(63 downto 0 );
         s_axis_s2mm_cmd_tready  : out std_logic;
         s_axis_s2mm_cmd_tvalid  : in std_logic;
         s_axis_s2mm_tdata       : in std_logic_vector(63 downto 0 );
         s_axis_s2mm_tkeep       : in std_logic_vector(7 downto 0 );
         s_axis_s2mm_tlast       : in std_logic;
         s_axis_s2mm_tready      : out std_logic;
         s_axis_s2mm_tvalid      : in std_logic
      );
   end component;

begin

   clk      <= clk200;
   run_led  <= running;

   UUT: system_top_wrapper
   port map (
      m_axis_mm2s_tdata       => m_axis_mm2s_tdata,
      m_axis_mm2s_tkeep       => m_axis_mm2s_tkeep,
      m_axis_mm2s_tlast       => m_axis_mm2s_tlast,
      m_axis_mm2s_tready      => m_axis_mm2s_tready,
      m_axis_mm2s_tvalid      => m_axis_mm2s_tvalid,
      mm2s_err                => mm2s_err,
      s2mm_err                => s2mm_err,
      s_axis_aclk             => clk200,
      s_axis_aresetn          => s_axis_aresetn,
      s_axis_mm2s_cmd_aclk    => cmd_clk,
      s_axis_mm2s_cmd_aresetn => s_axis_mm2s_cmd_aresetn,
      s_axis_mm2s_cmd_tdata   => s_axis_mm2s_cmd_tdata,
      s_axis_mm2s_cmd_tready  => s_axis_mm2s_cmd_tready,
      s_axis_mm2s_cmd_tvalid  => s_axis_mm2s_cmd_tvalid,
      s_axis_s2mm_cmd_aclk    => cmd_clk,
      s_axis_s2mm_cmd_aresetn => s_axis_s2mm_cmd_aresetn,
      s_axis_s2mm_cmd_tdata   => s_axis_s2mm_cmd_tdata,
      s_axis_s2mm_cmd_tready  => s_axis_s2mm_cmd_tready,
      s_axis_s2mm_cmd_tvalid  => s_axis_s2mm_cmd_tvalid,
      s_axis_s2mm_tdata       => s_axis_s2mm_tdata,
      s_axis_s2mm_tkeep       => s_axis_s2mm_tkeep,
      s_axis_s2mm_tlast       => s_axis_s2mm_tlast,
      s_axis_s2mm_tready      => s_axis_s2mm_tready,
      s_axis_s2mm_tvalid      => s_axis_s2mm_tvalid
   );

   error_led <= error_sig;

   s_axis_aresetn          <= resetn;
   s_axis_mm2s_cmd_aresetn <= cmd_resetn;
   s_axis_s2mm_cmd_aresetn <= cmd_resetn;
   s_axis_s2mm_tdata       <= data1 & data0;

   s_axis_s2mm_tkeep <= X"ff";
   s_axis_s2mm_tlast <= '0';

   wr_addr  <= X"000" & wr_cmd_count & '0' & wr_cmd(29 downto 16) & "000";
--  wr_addr  <= X"00000000";
   wr_size  <= X"000" & '0' & wr_cmd(13 downto 0) & "000";
   s_axis_s2mm_cmd_tdata <= wr_addr & "11" & wr_size;

   rd_addr  <= X"000" & rd_cmd_count & '0' & rd_cmd(29 downto 16) & "000";
   --rd_addr  <= X"00000000";
   rd_size  <= X"000" & '0' & rd_cmd(13 downto 0) & "000";
   s_axis_mm2s_cmd_tdata <= rd_addr & "11" & rd_size;

   -- reset generation
   process (reset,clk)
   begin
      if rising_edge(clk) then
         if reset = '1' then
            sync_reset  <= '1';
         elsif start_test = '1' then
            sync_reset  <= '0';
         end if;

         if sync_reset = '1' then
            running  <= '0';
         elsif error_sig = '1' then
            running  <= '0';
         else
            running  <= '1';
         end if;

         if sync_reset = '1' or start_test = '1' then
            error_sig <= '0';
         elsif error_detect = '1' then
            error_sig <= '1';
         end if;

         resetn      <= not sync_reset;
      end if;
   end process;


   process (reset,cmd_clk)
   begin
      if rising_edge(cmd_clk) then
         cmd_resetn <= not sync_reset;
      end if;
   end process;

   -- alive led generation
   process (reset,clk)
   begin
      if rising_edge(clk) then
         if sync_reset = '1' then
            count_reg   <= (others => '0');
            alive_led   <= '0';
            reset_led   <= '1';
         else
            count_reg   <= count_reg + 1;
            alive_led   <= count_reg(27);
            reset_led   <= '0';
        end if;
      end if;
   end process;

   -- data generation
   process (reset,clk)
   begin
      if rising_edge(clk) then
         if sync_reset = '1' then
            data0                <= INIT_DATA0;
            data1                <= INIT_DATA1;
            s_axis_s2mm_tvalid   <= '0';
         else
            if s_axis_s2mm_tready = '1' and s_axis_s2mm_tvalid = '1' then
--               lfsrAdd32(data0,data0);
--               lfsrAdd32(data1,data1);
               data0 <= data0 + 1;
               data1 <= data1 + 1;
            end if;

            s_axis_s2mm_tvalid   <= '1';

        end if;
      end if;
   end process;

   -- test data generation and error detection
   process (reset,clk)
   begin
      if rising_edge(clk) then
         if sync_reset = '1' then
            test0                <= INIT_DATA0;
            test1                <= INIT_DATA1;
            m_axis_mm2s_tready   <= '0';
            compare0             <= '0';
            compare1             <= '0';
            error_detect         <= '0';
         else
            if m_axis_mm2s_tready = '1' and m_axis_mm2s_tvalid = '1' then
--               lfsrAdd32(test0,test0);
--               lfsrAdd32(test1,test1);
               test0 <= test0 + 1;
               test1 <= test1 + 1;
            end if;

            m_axis_mm2s_tready   <= '1';

            if m_axis_mm2s_tready = '1' and m_axis_mm2s_tvalid = '1' then
               if (test0 = m_axis_mm2s_tdata(31 downto 0)) then
                  compare0 <= '0';
               else
                  compare0 <= '1';
               end if;

               if (test1 = m_axis_mm2s_tdata(63 downto 32)) then
                  compare1 <= '0';
               else
                  compare1 <= '1';
               end if;
            else
               compare0 <= '0';
               compare1 <= '0';
            end if;

            error_detect <= compare0 or compare1;

        end if;
      end if;
   end process;


   -- command generation
   cmd_arbitrate <= wr_cmd_count & rd_cmd_count;
   process (cmd_clk)
   begin
      if rising_edge(cmd_clk) then
         if cmd_resetn = '0' then
            wr_cmd         <= INIT_COMMAND;
            wr_lfsr_count  <= "000000";
            wr_cmd_count   <= "00";
            wr_ok          <= '0';

            rd_cmd         <= INIT_COMMAND;
            rd_lfsr_count           <= "000000";
            rd_cmd_count            <= "00";
            rd_ok                   <= '0';

            s_axis_s2mm_cmd_tvalid  <= '0';
            s_axis_mm2s_cmd_tvalid  <= '0';

        else

            -- write to mem command
           if (wr_lfsr_count(5 downto 4) = "11" and s_axis_s2mm_cmd_tvalid = '0') or (s_axis_s2mm_cmd_tready = '0' and s_axis_s2mm_cmd_tvalid = '1')  then
               inc_wr_count <= '0';
            else
               inc_wr_count <= '1';
            end if;

            if inc_wr_count = '1' then
               lfsrAdd32(wr_cmd,wr_cmd);
            end if;

            if s_axis_s2mm_cmd_tvalid = '1' then
               wr_lfsr_count  <= "000000";
            elsif inc_wr_count = '1' then
               wr_lfsr_count <= wr_lfsr_count + 1;
            end if;

            if s_axis_s2mm_cmd_tready = '1' and s_axis_s2mm_cmd_tvalid = '1' then
               s_axis_s2mm_cmd_tvalid <= '0' after 100 ps;
            elsif inc_wr_count = '0' and wr_ok = '1' and running = '1' then
               s_axis_s2mm_cmd_tvalid <= '1' after 100 ps;
            end if;

            if s_axis_s2mm_cmd_tready = '1' and s_axis_s2mm_cmd_tvalid = '1' then
               wr_cmd_count  <= wr_cmd_count + 1;
            end if;

            -- read from mem command
            if (rd_lfsr_count(5 downto 4) = "11" and s_axis_mm2s_cmd_tvalid = '0') or (s_axis_mm2s_cmd_tready = '0' and s_axis_mm2s_cmd_tvalid = '1')  then
               inc_rd_count <= '0';
            else
               inc_rd_count <= '1';
            end if;

            if inc_rd_count = '1' then
               lfsrAdd32(rd_cmd,rd_cmd);
            end if;

            if s_axis_mm2s_cmd_tvalid = '1' then
               rd_lfsr_count  <= "000000";
            elsif inc_rd_count = '1' then
               rd_lfsr_count <= rd_lfsr_count + 1;
            end if;

            if s_axis_mm2s_cmd_tready = '1' and s_axis_mm2s_cmd_tvalid = '1' then
               s_axis_mm2s_cmd_tvalid <= '0' after 100 ps;
            elsif inc_rd_count = '0' and rd_ok = '1' then
               s_axis_mm2s_cmd_tvalid <= '1' after 100 ps;
            end if;

            if s_axis_mm2s_cmd_tready = '1' and s_axis_mm2s_cmd_tvalid = '1' then
               rd_cmd_count  <= rd_cmd_count + 1;
            end if;

            case cmd_arbitrate is
               when "0000" => wr_ok <= '1'; rd_ok <= '0';
               when "0001" => wr_ok <= '0'; rd_ok <= '1';
               when "0010" => wr_ok <= '1'; rd_ok <= '1';
               when "0011" => wr_ok <= '1'; rd_ok <= '0';

               when "0100" => wr_ok <= '1'; rd_ok <= '0';
               when "0101" => wr_ok <= '1'; rd_ok <= '0';
               when "0110" => wr_ok <= '0'; rd_ok <= '1';
               when "0111" => wr_ok <= '1'; rd_ok <= '1';

               when "1000" => wr_ok <= '1'; rd_ok <= '1';
               when "1001" => wr_ok <= '1'; rd_ok <= '0';
               when "1010" => wr_ok <= '1'; rd_ok <= '0';
               when "1011" => wr_ok <= '0'; rd_ok <= '1';

               when "1100" => wr_ok <= '0'; rd_ok <= '1';
               when "1101" => wr_ok <= '1'; rd_ok <= '1';
               when "1110" => wr_ok <= '1'; rd_ok <= '0';
               when others => wr_ok <= '1'; rd_ok <= '0';
            end case;

        end if;
      end if;
   end process;


end RTL;
