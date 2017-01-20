
# Set the original project directory path for adding/importing sources in the new project
set orig_proj_dir "../kutu_datamover_v1_00_a"

# Create project
create_project -force kutu_datamover_v1_00_a ../kutu_datamover_v1_00_a

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [get_projects kutu_datamover_v1_00_a]
set_property "part" "xc7z010clg400-1" $obj
set_property "simulator_language" "Mixed" $obj
set_property "target_language" "VHDL" $obj

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Add files to 'sources_1' fileset
add_files -norecurse sources/kutu_datamover.vhd
add_files -norecurse sources/kutu_datamover_mm2s_omit_wrap.vhd
add_files -norecurse sources/kutu_datamover_mm2s_full_wrap.vhd
add_files -norecurse sources/kutu_datamover_s2mm_omit_wrap.vhd
add_files -norecurse sources/kutu_datamover_s2mm_full_wrap.vhd
add_files -norecurse sources/kutu_datamover_s2mm_realign.vhd
add_files -norecurse sources/kutu_datamover_s2mm_scatter.vhd
add_files -norecurse sources/kutu_datamover_cmd_status.vhd
add_files -norecurse sources/kutu_datamover_fifo.vhd
add_files -norecurse sources/kutu_datamover_addr_cntl.vhd
add_files -norecurse sources/kutu_datamover_mssai_skid_buf.vhd
add_files -norecurse sources/kutu_datamover_ms_strb_set.vhd
add_files -norecurse sources/kutu_datamover_pcc.vhd
add_files -norecurse sources/kutu_datamover_rddata_cntl.vhd
add_files -norecurse sources/kutu_datamover_rdmux.vhd
add_files -norecurse sources/kutu_datamover_rd_sf.vhd
add_files -norecurse sources/kutu_datamover_rd_status_cntl.vhd
add_files -norecurse sources/kutu_datamover_sfifo_autord.vhd
add_files -norecurse sources/kutu_datamover_skid2mm_buf.vhd
add_files -norecurse sources/kutu_datamover_skid_buf.vhd
add_files -norecurse sources/kutu_datamover_slice.vhd
add_files -norecurse sources/kutu_datamover_strb_gen2.vhd
add_files -norecurse sources/kutu_datamover_wrdata_cntl.vhd
add_files -norecurse sources/kutu_datamover_wr_demux.vhd
add_files -norecurse sources/kutu_datamover_wr_sf.vhd
add_files -norecurse sources/kutu_datamover_wr_status_cntl.vhd

add_files -norecurse sources/srl_fifo_f.vhd
add_files -norecurse sources/srl_fifo_rbu_f.vhd
add_files -norecurse sources/cntr_incr_decr_addn_f.vhd
add_files -norecurse sources/dynshreg_f.vhd


set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_mm2s_omit_wrap.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_mm2s_full_wrap.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_s2mm_omit_wrap.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_s2mm_full_wrap.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_s2mm_realign.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_s2mm_scatter.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_cmd_status.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_fifo.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_addr_cntl.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_mssai_skid_buf.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_ms_strb_set.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_pcc.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_rddata_cntl.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_rdmux.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_rd_sf.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_rd_status_cntl.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_sfifo_autord.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_skid2mm_buf.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_skid_buf.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_slice.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_strb_gen2.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_wrdata_cntl.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_wr_demux.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_wr_sf.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/kutu_datamover_wr_status_cntl.vhd]

set_property library kutu_datamover_v5_1_9 [get_files sources/srl_fifo_f.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/srl_fifo_rbu_f.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/cntr_incr_decr_addn_f.vhd]
set_property library kutu_datamover_v5_1_9 [get_files sources/dynshreg_f.vhd]


# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "../../XilinxIP" $obj
set_property "top" "kutu_datamover" $obj

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
set_property "top" "kutu_datamover" $obj

ipx::package_project -root_dir {../kutu_datamover_v1_00_a}
set_property vendor {kutu.com.au} [ipx::current_core]
set_property library {kutu} [ipx::current_core]
set_property taxonomy {{/Kutu}} [ipx::current_core]
set_property vendor_display_name {Kutu Pty. Ltd.} [ipx::current_core]
set_property company_url {www.kutu.com.au} [ipx::current_core]

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

set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_INCLUDE_MM2S'))=1 [ipx::get_bus_interfaces m_axi_mm2s -of_objects [ipx::current_core]]
set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_INCLUDE_S2MM'))=1 [ipx::get_bus_interfaces m_axi_s2mm -of_objects [ipx::current_core]]
set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_INCLUDE_MM2S'))=1 [ipx::get_bus_interfaces m_axis_mm2s -of_objects [ipx::current_core]]
set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_INCLUDE_S2MM'))=1 [ipx::get_bus_interfaces s_axis_s2mm -of_objects [ipx::current_core]]
set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_INCLUDE_MM2S'))=1 [ipx::get_bus_interfaces s_axis_mm2s_cmd -of_objects [ipx::current_core]]
set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_INCLUDE_S2MM'))=1 [ipx::get_bus_interfaces s_axis_s2mm_cmd -of_objects [ipx::current_core]]
set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_INCLUDE_MM2S'))=1 [ipx::get_ports mm2s_err -of_objects [ipx::current_core]]
set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_INCLUDE_S2MM'))=1 [ipx::get_ports s2mm_err -of_objects [ipx::current_core]]

set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_INCLUDE_MM2S'))=1 [ipx::get_bus_interfaces m_axi_mm2s_aresetn -of_objects [ipx::current_core]]
set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_INCLUDE_MM2S'))=1 [ipx::get_bus_interfaces s_axis_mm2s_cmd_aresetn -of_objects [ipx::current_core]]
set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_INCLUDE_MM2S'))=1 [ipx::get_bus_interfaces m_axi_mm2s_aclk -of_objects [ipx::current_core]]
set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_INCLUDE_MM2S'))=1 [ipx::get_bus_interfaces s_axis_mm2s_cmd_aclk -of_objects [ipx::current_core]]

set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_INCLUDE_S2MM'))=1 [ipx::get_bus_interfaces m_axi_s2mm_aresetn -of_objects [ipx::current_core]]
set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_INCLUDE_S2MM'))=1 [ipx::get_bus_interfaces s_axis_s2mm_cmd_aresetn -of_objects [ipx::current_core]]
set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_INCLUDE_S2MM'))=1 [ipx::get_bus_interfaces m_axi_s2mm_aclk -of_objects [ipx::current_core]]
set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_INCLUDE_S2MM'))=1 [ipx::get_bus_interfaces s_axis_s2mm_cmd_aclk -of_objects [ipx::current_core]]

set_property widget {radioGroup} [ipgui::get_guiparamspec -name "C_ENABLE_CACHE_USER" -component [ipx::current_core] ]
set_property layout {horizontal} [ipgui::get_guiparamspec -name "C_ENABLE_CACHE_USER" -component [ipx::current_core] ]
set_property value_validation_type pairs [ipx::get_user_parameters C_ENABLE_CACHE_USER -of_objects [ipx::current_core]]
set_property value_validation_pairs {{Cache Disabled} 0 {Cache Enabled} 1} [ipx::get_user_parameters C_ENABLE_CACHE_USER -of_objects [ipx::current_core]]

ipgui::move_param -component [ipx::current_core] -order 2 [ipgui::get_guiparamspec -name "C_ENABLE_CACHE_USER" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
set_property display_name {Include MM2S Controller} [ipgui::get_guiparamspec -name "C_INCLUDE_MM2S" -component [ipx::current_core] ]
set_property tooltip {Include Memory Mapped to Stream Controller} [ipgui::get_guiparamspec -name "C_INCLUDE_MM2S" -component [ipx::current_core] ]
set_property widget {radioGroup} [ipgui::get_guiparamspec -name "C_INCLUDE_MM2S" -component [ipx::current_core] ]
set_property layout {horizontal} [ipgui::get_guiparamspec -name "C_INCLUDE_MM2S" -component [ipx::current_core] ]
set_property value_validation_type pairs [ipx::get_user_parameters C_INCLUDE_MM2S -of_objects [ipx::current_core]]
set_property value_validation_pairs {Enabled 1 Disabled 0} [ipx::get_user_parameters C_INCLUDE_MM2S -of_objects [ipx::current_core]]

set_property display_name {Include S2MM Controller} [ipgui::get_guiparamspec -name "C_INCLUDE_S2MM" -component [ipx::current_core] ]
set_property tooltip {Include Stream to Memory Mapped Controller} [ipgui::get_guiparamspec -name "C_INCLUDE_S2MM" -component [ipx::current_core] ]
set_property widget {radioGroup} [ipgui::get_guiparamspec -name "C_INCLUDE_S2MM" -component [ipx::current_core] ]
set_property layout {horizontal} [ipgui::get_guiparamspec -name "C_INCLUDE_S2MM" -component [ipx::current_core] ]
set_property value_validation_type pairs [ipx::get_user_parameters C_INCLUDE_S2MM -of_objects [ipx::current_core]]
set_property value_validation_pairs {Enabled 1 Disabled 0} [ipx::get_user_parameters C_INCLUDE_S2MM -of_objects [ipx::current_core]]

ipgui::add_page -name {S2MM Controller} -component [ipx::current_core] -display_name {S2MM Controller}
ipgui::add_page -name {MM2S Controller} -component [ipx::current_core] -display_name {MM2S Controller}
set_property display_name {Global Parameters} [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core] ]
set_property tooltip {Parameters affecting both directions} [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core] ]

ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "C_INCLUDE_MM2S" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "MM2S Controller" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "C_INCLUDE_S2MM" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "S2MM Controller" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "C_MM2S_BTT_USED" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "MM2S Controller" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "C_INCLUDE_MM2S" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "MM2S Controller" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 1 [ipgui::get_guiparamspec -name "C_M_AXI_MM2S_ADDR_WIDTH" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "MM2S Controller" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 1 [ipgui::get_guiparamspec -name "C_M_AXI_MM2S_DATA_WIDTH" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "MM2S Controller" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 1 [ipgui::get_guiparamspec -name "C_M_AXI_MM2S_ID_WIDTH" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "MM2S Controller" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "C_S2MM_BTT_USED" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "S2MM Controller" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "C_INCLUDE_S2MM" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "S2MM Controller" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "C_M_AXI_S2MM_ADDR_WIDTH" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "MM2S Controller" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 1 [ipgui::get_guiparamspec -name "C_M_AXI_S2MM_DATA_WIDTH" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "MM2S Controller" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 1 [ipgui::get_guiparamspec -name "C_M_AXI_S2MM_ID_WIDTH" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "MM2S Controller" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 1 [ipgui::get_guiparamspec -name "C_M_AXI_S2MM_ADDR_WIDTH" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "S2MM Controller" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 2 [ipgui::get_guiparamspec -name "C_M_AXI_S2MM_DATA_WIDTH" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "S2MM Controller" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 2 [ipgui::get_guiparamspec -name "C_M_AXI_S2MM_ID_WIDTH" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "S2MM Controller" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 1 [ipgui::get_guiparamspec -name "C_M_AXI_S2MM_ID_WIDTH" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "S2MM Controller" -component [ipx::current_core]]

set_property widget {comboBox} [ipgui::get_guiparamspec -name "C_M_AXI_S2MM_ADDR_WIDTH" -component [ipx::current_core] ]
set_property value 32 [ipx::get_user_parameters C_M_AXI_S2MM_ADDR_WIDTH -of_objects [ipx::current_core]]
set_property value 32 [ipx::get_hdl_parameters C_M_AXI_S2MM_ADDR_WIDTH -of_objects [ipx::current_core]]
set_property value_validation_type list [ipx::get_user_parameters C_M_AXI_S2MM_ADDR_WIDTH -of_objects [ipx::current_core]]
set_property value_validation_list {32 64} [ipx::get_user_parameters C_M_AXI_S2MM_ADDR_WIDTH -of_objects [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 2 [ipgui::get_guiparamspec -name "C_M_AXI_MM2S_ADDR_WIDTH" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "MM2S Controller" -component [ipx::current_core]]
set_property widget {comboBox} [ipgui::get_guiparamspec -name "C_M_AXI_MM2S_ADDR_WIDTH" -component [ipx::current_core] ]
set_property value 32 [ipx::get_user_parameters C_M_AXI_MM2S_ADDR_WIDTH -of_objects [ipx::current_core]]
set_property value 32 [ipx::get_hdl_parameters C_M_AXI_MM2S_ADDR_WIDTH -of_objects [ipx::current_core]]
set_property value_validation_type list [ipx::get_user_parameters C_M_AXI_MM2S_ADDR_WIDTH -of_objects [ipx::current_core]]
set_property value_validation_list {32 64} [ipx::get_user_parameters C_M_AXI_MM2S_ADDR_WIDTH -of_objects [ipx::current_core]]

set_property display_name {S2MM BTT Used} [ipgui::get_guiparamspec -name "C_S2MM_BTT_USED" -component [ipx::current_core] ]
set_property tooltip {Number of Bits in DMA transfer command (in bytes)} [ipgui::get_guiparamspec -name "C_S2MM_BTT_USED" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "C_S2MM_BTT_USED" -component [ipx::current_core] ]
set_property value_validation_type range_long [ipx::get_user_parameters C_S2MM_BTT_USED -of_objects [ipx::current_core]]
set_property value_validation_range_minimum 12 [ipx::get_user_parameters C_S2MM_BTT_USED -of_objects [ipx::current_core]]
set_property value_validation_range_maximum 30 [ipx::get_user_parameters C_S2MM_BTT_USED -of_objects [ipx::current_core]]

set_property display_name {MM2S BTT Used} [ipgui::get_guiparamspec -name "C_MM2S_BTT_USED" -component [ipx::current_core] ]
set_property tooltip {Number of bits in DMA transfer command (in bytes)} [ipgui::get_guiparamspec -name "C_MM2S_BTT_USED" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "C_MM2S_BTT_USED" -component [ipx::current_core] ]
set_property value_validation_type range_long [ipx::get_user_parameters C_MM2S_BTT_USED -of_objects [ipx::current_core]]
set_property value_validation_range_minimum 12 [ipx::get_user_parameters C_MM2S_BTT_USED -of_objects [ipx::current_core]]
set_property value_validation_range_maximum 30 [ipx::get_user_parameters C_MM2S_BTT_USED -of_objects [ipx::current_core]]

ipgui::move_param -component [ipx::current_core] -order 4 [ipgui::get_guiparamspec -name "C_TLAST_OMIT" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "S2MM Controller" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 4 [ipgui::get_guiparamspec -name "C_S2MM_BTT_USED" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "S2MM Controller" -component [ipx::current_core]]
set_property widget {comboBox} [ipgui::get_guiparamspec -name "C_TLAST_OMIT" -component [ipx::current_core] ]
set_property value 0 [ipx::get_user_parameters C_TLAST_OMIT -of_objects [ipx::current_core]]
set_property value 0 [ipx::get_hdl_parameters C_TLAST_OMIT -of_objects [ipx::current_core]]
set_property value_validation_type pairs [ipx::get_user_parameters C_TLAST_OMIT -of_objects [ipx::current_core]]
set_property value_validation_pairs {{Tlast Required} 0 {Tlast Optional} 1} [ipx::get_user_parameters C_TLAST_OMIT -of_objects [ipx::current_core]]
set_property display_name {Tlast Signal} [ipgui::get_guiparamspec -name "C_TLAST_OMIT" -component [ipx::current_core] ]
set_property tooltip {If Tlast is required in stream} [ipgui::get_guiparamspec -name "C_TLAST_OMIT" -component [ipx::current_core] ]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces m_axis_mm2s -of_objects [ipx::current_core]]
set_property description {Clock frequency (Hertz)} [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces m_axis_mm2s -of_objects [ipx::current_core]]]

ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces s_axis_s2mm -of_objects [ipx::current_core]]
set_property description {Clock frequency (Hertz)} [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces s_axis_s2mm -of_objects [ipx::current_core]]]

ipx::create_xgui_files [ipx::current_core]
ipx::save_core [ipx::current_core]
#update_ip_catalog -rebuild -repo_path ../../XilinxIP
ipx::check_integrity -quiet [ipx::current_core]
ipx::unload_core {kutu.com.au:kutu:kutu_datamover:1.0}

puts "INFO: Project created:kutu_datamover_v1_00_a"
