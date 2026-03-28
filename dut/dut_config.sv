config dut_config;

  design CMP_DV.tb_top;
  default liblist CMP_RTL CMP_DV;

  `define SELECT_LIB(module_name) \
    `ifdef ``module_name``_STUB \
      cell ``module_name`` liblist CMP_STUB; \
    `endif \

  `SELECT_LIB(DMA)
  `SELECT_LIB(CPU)

endconfig
