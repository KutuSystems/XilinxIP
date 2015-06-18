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
ExecStep $xv_path/bin/xsim top_cfg_behav -key {Behavioral:sim_1:Functional:top_cfg} -tclbatch top_cfg.tcl -log simulate.log
