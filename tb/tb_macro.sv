`define APB_CONNECTOR(path, prefix, num) \
  apb_if soc_apb_``num``_if(clk_100mhz, resetn); \
  initial begin \
    force ``path``.``prefix``_PADDR 		= soc_apb_``num``_if.PADDR; \
    force ``path``.``prefix``_PSEL 		= soc_apb_``num``_if.PSEL; \
    force ``path``.``prefix``_PENABLE 		= soc_apb_``num``_if.PENABLE; \
    force ``path``.``prefix``_PWRITE 		= soc_apb_``num``_if.PWRITE; \
    force ``path``.``prefix``_PWDATA 		= soc_apb_``num``_if.PWDATA; \
    force soc_apb_``num``_if.PRDATA    		= ``path``.``prefix``_PRDATA; \
    force soc_apb_``num``_if.PREADY 		= ``path``.``prefix``_PREADY; \
  end \
  initial uvm_config_db#(virtual apb_if)::set(null, "*.apb_agt[``num``].*", "apb_vif", soc_apb_``num``_if); \

