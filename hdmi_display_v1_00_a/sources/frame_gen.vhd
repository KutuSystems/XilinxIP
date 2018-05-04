--------------------------------------------------------------
--
-- (C) Copyright Kutu Pty. Ltd. 2018.
--
-- file: frame_gen.vhd
--
-- author: Greg Smart
--
--------------------------------------------------------------
--------------------------------------------------------------
--
-- This module generates a video frame and interfaces to
-- a VDMA using an AXI stream.  Frame paramters are coded as
-- generic constants.
--
--------------------------------------------------------------
--
--  License:
--      This program is free software; distributed under the terms of
--      BSD 3-clause license ("Revised BSD License", "New BSD License", or "Modified BSD License")
--
--      Redistribution and use in source and binary forms, with or without modification,
--      are permitted provided that the following conditions are met:
--
--      1.    Redistributions of source code must retain the above copyright notice, this
--             list of conditions and the following disclaimer.
--      2.    Redistributions in binary form must reproduce the above copyright notice,
--             this list of conditions and the following disclaimer in the documentation
--             and/or other materials provided with the distribution.
--      3.    Neither the name(s) of the above-listed copyright holder(s) nor the names
--             of its contributors may be used to endorse or promote products derived
--             from this software without specific prior written permission.
--
--      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
--      ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
--      WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
--      IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
--      INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
--      BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
--      DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
--      LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
--      OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
--      OF THE POSSIBILITY OF SUCH DAMAGE.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity frame_gen is
   generic
   (
      -- Video frame parameters
      USR_HSIZE         : integer := 1920;
      USR_VSIZE         : integer := 1080;
      USR_HFRONT_PORCH  : integer := 88;
      USR_HBACK_PORCH   : integer := 148;
      USR_HPOLARITY     : integer := 0;
      USR_HMAX          : integer := 2200;
      USR_VFRONT_PORCH  : integer := 4;
      USR_VBACK_PORCH   : integer := 36;
      USR_VPOLARITY     : integer := 0;
      USR_VMAX          : integer := 1125;
      USR_RED           : integer := 0;
      USR_GREEN         : integer := 0;
      USR_BLUE          : integer := 0
   );
   Port
   (
      reset             : in  std_logic;
      pxl_clk           : in  std_logic;
      locked            : in  std_logic;

      s_axis_aresetn	   : in  std_logic;
      s_axis_tready	   : out std_logic;
      s_axis_tdata	   : in  std_logic_vector(31 downto 0);
      s_axis_tkeep	   : in  std_logic_vector(3 downto 0);
      s_axis_tlast	   : in  std_logic;
      s_axis_tvalid	   : in  std_logic;

      fsync             : out std_logic;
      hsync             : out std_logic;
      vsync             : out std_logic;
      de                : out std_logic;
      red               : out std_logic_vector(7 downto 0);
      green             : out std_logic_vector(7 downto 0);
      blue              : out std_logic_vector(7 downto 0);

      debug_hcount      : out std_logic_vector(11 downto 0);
      debug_vcount      : out std_logic_vector(11 downto 0);
      debug_vga_active  : out std_logic;
      debug_vga_running : out std_logic
   );
end frame_gen;

architecture RTL of frame_gen is

   -- Video frame parameters
   constant USER_HSIZE        : std_logic_vector(11 downto 0)  := conv_std_logic_vector(USR_HSIZE        , 12);
   constant USER_VSIZE        : std_logic_vector(11 downto 0)  := conv_std_logic_vector(USR_VSIZE        , 12);
   constant USER_HFRONT_PORCH : std_logic_vector(11 downto 0)  := conv_std_logic_vector(USR_HFRONT_PORCH , 12);
   constant USER_HBACK_PORCH  : std_logic_vector(11 downto 0)  := conv_std_logic_vector(USR_HBACK_PORCH  , 12);
   constant USER_HPOLARITY    : std_logic                      := conv_std_logic_vector(USR_HPOLARITY    , 1)(0);
   constant USER_HMAX         : std_logic_vector(11 downto 0)  := conv_std_logic_vector(USR_HMAX         , 12);
   constant USER_VFRONT_PORCH : std_logic_vector(11 downto 0)  := conv_std_logic_vector(USR_VFRONT_PORCH , 12);
   constant USER_VBACK_PORCH  : std_logic_vector(11 downto 0)  := conv_std_logic_vector(USR_VBACK_PORCH  , 12);
   constant USER_VPOLARITY    : std_logic                      := conv_std_logic_vector(USR_VPOLARITY    , 1)(0);
   constant USER_VMAX         : std_logic_vector(11 downto 0)  := conv_std_logic_vector(USR_VMAX         , 12);

   constant DEFAULT_RED       : std_logic_vector(7 downto 0)  := conv_std_logic_vector(USR_RED           , 8);
   constant DEFAULT_GREEN     : std_logic_vector(7 downto 0)  := conv_std_logic_vector(USR_GREEN         , 8);
   constant DEFAULT_BLUE      : std_logic_vector(7 downto 0)  := conv_std_logic_vector(USR_BLUE          , 8);


   signal vga_running         : std_logic := '0';
   signal vga_active          : std_logic := '0';

   signal h_count             : std_logic_vector(11 downto 0) := (others =>'0');
   signal v_count             : std_logic_vector(11 downto 0) := (others =>'0');

   signal last_h_count        : std_logic := '0';

   signal h_sync_reg          : std_logic := '0';
   signal v_sync_reg          : std_logic := '0';
   signal h_sync_dly          : std_logic := '0';
   signal v_sync_dly          : std_logic := '0';

   signal fsync_reg           : std_logic := '0';

   signal video_dv            : std_logic := '0';
   signal video_dv_dly        : std_logic := '0';

begin

   debug_hcount      <= h_count;
   debug_vcount      <= v_count;
   debug_vga_active  <= vga_active;
   debug_vga_running <= vga_running;

   -- VGA frame generation starts when there is
   -- a valid clock
   process (pxl_clk)
   begin
      if rising_edge(pxl_clk) then
         if reset = '1' or locked = '0' then
            vga_running <= '0';
         else
            vga_running <= '1';
         end if;
      end if;
   end process;

   -- frame output is default colour (normally black)
   -- until data from VDMA is available
   -- If data stops being sent by dma then revert to default colour
   process (pxl_clk)
   begin
      if (rising_edge(pxl_clk)) then
         if vga_running = '0' or (video_dv = '1' and S_AXIS_TVALID = '0') then
            vga_active <= '0';
         elsif S_AXIS_TVALID = '1' then
            vga_active <= '1';
         end if;
      end if;
   end process;


  -- frame counters
   process (pxl_clk)
   begin
      if (rising_edge(pxl_clk)) then

         if (h_count = USER_HMAX - 2) then
            last_h_count <= '1';
         else
            last_h_count <= '0';
         end if;

         if vga_running = '0'  then
            h_count <= (others =>'0');
         elsif last_h_count = '1' then
            h_count <= (others => '0');
         else
            h_count <= h_count + 1;
         end if;

         if vga_running = '0' then
            v_count <= (others =>'0');
         elsif last_h_count = '1' then
            if v_count = USER_VMAX - 1 then
               v_count <= (others => '0');
            else
               v_count <= v_count + 1;
            end if;
         end if;

      end if;
   end process;

  -- Sync Generator
   process (pxl_clk, locked)
   begin
      if locked = '0' then
         h_sync_reg <= '0';
      elsif rising_edge(pxl_clk) then
         if vga_running = '1' then
            if (h_count >= USER_HSIZE + USER_HFRONT_PORCH) and (h_count < USER_HMAX - USER_HBACK_PORCH) then
               h_sync_reg <= USER_HPOLARITY;
            else
               h_sync_reg <= not(USER_HPOLARITY);
            end if;
         else
            h_sync_reg <= '0';
         end if;
      end if;
   end process;

   process (pxl_clk, locked)
   begin
      if locked = '0' then
         v_sync_reg <= '0';
      elsif (rising_edge(pxl_clk)) then
         if vga_running = '1' then
            if (v_count >= USER_VSIZE + USER_VFRONT_PORCH) and (v_count < USER_VMAX - USER_VBACK_PORCH) then
               v_sync_reg <= USER_VPOLARITY;
            else
               v_sync_reg <= not(USER_VPOLARITY);
            end if;
         else
            v_sync_reg <= '0';
         end if;
      end if;
   end process;

   process (pxl_clk, locked)
   begin
      if locked = '0' then
         v_sync_dly <= '0';
         h_sync_dly <= '0';
      elsif rising_edge(pxl_clk) then
         v_sync_dly <= v_sync_reg;
         h_sync_dly <= h_sync_reg;
      end if;
   end process;

   hsync <= h_sync_dly;
   vsync <= v_sync_dly;

   -- trigger fsync to VDMA after last pixel has been read out
   process (pxl_clk)
   begin
      if rising_edge(pxl_clk) then
         if (v_count = USER_VSIZE + 3) and last_h_count = '1' then
            fsync_reg <= '1';
         else
            fsync_reg <= '0';
         end if;
      end if;
   end process;

   fsync <= fsync_reg;

   -- data enable
   process (pxl_clk, locked)
   begin
      if locked = '0' then
         video_dv       <= '0';
         de             <= '0';
         s_axis_tready  <= '0';
      elsif rising_edge(pxl_clk) then

         if vga_running = '0' then
            video_dv       <= '0';
            de             <= '0';
         else

            -- video dv is actual data reads
            if (v_count < USER_VSIZE) and (h_count < USER_HSIZE) then
               video_dv <= '1';
            else
               video_dv <= '0';
            end if;

            -- s_axis_tready has 4 extra lines to dump extra data
            if (v_count < USER_VSIZE + 3) and (h_count < USER_HSIZE) then
               s_axis_tready <= '1';
            else
               s_axis_tready <= '0';
            end if;

            de <= video_dv;

         end if;
      end if;
   end process;

   -- output data
   process (pxl_clk)
   begin
      if rising_edge(pxl_clk) then
         if video_dv = '1' and vga_active = '1' then
            red       <= S_AXIS_TDATA(23 downto 16);
            green     <= S_AXIS_TDATA(15 downto 8);
            blue      <= S_AXIS_TDATA(7 downto 0);
         else
            red       <= DEFAULT_RED;
            green     <= DEFAULT_GREEN;
            blue      <= DEFAULT_BLUE;
         end if;
      end if;
   end process;

end RTL;
