
################################################################
# This is a generated script based on design: system_top
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2015.4
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   puts "ERROR: This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source system_top_script.tcl

# If you do not already have a project created,
# you can create a project using the following command:
#    create_project project_1 myproj -part xc7k325tffg900-2
#    set_property BOARD_PART xilinx.com:kc705:part0:1.2 [current_project]

# CHECKING IF PROJECT EXISTS
if { [get_projects -quiet] eq "" } {
   puts "ERROR: Please open or create a project!"
   return 1
}



# CHANGE DESIGN NAME HERE
set design_name system_top

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "ERROR: Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      puts "INFO: Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   puts "INFO: Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "ERROR: Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "ERROR: Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   puts "INFO: Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   puts "INFO: Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

puts "INFO: Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   puts $errMsg
   return $nRet
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     puts "ERROR: Unable to find parent cell <$parentCell>!"
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set m_axis_mm2s [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_mm2s ]
  set_property -dict [ list \
CONFIG.FREQ_HZ {100000000} \
 ] $m_axis_mm2s
  set s_axis_mm2s_cmd [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_mm2s_cmd ]
  set_property -dict [ list \
CONFIG.FREQ_HZ {100000000} \
CONFIG.HAS_TKEEP {0} \
CONFIG.HAS_TLAST {0} \
CONFIG.HAS_TREADY {1} \
CONFIG.HAS_TSTRB {0} \
CONFIG.LAYERED_METADATA {undef} \
CONFIG.PHASE {0.000} \
CONFIG.TDATA_NUM_BYTES {8} \
CONFIG.TDEST_WIDTH {0} \
CONFIG.TID_WIDTH {0} \
CONFIG.TUSER_WIDTH {0} \
 ] $s_axis_mm2s_cmd
  set s_axis_s2mm [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_s2mm ]
  set_property -dict [ list \
CONFIG.FREQ_HZ {100000000} \
CONFIG.HAS_TKEEP {1} \
CONFIG.HAS_TLAST {1} \
CONFIG.HAS_TREADY {1} \
CONFIG.HAS_TSTRB {0} \
CONFIG.LAYERED_METADATA {undef} \
CONFIG.PHASE {0.000} \
CONFIG.TDATA_NUM_BYTES {8} \
CONFIG.TDEST_WIDTH {0} \
CONFIG.TID_WIDTH {0} \
CONFIG.TUSER_WIDTH {0} \
 ] $s_axis_s2mm
  set s_axis_s2mm_cmd [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_s2mm_cmd ]
  set_property -dict [ list \
CONFIG.FREQ_HZ {100000000} \
CONFIG.HAS_TKEEP {0} \
CONFIG.HAS_TLAST {0} \
CONFIG.HAS_TREADY {1} \
CONFIG.HAS_TSTRB {0} \
CONFIG.LAYERED_METADATA {undef} \
CONFIG.PHASE {0.000} \
CONFIG.TDATA_NUM_BYTES {8} \
CONFIG.TDEST_WIDTH {0} \
CONFIG.TID_WIDTH {0} \
CONFIG.TUSER_WIDTH {0} \
 ] $s_axis_s2mm_cmd

  # Create ports
  set mm2s_err [ create_bd_port -dir O mm2s_err ]
  set s2mm_err [ create_bd_port -dir O s2mm_err ]
  set s_axis_aclk [ create_bd_port -dir I -type clk s_axis_aclk ]
  set_property -dict [ list \
CONFIG.ASSOCIATED_BUSIF {m_axis_mm2s:s_axis_s2mm} \
CONFIG.FREQ_HZ {100000000} \
 ] $s_axis_aclk
  set s_axis_aresetn [ create_bd_port -dir I -type rst s_axis_aresetn ]
  set s_axis_mm2s_cmd_aclk [ create_bd_port -dir I -type clk s_axis_mm2s_cmd_aclk ]
  set s_axis_mm2s_cmd_aresetn [ create_bd_port -dir I -type rst s_axis_mm2s_cmd_aresetn ]
  set s_axis_s2mm_cmd_aclk [ create_bd_port -dir I -type clk s_axis_s2mm_cmd_aclk ]
  set s_axis_s2mm_cmd_aresetn [ create_bd_port -dir I -type rst s_axis_s2mm_cmd_aresetn ]

  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_0 ]
  set_property -dict [ list \
CONFIG.DATA_WIDTH {64} \
CONFIG.ECC_TYPE {0} \
CONFIG.SINGLE_PORT_BRAM {1} \
 ] $axi_bram_ctrl_0

  # Create instance: axi_bram_ctrl_0_bram, and set properties
  set axi_bram_ctrl_0_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.3 axi_bram_ctrl_0_bram ]
  set_property -dict [ list \
CONFIG.Assume_Synchronous_Clk {true} \
CONFIG.Enable_B {Use_ENB_Pin} \
CONFIG.Memory_Type {True_Dual_Port_RAM} \
CONFIG.Port_B_Clock {100} \
CONFIG.Port_B_Enable_Rate {100} \
CONFIG.Port_B_Write_Rate {50} \
CONFIG.Use_RSTB_Pin {true} \
 ] $axi_bram_ctrl_0_bram

  # Create instance: axi_bram_ctrl_1, and set properties
  set axi_bram_ctrl_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_1 ]
  set_property -dict [ list \
CONFIG.DATA_WIDTH {64} \
CONFIG.ECC_TYPE {0} \
CONFIG.SINGLE_PORT_BRAM {1} \
 ] $axi_bram_ctrl_1

  # Create instance: kutu_datamover_0, and set properties
  set kutu_datamover_0 [ create_bd_cell -type ip -vlnv kutu.com.au:kutu:kutu_datamover:1.0 kutu_datamover_0 ]
  set_property -dict [ list \
CONFIG.C_INCLUDE_MM2S {1} \
CONFIG.C_M_AXI_MM2S_DATA_WIDTH {64} \
CONFIG.C_M_AXI_S2MM_DATA_WIDTH {64} \
CONFIG.C_TLAST_OMIT {1} \
 ] $kutu_datamover_0

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTA]
  connect_bd_intf_net -intf_net kutu_datamover_0_m_axi_mm2s [get_bd_intf_pins axi_bram_ctrl_1/S_AXI] [get_bd_intf_pins kutu_datamover_0/m_axi_mm2s]
  connect_bd_intf_net -intf_net kutu_datamover_0_m_axi_s2mm [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] [get_bd_intf_pins kutu_datamover_0/m_axi_s2mm]
  connect_bd_intf_net -intf_net kutu_datamover_0_m_axis_mm2s [get_bd_intf_ports m_axis_mm2s] [get_bd_intf_pins kutu_datamover_0/m_axis_mm2s]
  connect_bd_intf_net -intf_net s_axis_mm2s_cmd_1 [get_bd_intf_ports s_axis_mm2s_cmd] [get_bd_intf_pins kutu_datamover_0/s_axis_mm2s_cmd]
  connect_bd_intf_net -intf_net s_axis_s2mm_1 [get_bd_intf_ports s_axis_s2mm] [get_bd_intf_pins kutu_datamover_0/s_axis_s2mm]
  connect_bd_intf_net -intf_net s_axis_s2mm_cmd_1 [get_bd_intf_ports s_axis_s2mm_cmd] [get_bd_intf_pins kutu_datamover_0/s_axis_s2mm_cmd]

  # Create port connections
  connect_bd_net -net axi_dataprocessor_0_m_axis_aclk [get_bd_ports s_axis_aclk] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins axi_bram_ctrl_1/s_axi_aclk] [get_bd_pins kutu_datamover_0/m_axi_mm2s_aclk] [get_bd_pins kutu_datamover_0/m_axi_s2mm_aclk]
  connect_bd_net -net axi_dataprocessor_0_m_axis_aresetn [get_bd_ports s_axis_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_1/s_axi_aresetn] [get_bd_pins kutu_datamover_0/m_axi_mm2s_aresetn] [get_bd_pins kutu_datamover_0/m_axi_s2mm_aresetn]
  connect_bd_net -net kutu_datamover_0_mm2s_err [get_bd_ports mm2s_err] [get_bd_pins kutu_datamover_0/mm2s_err]
  connect_bd_net -net kutu_datamover_0_s2mm_err [get_bd_ports s2mm_err] [get_bd_pins kutu_datamover_0/s2mm_err]
  connect_bd_net -net s_axis_mm2s_cmd_aclk_1 [get_bd_ports s_axis_mm2s_cmd_aclk] [get_bd_pins kutu_datamover_0/s_axis_mm2s_cmd_aclk]
  connect_bd_net -net s_axis_mm2s_cmd_aresetn_1 [get_bd_ports s_axis_mm2s_cmd_aresetn] [get_bd_pins kutu_datamover_0/s_axis_mm2s_cmd_aresetn]
  connect_bd_net -net s_axis_s2mm_cmd_aclk_1 [get_bd_ports s_axis_s2mm_cmd_aclk] [get_bd_pins kutu_datamover_0/s_axis_s2mm_cmd_aclk]
  connect_bd_net -net s_axis_s2mm_cmd_aresetn_1 [get_bd_ports s_axis_s2mm_cmd_aresetn] [get_bd_pins kutu_datamover_0/s_axis_s2mm_cmd_aresetn]

  # Create address segments
  create_bd_addr_seg -range 0x100000 -offset 0x0 [get_bd_addr_spaces kutu_datamover_0/m_axi_s2mm] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] SEG_axi_bram_ctrl_0_Mem0
  create_bd_addr_seg -range 0x100000 -offset 0x0 [get_bd_addr_spaces kutu_datamover_0/m_axi_mm2s] [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0] SEG_axi_bram_ctrl_1_Mem0

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   guistr: "# # String gsaved with Nlview 6.5.5  2015-06-26 bk=1.3371 VDI=38 GEI=35 GUI=JA:1.8
#  -string -flagsOSRD
preplace port s2mm_err -pg 1 -y 300 -defaultsOSRD
preplace port s_axis_s2mm_cmd_aresetn -pg 1 -y 270 -defaultsOSRD
preplace port s_axis_s2mm -pg 1 -y 90 -defaultsOSRD
preplace port mm2s_err -pg 1 -y 170 -defaultsOSRD
preplace port s_axis_aresetn -pg 1 -y 150 -defaultsOSRD
preplace port s_axis_aclk -pg 1 -y 130 -defaultsOSRD
preplace port s_axis_mm2s_cmd_aresetn -pg 1 -y 190 -defaultsOSRD
preplace port m_axis_mm2s -pg 1 -y 150 -defaultsOSRD
preplace port s_axis_mm2s_cmd -pg 1 -y 70 -defaultsOSRD
preplace port s_axis_s2mm_cmd -pg 1 -y 110 -defaultsOSRD
preplace port s_axis_s2mm_cmd_aclk -pg 1 -y 250 -defaultsOSRD
preplace port s_axis_mm2s_cmd_aclk -pg 1 -y 170 -defaultsOSRD
preplace inst axi_bram_ctrl_0_bram -pg 1 -lvl 3 -y 220 -defaultsOSRD
preplace inst kutu_datamover_0 -pg 1 -lvl 1 -y 170 -defaultsOSRD
preplace inst axi_bram_ctrl_0 -pg 1 -lvl 2 -y 230 -defaultsOSRD
preplace inst axi_bram_ctrl_1 -pg 1 -lvl 2 -y 80 -defaultsOSRD
preplace netloc s_axis_mm2s_cmd_aclk_1 1 0 1 NJ
preplace netloc s_axis_mm2s_cmd_1 1 0 1 NJ
preplace netloc kutu_datamover_0_m_axis_mm2s 1 1 3 NJ 150 NJ 150 NJ
preplace netloc axi_bram_ctrl_0_BRAM_PORTA 1 2 1 N
preplace netloc kutu_datamover_0_mm2s_err 1 1 3 NJ 160 NJ 160 NJ
preplace netloc s_axis_s2mm_cmd_aresetn_1 1 0 1 NJ
preplace netloc s_axis_mm2s_cmd_aresetn_1 1 0 1 NJ
preplace netloc axi_dataprocessor_0_m_axis_aclk 1 0 2 20 10 410
preplace netloc kutu_datamover_0_m_axi_mm2s 1 1 1 370
preplace netloc kutu_datamover_0_m_axi_s2mm 1 1 1 390
preplace netloc s_axis_s2mm_cmd_aclk_1 1 0 1 NJ
preplace netloc axi_dataprocessor_0_m_axis_aresetn 1 0 2 30 20 380
preplace netloc s_axis_s2mm_cmd_1 1 0 1 NJ
preplace netloc s_axis_s2mm_1 1 0 1 NJ
preplace netloc kutu_datamover_0_s2mm_err 1 1 3 NJ 300 NJ 300 NJ
preplace netloc axi_bram_ctrl_1_BRAM_PORTA 1 2 1 670
levelinfo -pg 1 0 200 540 780 910 -top 0 -bot 320
",
}

  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


puts "\n\nWARNING: This Tcl script was generated from a block design that has not been validated. It is possible that design <$design_name> may result in errors during validation."

