#
# Vivado (TM) v2017.4 (64-bit)
#
# build_ip.tcl: Tcl script for re-creating project 'hdmi_display_v1_00_a'
#
# Generated by Vivado on Thu Feb 20 17:45:23 +1100 2014
# IP Build 208076 on Mon Dec  2 12:38:17 MST 2013
#
# This file contains the Vivado Tcl commands for re-creating the project to the state*
# when this script was generated. In order to re-create the project, please source this
# file in the Vivado Tcl Shell.
#
# * Note that the runs in the created project will be configured the same way as the
#   original project, however they will not be launched automatically. To regenerate the
#   run results please launch the synthesis/implementation runs as needed.
#
#*****************************************************************************************

# Set the original project directory path for adding/importing sources in the new project
set orig_proj_dir "../hdmi_display_v1_00_a"

# Create project
create_project -force hdmi_display_v1_00_a ../hdmi_display_v1_00_a

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [get_projects hdmi_display_v1_00_a]
set_property "part" "xc7z010clg400-1" $obj
set_property "simulator_language" "Mixed" $obj
set_property "target_language" "VHDL" $obj

set_property  ip_repo_paths  {./interfaces} [current_project]
update_ip_catalog

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Add files to 'sources' fileset
add_files -norecurse sources/hdmi_display.vhd
add_files -norecurse sources/clock_gen_bufio.vhd
add_files -norecurse sources/TMDS_encoder.vhd
add_files -norecurse sources/hdmi_tx.vhd
add_files -norecurse sources/serializer.vhd
add_files -norecurse sources/frame_gen.vhd
add_files -norecurse sources/test_pattern.vhd

set_property library hdmi_display_v1_00_a [get_files sources/hdmi_display.vhd]
set_property library hdmi_display_v1_00_a [get_files sources/clock_gen_bufio.vhd]
set_property library hdmi_display_v1_00_a [get_files sources/TMDS_encoder.vhd]
set_property library hdmi_display_v1_00_a [get_files sources/serializer.vhd]
set_property library hdmi_display_v1_00_a [get_files sources/hdmi_tx.vhd]
set_property library hdmi_display_v1_00_a [get_files sources/frame_gen.vhd]
set_property library hdmi_display_v1_00_a [get_files sources/test_pattern.vhd]

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "../../XilinxIP" $obj
set_property "top" "hdmi_display" $obj

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
add_files -norecurse sources/hdmi_display_tb1.vhd

set_property used_in_synthesis false [get_files  /home/greg/github/XilinxIP/hdmi_display_v1_00_a/sources/hdmi_display_tb1.vhd]

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property "top" "testbench" $obj

# Create 'synth_1' run (if not found)
if {[string equal [get_runs synth_1] ""]} {
  create_run -name synth_1 -part xc7z045ffg900-2 -flow {Vivado Synthesis 2014} -strategy "Vivado Synthesis Defaults" -constrset constrs_1
}
set obj [get_runs synth_1]

# Create 'impl_1' run (if not found)
if {[string equal [get_runs impl_1] ""]} {
  create_run -name impl_1 -part xc7z045ffg900-2 -flow {Vivado Implementation 2014} -strategy "Vivado Implementation Defaults" -constrset constrs_1 -parent_run synth_1
}
set obj [get_runs impl_1]

ipx::package_project -root_dir {../hdmi_display_v1_00_a}

set_property vendor {kutu.com.au} [ipx::current_core]
set_property library {kutu} [ipx::current_core]
set_property taxonomy {{/Kutu}} [ipx::current_core]
set_property vendor_display_name {Kutu Pty. Ltd.} [ipx::current_core]
set_property company_url {http://www.kutu.com.au} [ipx::current_core]

set_property supported_families \
    {{virtex7}    {Production} \
     {qvirtex7}   {Production} \
     {kintex7}    {Production} \
     {kintex7l}   {Production} \
     {qkintex7}   {Production} \
     {qkintex7l}  {Production} \
     {artix7}     {Production} \
     {artix7l}    {Production} \
     {aartix7}    {Production} \
     {qartix7}    {Production} \
     {zynq}       {Production} \
     {qzynq}      {Production} \
     {azynq}      {Production}} \
  [ipx::current_core]

ipx::remove_bus_interface HDMI_CLK_N [ipx::current_core]
ipx::remove_bus_interface HDMI_CLK_P [ipx::current_core]
ipx::remove_bus_interface reset [ipx::current_core]
ipx::associate_bus_interfaces -busif s_axis_mm2s -clock s_axis_mm2s_aclk [ipx::current_core]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces s_axis_mm2s_aclk -of_objects [ipx::current_core]]
set_property value 148500000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces s_axis_mm2s_aclk -of_objects [ipx::current_core]]]

ipx::add_bus_interface HDMI [ipx::current_core]
set_property abstraction_type_vlnv kutu:user:hdmi_rtl:1.0 [ipx::get_bus_interfaces HDMI -of_objects [ipx::current_core]]
set_property bus_type_vlnv kutu:user:hdmi:1.0 [ipx::get_bus_interfaces HDMI -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces HDMI -of_objects [ipx::current_core]]

ipx::add_port_map CLK_P [ipx::get_bus_interfaces HDMI -of_objects [ipx::current_core]]
set_property physical_name HDMI_CLK_P [ipx::get_port_maps CLK_P -of_objects [ipx::get_bus_interfaces HDMI -of_objects [ipx::current_core]]]
ipx::add_port_map D2_P [ipx::get_bus_interfaces HDMI -of_objects [ipx::current_core]]
set_property physical_name HDMI_D2_P [ipx::get_port_maps D2_P -of_objects [ipx::get_bus_interfaces HDMI -of_objects [ipx::current_core]]]
ipx::add_port_map D1_P [ipx::get_bus_interfaces HDMI -of_objects [ipx::current_core]]
set_property physical_name HDMI_D1_P [ipx::get_port_maps D1_P -of_objects [ipx::get_bus_interfaces HDMI -of_objects [ipx::current_core]]]
ipx::add_port_map CLK_N [ipx::get_bus_interfaces HDMI -of_objects [ipx::current_core]]
set_property physical_name HDMI_CLK_N [ipx::get_port_maps CLK_N -of_objects [ipx::get_bus_interfaces HDMI -of_objects [ipx::current_core]]]
ipx::add_port_map D2_N [ipx::get_bus_interfaces HDMI -of_objects [ipx::current_core]]
set_property physical_name HDMI_D2_N [ipx::get_port_maps D2_N -of_objects [ipx::get_bus_interfaces HDMI -of_objects [ipx::current_core]]]
ipx::add_port_map D0_P [ipx::get_bus_interfaces HDMI -of_objects [ipx::current_core]]
set_property physical_name HDMI_D0_P [ipx::get_port_maps D0_P -of_objects [ipx::get_bus_interfaces HDMI -of_objects [ipx::current_core]]]
ipx::add_port_map D1_N [ipx::get_bus_interfaces HDMI -of_objects [ipx::current_core]]
set_property physical_name HDMI_D1_N [ipx::get_port_maps D1_N -of_objects [ipx::get_bus_interfaces HDMI -of_objects [ipx::current_core]]]
ipx::add_port_map D0_N [ipx::get_bus_interfaces HDMI -of_objects [ipx::current_core]]
set_property physical_name HDMI_D0_N [ipx::get_port_maps D0_N -of_objects [ipx::get_bus_interfaces HDMI -of_objects [ipx::current_core]]]

set_property display_name {Frame Parameters} [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core] ]
set_property tooltip {Default frame is 1920x1080} [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core] ]
ipgui::add_page -name {PLL Configuration} -component [ipx::current_core] -display_name {PLL Configuration}
set_property tooltip {Default clock configuration is for 1080p60 output} [ipgui::get_pagespec -name "PLL Configuration" -component [ipx::current_core] ]
ipgui::add_page -name {Default Colour} -component [ipx::current_core] -display_name {Default Colour}
set_property tooltip {Colour output when no data is present} [ipgui::get_pagespec -name "Default Colour" -component [ipx::current_core] ]

set_property enablement_dependency DEBUG_OUTPUTS==1 [ipx::get_ports debug_hcount -of_objects [ipx::current_core]]
set_property enablement_dependency DEBUG_OUTPUTS==1 [ipx::get_ports debug_vcount -of_objects [ipx::current_core]]
set_property enablement_dependency DEBUG_OUTPUTS==1 [ipx::get_ports debug_vga_active -of_objects [ipx::current_core]]
set_property enablement_dependency DEBUG_OUTPUTS==1 [ipx::get_ports debug_vga_running -of_objects [ipx::current_core]]
set_property enablement_dependency DEBUG_OUTPUTS==1 [ipx::get_ports debug_hsync -of_objects [ipx::current_core]]
set_property enablement_dependency DEBUG_OUTPUTS==1 [ipx::get_ports debug_vsync -of_objects [ipx::current_core]]
set_property enablement_dependency DEBUG_OUTPUTS==1 [ipx::get_ports debug_de -of_objects [ipx::current_core]]
set_property enablement_dependency DEBUG_OUTPUTS==1 [ipx::get_ports debug_red -of_objects [ipx::current_core]]
set_property enablement_dependency DEBUG_OUTPUTS==1 [ipx::get_ports debug_green -of_objects [ipx::current_core]]
set_property enablement_dependency DEBUG_OUTPUTS==1 [ipx::get_ports debug_blue -of_objects [ipx::current_core]]
set_property enablement_dependency DEBUG_OUTPUTS==1 [ipx::get_ports debug_tmds_blue -of_objects [ipx::current_core]]
set_property enablement_dependency DEBUG_OUTPUTS==1 [ipx::get_ports debug_tmds_red -of_objects [ipx::current_core]]
set_property enablement_dependency DEBUG_OUTPUTS==1 [ipx::get_ports debug_tmds_green -of_objects [ipx::current_core]]

ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "CLK_DIVIDE" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "PLL Configuration" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "PLL_DIVIDE" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "PLL Configuration" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "PLL_MULTIPLY" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "PLL Configuration" -component [ipx::current_core]]
set_property display_name {MMCM Multiply} [ipgui::get_guiparamspec -name "PLL_MULTIPLY" -component [ipx::current_core] ]
set_property tooltip {MMCM Multiply value} [ipgui::get_guiparamspec -name "PLL_MULTIPLY" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "PLL_MULTIPLY" -component [ipx::current_core] ]
set_property value_validation_type range_long [ipx::get_user_parameters PLL_MULTIPLY -of_objects [ipx::current_core]]
set_property value_validation_range_minimum 2.0 [ipx::get_user_parameters PLL_MULTIPLY -of_objects [ipx::current_core]]
set_property value_validation_range_maximum 64.0 [ipx::get_user_parameters PLL_MULTIPLY -of_objects [ipx::current_core]]
set_property display_name {MMCM Divide} [ipgui::get_guiparamspec -name "PLL_DIVIDE" -component [ipx::current_core] ]
set_property tooltip {MMCM Divide value} [ipgui::get_guiparamspec -name "PLL_DIVIDE" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "PLL_DIVIDE" -component [ipx::current_core] ]
set_property value_validation_type range_long [ipx::get_user_parameters PLL_DIVIDE -of_objects [ipx::current_core]]
set_property value_validation_range_minimum 1 [ipx::get_user_parameters PLL_DIVIDE -of_objects [ipx::current_core]]
set_property value_validation_range_maximum 64 [ipx::get_user_parameters PLL_DIVIDE -of_objects [ipx::current_core]]
set_property display_name {Clock Divide} [ipgui::get_guiparamspec -name "CLK_DIVIDE" -component [ipx::current_core] ]
set_property tooltip {High speed output clock divider} [ipgui::get_guiparamspec -name "CLK_DIVIDE" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "CLK_DIVIDE" -component [ipx::current_core] ]
set_property value_validation_type range_long [ipx::get_user_parameters CLK_DIVIDE -of_objects [ipx::current_core]]
set_property value_validation_range_minimum 1 [ipx::get_user_parameters CLK_DIVIDE -of_objects [ipx::current_core]]
set_property value_validation_range_maximum 32 [ipx::get_user_parameters CLK_DIVIDE -of_objects [ipx::current_core]]

ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "USR_BLUE" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Default Colour" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "USR_GREEN" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Default Colour" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "USR_RED" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Default Colour" -component [ipx::current_core]]
set_property display_name {Default Red Level} [ipgui::get_guiparamspec -name "USR_RED" -component [ipx::current_core] ]
set_property tooltip {Default Red Level} [ipgui::get_guiparamspec -name "USR_RED" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "USR_RED" -component [ipx::current_core] ]
set_property value_validation_type range_long [ipx::get_user_parameters USR_RED -of_objects [ipx::current_core]]
set_property value_validation_range_minimum 0 [ipx::get_user_parameters USR_RED -of_objects [ipx::current_core]]
set_property value_validation_range_maximum 255 [ipx::get_user_parameters USR_RED -of_objects [ipx::current_core]]
set_property display_name {Default Green Level} [ipgui::get_guiparamspec -name "USR_GREEN" -component [ipx::current_core] ]
set_property tooltip {Default Green Level} [ipgui::get_guiparamspec -name "USR_GREEN" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "USR_GREEN" -component [ipx::current_core] ]
set_property value_validation_type range_long [ipx::get_user_parameters USR_GREEN -of_objects [ipx::current_core]]
set_property value_validation_range_minimum 0 [ipx::get_user_parameters USR_GREEN -of_objects [ipx::current_core]]
set_property value_validation_range_maximum 255 [ipx::get_user_parameters USR_GREEN -of_objects [ipx::current_core]]
set_property display_name {Default Blue Level} [ipgui::get_guiparamspec -name "USR_BLUE" -component [ipx::current_core] ]
set_property tooltip {Default Blue Level} [ipgui::get_guiparamspec -name "USR_BLUE" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "USR_BLUE" -component [ipx::current_core] ]
set_property value_validation_type range_long [ipx::get_user_parameters USR_BLUE -of_objects [ipx::current_core]]
set_property value_validation_range_minimum 0 [ipx::get_user_parameters USR_BLUE -of_objects [ipx::current_core]]
set_property value_validation_range_maximum 255 [ipx::get_user_parameters USR_BLUE -of_objects [ipx::current_core]]

ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "USR_HMAX" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
set_property display_name {Horizontal Total} [ipgui::get_guiparamspec -name "USR_HMAX" -component [ipx::current_core] ]
set_property tooltip {Horizontal Total} [ipgui::get_guiparamspec -name "USR_HMAX" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "USR_HMAX" -component [ipx::current_core] ]
set_property value_validation_type range_long [ipx::get_user_parameters USR_HMAX -of_objects [ipx::current_core]]
set_property value_validation_range_minimum 0 [ipx::get_user_parameters USR_HMAX -of_objects [ipx::current_core]]
set_property value_validation_range_maximum 4095 [ipx::get_user_parameters USR_HMAX -of_objects [ipx::current_core]]

ipgui::move_param -component [ipx::current_core] -order 1 [ipgui::get_guiparamspec -name "USR_HSIZE" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
set_property display_name {Horizontal Active Pixels} [ipgui::get_guiparamspec -name "USR_HSIZE" -component [ipx::current_core] ]
set_property tooltip {Horizontal Active Pixels} [ipgui::get_guiparamspec -name "USR_HSIZE" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "USR_HSIZE" -component [ipx::current_core] ]
set_property value_validation_type range_long [ipx::get_user_parameters USR_HSIZE -of_objects [ipx::current_core]]
set_property value_validation_range_minimum 0 [ipx::get_user_parameters USR_HSIZE -of_objects [ipx::current_core]]
set_property value_validation_range_maximum 4095 [ipx::get_user_parameters USR_HSIZE -of_objects [ipx::current_core]]

ipgui::move_param -component [ipx::current_core] -order 2 [ipgui::get_guiparamspec -name "USR_HFRONT_PORCH" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
set_property display_name {Horizontal Front Porch} [ipgui::get_guiparamspec -name "USR_HFRONT_PORCH" -component [ipx::current_core] ]
set_property tooltip {Horizontal Front Porch} [ipgui::get_guiparamspec -name "USR_HFRONT_PORCH" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "USR_HFRONT_PORCH" -component [ipx::current_core] ]
set_property value_validation_type range_long [ipx::get_user_parameters USR_HFRONT_PORCH -of_objects [ipx::current_core]]
set_property value_validation_range_minimum 0 [ipx::get_user_parameters USR_HFRONT_PORCH -of_objects [ipx::current_core]]
set_property value_validation_range_maximum 4095 [ipx::get_user_parameters USR_HFRONT_PORCH -of_objects [ipx::current_core]]

ipgui::move_param -component [ipx::current_core] -order 3 [ipgui::get_guiparamspec -name "USR_HBACK_PORCH" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
set_property display_name {Horizontal Back Porch} [ipgui::get_guiparamspec -name "USR_HBACK_PORCH" -component [ipx::current_core] ]
set_property tooltip {Horizontal Back Porch} [ipgui::get_guiparamspec -name "USR_HBACK_PORCH" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "USR_HBACK_PORCH" -component [ipx::current_core] ]
set_property value_validation_type range_long [ipx::get_user_parameters USR_HBACK_PORCH -of_objects [ipx::current_core]]
set_property value_validation_range_minimum 0 [ipx::get_user_parameters USR_HBACK_PORCH -of_objects [ipx::current_core]]
set_property value_validation_range_maximum 4095 [ipx::get_user_parameters USR_HBACK_PORCH -of_objects [ipx::current_core]]

ipgui::move_param -component [ipx::current_core] -order 4 [ipgui::get_guiparamspec -name "USR_VMAX" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
set_property display_name {Vertical Total} [ipgui::get_guiparamspec -name "USR_VMAX" -component [ipx::current_core] ]
set_property tooltip {Vertical Total} [ipgui::get_guiparamspec -name "USR_VMAX" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "USR_VMAX" -component [ipx::current_core] ]
set_property value_validation_type range_long [ipx::get_user_parameters USR_VMAX -of_objects [ipx::current_core]]
set_property value_validation_range_minimum 0 [ipx::get_user_parameters USR_VMAX -of_objects [ipx::current_core]]
set_property value_validation_range_maximum 4095 [ipx::get_user_parameters USR_VMAX -of_objects [ipx::current_core]]

ipgui::move_param -component [ipx::current_core] -order 5 [ipgui::get_guiparamspec -name "USR_VSIZE" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
set_property display_name {Vertical Active Pixels} [ipgui::get_guiparamspec -name "USR_VSIZE" -component [ipx::current_core] ]
set_property tooltip {Vertical Active Pixels} [ipgui::get_guiparamspec -name "USR_VSIZE" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "USR_VSIZE" -component [ipx::current_core] ]
set_property value_validation_type range_long [ipx::get_user_parameters USR_VSIZE -of_objects [ipx::current_core]]
set_property value_validation_range_minimum 0 [ipx::get_user_parameters USR_VSIZE -of_objects [ipx::current_core]]
set_property value_validation_range_maximum 4095 [ipx::get_user_parameters USR_VSIZE -of_objects [ipx::current_core]]

ipgui::move_param -component [ipx::current_core] -order 6 [ipgui::get_guiparamspec -name "USR_VFRONT_PORCH" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
set_property display_name {Vertical Front Porch} [ipgui::get_guiparamspec -name "USR_VFRONT_PORCH" -component [ipx::current_core] ]
set_property tooltip {Vertical Front Porch} [ipgui::get_guiparamspec -name "USR_VFRONT_PORCH" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "USR_VFRONT_PORCH" -component [ipx::current_core] ]
set_property value_validation_type range_long [ipx::get_user_parameters USR_VFRONT_PORCH -of_objects [ipx::current_core]]
set_property value_validation_range_minimum 0 [ipx::get_user_parameters USR_VFRONT_PORCH -of_objects [ipx::current_core]]
set_property value_validation_range_maximum 4095 [ipx::get_user_parameters USR_VFRONT_PORCH -of_objects [ipx::current_core]]

ipgui::move_param -component [ipx::current_core] -order 7 [ipgui::get_guiparamspec -name "USR_VBACK_PORCH" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
set_property display_name {Vertical Back Porch} [ipgui::get_guiparamspec -name "USR_VBACK_PORCH" -component [ipx::current_core] ]
set_property tooltip {Vertical Back Porch} [ipgui::get_guiparamspec -name "USR_VBACK_PORCH" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "USR_VBACK_PORCH" -component [ipx::current_core] ]
set_property value_validation_type range_long [ipx::get_user_parameters USR_VBACK_PORCH -of_objects [ipx::current_core]]
set_property value_validation_range_minimum 0 [ipx::get_user_parameters USR_VBACK_PORCH -of_objects [ipx::current_core]]
set_property value_validation_range_maximum 4095 [ipx::get_user_parameters USR_VBACK_PORCH -of_objects [ipx::current_core]]

set_property widget {radioGroup} [ipgui::get_guiparamspec -name "DEBUG_OUTPUTS" -component [ipx::current_core] ]
set_property layout {vertical} [ipgui::get_guiparamspec -name "DEBUG_OUTPUTS" -component [ipx::current_core] ]
set_property value_validation_type pairs [ipx::get_user_parameters DEBUG_OUTPUTS -of_objects [ipx::current_core]]
set_property value_validation_pairs {Disabled 0 Enabled 1} [ipx::get_user_parameters DEBUG_OUTPUTS -of_objects [ipx::current_core]]

set_property widget {comboBox} [ipgui::get_guiparamspec -name "USE_TEST_PATTERN" -component [ipx::current_core] ]
set_property value_validation_type pairs [ipx::get_user_parameters USE_TEST_PATTERN -of_objects [ipx::current_core]]
set_property value_validation_pairs {{Enable Test Pattern} 1 {Enable External Data Input} 0} [ipx::get_user_parameters USE_TEST_PATTERN -of_objects [ipx::current_core]]

set_property enablement_value false [ipx::get_user_parameters USR_HPOLARITY -of_objects [ipx::current_core]]
ipgui::remove_param -component [ipx::current_core] [ipgui::get_guiparamspec -name "USR_HPOLARITY" -component [ipx::current_core]]
set_property enablement_value false [ipx::get_user_parameters USR_VPOLARITY -of_objects [ipx::current_core]]
ipgui::remove_param -component [ipx::current_core] [ipgui::get_guiparamspec -name "USR_VPOLARITY" -component [ipx::current_core]]

ipx::create_xgui_files [ipx::current_core]
ipx::save_core [ipx::current_core]
# update_ip_catalog -rebuild -repo_path ../../XilinxIP
ipx::check_integrity -quiet [ipx::current_core]
ipx::unload_core {kutu.com.au:kutu:hdmi_display:1.0}
