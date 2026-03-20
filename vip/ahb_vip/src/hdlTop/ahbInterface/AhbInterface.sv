`ifndef AHBINTERFACE_INCLUDED_
`define AHBINTERFACE_INCLUDED_

import AhbGlobalPackage::*;

interface AhbInterface(input hclk, input hresetn);
  
  logic  [AHB_ADDR_WIDTH-1:0] haddr;

  logic [AHB_NO_OF_SLAVES-1:0] hselx;
  
  logic [2:0] hburst;

  logic hmastlock;

  logic [HPROT_WIDTH-1:0] hprot;
 
  logic [2:0] hsize;

  logic hnonsec;

  logic hexcl;

  logic [HMASTER_WIDTH-1:0] hmaster;

  logic [1:0] htrans;


  logic [AHB_DATA_WIDTH-1:0] hwdata;

  logic [(AHB_DATA_WIDTH/8)-1:0] hwstrb;

  logic hwrite;

  logic [AHB_DATA_WIDTH-1:0] hrdata;

  logic hreadyout;

  logic hresp;

  logic hexokay;

  logic hready;

 endinterface : AhbInterface

`endif

