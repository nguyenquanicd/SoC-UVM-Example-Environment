class soc_base_test_c extends uvm_test;

  apb_env apb_env_h;
  apb_env_config apb_env_cfg_h;
  apb_virtual_32b_write_seq apb_seq;

  AhbEnvironment ahbEnvironment;
  AhbEnvironmentConfig ahbEnvironmentConfig;
  AhbVirtualWriteSequence ahb_seq; 

  axi4_env_config axi4_env_cfg_h;
  axi4_env axi4_env_h;
  axi4_virtual_bk_32b_write_data_seq axi_seq;

  `uvm_component_utils(soc_base_test_c)

  function new(string name = "soc_base_test_c", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);

    setup_apb_env_config();
    apb_env_h = apb_env::type_id::create("apb_env",this);
    apb_seq = apb_virtual_32b_write_seq::type_id::create("apb_seq", this);

    setupAhbEnvironmentConfig();
    ahbEnvironment = AhbEnvironment::type_id::create("ahbEnvironment",this);
    foreach(ahbEnvironment.ahbSlaveAgentConfig[i]) begin
      if(!ahbEnvironment.ahbSlaveAgentConfig[i].randomize() with {noOfWaitStates==0;}) begin
        `uvm_fatal(get_type_name(),"Unable to randomise noOfWaitStates")
      end
      ahbEnvironment.ahbMasterAgentConfig[i].noOfWaitStates = ahbEnvironment.ahbSlaveAgentConfig[i].noOfWaitStates ;
    end
    ahb_seq = AhbVirtualWriteSequence::type_id::create("ahb_seq", this);

    setup_axi4_env_cfg();
    axi4_env_h = axi4_env::type_id::create("axi4_env_h",this);
    axi_seq = axi4_virtual_bk_32b_write_data_seq::type_id::create("axi_seq");

  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
      $display("before start");
      apb_seq.start(apb_env_h.apb_virtual_seqr_h);
      ahb_seq.start(ahbEnvironment.ahbVirtualSequencer);
      axi_seq.start(axi4_env_h.axi4_virtual_seqr_h);
      $display("after start");
    phase.drop_objection(this);
  endtask

function void setup_apb_env_config();
  apb_env_cfg_h = apb_env_config::type_id::create("apb_env_cfg_h");
  apb_env_cfg_h.no_of_slaves      = APB_NO_OF_SLAVES;
  apb_env_cfg_h.has_scoreboard    = 1;
  apb_env_cfg_h.has_virtual_seqr  = 1;

  //Setting up the configuration for master agent
  setup_apb_master_agent_config();

  //Setting the master agent configuration into config_db
  uvm_config_db#(apb_master_agent_config)::set(this,"*master_agent*","apb_master_agent_config",
                                               apb_env_cfg_h.apb_master_agent_cfg_h);
  //Displaying the master agent configuration
  `uvm_info(get_type_name(),$sformatf("\nAPB_MASTER_AGENT_CONFIG\n%s",apb_env_cfg_h.apb_master_agent_cfg_h.sprint()),UVM_LOW);

  setup_apb_slave_agent_config();

  uvm_config_db#(apb_env_config)::set(this,"*","apb_env_config",apb_env_cfg_h);
  `uvm_info(get_type_name(),$sformatf("\nAPB_ENV_CONFIG\n%s",apb_env_cfg_h.sprint()),UVM_LOW);

endfunction : setup_apb_env_config

function void setup_apb_master_agent_config();
  bit [63:0]local_min_address;
  bit [63:0]local_max_address;
  
  apb_env_cfg_h.apb_master_agent_cfg_h = apb_master_agent_config::type_id::create("apb_master_agent_config");
  
  if(APB_MASTER_AGENT_ACTIVE === 1) begin
    apb_env_cfg_h.apb_master_agent_cfg_h.is_active = uvm_active_passive_enum'(UVM_ACTIVE);
  end
  else begin
    apb_env_cfg_h.apb_master_agent_cfg_h.is_active = uvm_active_passive_enum'(UVM_PASSIVE);
  end
  apb_env_cfg_h.apb_master_agent_cfg_h.no_of_slaves = APB_NO_OF_SLAVES;
  apb_env_cfg_h.apb_master_agent_cfg_h.has_coverage = 0;

  for(int i =0; i<APB_NO_OF_SLAVES; i++) begin
    if(i == 0) begin  
      apb_env_cfg_h.apb_master_agent_cfg_h.master_min_addr_range(i,0);
      local_min_address = apb_env_cfg_h.apb_master_agent_cfg_h.master_min_addr_range_array[i];
      
      apb_env_cfg_h.apb_master_agent_cfg_h.master_max_addr_range(i,2**(APB_SLAVE_MEMORY_SIZE)-1 );
      local_max_address = apb_env_cfg_h.apb_master_agent_cfg_h.master_max_addr_range_array[i];
    end
    else begin
      apb_env_cfg_h.apb_master_agent_cfg_h.master_min_addr_range(i,local_max_address + APB_SLAVE_MEMORY_GAP);
      local_min_address = apb_env_cfg_h.apb_master_agent_cfg_h.master_min_addr_range_array[i];
      
      apb_env_cfg_h.apb_master_agent_cfg_h.master_max_addr_range(i,local_max_address+2**(APB_SLAVE_MEMORY_SIZE)-1 + APB_SLAVE_MEMORY_GAP);
      local_max_address = apb_env_cfg_h.apb_master_agent_cfg_h.master_max_addr_range_array[i];
    end
  end
endfunction : setup_apb_master_agent_config

function void setup_apb_slave_agent_config();
  apb_env_cfg_h.apb_slave_agent_cfg_h = new[apb_env_cfg_h.no_of_slaves];
  foreach(apb_env_cfg_h.apb_slave_agent_cfg_h[i]) begin
    apb_env_cfg_h.apb_slave_agent_cfg_h[i] = apb_slave_agent_config::type_id::create($sformatf("apb_slave_agent_config[%0d]",i));
    apb_env_cfg_h.apb_slave_agent_cfg_h[i].slave_id       = i;
    apb_env_cfg_h.apb_slave_agent_cfg_h[i].slave_selected = 0;
    apb_env_cfg_h.apb_slave_agent_cfg_h[i].min_address    = apb_env_cfg_h.apb_master_agent_cfg_h.master_min_addr_range_array[i];
    apb_env_cfg_h.apb_slave_agent_cfg_h[i].max_address    = apb_env_cfg_h.apb_master_agent_cfg_h.master_max_addr_range_array[i];
    if(APB_SLAVE_AGENT_ACTIVE === 1) begin
      apb_env_cfg_h.apb_slave_agent_cfg_h[i].is_active = uvm_active_passive_enum'(UVM_ACTIVE);
    end
    else begin
      apb_env_cfg_h.apb_slave_agent_cfg_h[i].is_active = uvm_active_passive_enum'(UVM_PASSIVE);
    end
    apb_env_cfg_h.apb_slave_agent_cfg_h[i].has_coverage = 0; 
    uvm_config_db #(apb_slave_agent_config)::set(this,$sformatf("*env*"),$sformatf("apb_slave_agent_config[%0d]",i),
    apb_env_cfg_h.apb_slave_agent_cfg_h[i]);
   `uvm_info(get_type_name(),$sformatf("\nAPB_SLAVE_CONFIG[%0d]\n%s",i,apb_env_cfg_h.apb_slave_agent_cfg_h[i].sprint()),UVM_LOW);
  end

endfunction : setup_apb_slave_agent_config

function void setupAhbEnvironmentConfig();
  ahbEnvironmentConfig = AhbEnvironmentConfig::type_id::create("ahbEnvironmentConfig");
  ahbEnvironmentConfig.noOfSlaves           = AHB_NO_OF_SLAVES;
  ahbEnvironmentConfig.noOfMasters          = AHB_NO_OF_MASTERS;
  ahbEnvironmentConfig.hasScoreboard        = 0;
  ahbEnvironmentConfig.hasVirtualSequencer  = 1;
  ahbEnvironmentConfig.operationMode        = WRITE_READ ;
   
  ahbEnvironmentConfig.ahbMasterAgentConfig = new[ahbEnvironmentConfig.noOfMasters];
  foreach(ahbEnvironmentConfig.ahbMasterAgentConfig[i]) begin
    ahbEnvironmentConfig.ahbMasterAgentConfig[i] = AhbMasterAgentConfig::type_id::create($sformatf("AhbMasterAgentConfig[%0d]",i));
  end
  setupAhbMasterAgentConfig();

  foreach(ahbEnvironmentConfig.ahbMasterAgentConfig[i]) begin
   uvm_config_db #(AhbMasterAgentConfig)::set(this,"*",$sformatf("AhbMasterAgentConfig[%0d]",i),ahbEnvironmentConfig.ahbMasterAgentConfig[i]);
  `uvm_info(get_type_name(),$sformatf("\nAHB_MASTER_CONFIG[%0d]\n%s",i,ahbEnvironmentConfig.ahbMasterAgentConfig[i].sprint()),UVM_LOW);
  end

  ahbEnvironmentConfig.ahbSlaveAgentConfig = new[ahbEnvironmentConfig.noOfSlaves];
  foreach(ahbEnvironmentConfig.ahbSlaveAgentConfig[i]) begin
    ahbEnvironmentConfig.ahbSlaveAgentConfig[i] = AhbSlaveAgentConfig::type_id::create($sformatf("AhbSlaveAgentConfig[%0d]",i));
  end

  setupAhbSlaveAgentConfig();
 
  foreach(ahbEnvironmentConfig.ahbSlaveAgentConfig[i]) begin
    uvm_config_db #(AhbSlaveAgentConfig)::set(this,"*",$sformatf("AhbSlaveAgentConfig[%0d]",i),ahbEnvironmentConfig.ahbSlaveAgentConfig[i]);
    `uvm_info(get_type_name(),$sformatf("\nAHB_SLAVE_CONFIG[%0d]\n%s",i,ahbEnvironmentConfig.ahbSlaveAgentConfig[i].sprint()),UVM_LOW);
  end

  uvm_config_db#(AhbEnvironmentConfig)::set(this,"*","AhbEnvironmentConfig",ahbEnvironmentConfig);
  `uvm_info(get_type_name(),$sformatf("\nAHB_ENV_CONFIG\n%s",ahbEnvironmentConfig.sprint()),UVM_LOW);

endfunction : setupAhbEnvironmentConfig

function void setupAhbMasterAgentConfig();
  
  foreach(ahbEnvironmentConfig.ahbMasterAgentConfig[i]) begin
    if(AHB_AHB_MASTER_AGENT_ACTIVE === 1) begin
      ahbEnvironmentConfig.ahbMasterAgentConfig[i].is_active = uvm_active_passive_enum'(UVM_ACTIVE);
    end
    else begin
      ahbEnvironmentConfig.ahbMasterAgentConfig[i].is_active = uvm_active_passive_enum'(UVM_PASSIVE);
    end
    ahbEnvironmentConfig.ahbMasterAgentConfig[i].hasCoverage = 1; 
  end

endfunction : setupAhbMasterAgentConfig

function void setupAhbSlaveAgentConfig();
  
  foreach(ahbEnvironmentConfig.ahbSlaveAgentConfig[i]) begin
    if(AHB_SLAVE_AGENT_ACTIVE === 1) begin
      ahbEnvironmentConfig.ahbSlaveAgentConfig[i].is_active = uvm_active_passive_enum'(UVM_ACTIVE);
    end
    else begin
      ahbEnvironmentConfig.ahbSlaveAgentConfig[i].is_active = uvm_active_passive_enum'(UVM_PASSIVE);
    end
    ahbEnvironmentConfig.ahbSlaveAgentConfig[i].hasCoverage = 1; 
  end

endfunction : setupAhbSlaveAgentConfig

function void setup_axi4_env_cfg();
  axi4_env_cfg_h = axi4_env_config::type_id::create("axi4_env_cfg_h");
 
  axi4_env_cfg_h.has_scoreboard = 0;
  axi4_env_cfg_h.has_virtual_seqr = 1;
  axi4_env_cfg_h.no_of_masters = NO_OF_MASTERS;
  axi4_env_cfg_h.no_of_slaves = NO_OF_SLAVES;

  // Setup the axi4_master agent cfg 
  setup_axi4_master_agent_cfg();
  set_and_display_master_config();

  // Setup the axi4_slave agent cfg 
  setup_axi4_slave_agent_cfg();
  set_and_display_slave_config();

  axi4_env_cfg_h.write_read_mode_h = WRITE_READ_DATA;

  // set method for axi4_env_cfg
  uvm_config_db #(axi4_env_config)::set(this,"*","axi4_env_config",axi4_env_cfg_h);
  `uvm_info(get_type_name(),$sformatf("\nAXI4_ENV_CONFIG\n%s",axi4_env_cfg_h.sprint()),UVM_LOW);
endfunction: setup_axi4_env_cfg

function void setup_axi4_master_agent_cfg();
  bit [63:0]local_min_address;
  bit [63:0]local_max_address;
  axi4_env_cfg_h.axi4_master_agent_cfg_h = new[axi4_env_cfg_h.no_of_masters];
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i])begin
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i] =
    axi4_master_agent_config::type_id::create($sformatf("axi4_master_agent_cfg_h[%0d]",i));
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].is_active   = uvm_active_passive_enum'(UVM_ACTIVE);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].has_coverage = 1; 
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
  end

  for(int i =0; i<NO_OF_SLAVES; i++) begin
    if(i == 0) begin  
      axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_min_addr_range(i,0);
      local_min_address = axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_min_addr_range_array[i];
      axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_max_addr_range(i,2**(SLAVE_MEMORY_SIZE)-1 );
      local_max_address = axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_max_addr_range_array[i];
    end
    else begin
      axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_min_addr_range(i,local_max_address + SLAVE_MEMORY_GAP);
      local_min_address = axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_min_addr_range_array[i];
      axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_max_addr_range(i,local_max_address+ 2**(SLAVE_MEMORY_SIZE)-1 + 
                                                                      SLAVE_MEMORY_GAP);
      local_max_address = axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_max_addr_range_array[i];
    end
  end
endfunction: setup_axi4_master_agent_cfg

function void set_and_display_master_config();
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i])begin
    uvm_config_db#(axi4_master_agent_config)::set(this,"*env*",$sformatf("axi4_master_agent_config[%0d]",i),axi4_env_cfg_h.axi4_master_agent_cfg_h[i]);
   `uvm_info(get_type_name(),$sformatf("\nAXI4_MASTER_CONFIG[%0d]\n%s",i,axi4_env_cfg_h.axi4_master_agent_cfg_h[i].sprint()),UVM_LOW);
 end
endfunction: set_and_display_master_config

function void setup_axi4_slave_agent_cfg();
  axi4_env_cfg_h.axi4_slave_agent_cfg_h = new[axi4_env_cfg_h.no_of_slaves];
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i])begin
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i] =
    axi4_slave_agent_config::type_id::create($sformatf("axi4_slave_agent_cfg_h[%0d]",i));
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].slave_id = i;
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = axi4_env_cfg_h.axi4_master_agent_cfg_h[i].
                                                           master_min_addr_range_array[i];
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address = axi4_env_cfg_h.axi4_master_agent_cfg_h[i].
                                                           master_max_addr_range_array[i];
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].maximum_transactions = 3;
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode = SLAVE_MEM_MODE;
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].slave_response_mode = RESP_IN_ORDER;
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;

    
    if(SLAVE_AGENT_ACTIVE === 1) begin
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].is_active = uvm_active_passive_enum'(UVM_ACTIVE);
    end
    else begin
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].is_active = uvm_active_passive_enum'(UVM_PASSIVE);
    end 
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].has_coverage = 1; 
    
  end
endfunction: setup_axi4_slave_agent_cfg

function void set_and_display_slave_config();
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i])begin
    uvm_config_db #(axi4_slave_agent_config)::set(this,"*env*",$sformatf("axi4_slave_agent_config[%0d]",i), axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]);   
    uvm_config_db #(read_data_type_mode_e)::set(this,"*","read_data_mode",axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode);   
   `uvm_info(get_type_name(),$sformatf("\nAXI4_SLAVE_CONFIG[%0d]\n%s",i,axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].sprint()),UVM_LOW);
 end
endfunction: set_and_display_slave_config

endclass //soc_base_test_c
