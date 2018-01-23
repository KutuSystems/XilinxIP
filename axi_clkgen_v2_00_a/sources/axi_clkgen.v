// ***************************************************************************
// ***************************************************************************
// Copyright 2011(c) Analog Devices, Inc.
// 
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//     - Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     - Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in
//       the documentation and/or other materials provided with the
//       distribution.
//     - Neither the name of Analog Devices, Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//     - The use of this software may or may not infringe the patent rights
//       of one or more patent holders.  This license does not release you
//       from the requirement that you obtain separate licenses from these
//       patent holders to use this software.
//     - Use of the software either in source or binary form, must be run
//       on or directly connected to an Analog Devices Inc. component.
//    
// THIS SOFTWARE IS PROVIDED BY ANALOG DEVICES "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
// INCLUDING, BUT NOT LIMITED TO, NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
// PARTICULAR PURPOSE ARE DISCLAIMED.
//
// IN NO EVENT SHALL ANALOG DEVICES BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, INTELLECTUAL PROPERTY
// RIGHTS, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
// THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ***************************************************************************
// ***************************************************************************
// ***************************************************************************
// ***************************************************************************
// software programmable clock generator (still needs a reference input!)

module axi_clkgen (

  // clocks

  clk,
  clk_0,
  clk_1,
  drp_clk,

  // axi interface

  s_axi_aclk,
  s_axi_aresetn,
  s_axi_awvalid,
  s_axi_awaddr,
  s_axi_awready,
  s_axi_wvalid,
  s_axi_wdata,
  s_axi_wstrb,
  s_axi_wready,
  s_axi_bvalid,
  s_axi_bresp,
  s_axi_bready,
  s_axi_arvalid,
  s_axi_araddr,
  s_axi_arready,
  s_axi_rvalid,
  s_axi_rdata,
  s_axi_rresp,
  s_axi_rready);

  // parameters

  parameter   PCORE_ID = 0;
  parameter   PCORE_DEVICE_TYPE = 0;
  parameter   PCORE_CLKIN_PERIOD  = 5.0;
  parameter   PCORE_VCO_DIV = 11;
  parameter   PCORE_VCO_MUL = 49;
  parameter   PCORE_CLK0_DIV = 6;
  parameter   PCORE_CLK1_DIV = 6;
  parameter   C_S_AXI_MIN_SIZE = 32'hffff;

  // clocks

  input           clk;
  output          clk_0;
  output          clk_1;
  input           drp_clk;

  // axi interface

  input           s_axi_aclk;
  input           s_axi_aresetn;
  input           s_axi_awvalid;
  input   [31:0]  s_axi_awaddr;
  output          s_axi_awready;
  input           s_axi_wvalid;
  input   [31:0]  s_axi_wdata;
  input   [ 3:0]  s_axi_wstrb;
  output          s_axi_wready;
  output          s_axi_bvalid;
  output  [ 1:0]  s_axi_bresp;
  input           s_axi_bready;
  input           s_axi_arvalid;
  input   [31:0]  s_axi_araddr;
  output          s_axi_arready;
  output          s_axi_rvalid;
  output  [31:0]  s_axi_rdata;
  output  [ 1:0]  s_axi_rresp;
  input           s_axi_rready;

  // reset and clocks

  wire            mmcm_rst;
  wire            drp_rst;
  wire            up_rstn;
  wire            up_clk;

  // internal signals

  wire            drp_sel_s;
  wire            drp_wr_s;
  wire    [11:0]  drp_addr_s;
  wire    [15:0]  drp_wdata_s;
  wire    [15:0]  drp_rdata_s;
  wire            drp_ready_s;
  wire            drp_locked_s;
  wire            up_wreq_s;
  wire    [13:0]  up_waddr_s;
  wire    [31:0]  up_wdata_s;
  wire            up_wack_s;
  wire            up_rreq_s;
  wire    [13:0]  up_raddr_s;
  wire    [31:0]  up_rdata_s;
  wire            up_rack_s;

  // signal name changes

  assign up_clk = s_axi_aclk;
  assign up_rstn = s_axi_aresetn;

  // up bus interface

  up_axi_clkgen i_up_axi (
    .up_rstn (up_rstn),
    .up_clk (up_clk),
    .up_axi_awvalid (s_axi_awvalid),
    .up_axi_awaddr (s_axi_awaddr),
    .up_axi_awready (s_axi_awready),
    .up_axi_wvalid (s_axi_wvalid),
    .up_axi_wdata (s_axi_wdata),
    .up_axi_wstrb (s_axi_wstrb),
    .up_axi_wready (s_axi_wready),
    .up_axi_bvalid (s_axi_bvalid),
    .up_axi_bresp (s_axi_bresp),
    .up_axi_bready (s_axi_bready),
    .up_axi_arvalid (s_axi_arvalid),
    .up_axi_araddr (s_axi_araddr),
    .up_axi_arready (s_axi_arready),
    .up_axi_rvalid (s_axi_rvalid),
    .up_axi_rresp (s_axi_rresp),
    .up_axi_rdata (s_axi_rdata),
    .up_axi_rready (s_axi_rready),
    .up_wreq (up_wreq_s),
    .up_waddr (up_waddr_s),
    .up_wdata (up_wdata_s),
    .up_wack (up_wack_s),
    .up_rreq (up_rreq_s),
    .up_raddr (up_raddr_s),
    .up_rdata (up_rdata_s),
    .up_rack (up_rack_s));

  // processor interface

  up_clkgen i_up_clkgen (
    .mmcm_rst (mmcm_rst),
    .drp_clk (drp_clk),
    .drp_rst (drp_rst),
    .drp_sel (drp_sel_s),
    .drp_wr (drp_wr_s),
    .drp_addr (drp_addr_s),
    .drp_wdata (drp_wdata_s),
    .drp_rdata (drp_rdata_s),
    .drp_ready (drp_ready_s),
    .drp_locked (drp_locked_s),
    .up_rstn (up_rstn),
    .up_clk (up_clk),
    .up_wreq (up_wreq_s),
    .up_waddr (up_waddr_s),
    .up_wdata (up_wdata_s),
    .up_wack (up_wack_s),
    .up_rreq (up_rreq_s),
    .up_raddr (up_raddr_s),
    .up_rdata (up_rdata_s),
    .up_rack (up_rack_s));

  // mmcm instantiations

  ad_mmcm_drp #(
    .MMCM_DEVICE_TYPE (PCORE_DEVICE_TYPE),
    .MMCM_CLKIN_PERIOD (PCORE_CLKIN_PERIOD),
    .MMCM_VCO_DIV (PCORE_VCO_DIV),
    .MMCM_VCO_MUL (PCORE_VCO_MUL),
    .MMCM_CLK0_DIV (PCORE_CLK0_DIV),
    .MMCM_CLK1_DIV (PCORE_CLK1_DIV))
  i_mmcm_drp (
    .clk (clk),
    .mmcm_rst (mmcm_rst),
    .mmcm_clk_0 (clk_0),
    .mmcm_clk_1 (clk_1),
    .drp_clk (drp_clk),
    .drp_rst (drp_rst),
    .drp_sel (drp_sel_s),
    .drp_wr (drp_wr_s),
    .drp_addr (drp_addr_s),
    .drp_wdata (drp_wdata_s),
    .drp_rdata (drp_rdata_s),
    .drp_ready (drp_ready_s),
    .drp_locked (drp_locked_s));

endmodule

// ***************************************************************************
// ***************************************************************************
