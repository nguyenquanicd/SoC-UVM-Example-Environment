#!/bin/csh -f

source SourceMe.csh

#####################################
# Execute
#####################################
set compile = "all"
set run_dir = ""
#set date0 = date + '%Y%h%d %R:%S'
set run_string = "$0 $argv"

set test_name = "soc_base_test_c"
set fsdb = ""
set synthesis = "+define+SYNTHESIS"
set coverage = ""
set seed = "+ntb_random_seed_automatic"
set cell = ""
set plusarg = ""
set VarNum = 0

while ($#argv > $VarNum)
  switch ($argv[1])
    case "-test":
      shift
      set test_name = $argv[1]
      set compile = "run"
      breaksw
    case "-seed":
      shift
      set seed = "+ntb_random_seed=$argv[1]"
      breaksw
    case "-run_dir":
      shift
      set run_dir = $argv[1]
      breaksw
    case "-compile":
      shift
      set compile = $argv[1]
      breaksw
    case "-unsynthesis":
      shift
      set synthesis = ""
      breaksw
    case "-fsdb":
      shift
      set fsdb = "+DUMP_FSDB=1"
      breaksw
    case "-fsdb_mda":
      shift
      set fsdb = "-fsdb_opt mda"
      breaksw
    case "-cell":
      shift
      set cell = "-debug_region+cell+lib"
      breaksw
    case "-coverage":
      shift
      set coverage = "-cm tgl+line+branch+fsm+cond"
      breaksw
    default:
      if (`echo $argv[1] | cut -b 1` == "+") then
        set plusarg = "$plusarg $argv[1]"
      endif
      shift
      breaksw
  endsw
end

echo $plusarg

set common_opts = "-full64 -sverilog -debug_access+all -diag timescale -timescale=1ns/1ps -kdb=common_elab -ntb_opts uvm-1.2 $cell"
set vlogan_opts = "$common_opts $coverage $synthesis $plusarg"
set vcs_opts    = "$common_opts $coverage -allxmrs -lca -assert svaext -reportstats +nospecify"
set vsim_opts   = "$coverage $fsdb $seed $plusarg +vcs+lic+wait"


echo $run_string
echo $run_string >> commands.log

if ($compile == "rtl") then
  if (! -d outfeed_cmp_rtl) then
    mkdir outfeed_cmp_rtl
  endif
  cd $TB_HOME/outfeed_cmp_rtl

vlogan\
$vlogan_opts \
-xlrm env_expand \
-F $TB_HOME/filelist_rtl.f \
-l rtl_vlogan_log.log \
-work CMP_RTL

vlogan\
$vlogan_opts \
-xlrm env_expand \
-F $TB_HOME/filelist_stub.f \
-l stub_vlogan_log.log \
-work CMP_STUB

endif

if ($compile == "dv") then
  if (! -d outfeed_cmp_dv) then
    mkdir outfeed_cmp_dv
  endif
  cd $TB_HOME/outfeed_cmp_dv

  vlogan \
  -l uvm.log \
  -ntb_opts uvm-1.2 \
  $vlogan_opts \
  -work CMP_DV

  vlogan\
  -l dv_vlogan_log.log \
  -xlrm env_expand \
  -ntb_opts uvm-1.2 \
  -f $TB_HOME/filelist_dv.f \
  $vlogan_opts \
  -work CMP_DV

  vlogan\
  -l cfg_vlogan_log.log \
  -xlrm env_expand \
  -ntb_opts uvm-1.2 \
  $vlogan_opts \
  $TB_HOME/dut/dut_config.sv\

 vcs \
 dut_config \
 -partcomp \
 -ntb_opts uvm-1.2 \
 -allxmrs \
 -l vcs_log.log \
 $vcs_opts \

echo "Debug: $plusarg"

endif

if ($compile == "run") then
echo "Running test $test_name at $run_dir..."
  if (! -d $run_dir) then
    mkdir $run_dir
  endif

  cd $TB_HOME/$run_dir
  if (!(-e simv.daidir)) then
    ln -s $TB_HOME/outfeed_cmp_dv/simv.daidir
    ln -s $TB_HOME/outfeed_cmp_dv/simv
  endif

echo $run_string >> commands.log

  set i = 10
  while ($i>0)
    set j = $i;
    @ i--;
    if ($i == 0 ) then
      if (-e run.log) then
        mv run.log run.log.1
      endif
    else
    if (-e run.log.$i) then
        mv run.log.$i run.log.$j
      endif
    endif
  end

  ./simv \
    +UVM_NO_RELNOTES \
    +UVM_VERBOSITY=UVM_MEDIUM \
    +UVM_TESTNAME=$test_name \
    -cm_dir simv.vdb \
    -l run.log \
    $vsim_opts \

endif
