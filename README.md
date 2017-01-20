XilinxIP
========

Xilinx IP repository

This repository is a group of IP blocks for Vivado.  Some of the IP blocks come from Analog Devices who provide reference designs for Xilinx boards that use the ADV7511 HDMI transmitter.
So far this library has been tested with the zc706, zc702, Zedboard and ZYBO.

These IP blocks all build into a Kutu IP library.

To build the library  do the following:
1. Open Vivado (currently 2016.4)
2. cd <your dir>/XilinxIP
3. source build_ip_lib.tcl

After the script runs you will have the projects all built and the IP generated.
