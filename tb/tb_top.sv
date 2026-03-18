`timescale 1ns/1ps

//Common UVM
`include "uvm_macros.svh"
import uvm_pkg::*;

module tb_top();

//Test
import soc_test_pkg::*;
import uvm_pkg::*;
  
  //Clock gen
  parameter I_CLK_100MHZ_PERIOD = 10ns;
  //Reset gen
  logic resetn = 0;

  logic clk_100mhz = 0;

  always #(I_CLK_100MHZ_PERIOD/2) clk_100mhz = ~clk_100mhz;

  initial #200ns resetn = 1;

  SOC_TOP dut();

  initial begin
    run_test("");
  end

  //initial begin
  //  force dut.u_dma.PCLK = clk_100mhz;
  //  force dut.u_dma.RESETN = resetn;
  //end

  // Variable : intf
  // axi4 Interface Instantiation
  axi4_if intf(.aclk(clk_100mhz),
               .aresetn(resetn));

 
  // AXI4  No of Master and Slaves Agent Instantiation
  //-------------------------------------------------------
  genvar i;
  generate
  
    for (i=0; i<NO_OF_MASTERS; i++) begin : axi4_master_agent_bfm
      axi4_master_agent_bfm #(.MASTER_ID(i)) axi4_master_agent_bfm_h(intf);
      defparam axi4_master_agent_bfm[i].axi4_master_agent_bfm_h.MASTER_ID = i;
    end
  

    for (i=0; i<NO_OF_MASTERS; i++) begin : axi4_slave_agent_bfm
      axi4_slave_agent_bfm #(.SLAVE_ID(i)) axi4_slave_agent_bfm_h(intf);
      defparam axi4_slave_agent_bfm[i].axi4_slave_agent_bfm_h.SLAVE_ID = i;
    end
  endgenerate

  initial begin
    if ($test$plusargs("DUMP_FSDB")) begin
      $fsdbDumpfile("test");
      $fsdbDumpvars(0, tb_top, "+all");
    end
  end

  //`APB_CONNECTOR(dut.u_dma, SI0_APB3, 0)

endmodule
