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
  logic resetn = 1;

  logic clk_100mhz = 0;

  always #(I_CLK_100MHZ_PERIOD/2) clk_100mhz = ~clk_100mhz;

  initial begin
    #200ns resetn = 0;
    #200ns resetn = 1;
  end

  SOC_TOP dut();

  initial begin
    run_test("");
  end

  //initial begin
  //  force dut.u_dma.PCLK = clk_100mhz;
  //  force dut.u_dma.RESETN = resetn;
  //end

  //-------------------------------------------------------
  // APB Interface Instantiation
  //-------------------------------------------------------
  apb_if apb_intf_s[APB_NO_OF_SLAVES](clk_100mhz,resetn);
  apb_if apb_intf(clk_100mhz,resetn);

  // Variable : intf
  // axi4 Interface Instantiation
  axi4_if intf(.aclk(clk_100mhz),
               .aresetn(resetn));

  //-------------------------------------------------------
  // APB Master BFM Agent Instantiation
  //-------------------------------------------------------
  apb_master_agent_bfm apb_master_agent_bfm_h(apb_intf); 
  
  always_comb begin
    case(apb_intf.pselx)
      2'b01: begin
               apb_intf_s[0].pselx   = apb_intf.pselx[0];
               apb_intf_s[0].penable = apb_intf.penable;
               apb_intf_s[0].paddr   = apb_intf.paddr;
               apb_intf_s[0].pwrite  = apb_intf.pwrite;
               apb_intf_s[0].pstrb   = apb_intf.pstrb;
               apb_intf_s[0].pwdata  = apb_intf.pwdata;
               apb_intf_s[0].pprot   = apb_intf.pprot;
               apb_intf.pready  = apb_intf_s[0].pready;
               apb_intf.prdata  = apb_intf_s[0].prdata;
               apb_intf.pslverr = apb_intf_s[0].pslverr;
             end
     //-------------------------------------------------------------------------------------------
     //whenever you require multiple slaves like 2 slave then uncomment below case
     //So if you uncomment then case 1 and case 2 will select particular slave
     //As of now using single slave and connected using case 1
     //Change NO_OF_SLAVES 1 to 2 inside the global pkg then you will get 2 slave interface handle
     //-------------------------------------------------------------------------------------------
     // 2'b10: begin
     //          apb_intf_s[1].pselx = apb_intf.pselx[1];
     //          apb_intf_s[1].penable = apb_intf.penable;
     //          apb_intf_s[1].paddr   = apb_intf.paddr;
     //          apb_intf_s[1].pwrite  = apb_intf.pwrite;
     //          apb_intf_s[1].pstrb   = apb_intf.pstrb;
     //          apb_intf_s[1].pwdata  = apb_intf.pwdata;
     //          apb_intf_s[1].pprot   = apb_intf.pprot;
     //          apb_intf.pready  = apb_intf_s[1].pready;
     //          apb_intf.prdata  = apb_intf_s[1].prdata;
     //          apb_intf.pslverr = apb_intf_s[1].pslverr;
     //        end
      default : begin
                  apb_intf_s[0].pselx   = 'b0;
                  apb_intf_s[0].penable = 'b0;
                  //apb_intf_s[1].pselx   = 'b0;
                  //apb_intf_s[1].penable = 'b0;
                end
    endcase
  end

  //-------------------------------------------------------
  // APB Slave BFM Agent Instantiation
  //-------------------------------------------------------
  genvar i;
  generate
    for (i=0; i < APB_NO_OF_SLAVES; i++) begin : apb_slave_agent_bfm
      apb_slave_agent_bfm #(.SLAVE_ID(i)) apb_slave_agent_bfm_h(apb_intf_s[i]);
      defparam apb_slave_agent_bfm[i].apb_slave_agent_bfm_h.SLAVE_ID = i;
    end
  endgenerate

  AhbInterface ahbInterface(clk_100mhz,resetn);

  AhbMasterAgentBFM ahbMasterAgentBFM(ahbInterface); 

  AhbSlaveAgentBFM ahbSlaveAgentBFM(ahbInterface); 

 
  // AXI4  No of Master and Slaves Agent Instantiation
  //-------------------------------------------------------
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
