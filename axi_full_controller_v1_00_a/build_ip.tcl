
# Set the original project directory path for adding/importing sources in the new project
set orig_proj_dir "../axi_full_controller_v1_00_a"

# Create project
create_project -force axi_full_controller_v1_00_a ../axi_full_controller_v1_00_a

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [get_projects axi_full_controller_v1_00_a]
set_property "board" "xilinx.com:zynq:zc706:1.1" $obj
set_property "simulator_language" "Mixed" $obj
set_property "target_language" "VHDL" $obj

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Add files to 'sources_1' fileset
add_files -norecurse sources/ahb_mstr_if.vhd
add_files -norecurse sources/axi_full_controller.vhd
add_files -norecurse sources/axi_slv_if.vhd
add_files -norecurse sources/counter_f.vhd
add_files -norecurse sources/time_out.vhd

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "../../XilinxIP" $obj
set_property "top" "axi_full_controller" $obj

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

   # Add files to 'sim_1' fileset
   set obj [get_filesets sim_1]
   # Empty (no sources present)

   # Set 'sim_1' fileset properties
   set obj [get_filesets sim_1]
   set_property "top" "axi_full_controller" $obj
}

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


ipx::package_project -root_dir {../axi_full_controller_v1_00_a}
set_property vendor {kutu.com.au} [ipx::current_core]
set_property library {kutu} [ipx::current_core]
set_property taxonomy {{/Kutu}} [ipx::current_core]
set_property vendor_display_name {Kutu Pty. Ltd.} [ipx::current_core]
set_property company_url {www.kutu.com.au} [ipx::current_core]
ipx::add_bus_interface AHB [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:ahblite_rtl:1.0 [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:ahblite:1.0 [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]
ipx::add_port_map HTRANS [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]
set_property physical_name m_ahb_htrans [ipx::get_port_maps HTRANS -of_objects [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]]
ipx::add_port_map HPROT [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]
set_property physical_name m_ahb_hprot [ipx::get_port_maps HPROT -of_objects [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]]
ipx::add_port_map HSIZE [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]
set_property physical_name m_ahb_hsize [ipx::get_port_maps HSIZE -of_objects [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]]
ipx::add_port_map HRDATA [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]
set_property physical_name m_ahb_hrdata [ipx::get_port_maps HRDATA -of_objects [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]]
ipx::add_port_map HRESP [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]
set_property physical_name m_ahb_hresp [ipx::get_port_maps HRESP -of_objects [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]]
ipx::add_port_map HWRITE [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]
set_property physical_name m_ahb_hwrite [ipx::get_port_maps HWRITE -of_objects [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]]
ipx::add_port_map HREADY [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]
set_property physical_name m_ahb_hready [ipx::get_port_maps HREADY -of_objects [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]]
ipx::add_port_map HADDR [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]
set_property physical_name m_ahb_haddr [ipx::get_port_maps HADDR -of_objects [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]]
ipx::add_port_map HMASTLOCK [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]
set_property physical_name m_ahb_hmastlock [ipx::get_port_maps HMASTLOCK -of_objects [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]]
ipx::add_port_map HBURST [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]
set_property physical_name m_ahb_hburst [ipx::get_port_maps HBURST -of_objects [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]]
ipx::add_port_map HWDATA [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]
set_property physical_name m_ahb_hwdata [ipx::get_port_maps HWDATA -of_objects [ipx::get_bus_interfaces AHB -of_objects [ipx::current_core]]]
ipx::create_xgui_files [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::save_core [ipx::current_core]
#update_ip_catalog -rebuild -repo_path ../../XilinxIP
ipx::check_integrity -quiet [ipx::current_core]
ipx::unload_core {kutu.com.au:kutu:axi_full_controller:1.0}

puts "INFO: Project created:axi_full_controller_v1_00_a"
