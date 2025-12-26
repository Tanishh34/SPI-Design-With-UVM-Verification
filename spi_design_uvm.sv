module spi_controller(input clk,
                      input rst,
                      input wr,
                      input [7:0]addr,
                      input [7:0]din,
                      input ready,
                      input op_done,
                      input miso,
                      output [7:0]dout,
                      output reg err,
                      output reg mosi,
                      output reg done,
                      output reg cs
                     );
  reg [16:0]d_reg;
  integer count=0;
  reg [7:0]d_out;
  
  typedef enum bit[3:0]{idle=4'b0000,load=4'b0001,operation=4'b0010,write=4'b0011,read1=4'b0100,error_check=4'b0101,donee=4'b0110,check_ready=4'b0111,read2=4'b1000} state_type;
  state_type state=idle;
  
  always@(posedge clk) begin
    if(rst)begin
      mosi<=0;
      cs<=1;
      err<=0;
      done<=0;
      count<=0;
      state<=idle;
    end
    else begin
      case(state)
        idle:begin
          d_out<=0;
          err<=0;
          mosi<=0;
          cs<=1;
          done<=0;
          state<=load;
        end
         load:begin
           d_reg<={din,addr,wr};
           state<=operation;
         end
        operation:begin
          if(wr==1 && addr<32)begin
            cs<=0;
            state<=write;
          end
          else if(wr==0 && addr<32)begin
            cs<=0;
            state<=read1;
          end
          else begin
            state<=error_check;
            cs<=1;
          end
        end
        write:begin
          if(count<17)
            begin
              mosi<=d_reg[count];
              count<=count+1;
              state<=write;
            end
          else
            begin
              cs<=1;
              mosi<=0;
              if(op_done)begin
                count<=0;
                state<=donee;
              end
              else
                state<=write;
            end
        end
        read1:begin
          if(count<9)begin
            mosi<=d_reg[count];
            count<=count+1;
            state<=read1;
          end
          else
            begin
              count<=0;
              cs<=1;
              state<=check_ready;
            end
        end
        check_ready:begin 
          if(ready==1)
            state<=read2;
          else
            state<=check_ready;
        end
        read2:begin
          if(count<8)begin
            d_out[count]<=miso;
            count<=count+1;
          end
          else begin
            count<=0;
            state<=donee;
          end
        end
        error_check:begin
          err<=1;
          state<=donee;
        end
        donee:begin
          done=1;
          state=idle;
        end
        default:begin
          state<=idle;
          count<=0;
        end
      endcase
    end
  end
  assign dout=d_out;
endmodule

module spi_memory(input clk,
                  input rst,
                  input mosi,
                  input cs,
                  output reg ready,
                  output reg miso,
                  output reg done
                 );
  reg [7:0]mem[31:0]='{default:0};
  integer count=0;
  reg [15:0]d_reg;
  reg [7:0]data_out;
    typedef enum bit[2:0]{idle=3'b000,detect=3'b001,store=3'b010,store_data=3'b011,send_addr=3'b100,send_data=3'b101,donee=3'b110}state_type;
  state_type state=idle;
  always@(posedge clk) begin
    if(rst)
      begin
        ready<=0;
        miso<=0;
        count<=0;
        state<=idle;
        done<=0;
      end
    else begin
      case(state)
        idle:begin
          count<=0;
          ready<=0;
          miso<=0;
          done<=0;
          d_reg<=0;
          if(cs==0)begin
            state<=detect;
          end
          else
            state<=idle;
        end
        detect:begin
          if(mosi)
            state<=store;
          else
            state<=send_addr;
        end
        store:begin
          if(count<16)begin
            d_reg[count]<=mosi;
            count<=count+1;
            state<=store;
          end
          else
            begin
              count<=0;
              state<=store_data;
            end
        end
        store_data:begin 
          mem[d_reg[7:0]]<=d_reg[15:8];
          state<=donee;
        end
        send_addr:begin
          if(count<8)begin
            d_reg[count]<=mosi;
            count<=count+1;
            state<=send_addr;
          end
          else begin
            count<=0;
            ready<=1;
            state<=send_data;
            data_out<=mem[d_reg];
          end
        end
        send_data:begin
          if(count<8)begin
            miso<=data_out[count];
            count<=count+1;
            state<=send_data;
          end
          else begin
            count<=0;
            ready<=0;
            state<=donee;
          end
        end
        donee:begin
          done=1;
          state=idle;
        end
        default:begin state<=idle; end
      endcase
    end
  end
endmodule

module spi(input clk,
           input rst,
           input [7:0]addr,
           input wr,
           input [7:0]din,
           output reg [7:0]dout,
           output reg err,
           output reg done
          );
  wire miso,cs,ready,mosi,op_done;
  
  spi_controller uut1(clk,rst,wr,addr,din,ready,op_done,miso,dout,err,mosi,done,cs);
  spi_memory uut2(clk,rst,mosi,cs,ready,miso,op_done);
endmodule

interface spi_if;
  logic clk;
  logic rst;
  logic [7:0]addr;
  logic wr;
  logic [7:0]din;
  logic [7:0]dout;
  logic err;
  logic done;
endinterface
    
