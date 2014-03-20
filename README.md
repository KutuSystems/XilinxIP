XilinxIP
========

Xilinx IP repository

This repository is a group of IP blocks for Vivado.  The IP blocks mostly come from Analog Devices who provide reference designs for Xilinx boards that use the ADV7511 HDMI transmitter.
So far this only supports the zc706, but I have a zc702 and a ZYBO, so I hope to add support for those soon.

The reason for adding this repository i that I noticed that ADI are working on moving their library to Vivado, but it seems unfinished.  I am doing something similar and would like to see a good version of a linux desktop built woth Vivado and running on the zc702/zc702/Zedboard.

These IP blocks all build into a Kutu IP library.

The current repository builds without errors, but is untested.

To build the library  do the following:
1. Open Vivado (currently 2013.4)
2. cd <your dir>/XilinxIP
3. source build_ip_lib.tcl

After the script runs you will have the projects all built and the IP generated.

regards,
Greg
