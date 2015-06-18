#!/bin/sh -f
xv_path="/opt/Xilinx/Vivado/2014.4"
ExecStep()
{
"$@"
RETVAL=$?
if [ $RETVAL -ne 0 ]
then
exit $RETVAL
fi
}
ExecStep $xv_path/bin/xelab -wto 682d0ccd9c4f4aefba2b092345bc60e9 -m64 --debug typical --relax -L xil_defaultlib -L secureip --snapshot top_cfg_behav xil_defaultlib.top_cfg -log elaborate.log
