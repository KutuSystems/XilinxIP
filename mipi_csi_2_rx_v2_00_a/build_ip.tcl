
# Set the original project directory path for adding/importing sources in the new project
set orig_proj_dir "../mipi_csi_2_rx_v2_00_a"

# Create project
create_project -force mipi_csi_2_rx_v2_00_a ../mipi_csi_2_rx_v2_00_a

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [get_projects mipi_csi_2_rx_v2_00_a]
set_property "part" "xc7z010clg400-1" $obj
set_property "simulator_language" "Mixed" $obj
set_property "target_language" "VHDL" $obj

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Add files to 'sources_1' fileset
add_files -norecurse sources/MIPI_CSI_2_RX_S_AXI_LITE.vhd
add_files -norecurse sources/MIPI_CSI2_RxTop.vhd
add_files -norecurse sources/MIPI_CSI2_Rx.vhd
add_files -norecurse sources/SyncAsyncReset.vhd
add_files -norecurse sources/LLP.vhd
add_files -norecurse sources/LM.vhd
add_files -norecurse sources/SyncAsync.vhd
add_files -norecurse sources/simple_fifo.vhd
add_files -norecurse sources/ECC.vhd
add_files -norecurse sources/CRC16_behavioral.vhd
add_files -norecurse sources/sync_fifo.vhd
add_files -norecurse sources/async_fifo_keep.vhd

set_property library mipi_csi_2_rx_v2_0_0 [get_files sources/MIPI_CSI_2_RX_S_AXI_LITE.vhd]
set_property library mipi_csi_2_rx_v2_0_0 [get_files sources/MIPI_CSI2_RxTop.vhd]
set_property library mipi_csi_2_rx_v2_0_0 [get_files sources/MIPI_CSI2_Rx.vhd]
set_property library mipi_csi_2_rx_v2_0_0 [get_files sources/SyncAsyncReset.vhd]
set_property library mipi_csi_2_rx_v2_0_0 [get_files sources/LLP.vhd]
set_property library mipi_csi_2_rx_v2_0_0 [get_files sources/LM.vhd]
set_property library mipi_csi_2_rx_v2_0_0 [get_files sources/SyncAsync.vhd]
set_property library mipi_csi_2_rx_v2_0_0 [get_files sources/simple_fifo.vhd]
set_property library mipi_csi_2_rx_v2_0_0 [get_files sources/ECC.vhd]
set_property library mipi_csi_2_rx_v2_0_0 [get_files sources/CRC16_behavioral.vhd]
set_property library mipi_csi_2_rx_v2_0_0 [get_files sources/sync_fifo.vhd]
set_property library mipi_csi_2_rx_v2_0_0 [get_files sources/async_fifo_keep.vhd]

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "../../XilinxIP" $obj
set_property "top" "mipi_csi2_rx_top" $obj

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
set_property "top" "mipi_csi2_rx_top" $obj

ipx::package_project -root_dir {../mipi_csi_2_rx_v2_00_a}
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
     {zynquplus}  {Beta} \
     {qzynq}      {Production} \
     {azynq}      {Production}} \
  [ipx::current_core]


ipx::create_xgui_files [ipx::current_core]
ipx::save_core [ipx::current_core]
#update_ip_catalog -rebuild -repo_path ../../XilinxIP
ipx::check_integrity -quiet [ipx::current_core]
ipx::unload_core {kutu.com.au:kutu:mipi_csi2_rx_top:1.0}

puts "INFO: Project created:mipi_csi_2_rx_v2_00_a"
