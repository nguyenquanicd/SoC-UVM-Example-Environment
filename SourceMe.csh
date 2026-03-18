#!/bin/csh -f 

#module load synopsys/vcs
#module load synopsys/verdi

setenv TB_HOME `pwd`

setenv APB_VIP $TB_HOME/vip/apb_vip
setenv AHB_VIP $TB_HOME/vip/ahb_vip
setenv AXI_VIP $TB_HOME/vip/axi_vip
setenv JTAG_VIP $TB_HOME/vip/jtag_vip

echo "TB_HOME path": $TB_HOME
#echo "Design path" : $DESIGN

setenv SYNOPSYS_SIM_SETUP $TB_HOME/synopsys_sim.setup
