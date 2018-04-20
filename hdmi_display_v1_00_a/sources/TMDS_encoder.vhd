----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
--
-- Description: TDMS Encoder
--     8 bits colour, 2 control bits and one blanking bits in
--       10 bits of TDMS encoded data out
--     Clocked at the pixel clock
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity TMDS_encoder is
   Port
   (
      reset   : in  std_logic;
      clk     : in  std_logic;
      data    : in  std_logic_vector(7 downto 0);
      c       : in  std_logic_vector(1 downto 0);
      blank   : in  std_logic;
      encoded : out  std_logic_vector(9 downto 0)
   );
end TMDS_encoder;

architecture Behavioral of TMDS_encoder is

   constant NEITHER_HSYNC_OR_VSYNC  : std_logic_vector(9 downto 0) := "1101010100";
   constant HSYNC_NO_VSYNC          : std_logic_vector(9 downto 0) := "0010101011";
   constant NO_HSYNC_VSYNC          : std_logic_vector(9 downto 0) := "0101010100";
   constant BOTH_HSYNC_AND_VSYNC    : std_logic_vector(9 downto 0) := "1010101011";


   signal xored               : std_logic_vector(8 downto 0);
   signal xnored              : std_logic_vector(8 downto 0);
   signal xored_reg           : std_logic_vector(8 downto 0);
   signal xnored_reg          : std_logic_vector(8 downto 0);
   signal data0_reg           : std_logic;

   signal c_dly               : std_logic_vector(1 downto 0);
   signal blank_dly           : std_logic;
   signal c_reg               : std_logic_vector(1 downto 0);
   signal blank_reg           : std_logic;

   signal ones                : std_logic_vector(3 downto 0);
   signal data_word           : std_logic_vector(8 downto 0);
   signal data_word_reg       : std_logic_vector(8 downto 0);
   signal data_word_disparity : std_logic_vector(3 downto 0);
   signal dc_bias             : std_logic_vector(3 downto 0) := (others => '0');
begin

   xored(0) <= data(0);
   xored(1) <= data(1) xor xored(0);
   xored(2) <= data(2) xor xored(1);
   xored(3) <= data(3) xor xored(2);
   xored(4) <= data(4) xor xored(3);
   xored(5) <= data(5) xor xored(4);
   xored(6) <= data(6) xor xored(5);
   xored(7) <= data(7) xor xored(6);
   xored(8) <= '1';

   xnored(0) <= data(0);
   xnored(1) <= data(1) xnor xnored(0);
   xnored(2) <= data(2) xnor xnored(1);
   xnored(3) <= data(3) xnor xnored(2);
   xnored(4) <= data(4) xnor xnored(3);
   xnored(5) <= data(5) xnor xnored(4);
   xnored(6) <= data(6) xnor xnored(5);
   xnored(7) <= data(7) xnor xnored(6);
   xnored(8) <= '0';

   process(clk)
   begin
      if rising_edge(clk) then

         -- register xor/xnor to reduce fan-in
         xored_reg   <= xored;
         xnored_reg  <= xnored;

         if reset = '1' then
            ones <= "0000";
         else
         -- Count how many ones are set in data
            ones <= "0000" + data(0) + data(1) + data(2) + data(3)
                     + data(4) + data(5) + data(6) + data(7);
         end if;

         data0_reg <= data(0);

         c_dly     <= c;
         blank_dly <= blank or reset;
      end if;
   end process;

   -- Decide which encoding to use
   process(ones, data0_reg, xnored_reg, xored_reg)
   begin
      if ones > 4 or (ones = 4 and data0_reg = '0') then
         data_word     <= xnored_reg;
      else
         data_word     <= xored_reg;
      end if;
   end process;

   -- 2nd pipeline stage
   process(clk)
   begin
      if rising_edge(clk) then
         -- Work out the DC bias of the dataword;
         if reset = '1' then
            data_word_disparity <= "0000";
         else
            data_word_disparity  <= "1100" + data_word(0) + data_word(1) + data_word(2) + data_word(3)
                                    + data_word(4) + data_word(5) + data_word(6) + data_word(7);
         end if;

         data_word_reg        <= data_word;

         c_reg                <= c_dly;
         blank_reg            <= blank_dly or reset;
      end if;
   end process;

   -- final pipeline stage
   process(clk)
   begin
      if rising_edge(clk) then
         if blank_reg = '1' or reset = '1' then
            -- In the control periods, all values have and have balanced bit count
            dc_bias <= (others => '0');
         else
            if dc_bias = "0000" or data_word_disparity = "0000" then
               -- dataword has no disparity
               if data_word_reg(8) = '1' then
                  dc_bias <= dc_bias + data_word_disparity;
               else
                  dc_bias <= dc_bias - data_word_disparity;
               end if;
            elsif (dc_bias(3) = '0' and data_word_disparity(3) = '0') or (dc_bias(3) = '1' and data_word_disparity(3) = '1') then
               dc_bias <= dc_bias + data_word_reg(8) - data_word_disparity;
            else
               dc_bias <= dc_bias - (not data_word_reg(8)) + data_word_disparity;
            end if;
         end if;
      end if;
   end process;

   process(clk)
   begin
      if rising_edge(clk) then
         if blank_reg = '1' then
            -- In the control periods, all values have and have balanced bit count
            case c_reg is
               when "00"   => encoded <= NEITHER_HSYNC_OR_VSYNC;
               when "01"   => encoded <= HSYNC_NO_VSYNC;
               when "10"   => encoded <= NO_HSYNC_VSYNC;
               when others => encoded <= BOTH_HSYNC_AND_VSYNC;
            end case;
         else
            if dc_bias = "0000" or data_word_disparity = 0 then
               -- dataword has no disparity
               if data_word_reg(8) = '1' then
                  encoded <= "01" & data_word_reg(7 downto 0);
               else
                  encoded <= "10" & (not data_word_reg(7 downto 0));
               end if;
            elsif (dc_bias(3) = '0' and data_word_disparity(3) = '0') or (dc_bias(3) = '1' and data_word_disparity(3) = '1') then
               encoded <= '1' & data_word_reg(8) & (not data_word_reg(7 downto 0));
            else
               encoded <= '0' & data_word_reg;
            end if;
         end if;
      end if;
   end process;

end Behavioral;
