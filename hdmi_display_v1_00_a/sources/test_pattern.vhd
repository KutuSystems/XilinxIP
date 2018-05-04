--
-- VHDL Architecture display.video_data_gen.rtl
--
-- Created:
--          by - Administrator.UNKNOWN (ADS-LAPTOP)
--          at - 11:37:25 09/09/2007
--
-- using Mentor Graphics HDL Designer(TM) 2004.1 (Build 41)
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity test_pattern is
   generic
   (
      -- Video frame parameters
      USR_HSIZE            : integer := 1920;
      USR_VSIZE            : integer := 1080
   );
   port
   (
      reset                : in  std_logic;
      fsync                : in  std_logic;

      -- simulating AXI-Stream port from VDMA
      s_axis_mm2s_aresetn	: out std_logic;
      s_axis_mm2s_aclk	   : in  std_logic;
      s_axis_mm2s_tready	: in  std_logic;
      s_axis_mm2s_tdata	   : out std_logic_vector(31 downto 0);
      s_axis_mm2s_tkeep	   : out std_logic_vector(3 downto 0);
      s_axis_mm2s_tlast	   : out std_logic;
      s_axis_mm2s_tvalid	: out std_logic
   );
end test_pattern;

architecture RTL of test_pattern is

   constant USER_HSIZE           : std_logic_vector(11 downto 0)  := conv_std_logic_vector(USR_HSIZE, 12);
   constant USER_VSIZE           : std_logic_vector(11 downto 0)  := conv_std_logic_vector(USR_VSIZE, 12);

   signal h_count                : std_logic_vector(11 downto 0) := (others =>'0');
   signal v_count                : std_logic_vector(11 downto 0) := (others =>'0');
   signal last_h_count           : std_logic := '0';
   signal last_v_count           : std_logic := '0';
   signal s_axis_mm2s_tvalid_sig : std_logic := '0';
   --signal red                    : std_logic_vector(7 downto 0) := (others =>'0');
   signal green                  : std_logic_vector(9 downto 0) := (others =>'0');
   signal blue                   : std_logic_vector(7 downto 0) := (others =>'0');

begin

   s_axis_mm2s_aresetn  <= not reset;
   s_axis_mm2s_tvalid   <= s_axis_mm2s_tvalid_sig;
--   s_axis_mm2s_tdata	   <= X"00" & red & green & blue;
   s_axis_mm2s_tdata	   <= X"00" & green(9 downto 2) & green(7 downto 0) & blue;
   s_axis_mm2s_tkeep	   <= "1111";
   s_axis_mm2s_tlast	   <= '0';

   -- frame counters
   process (s_axis_mm2s_aclk)
   begin
      if rising_edge(s_axis_mm2s_aclk) then
         if reset = '1' then
            h_count                 <= (others =>'0');
            last_h_count            <= '0';
            v_count                 <= (others =>'0');
            last_v_count            <= '0';
            s_axis_mm2s_tvalid_sig  <= '0';
           -- red                     <= X"00";
            green                   <= (others =>'0');
            blue                    <= (others =>'0');
         else

            if fsync = '1' or (s_axis_mm2s_tready = '1' and s_axis_mm2s_tvalid_sig = '1' and last_h_count = '1') then
               h_count <= (others =>'0');
            elsif s_axis_mm2s_tready = '1' and s_axis_mm2s_tvalid_sig = '1' then
               h_count <= h_count + 1;
            end if;

            if (h_count = USER_HSIZE - 2) and s_axis_mm2s_tready = '1' and s_axis_mm2s_tvalid_sig = '1' then
               last_h_count <= '1';
            elsif (h_count = USER_HSIZE - 1) and (s_axis_mm2s_tready = '0' or s_axis_mm2s_tvalid_sig = '0') then
               last_h_count <= '1';
            else
               last_h_count <= '0';
            end if;

            if fsync = '1' then
               v_count <= (others =>'0');
            elsif s_axis_mm2s_tready = '1' and s_axis_mm2s_tvalid_sig = '1' and last_h_count = '1' then
               v_count <= v_count + 1;
            end if;

            if v_count = USER_VSIZE - 1 then
               last_v_count <= '1';
            else
               last_v_count <= '0';
            end if;

            if fsync = '1' then
               s_axis_mm2s_tvalid_sig <= '1';
            elsif last_v_count = '1' and s_axis_mm2s_tready = '1' and s_axis_mm2s_tvalid_sig = '1' and last_h_count = '1' then
               s_axis_mm2s_tvalid_sig <= '0';
            end if;

            -- blue increments horizontally
            if fsync = '1' or (s_axis_mm2s_tready = '1' and s_axis_mm2s_tvalid_sig = '1' and last_h_count = '1') then
               blue <= (others =>'0');
            elsif s_axis_mm2s_tready = '1' and s_axis_mm2s_tvalid_sig = '1' then
               blue <= blue + 1;
            end if;

            -- green increments vertically
            if fsync = '1' then
               green <= (others =>'0');
            elsif s_axis_mm2s_tready = '1' and s_axis_mm2s_tvalid_sig = '1' and last_h_count = '1' then
               green <= green + 1;
            end if;

            -- red increments with blue overflow
      --      if fsync = '1' then
      --         red <= (others =>'0');
      --      elsif s_axis_mm2s_tready = '1' and s_axis_mm2s_tvalid_sig = '1' and (last_h_count = '1' or red = X"FF") then
      --         red <= red + 1;
      --      end if;
         end if;

      end if;
   end process;

end RTL;
