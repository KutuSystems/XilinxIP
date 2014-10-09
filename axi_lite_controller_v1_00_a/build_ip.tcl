
# Set the original project directory path for adding/importing sources in the new project
set orig_proj_dir "../axi_lite_controller_v1_00_a"

# Create project
create_project -force axi_lite_controller_v1_00_a ../axi_lite_controller_v1_00_a

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [get_projects axi_lite_controller_v1_00_a]
set_property "board" "xilinx.com:zynq:zc706:1.1" $obj
set_property "simulator_language" "Mixed" $obj
set_property "target_language" "VHDL" $obj

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Add files to 'sources_1' fileset
add_files -norecurse sources/axi4_lite_controller.vhd

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "../../XilinxIP" $obj
set_property "top" "axi4_lite_controller" $obj

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Add files to 'constrs_1' fileset
set obj [get_filesets constrs_1]
# Empty (no sources present)

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets sim_1] ""]} {
  create_fileset -simset sim_1
}

# Add files to 'sim_1' fileset
set obj [get_filesets sim_1]
# Empty (no sources present)

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property "top" "axi4_lite_controller" $obj

# Create 'synth_1' run (if not found)
if {[string equal [get_runs synth_1] ""]} {
  create_run -name synth_1 -part xc7z045ffg900-2 -flow {Vivado Synthesis 2013} -strategy "Vivado Synthesis Defaults" -constrset constrs_1
}
set obj [get_runs synth_1]

# Create 'impl_1' run (if not found)
if {[string equal [get_runs impl_1] ""]} {
  create_run -name impl_1 -part xc7z045ffg900-2 -flow {Vivado Implementation 2013} -strategy "Vivado Implementation Defaults" -constrset constrs_1 -parent_run synth_1
}
set obj [get_runs impl_1]

ipx::package_project -root_dir {../axi_lite_controller_v1_00_a}
set_property vendor {kutu.com.au} [ipx::current_core]
set_property library {kutu} [ipx::current_core]
set_property taxonomy {{/Kutu}} [ipx::current_core]
set_property vendor_display_name {Kutu Pty. Ltd.} [ipx::current_core]
set_property company_url {www.kutu.com.au} [ipx::current_core]
set_property value_validation_range_maximum {16} [ipx::get_user_parameter C_DPHASE_TIMEOUT [ipx::current_core]]
set_property value_validation_range_maximum {16} [ipx::get_hdl_parameter C_DPHASE_TIMEOUT [ipx::current_core]]
set_property value_validation_range_minimum {0} [ipx::get_user_parameter C_DPHASE_TIMEOUT [ipx::current_core]]
set_property value_validation_range_minimum {0} [ipx::get_hdl_parameter C_DPHASE_TIMEOUT [ipx::current_core]]
set_property value_validation_range_maximum {1} [ipx::get_user_parameter C_USE_WSTRB [ipx::current_core]]
set_property value_validation_range_maximum {1} [ipx::get_hdl_parameter C_USE_WSTRB [ipx::current_core]]
set_property value_validation_range_minimum {0} [ipx::get_user_parameter C_USE_WSTRB [ipx::current_core]]
set_property value_validation_range_minimum {0} [ipx::get_hdl_parameter C_USE_WSTRB [ipx::current_core]]
set_property value_validation_range_maximum {32} [ipx::get_user_parameter C_S_AXI_ADDR_WIDTH [ipx::current_core]]
set_property value_validation_range_maximum {32} [ipx::get_hdl_parameter C_S_AXI_ADDR_WIDTH [ipx::current_core]]
set_property value_validation_range_maximum {32} [ipx::get_user_parameter C_S_AXI_DATA_WIDTH [ipx::current_core]]
set_property value_validation_range_maximum {32} [ipx::get_hdl_parameter C_S_AXI_DATA_WIDTH [ipx::current_core]]
set_property value_validation_range_minimum {32} [ipx::get_user_parameter C_S_AXI_ADDR_WIDTH [ipx::current_core]]
set_property value_validation_range_minimum {32} [ipx::get_hdl_parameter C_S_AXI_ADDR_WIDTH [ipx::current_core]]
set_property value_validation_range_minimum {32} [ipx::get_user_parameter C_S_AXI_DATA_WIDTH [ipx::current_core]]
set_property value_validation_range_minimum {32} [ipx::get_hdl_parameter C_S_AXI_DATA_WIDTH [ipx::current_core]]
set_property value_validation_range_maximum {24} [ipx::get_user_parameter C_SYS_ADDR_WIDTH [ipx::current_core]]
set_property value_validation_range_maximum {24} [ipx::get_hdl_parameter C_SYS_ADDR_WIDTH [ipx::current_core]]
set_property value_validation_range_minimum {8} [ipx::get_user_parameter C_SYS_ADDR_WIDTH [ipx::current_core]]
set_property value_validation_range_minimum {8} [ipx::get_hdl_parameter C_SYS_ADDR_WIDTH [ipx::current_core]]
ipx::add_bus_interface {S_AXI_LITE_ACLK} [ipx::current_core]
set_property abstraction_type_vlnv {xilinx.com:signal:clock_rtl:1.0} [ipx::get_bus_interface S_AXI_LITE_ACLK [ipx::current_core]]
set_property bus_type_vlnv {xilinx.com:signal:clock:1.0} [ipx::get_bus_interface S_AXI_LITE_ACLK [ipx::current_core]]
set_property display_name {S_AXI_LITE_ACLK} [ipx::get_bus_interface S_AXI_LITE_ACLK [ipx::current_core]]
ipx::infer_port_maps [ipx::get_bus_interface S_AXI_LITE_ACLK [ipx::current_core]]
ipx::add_port_map {CLK} [ipx::get_bus_interface S_AXI_LITE_ACLK [ipx::current_core]]
ipx::add_bus_interface {S_AXI_LITE_ARESETN} [ipx::current_core]
set_property abstraction_type_vlnv {xilinx.com:signal:reset_rtl:1.0} [ipx::get_bus_interface S_AXI_LITE_ARESETN [ipx::current_core]]
set_property bus_type_vlnv {xilinx.com:signal:reset:1.0} [ipx::get_bus_interface S_AXI_LITE_ARESETN [ipx::current_core]]
set_property display_name {S_AXI_LITE_ARESETN} [ipx::get_bus_interface S_AXI_LITE_ARESETN [ipx::current_core]]
ipx::infer_port_maps [ipx::get_bus_interface S_AXI_LITE_ARESETN [ipx::current_core]]
ipx::add_bus_parameter {ASSOCIATED_BUSIF} [ipx::get_bus_interface S_AXI_LITE_ACLK [ipx::current_core]]
set_property value {S_AXI_LITE} [ipx::get_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interface S_AXI_LITE_ACLK [ipx::current_core]]]
ipx::add_bus_parameter {POLARITY} [ipx::get_bus_interface S_AXI_LITE_ARESETN [ipx::current_core]]
set_property value {ACTIVE_LOW} [ipx::get_bus_parameter POLARITY [ipx::get_bus_interface S_AXI_LITE_ARESETN [ipx::current_core]]]

ipx::create_xgui_files [ipx::current_core]
ipx::infer_port_maps [ipx::get_bus_interface S_AXI_LITE_ACLK [ipx::current_core]]
set_property physical_name {S_AXI_LITE_ACLK} [ipx::get_port_map CLK [ipx::get_bus_interface S_AXI_LITE_ACLK [ipx::current_core]]]
ipx::create_xgui_files [ipx::current_core]
ipx::save_core [ipx::current_core]
update_ip_catalog -rebuild -repo_path ../../XilinxIP
ipx::check_integrity -quiet [ipx::current_core]
ipx::unload_core {kutu.com.au:kutu:axi4_lite_controller:1.0}

puts "INFO: Project created:axi_lite_controller_v1_00_a"
