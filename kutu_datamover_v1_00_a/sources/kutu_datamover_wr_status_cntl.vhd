  -------------------------------------------------------------------------------
  -- kutu_datamover_wr_status_cntl.vhd
  -------------------------------------------------------------------------------
  --
  -- *************************************************************************
  --
--  (c) Copyright 2010-2011 Xilinx, Inc. All rights reserved.
--
--  This file contains confidential and proprietary information
--  of Xilinx, Inc. and is protected under U.S. and
--  international copyright and other intellectual property
--  laws.
--
--  DISCLAIMER
--  This disclaimer is not a license and does not grant any
--  rights to the materials distributed herewith. Except as
--  otherwise provided in a valid license issued to you by
--  Xilinx, and to the maximum extent permitted by applicable
--  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
--  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
--  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
--  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
--  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
--  (2) Xilinx shall not be liable (whether in contract or tort,
--  including negligence, or under any other theory of
--  liability) for any loss or damage of any kind or nature
--  related to, arising under or in connection with these
--  materials, including for any direct, or any indirect,
--  special, incidental, or consequential loss or damage
--  (including loss of data, profits, goodwill, or any type of
--  loss or damage suffered as a result of any action brought
--  by a third party) even if such damage or loss was
--  reasonably foreseeable or Xilinx had been advised of the
--  possibility of the same.
--
--  CRITICAL APPLICATIONS
--  Xilinx products are not designed or intended to be fail-
--  safe, or for use in any application requiring fail-safe
--  performance, such as life-support or safety devices or
--  systems, Class III medical devices, nuclear facilities,
--  applications related to the deployment of airbags, or any
--  other applications that could lead to death, personal
--  injury, or severe property or environmental damage
--  (individually and collectively, "Critical
--  Applications"). Customer assumes the sole risk and
--  liability of any use of Xilinx products in Critical
--  Applications, subject only to applicable laws and
--  regulations governing limitations on product liability.
--
--  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
--  PART OF THIS FILE AT ALL TIMES.
  --
  -- *************************************************************************
  --
  -------------------------------------------------------------------------------
  -- Filename:        kutu_datamover_wr_status_cntl.vhd
  --
  -- Description:
  --    This file implements the DataMover Master Write Status Controller.
  --
  --
  --
  --
  -- VHDL-Standard:   VHDL'93
  -------------------------------------------------------------------------------
  -------------------------------------------------------------------------------
  library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

  library kutu_datamover_v5_1_9;
  use kutu_datamover_v5_1_9.kutu_datamover_fifo;

  -------------------------------------------------------------------------------

  entity kutu_datamover_wr_status_cntl is
    generic (

      C_SF_BYTES_RCVD_WIDTH  : Integer range  1 to  30 :=  1;
        -- Sets the width of the data2wsc_bytes_rcvd port used for
        -- relaying the actual number of bytes received when Idet BTT is
        -- enabled (C_ENABLE_INDET_BTT = 1)

      C_STS_FIFO_DEPTH       : Integer range  1 to  32 :=  8;
        -- Specifies the depth of the internal status queue fifo

      C_STS_WIDTH            : Integer range  8 to  32 :=  8;
        -- sets the width of the Status ports

      C_TAG_WIDTH            : Integer range  1 to 8   :=  4;
        -- Sets the width of the Tag field in the Status reply

      C_FAMILY               : String                  := "virtex7"
        -- Specifies the target FPGA device family


      );
    port (

      -- Clock and Reset inputs ------------------------------------------
                                                                        --
      primary_aclk         : in  std_logic;                             --
         -- Primary synchronization clock for the Master side           --
         -- interface and internal logic. It is also used               --
         -- for the User interface synchronization when                 --
         -- C_STSCMD_IS_ASYNC = 0.                                      --
                                                                        --
      -- Reset input                                                    --
      mmap_reset           : in  std_logic;                             --
         -- Reset used for the internal master logic                    --
      --------------------------------------------------------------------




      -- Soft Shutdown Control interface  --------------------------------
                                                                        --
                                                                        --
      addr2wsc_addr_posted : In std_logic ;                             --
         -- Indication from the Address Channel Controller to the       --
         -- write Status Controller that an address has been posted     --
         -- to the AXI Address Channel                                  --
      --------------------------------------------------------------------




      --  Write Response Channel Interface -------------------------------
                                                                        --
      s2mm_bresp          : In std_logic_vector(1 downto 0);            --
         -- The Write response value                                    --
                                                                        --
      s2mm_bvalid         : In std_logic ;                              --
         -- Indication from the Write Response Channel that a new       --
         -- write status input is valid                                 --
                                                                        --
      s2mm_bready         : out std_logic ;                             --
         -- Indication to the Write Response Channel that the           --
         -- Status module is ready for a new status input               --
      --------------------------------------------------------------------


      -- Address Controller Status ----------------------------------------
                                                                         --
      addr2wsc_calc_error    : In std_logic ;                            --
         -- Indication from the Address Channel Controller that it       --
         -- has encountered a calculation error from the command         --
         -- Calculator                                                   --
                                                                         --
      addr2wsc_fifo_empty    : In std_logic ;                            --
         -- Indication from the Address Controller FIFO that it          --
         -- is empty (no commands pending)                               --
      ---------------------------------------------------------------------




      --  Data Controller Status ---------------------------------------------------------
                                                                                        --
      data2wsc_tag           : In std_logic_vector(C_TAG_WIDTH-1 downto 0);             --
         -- The command tag                                                             --
                                                                                        --
      data2wsc_calc_error    : In std_logic ;                                           --
         -- Indication from the Data Channel Controller FIFO that it                    --
         -- has encountered a Calculation error in the command pipe                     --
                                                                                        --
      data2wsc_last_error    : In std_logic ;                                           --
         -- Indication from the Write Data Channel Controller that a                    --
         -- premature TLAST assertion was encountered on the incoming                   --
         -- Stream Channel                                                              --
                                                                                        --
      data2wsc_cmd_cmplt    : In std_logic ;                                            --
         -- Indication from the Data Channel Controller that the                        --
         -- corresponding status is the final status for a parent                       --
         -- command fetched from the command FIFO                                       --
                                                                                        --
      data2wsc_valid         : In std_logic ;                                           --
         -- Indication from the Data Channel Controller FIFO that it                    --
         -- has a new tag/error status to transfer                                      --
                                                                                        --
      wsc2data_ready         : out std_logic ;                                          --
         -- Indication to the Data Channel Controller FIFO that the                     --
         -- Status module is ready for a new tag/error status input                     --
                                                                                        --
                                                                                        --
      data2wsc_eop           : In  std_logic;                                           --
         -- Input from the Write Data Controller indicating that the                    --
         -- associated command status also corresponds to a End of Packet               --
         -- marker for the input Stream. This is only used when Store and               --
         -- Forward is enabled in the S2MM.                                             --
                                                                                        --
      data2wsc_bytes_rcvd    : In  std_logic_vector(C_SF_BYTES_RCVD_WIDTH-1 downto 0);  --
         -- Input from the Write Data Controller indicating the actual                  --
         -- number of bytes received from the Stream input for the                      --
         -- corresponding command status. This is only used when Store and              --
         -- Forward is enabled in the S2MM.                                             --
      ------------------------------------------------------------------------------------



      -- Command/Status Interface --------------------------------------------------------
                                                                                        --
      wsc2stat_status       : Out std_logic_vector(C_STS_WIDTH-1 downto 0);             --
         -- Read Status value collected during a Read Data transfer                     --
         -- Output to the Command/Status Module                                         --
                                                                                        --
      stat2wsc_status_ready : In  std_logic;                                            --
         -- Input from the Command/Status Module indicating that the                    --
         -- Status Reg/FIFO is Full and cannot accept more staus writes                 --
                                                                                        --
      wsc2stat_status_valid : Out std_logic ;                                           --
         -- Control Signal to Write the Status value to the Status                      --
         -- Reg/FIFO                                                                    --
      ------------------------------------------------------------------------------------




      -- Address and Data Controller Pipe halt --------------------------------
                                                                             --
      wsc2mstr_halt_pipe    : Out std_logic                                  --
         -- Indication to Halt the Data and Address Command pipeline due     --
         -- to the Status pipe getting full at some point                    --
      -------------------------------------------------------------------------


      );

  end entity kutu_datamover_wr_status_cntl;


  architecture implementation of kutu_datamover_wr_status_cntl is
  attribute DowngradeIPIdentifiedWarnings: string;
  attribute DowngradeIPIdentifiedWarnings of implementation : architecture is "yes";



    -------------------------------------------------------------------
    -- Function
    --
    -- Function Name: funct_set_cnt_width
    --
    -- Function Description:
    --    Sets a count width based on a fifo depth. A depth of 4 or less
    -- is a special case which requires a minimum count width of 3 bits.
    --
    -------------------------------------------------------------------
    function funct_set_cnt_width (fifo_depth : integer) return integer is

      Variable temp_cnt_width : Integer := 4;

    begin


      if (fifo_depth <= 4) then

         temp_cnt_width := 3;

      elsif (fifo_depth <= 8) then

         temp_cnt_width := 4;

      elsif (fifo_depth <= 16) then

         temp_cnt_width := 5;

      elsif (fifo_depth <= 32) then

         temp_cnt_width := 6;

      else  -- fifo depth <= 64

         temp_cnt_width := 7;

      end if;

      Return (temp_cnt_width);


    end function funct_set_cnt_width;





    -- Constant Declarations  --------------------------------------------

    Constant OKAY                   : std_logic_vector(1 downto 0) := "00";
    Constant EXOKAY                 : std_logic_vector(1 downto 0) := "01";
    Constant SLVERR                 : std_logic_vector(1 downto 0) := "10";
    Constant DECERR                 : std_logic_vector(1 downto 0) := "11";
    Constant STAT_RSVD              : std_logic_vector(3 downto 0) := "0000";
    Constant TAG_WIDTH              : integer := C_TAG_WIDTH;
    Constant STAT_REG_TAG_WIDTH     : integer := 4;
    Constant SYNC_FIFO_SELECT       : integer := 0;
    Constant SRL_FIFO_TYPE          : integer := 2;
    Constant DCNTL_SFIFO_DEPTH      : integer := C_STS_FIFO_DEPTH;
    Constant DCNTL_STATCNT_WIDTH    : integer := funct_set_cnt_width(C_STS_FIFO_DEPTH);-- bits
    Constant DCNTL_HALT_THRES       : unsigned(DCNTL_STATCNT_WIDTH-1 downto 0) :=
                                      TO_UNSIGNED(DCNTL_SFIFO_DEPTH-2,DCNTL_STATCNT_WIDTH);
    Constant DCNTL_STATCNT_ZERO     : unsigned(DCNTL_STATCNT_WIDTH-1 downto 0) := (others => '0');
    Constant DCNTL_STATCNT_MAX      : unsigned(DCNTL_STATCNT_WIDTH-1 downto 0) :=
                                      TO_UNSIGNED(DCNTL_SFIFO_DEPTH,DCNTL_STATCNT_WIDTH);
    Constant DCNTL_STATCNT_ONE      : unsigned(DCNTL_STATCNT_WIDTH-1 downto 0) :=
                                      TO_UNSIGNED(1, DCNTL_STATCNT_WIDTH);
    Constant WRESP_WIDTH            : integer := 2;
    Constant WRESP_SFIFO_WIDTH      : integer := WRESP_WIDTH;
    Constant WRESP_SFIFO_DEPTH      : integer := DCNTL_SFIFO_DEPTH;

    Constant ADDR_POSTED_CNTR_WIDTH : integer := funct_set_cnt_width(C_STS_FIFO_DEPTH);-- bits


    Constant ADDR_POSTED_ZERO       : unsigned(ADDR_POSTED_CNTR_WIDTH-1 downto 0)
                                      := (others => '0');
    Constant ADDR_POSTED_ONE        : unsigned(ADDR_POSTED_CNTR_WIDTH-1 downto 0)
                                      := TO_UNSIGNED(1, ADDR_POSTED_CNTR_WIDTH);
    Constant ADDR_POSTED_MAX        : unsigned(ADDR_POSTED_CNTR_WIDTH-1 downto 0)
                                      := (others => '1');


    -- Signal Declarations  --------------------------------------------

    signal sig_valid_status_rdy      : std_logic := '0';
    signal sig_decerr                : std_logic := '0';
    signal sig_slverr                : std_logic := '0';
    signal sig_coelsc_okay_reg       : std_logic := '0';
    signal sig_coelsc_interr_reg     : std_logic := '0';
    signal sig_coelsc_decerr_reg     : std_logic := '0';
    signal sig_coelsc_slverr_reg     : std_logic := '0';
    signal sig_coelsc_tag_reg        : std_logic_vector(TAG_WIDTH-1 downto 0) := (others => '0');
    signal sig_pop_coelsc_reg        : std_logic := '0';
    signal sig_push_coelsc_reg       : std_logic := '0';
    signal sig_tag2status            : std_logic_vector(TAG_WIDTH-1 downto 0) := (others => '0');
    signal sig_data_tag_reg          : std_logic_vector(TAG_WIDTH-1 downto 0) := (others => '0');
    signal sig_data_err_reg          : std_logic := '0';
    signal sig_data_last_err_reg     : std_logic := '0';
    signal sig_data_cmd_cmplt_reg    : std_logic := '0';
    signal sig_bresp_reg             : std_logic_vector(1 downto 0) := (others => '0');
    signal sig_push_status           : std_logic := '0';
    Signal sig_status_push_ok        : std_logic := '0';
    signal sig_status_valid          : std_logic := '0';
    signal sig_wsc2data_ready        : std_logic := '0';
    signal sig_s2mm_bready           : std_logic := '0';
    signal sig_wresp_sfifo_in        : std_logic_vector(WRESP_SFIFO_WIDTH-1 downto 0) := (others => '0');
    signal sig_wresp_sfifo_out       : std_logic_vector(WRESP_SFIFO_WIDTH-1 downto 0) := (others => '0');
    signal sig_wresp_sfifo_wr_valid  : std_logic := '0';
    signal sig_wresp_sfifo_wr_ready  : std_logic := '0';
    signal sig_wresp_sfifo_wr_full   : std_logic := '0';
    signal sig_wresp_sfifo_rd_valid  : std_logic := '0';
    signal sig_wresp_sfifo_rd_ready  : std_logic := '0';
    signal sig_wresp_sfifo_rd_empty  : std_logic := '0';
    signal sig_addr_posted_cntr      : unsigned(ADDR_POSTED_CNTR_WIDTH-1 downto 0) := (others => '0');
    signal sig_addr_posted_cntr_eq_0 : std_logic := '0';
    signal sig_addr_posted_cntr_eq_1 : std_logic := '0';
    signal sig_addr_posted_cntr_max  : std_logic := '0';
    signal sig_decr_addr_posted_cntr : std_logic := '0';
    signal sig_incr_addr_posted_cntr : std_logic := '0';
    signal sig_no_posted_cmds        : std_logic := '0';
    signal sig_addr_posted           : std_logic := '0';
    signal sig_all_cmds_done         : std_logic := '0';
    signal sig_wsc2stat_status       : std_logic_vector(C_STS_WIDTH-1 downto 0) := (others => '0');
    signal sig_dcntl_sfifo_wr_valid  : std_logic := '0';
    signal sig_dcntl_sfifo_wr_ready  : std_logic := '0';
    signal sig_dcntl_sfifo_wr_full   : std_logic := '0';
    signal sig_dcntl_sfifo_rd_valid  : std_logic := '0';
    signal sig_dcntl_sfifo_rd_ready  : std_logic := '0';
    signal sig_dcntl_sfifo_rd_empty  : std_logic := '0';
    signal sig_wdc_statcnt           : unsigned(DCNTL_STATCNT_WIDTH-1 downto 0) := (others => '0');
    signal sig_incr_statcnt          : std_logic := '0';
    signal sig_decr_statcnt          : std_logic := '0';
    signal sig_statcnt_eq_max        : std_logic := '0';
    signal sig_statcnt_eq_0          : std_logic := '0';
    signal sig_statcnt_gt_eq_thres   : std_logic := '0';
    signal sig_wdc_status_going_full : std_logic := '0';


       Constant DCNTL_SFIFO_WIDTH           : integer := STAT_REG_TAG_WIDTH+3;
       Constant DCNTL_SFIFO_CMD_CMPLT_INDEX : integer := 0;
       Constant DCNTL_SFIFO_TLAST_ERR_INDEX : integer := 1;
       Constant DCNTL_SFIFO_CALC_ERR_INDEX  : integer := 2;
       Constant DCNTL_SFIFO_TAG_INDEX       : integer := DCNTL_SFIFO_CALC_ERR_INDEX+1;


       -- local signals
       signal sig_dcntl_sfifo_in        : std_logic_vector(DCNTL_SFIFO_WIDTH-1 downto 0) := (others => '0');
       signal sig_dcntl_sfifo_out       : std_logic_vector(DCNTL_SFIFO_WIDTH-1 downto 0) := (others => '0');



  begin --(architecture implementation)


    -- Assign the ready output to the AXI Write Response Channel
    s2mm_bready           <= sig_s2mm_bready;

    -- Assign the ready output to the Data Controller status interface
    wsc2data_ready        <= sig_wsc2data_ready;

    -- Assign the status valid output control to the Status FIFO
    wsc2stat_status_valid <= sig_status_valid ;

    -- Formulate the status output value to the Status FIFO
    wsc2stat_status       <=  sig_wsc2stat_status;


    -- Formulate the status write request signal
    sig_status_valid      <= sig_push_status;



    -- Indicate the desire to push a coelesced status word
    -- to the Status FIFO
    sig_push_status       <= '0';



    -- Detect that a push of a new status word is completing
    sig_status_push_ok    <= sig_status_valid and
                             stat2wsc_status_ready;

    sig_pop_coelsc_reg    <= sig_status_push_ok;


    -- Signal a halt to the execution pipe if new status
    -- is valid but the Status FIFO is not accepting it or
    -- the WDC Status FIFO is going full
    wsc2mstr_halt_pipe    <= (sig_status_valid and
                             not(stat2wsc_status_ready)) or
                             sig_wdc_status_going_full;


    -- Monitor the Status capture registers to detect a
    -- qualified Status set and push to the coelescing register
    -- when available to do so
    sig_push_coelsc_reg   <= sig_valid_status_rdy;

    --    pre CR616212  sig_valid_status_rdy  <= (sig_wresp_sfifo_rd_valid  and
    --    pre CR616212                            sig_dcntl_sfifo_rd_valid) or
    --    pre CR616212                           (sig_data_err_reg and
    --    pre CR616212                            sig_dcntl_sfifo_rd_valid);

    sig_valid_status_rdy  <= (sig_wresp_sfifo_rd_valid  and
                              sig_dcntl_sfifo_rd_valid) or
                             (sig_data_err_reg and
                              sig_dcntl_sfifo_rd_valid) or  -- or Added for CR616212
                             (sig_data_last_err_reg and     -- Added for CR616212
                              sig_dcntl_sfifo_rd_valid);    -- Added for CR616212




    -- Decode the AXI MMap Read Respose
    sig_decerr  <= '1'
      When sig_bresp_reg = DECERR
      Else '0';

    sig_slverr  <= '1'
      When sig_bresp_reg = SLVERR
      Else '0';




    ------------------------------------------------------------
    -- If Generate
    --
    -- Label: GEN_TAG_LE_STAT
    --
    -- If Generate Description:
    -- Populates the TAG bits into the availble Status bits when
    -- the TAG width is less than or equal to the available number
    -- of bits in the Status word.
    --
    ------------------------------------------------------------
    GEN_TAG_LE_STAT : if (TAG_WIDTH <= STAT_REG_TAG_WIDTH) generate

       -- local signals
         signal lsig_temp_tag_small : std_logic_vector(STAT_REG_TAG_WIDTH-1 downto 0) := (others => '0');


       begin

         sig_tag2status <= lsig_temp_tag_small;



         -------------------------------------------------------------
         -- Combinational Process
         --
         -- Label: POPULATE_SMALL_TAG
         --
         -- Process Description:
         --
         --
         -------------------------------------------------------------
         POPULATE_SMALL_TAG : process (sig_coelsc_tag_reg)
            begin

              -- Set default value
              lsig_temp_tag_small <= (others => '0');

              -- Now overload actual TAG bits
              lsig_temp_tag_small(TAG_WIDTH-1 downto 0) <= sig_coelsc_tag_reg;


            end process POPULATE_SMALL_TAG;


       end generate GEN_TAG_LE_STAT;





    ------------------------------------------------------------
    -- If Generate
    --
    -- Label: GEN_TAG_GT_STAT
    --
    -- If Generate Description:
    -- Populates the TAG bits into the availble Status bits when
    -- the TAG width is greater than the available number of
    -- bits in the Status word. The upper bits of the TAG are
    -- clipped off (discarded).
    --
    ------------------------------------------------------------
    GEN_TAG_GT_STAT : if (TAG_WIDTH > STAT_REG_TAG_WIDTH) generate

       -- local signals
         signal lsig_temp_tag_big : std_logic_vector(STAT_REG_TAG_WIDTH-1 downto 0) := (others => '0');


       begin


         sig_tag2status <= lsig_temp_tag_big;


         -------------------------------------------------------------
         -- Combinational Process
         --
         -- Label: POPULATE_BIG_TAG
         --
         -- Process Description:
         --
         --
         -------------------------------------------------------------
         POPULATE_SMALL_TAG : process (sig_coelsc_tag_reg)
            begin

              -- Set default value
              lsig_temp_tag_big <= (others => '0');

              -- Now overload actual TAG bits
              lsig_temp_tag_big <= sig_coelsc_tag_reg(STAT_REG_TAG_WIDTH-1 downto 0);


            end process POPULATE_SMALL_TAG;


       end generate GEN_TAG_GT_STAT;

















    -------------------------------------------------------------------------
    -- Write Response Channel input FIFO and logic


    -- BRESP is the only fifo data
    sig_wresp_sfifo_in       <=  s2mm_bresp;


    -- The fifo output is already in the right format
    sig_bresp_reg            <=  sig_wresp_sfifo_out;


    -- Write Side assignments
    sig_wresp_sfifo_wr_valid <=  s2mm_bvalid;

    sig_s2mm_bready          <=  sig_wresp_sfifo_wr_ready;


    -- read Side ready assignment
    sig_wresp_sfifo_rd_ready <=  sig_push_coelsc_reg;



    ------------------------------------------------------------
    -- Instance: I_WRESP_STATUS_FIFO
    --
    -- Description:
    -- Instance for the AXI Write Response FIFO
    --
    ------------------------------------------------------------
     I_WRESP_STATUS_FIFO : entity kutu_datamover_v5_1_9.kutu_datamover_fifo
     generic map (

       C_DWIDTH             =>  WRESP_SFIFO_WIDTH         ,
       C_DEPTH              =>  WRESP_SFIFO_DEPTH         ,
       C_IS_ASYNC           =>  SYNC_FIFO_SELECT          ,
       C_PRIM_TYPE          =>  SRL_FIFO_TYPE             ,
       C_FAMILY             =>  C_FAMILY

       )
     port map (

       -- Write Clock and reset
       fifo_wr_reset        =>   mmap_reset               ,
       fifo_wr_clk          =>   primary_aclk             ,

       -- Write Side
       fifo_wr_tvalid       =>   sig_wresp_sfifo_wr_valid ,
       fifo_wr_tready       =>   sig_wresp_sfifo_wr_ready ,
       fifo_wr_tdata        =>   sig_wresp_sfifo_in       ,
       fifo_wr_full         =>   sig_wresp_sfifo_wr_full  ,


       -- Read Clock and reset (not used in Sync mode)
       fifo_async_rd_reset  =>   mmap_reset               ,
       fifo_async_rd_clk    =>   primary_aclk             ,

       -- Read Side
       fifo_rd_tvalid       =>   sig_wresp_sfifo_rd_valid ,
       fifo_rd_tready       =>   sig_wresp_sfifo_rd_ready ,
       fifo_rd_tdata        =>   sig_wresp_sfifo_out      ,
       fifo_rd_empty        =>   sig_wresp_sfifo_rd_empty

       );



    --------  Write Data Controller Status FIFO Going Full Logic -------------


    sig_incr_statcnt   <= sig_dcntl_sfifo_wr_valid and
                          sig_dcntl_sfifo_wr_ready;

    sig_decr_statcnt   <= sig_dcntl_sfifo_rd_valid and
                          sig_dcntl_sfifo_rd_ready;


    sig_statcnt_eq_max <= '1'
      when (sig_wdc_statcnt = DCNTL_STATCNT_MAX)
      Else '0';

    sig_statcnt_eq_0   <= '1'
      when (sig_wdc_statcnt = DCNTL_STATCNT_ZERO)
      Else '0';

    sig_statcnt_gt_eq_thres <= '1'
      when (sig_wdc_statcnt >= DCNTL_HALT_THRES)
      Else '0';


    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: IMP_WDC_GOING_FULL_FLOP
    --
    -- Process Description:
    --  Implements a flop for the WDC Status FIFO going full flag.
    --
    -------------------------------------------------------------
    IMP_WDC_GOING_FULL_FLOP : process (primary_aclk)
      begin
        if (primary_aclk'event and primary_aclk = '1') then
           if (mmap_reset = '1') then

             sig_wdc_status_going_full <= '0';

           else

             sig_wdc_status_going_full <= sig_statcnt_gt_eq_thres;

           end if;
        end if;
      end process IMP_WDC_GOING_FULL_FLOP;



    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: IMP_DCNTL_FIFO_CNTR
    --
    -- Process Description:
    --   Implements a simple counter keeping track of the number
    -- of entries in the WDC Status FIFO. If the Status FIFO gets
    -- too full, the S2MM Data Pipe has to be halted.
    --
    -------------------------------------------------------------
    IMP_DCNTL_FIFO_CNTR : process (primary_aclk)
      begin
        if (primary_aclk'event and primary_aclk = '1') then
           if (mmap_reset = '1') then

             sig_wdc_statcnt <= (others => '0');

           elsif (sig_incr_statcnt   = '1' and
                  sig_decr_statcnt   = '0' and
                  sig_statcnt_eq_max = '0') then

             sig_wdc_statcnt <= sig_wdc_statcnt + DCNTL_STATCNT_ONE;

           elsif (sig_incr_statcnt = '0' and
                  sig_decr_statcnt = '1' and
                  sig_statcnt_eq_0 = '0') then

             sig_wdc_statcnt <= sig_wdc_statcnt - DCNTL_STATCNT_ONE;

           else

             null; -- Hold current count value

           end if;
        end if;
      end process IMP_DCNTL_FIFO_CNTR;



         sig_wsc2stat_status       <=  sig_coelsc_okay_reg    &
                                       sig_coelsc_slverr_reg  &
                                       sig_coelsc_decerr_reg  &
                                       sig_coelsc_interr_reg  &
                                       sig_tag2status;



         -----------------------------------------------------------------------------
         -- Data Controller Status FIFO and Logic


         -- Concatonate Input bits to build Dcntl fifo data word
         sig_dcntl_sfifo_in      <=  data2wsc_tag        &   -- bit 3 to tag Width+2
                                     data2wsc_calc_error &   -- bit 2
                                     data2wsc_last_error &   -- bit 1
                                     data2wsc_cmd_cmplt  ;   -- bit 0


         -- Rip the DCntl fifo outputs back to constituant pieces
         sig_data_tag_reg        <= sig_dcntl_sfifo_out((DCNTL_SFIFO_TAG_INDEX+STAT_REG_TAG_WIDTH)-1 downto
                                                        DCNTL_SFIFO_TAG_INDEX);

         sig_data_err_reg        <= sig_dcntl_sfifo_out(DCNTL_SFIFO_CALC_ERR_INDEX) ;

         sig_data_last_err_reg   <= sig_dcntl_sfifo_out(DCNTL_SFIFO_TLAST_ERR_INDEX);

         sig_data_cmd_cmplt_reg  <= sig_dcntl_sfifo_out(DCNTL_SFIFO_CMD_CMPLT_INDEX);



         -- Data Control Valid/Ready assignments
         sig_dcntl_sfifo_wr_valid <= data2wsc_valid     ;

         sig_wsc2data_ready       <= sig_dcntl_sfifo_wr_ready;



         -- read side ready assignment
         sig_dcntl_sfifo_rd_ready <= sig_push_coelsc_reg;



         ------------------------------------------------------------
         -- Instance: I_DATA_CNTL_STATUS_FIFO
         --
         -- Description:
         -- Instance for the Command Qualifier FIFO
         --
         ------------------------------------------------------------
          I_DATA_CNTL_STATUS_FIFO : entity kutu_datamover_v5_1_9.kutu_datamover_fifo
          generic map (

            C_DWIDTH             =>  DCNTL_SFIFO_WIDTH         ,
            C_DEPTH              =>  DCNTL_SFIFO_DEPTH         ,
            C_IS_ASYNC           =>  SYNC_FIFO_SELECT          ,
            C_PRIM_TYPE          =>  SRL_FIFO_TYPE             ,
            C_FAMILY             =>  C_FAMILY

            )
          port map (

            -- Write Clock and reset
            fifo_wr_reset        =>   mmap_reset               ,
            fifo_wr_clk          =>   primary_aclk             ,

            -- Write Side
            fifo_wr_tvalid       =>   sig_dcntl_sfifo_wr_valid ,
            fifo_wr_tready       =>   sig_dcntl_sfifo_wr_ready ,
            fifo_wr_tdata        =>   sig_dcntl_sfifo_in       ,
            fifo_wr_full         =>   sig_dcntl_sfifo_wr_full  ,


            -- Read Clock and reset (not used in Sync mode)
            fifo_async_rd_reset  =>   mmap_reset               ,
            fifo_async_rd_clk    =>   primary_aclk             ,

            -- Read Side
            fifo_rd_tvalid       =>   sig_dcntl_sfifo_rd_valid ,
            fifo_rd_tready       =>   sig_dcntl_sfifo_rd_ready ,
            fifo_rd_tdata        =>   sig_dcntl_sfifo_out      ,
            fifo_rd_empty        =>   sig_dcntl_sfifo_rd_empty

            );









         -------------------------------------------------------------
         -- Synchronous Process with Sync Reset
         --
         -- Label: STATUS_COELESC_REG
         --
         -- Process Description:
         --   Implement error status coelescing register.
         -- Once a bit is set it will remain set until the overall
         -- status is written to the Status FIFO.
         -- Tag bits are just registered at each valid dbeat.
         --
         -------------------------------------------------------------
         STATUS_COELESC_REG : process (primary_aclk)
            begin
              if (primary_aclk'event and primary_aclk = '1') then
                 if (mmap_reset         = '1' or
                     sig_pop_coelsc_reg = '1') then

                   sig_coelsc_tag_reg       <= (others => '0');
                   sig_coelsc_interr_reg    <= '0';
                   sig_coelsc_decerr_reg    <= '0';
                   sig_coelsc_slverr_reg    <= '0';
                   sig_coelsc_okay_reg      <= '1'; -- set back to default of "OKAY"


                 Elsif (sig_push_coelsc_reg = '1') Then

                   sig_coelsc_tag_reg       <= sig_data_tag_reg;
                   sig_coelsc_interr_reg    <= sig_data_err_reg      or
                                               sig_data_last_err_reg or
                                               sig_coelsc_interr_reg;
                   sig_coelsc_decerr_reg    <= not(sig_data_err_reg) and
                                               (sig_decerr           or
                                                sig_coelsc_decerr_reg);
                   sig_coelsc_slverr_reg    <= not(sig_data_err_reg) and
                                               (sig_slverr           or
                                                sig_coelsc_slverr_reg);
                   sig_coelsc_okay_reg      <= not(sig_decerr            or
                                                   sig_coelsc_decerr_reg or
                                                   sig_slverr            or
                                                   sig_coelsc_slverr_reg or
                                                   sig_data_err_reg      or
                                                   sig_data_last_err_reg or
                                                   sig_coelsc_interr_reg
                                                   );

                 else

                   null;  -- hold current state

                 end if;
              end if;
            end process STATUS_COELESC_REG;





   -------  Soft Shutdown Logic -------------------------------




   -- Address Posted Counter Logic ---------------------t-----------------
   -- Supports soft shutdown by tracking when all commited Write
   -- transfers to the AXI Bus have had corresponding Write Status
   -- Reponses Received.


    sig_addr_posted           <= addr2wsc_addr_posted ;

    sig_incr_addr_posted_cntr <= sig_addr_posted      ;

    sig_decr_addr_posted_cntr <= sig_s2mm_bready  and
                                 s2mm_bvalid          ;

    sig_addr_posted_cntr_eq_0 <= '1'
      when (sig_addr_posted_cntr = ADDR_POSTED_ZERO)
      Else '0';

    sig_addr_posted_cntr_eq_1 <= '1'
      when (sig_addr_posted_cntr = ADDR_POSTED_ONE)
      Else '0';


    sig_addr_posted_cntr_max <= '1'
      when (sig_addr_posted_cntr = ADDR_POSTED_MAX)
      Else '0';




    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: IMP_ADDR_POSTED_FIFO_CNTR
    --
    -- Process Description:
    --    This process implements a counter for the tracking
    -- if an Address has been posted on the AXI address channel.
    -- The counter is used to track flushing operations where all
    -- transfers committed on the AXI Address Channel have to
    --  be completed before a halt can occur.
    -------------------------------------------------------------
    IMP_ADDR_POSTED_FIFO_CNTR : process (primary_aclk)
       begin
         if (primary_aclk'event and primary_aclk = '1') then
            if (mmap_reset = '1') then

              sig_addr_posted_cntr <= ADDR_POSTED_ZERO;

            elsif (sig_incr_addr_posted_cntr = '1' and
                   sig_decr_addr_posted_cntr = '0' and
                   sig_addr_posted_cntr_max  = '0') then

              sig_addr_posted_cntr <= sig_addr_posted_cntr + ADDR_POSTED_ONE ;

            elsif (sig_incr_addr_posted_cntr = '0' and
                   sig_decr_addr_posted_cntr = '1' and
                   sig_addr_posted_cntr_eq_0 = '0') then

              sig_addr_posted_cntr <= sig_addr_posted_cntr - ADDR_POSTED_ONE ;

            else
              null;  -- don't change state
            end if;
         end if;
       end process IMP_ADDR_POSTED_FIFO_CNTR;




    sig_no_posted_cmds <= (sig_addr_posted_cntr_eq_0 and
                            not(addr2wsc_calc_error)) or
                           (sig_addr_posted_cntr_eq_1 and
                            addr2wsc_calc_error);



  end implementation;
