`include "uvm_macros.svh"
import uvm_pkg::*;

class uvm_config extends uvm_object;
  `uvm_object_utils(uvm_config)
  
  function new(string path="uvm_config");
    super.new(path);
  endfunction
  
  uvm_active_passive_enum is_active=UVM_ACTIVE;
endclass

class transaction extends uvm_sequence_item;
  `uvm_object_utils(transaction)
  
  function new(string path="trans");
    super.new(path);
  endfunction
  
  logic wr;
  logic rst;
  rand logic[7:0]addr;
  rand logic[7:0]din;
  logic [7:0]dout;
  logic err;
  logic done;
  
  constraint ad{addr<32;}
  constraint ad_err{addr>32;}
endclass

class write_data extends uvm_sequence#(transaction);
  `uvm_object_utils(write_data)
  
  transaction t;
  
  function new(string path="write_data");
    super.new(path);
  endfunction
  
  virtual task body();
    repeat(15)begin
      t=transaction::type_id::create("t");
      t.ad.constraint_mode(1);
      t.ad_err.constraint_mode(0);
      start_item(t);
      assert(t.randomize())else `uvm_error("seq1","RANDOMIZATION FAILED!");
      t.wr=1;
      finish_item(t);
    end
  endtask
endclass
class write_err extends uvm_sequence#(transaction);
  `uvm_object_utils(write_err)
  
  transaction t;
  
  function new(string path="write_err");
    super.new(path);
  endfunction
  
  virtual task body();
    repeat(15)begin
      t=transaction::type_id::create("t");
      t.ad.constraint_mode(0);
      t.ad_err.constraint_mode(1);
      start_item(t);
      assert(t.randomize())else `uvm_error("seq1","RANDOMIZATION FAILED!");
      t.wr=1;
      finish_item(t);
    end
  endtask
endclass
class read_data extends uvm_sequence#(transaction);
  `uvm_object_utils(read_data)
  
  transaction t;
  
  function new(string path="read_data");
    super.new(path);
  endfunction
  
  virtual task body();
    repeat(15)begin
      t=transaction::type_id::create("t");
      t.ad.constraint_mode(1);
      t.ad_err.constraint_mode(0);
      start_item(t);
      assert(t.randomize())else `uvm_error("seq1","RANDOMIZATION FAILED!");
      t.wr=0;
      finish_item(t);
    end
  endtask
endclass
class read_err extends uvm_sequence#(transaction);
  `uvm_object_utils(read_err)
  
  transaction t;
  
  function new(string path="read_err");
    super.new(path);
  endfunction
  
  virtual task body();
    repeat(15)begin
      t=transaction::type_id::create("t");
      t.ad.constraint_mode(0);
      t.ad_err.constraint_mode(1);
      start_item(t);
      assert(t.randomize())else `uvm_error("seq1","RANDOMIZATION FAILED!");
      t.wr=0;
      finish_item(t);
    end
  endtask
endclass
class reset_dut extends uvm_sequence#(transaction);
  `uvm_object_utils(reset_dut)
  
  transaction t;
  
  function new(string path="reset_dut");
    super.new(path);
  endfunction
  
  virtual task body();
    repeat(15)begin
      t=transaction::type_id::create("t");
      t.ad.constraint_mode(1);
      t.ad_err.constraint_mode(0);
      start_item(t);
      assert(t.randomize())else `uvm_error("seq1","RANDOMIZATION FAILED!");
      t.rst=1;
      finish_item(t);
    end
  endtask
endclass
class writeb_readb extends uvm_sequence#(transaction);
  `uvm_object_utils(writeb_readb)
  
  transaction t;
  
  function new(string path="writeb_readb");
    super.new(path);
  endfunction
  
  virtual task body();
    repeat(10)begin
      t=transaction::type_id::create("t");
      t.ad.constraint_mode(1);
      t.ad_err.constraint_mode(0);
      start_item(t);
      assert(t.randomize())else `uvm_error("seq1","RANDOMIZATION FAILED!");
      t.wr=1;
      finish_item(t);
    end
    
    repeat(10)begin
      t=transaction::type_id::create("t");
      t.ad.constraint_mode(1);
      t.ad_err.constraint_mode(0);
      start_item(t);
      assert(t.randomize())else `uvm_error("seq1","RANDOMIZATION FAILED!");
      t.wr=0;
      finish_item(t);
    end
  endtask
endclass

class driver extends uvm_driver#(transaction);
  `uvm_component_utils(driver)
  
  virtual spi_if f;
  transaction tr;
  
  function new(string path="driver",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr=transaction::type_id::create("trans");
    if(!uvm_config_db#(virtual spi_if)::get(this,"","f",f))
       `uvm_error("drv","INTERFACE MISMATCHED!");
  endfunction
  
  task reset();
    f.rst<=1;
    f.wr<=0;
    f.din<=0;
    f.addr<=0;
    repeat(5)@(posedge f.clk);
    f.rst<=0;
    `uvm_info("drv","RESET DONE!",UVM_NONE);
  endtask
  
  task main();
    reset();
    forever begin
      seq_item_port.get_next_item(tr);
      if(tr.rst==1)begin
        f.rst<=1;
        `uvm_info("drv","RESET SYSTEM!",UVM_NONE);
        @(posedge f.clk);
      end
      else if(tr.wr==1)begin
        f.rst<=0;
        f.wr<=tr.wr;
        f.addr<=tr.addr;
        f.din<=tr.din;
        @(posedge f.clk);
        `uvm_info("drv",$sformatf("wr:[%0d],address:[%0d],din:[%0d]",tr.wr,tr.addr,tr.din),UVM_NONE);
        @(posedge f.done);
      end
      else if(tr.wr==0)begin
        f.rst<=0;
        f.wr<=tr.wr;
        f.addr<=tr.addr;
        @(posedge f.clk);
        `uvm_info("drv",$sformatf("wr:[%0d],address:[%0d]",tr.wr,tr.addr),UVM_NONE);
        @(posedge f.done);
      end
      seq_item_port.item_done();
    end
  endtask
  
  virtual task run_phase(uvm_phase phase);
    main();
  endtask
endclass

class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)
  
  uvm_analysis_port#(transaction) send;
  
  virtual spi_if f;
  transaction ts;
  
  function new(string path="mon",uvm_component parent=null);
    super.new(path,parent);
    send=new("send",this);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ts=transaction::type_id::create("trans");
    if(!uvm_config_db#(virtual spi_if)::get(this,"","f",f))
       `uvm_error("drv","INTERFACE MISMATCHED!");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever begin
      @(posedge f.clk);
      if(f.rst)
        begin
          `uvm_info("mon","RESET SYSTEM!",UVM_NONE);
          send.write(ts);
        end
      else if(!f.rst && f.wr)begin
        @(posedge f.done);
        ts.wr=f.wr;
        ts.addr=f.addr;
        ts.din=f.din;
        ts.err=f.err;
        ts.done=f.done;
        `uvm_info("mon",$sformatf("wr:[%0d],addr:[%0d],din:[%0d],err:[%0d],done:[%0d]",f.wr,f.addr,f.din,f.err,f.done),UVM_NONE);
        send.write(ts);
      end
      else if(!f.rst && !f.wr)begin
        @(posedge f.done);
        ts.wr=f.wr;
        ts.addr=f.addr;
        ts.dout=f.dout;
        ts.err=f.err;
        `uvm_info("mon",$sformatf("wr:[%0d],addr:[%0d],dout:[%0d],err:[%0d]",f.wr,f.addr,f.dout,f.err),UVM_NONE);
        send.write(ts);
      end
    end
  endtask
endclass

class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)
  
  uvm_analysis_imp#(transaction,scoreboard) recv;
  bit [31:0]arr[32]='{default:0};
  bit [7:0]data_rd;
  
  function new(string path="sco",uvm_component parent=null);
    super.new(path,parent);
    recv=new("recv",this);
  endfunction
  
  virtual function void write(transaction tt);
    if(tt.rst==1)begin
      `uvm_info("sco","SYSTEM RESET!",UVM_NONE);
    end
    else if(tt.wr==1)begin
      if(tt.err==1)begin
        `uvm_info("sco","ERROR DETECTED!",UVM_NONE);
      end
      else begin
        arr[tt.addr]=tt.din;
        `uvm_info("sco",$sformatf("data:[%0d] stored at address:[%0d]",tt.din,tt.addr),UVM_NONE);
      end
    end
    else if(tt.wr==0)begin
      if(tt.err==1)begin
        `uvm_info("sco","ERROR DETECTED!",UVM_NONE);
      end
      else begin
        data_rd=arr[tt.addr];
        if(data_rd==tt.dout)begin
          `uvm_info("sco","TEST PASSED!",UVM_NONE);
        end
        else
          `uvm_info("sco","TEST FAILED!",UVM_NONE);
      end
    end
    $display("----------------------------------------------------------");
  endfunction
endclass
class agent extends uvm_agent;
  `uvm_component_utils(agent)
  
  uvm_config con;
  
  uvm_sequencer#(transaction) seqr;
  driver drv;
  monitor mon;
  
  function new(string path="agent",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    con=uvm_config::type_id::create("config");
    mon=monitor::type_id::create("mon",this);
    if(con.is_active==UVM_ACTIVE)begin
      seqr=uvm_sequencer#(transaction)::type_id::create("seqr",this);
      drv=driver::type_id::create("drv",this);
    end
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(con.is_active==UVM_ACTIVE)begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction
endclass
class env extends uvm_env;
  `uvm_component_utils(env)
  
  scoreboard sco;
  agent ag;
  
  function new(string path="env",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sco=scoreboard::type_id::create("sco",this);
    ag=agent::type_id::create("ag",this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ag.mon.send.connect(sco.recv);
  endfunction
endclass
class test extends uvm_test;
  `uvm_component_utils(test)
  
  env e;
  write_data wd;
  write_err we;
  read_data rd;
  read_err re;
  reset_dut rs;
  writeb_readb wrb;
  
  function new(string path="test",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
   virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
     wd=write_data::type_id::create("wd");
     we=write_err::type_id::create("we");
     rd=read_data::type_id::create("rd");
     re=read_err::type_id::create("re");
     rs=reset_dut::type_id::create("rs");
     wrb=writeb_readb::type_id::create("wrb");
     e=env::type_id::create("e",this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    wrb.start(e.ag.seqr);
    #20;
    phase.drop_objection(this);
  endtask
endclass

module tb;
  spi_if f();
  
  spi dut(f.clk,f.rst,f.addr,f.wr,f.din,f.dout,f.err,f.done);
  initial f.clk<=0;
  
  always #10 f.clk<=~f.clk;
  
  initial begin
    uvm_config_db#(virtual spi_if)::set(null,"*","f",f);
    run_test("test");
  end
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0,tb);
  end
endmodule
  
  
  
  
  
  
  
  
  
          
        
        
        
  
    
  
  
  
  

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
