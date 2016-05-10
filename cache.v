`timescale 1ns/10ps

`define num_of_blocks  128 //no: of entries in cache
`define mem_addr_width 9   //no: of bits for memory address
`define data_width     8   //no: of bits for data

//models a direct-mapped cache, cache controller and MOESI protocol FSM
//
// Cache Block Organization
//---------------------------------------------------------------
// Bits[15:13] | Bits[12:10] | Bits[9:8] | Bits[7:0] |
// --------------------------------------------------------------
//   UNUSED    |   STATE     |    TAG    |   DATA    |

module cache (clk,
	      rst_n,
              cpu_write_request,
              cpu_write_addr,
              cpu_write_data,
              cpu_write_ack,
              cpu_read_request, 
              cpu_read_addr,
              cpu_read_data,
              cpu_read_ack,
              ReadEx,
              Cache_Request_Addr,
              Mem_cache_data,
              ReadEx_Ack,
              ReadS,
              ReadS_Ack,
              shared,
              GetS,
              GetS_Addr,
              GetS_Ack,
              owned_data,
              Invalid,
              Invalid_Addr,
              WB_data,
              Invalid_Ack,
              write_back,
              write_back_tag,
              retry_request,
              core_id              
);

//global clock, reset signals
input clk;
input rst_n;

//CPU-Mem system write signals
input                       cpu_write_request; //write request from cpu
input [`mem_addr_width-1:0] cpu_write_addr;    //address to be written to
input [`data_width-1:0]     cpu_write_data;    //data to be written
output reg                  cpu_write_ack;     //ack back indicating that the write request is processed

//CPU-Mem System read signals
input                        cpu_read_request;
input [`mem_addr_width-1:0]  cpu_read_addr;
output reg [`data_width-1:0] cpu_read_data; //data that is given back to CPU for read request
output reg                   cpu_read_ack;  //Ack indicating that the read request is processed

//Cache <-> Directory signals for exclusive access of a block
output reg                       ReadEx;      //request to directory for exclusive access
output reg [`mem_addr_width-1:0] Cache_Request_Addr; //Address for which exclusive or shared access is requested
input      [`data_width-1:0]     Mem_cache_data; //get the latest data from lower level cache or owned data from same level cache
input                            ReadEx_Ack;  //Ack from directory. It should be a pulse

//Cache <-> Directory signals to get shared access of a block
//on a cpu read, cache requests directory to give a shared access of the block if cache doesn't have it.
//This interface takes care of that

output reg                        ReadS;       //request from cache 
input                             ReadS_Ack;   //Ack from directory. It should be pulse
input                             shared;      //indicates whether a block is available in other cpu too

//Cache <-> Directory signals to give shared access to a block
// If directory knows that a cache owns a block (O or M) it requests that cache to provide shared access along with the data to the CPU that requested for it

input                            GetS;       
input      [`mem_addr_width-1:0] GetS_Addr;  //Address for which shared access is requested
output reg                       GetS_Ack;   //Acknowledgement sent back to directory
output reg [`data_width-1:0]     owned_data;

///Cache <-> Directory signals to invalidate a block from cache
input                        Invalid;      //only directory can send invalid request
input [`mem_addr_width-1:0]  Invalid_Addr; //Address to invalidate 
output reg [`data_width-1:0] WB_data;      //write back either on invalid or eviction
output reg                   Invalid_Ack;  //acknowledgement for invalidation request from directory

//Cache <-> Directory signals to write back a block on eviction
//Since a block is evicted only on a read or write miss, send the tag and data of the block that is being evicted
output reg       write_back;
output reg [1:0] write_back_tag;            

//retry the request
input retry_request; //directory sends retry request/NACK (negative acknowledgement) to cache, becasue the address is being accessed by another cpu

//Tell which core the cache instance belongs to
input [1:0] core_id;

//MOESI FSM encoding
parameter S_M = 3'b100;
parameter S_O = 3'b011;
parameter S_E = 3'b010;
parameter S_S = 3'b001;
parameter S_I = 3'b000;

//internal wires and reg
reg Invalid_1, Invalid_2, invalid_pulse, invalid_pulse_1, nxt_invalid_ack;

reg GetS_pulse, GetS_pulse_1, GetS_1, GetS_2, nxt_gets_ack;

reg cpu_write_request_1, cpu_write_request_2, cpu_read_request_1, cpu_read_request_2;

reg [2:0]  state, nxt_state;
reg [`data_width-1:0] nxt_data;

reg [`data_width-1:0] nxt_wb_data, nxt_owned_data;
reg                   nxt_write_back;
reg [1:0]             nxt_wb_tag;

reg [15:0] buffer [0:127];
reg [15:0] cache_line;

reg [`mem_addr_width-1:0] address, dir_address;
reg [6:0]                 cpu_addr_index, dir_addr_index;
reg [1:0]                 cpu_addr_tag, dir_addr_tag;

reg                       nxt_readex, nxt_reads;
reg [`mem_addr_width-1:0] nxt_cache_addr;

reg hit; //cache hit or miss

always @ (*) begin
if (cpu_write_request == 1'b1)
   address = cpu_write_addr;
else if (cpu_read_request == 1'b1)
   address = cpu_read_addr;
else
   address = 9'b0;

cpu_addr_index = address % 128; //determine the index for a read/write request from CPU
cpu_addr_tag   = address [8:7]; //determine the tag of incoming read/write request
end

always @ (*) begin
if (Invalid == 1'b1)
   dir_address = Invalid_Addr;
else if (GetS == 1'b1)
   dir_address = GetS_Addr;
else
   dir_address = 9'b0;

dir_addr_index = dir_address % 128; //determine the index of the address for which invalidation/shared request is sent by directory
dir_addr_tag   = dir_address [8:7]; //determine the tag of address for which invalidation/shared request is sent by directory
end

//Determine for a cpu request if it is a cache hit or miss
//There is a window where hit will be falsely asserted on block allocatin after a miss
//To avoid this scenario, use read/write ack to determine only true hits
always @ (*) begin
  if (((cpu_write_request_1 == 1'b1) && (cpu_write_request != 1'b0) && (cpu_write_ack == 1'b0)) || 
      ((cpu_read_request_1 == 1'b1) && (cpu_read_request != 1'b0) && (cpu_read_ack == 1'b0))) begin 
    if ((cache_line [9:8] == cpu_addr_tag) && (cache_line [12:10] != S_I)) begin //check state and tag bits. If state is anything other than invalid then it is a hit
      hit = 1'b1;
    end else begin
      hit = 1'b0;
    end
  end else begin
    hit = 1'b0;
  end
end

//generate 1,2 cycle delayed versions of requests that come to cache
always @ (posedge clk) begin
  if  (rst_n == 1'b0) begin
   Invalid_1           <= 1'b0;
   Invalid_2           <= 1'b0;
   GetS_1              <= 1'b0;
   GetS_2              <= 1'b0;
   cpu_write_request_1 <= 1'b0;
   cpu_write_request_2 <= 1'b0;
   cpu_read_request_1  <= 1'b0;
   cpu_read_request_2  <= 1'b0;
  end else begin 
   Invalid_1           <= Invalid;
   Invalid_2           <= Invalid_1;
   GetS_1              <= GetS;
   GetS_2              <= GetS_1;
   cpu_write_request_1 <= cpu_write_request;
   cpu_write_request_2 <= cpu_write_request_1;
   cpu_read_request_1  <= cpu_read_request;
   cpu_read_request_2  <= cpu_read_request_1;
  end 
end

always @ (*) begin
invalid_pulse     = (Invalid_1 ^ Invalid) & Invalid; //generate pulse at the same time when invalid request comes. Used to latch state value on invalid request
invalid_pulse_1   = (Invalid_1 ^ Invalid_2) & Invalid_1; //generate pulse one cycle after invalid request comes
GetS_pulse        = (GetS_1 ^ GetS) & GetS; //generate pulse at the same time when GetS request comes.Used to latch state value on Shared request
GetS_pulse_1      = (GetS_1 ^ GetS_2) & GetS_1; //generate pulse one cycle after GetS request comes
end

//readex and reads requests to directory
always @ (posedge clk) begin
  if (rst_n == 1'b0) begin //reset value
    ReadEx             <= 1'b0;
    Cache_Request_Addr <= 8'b0;
    ReadS              <= 1'b0;
  end else begin
    ReadEx             <= nxt_readex;
    Cache_Request_Addr <= nxt_cache_addr;
    ReadS              <= nxt_reads;
    write_back         <= nxt_write_back;
    write_back_tag     <= nxt_wb_tag;
  end
end
 
//read acknowledgement and read data
always @ (posedge clk) begin
  if (rst_n == 1'b0) begin //reset value
    cpu_read_ack  <= 1'b0;
    cpu_read_data <= 8'b0;
  end else if ((cpu_read_request_2 == 1'b1) && (cpu_read_request == 1'b1) && (cpu_read_ack == 1'b0)) begin
    if (hit == 1'b1) begin
      cpu_read_ack  <= 1'b1;
      cpu_read_data <= buffer [cpu_addr_index] [7:0];
    end else if (hit == 1'b0) begin
      if (ReadS_Ack == 1'b1) begin //if it is a miss, wait for ack from directory for ReadS request
        cpu_read_ack  <= 1'b1;
        cpu_read_data <= nxt_data;
      end
    end
  end else if (cpu_read_ack == 1'b1) begin  //only generate a pulse for the read acknowledgement
    cpu_read_ack  <= 1'b0;
    cpu_read_data <= 8'b0;
  end else begin
    cpu_read_ack  <= 1'b0; //default values
    cpu_read_data <= 8'b0;
  end
end //always

//write acknowledgement
always @ (posedge clk) begin
  if (rst_n == 1'b0) begin //reset value
    cpu_write_ack <= 1'b0;
  end else if ((cpu_write_request_2 == 1'b1) && (cpu_write_request == 1'b1) && (cpu_write_ack == 1'b0)) begin   //process a write request
    if (hit == 1'b1) begin  //if the block is present
      if ((cache_line [12:10] == S_M) || (cache_line == S_E)) begin //if the block has latest data then need not wait for any acknowledgement from directory 
        cpu_write_ack <= 1'b1;
      end else if ((cache_line [12:10] == S_S) || (cache_line [12:10] == S_O)) begin //if block is in S or O state, wait for acknowedgement from directory for ReadEx request
        if (ReadEx_Ack == 1'b1) begin
          cpu_write_ack <= 1'b1;
        end 
      end
    end else if (hit == 1'b0) begin //on a write miss, wait for ReadEx_Ack and then assert write ack once block is allocated
          if (ReadEx_Ack == 1'b1) begin
            cpu_write_ack <= 1'b1;
          end
    end
  end else if (cpu_write_ack == 1'b1) begin //only generate a pulse for the write acknowledgement
    cpu_write_ack <= 1'b0;
  end else begin
    cpu_write_ack <= 1'b0; //default
  end
end //always

integer i;

always @ (posedge clk) begin
 if (rst_n == 1'b0) begin
  cache_line <= 16'b0;
 end else
 if ((Invalid == 1'b1) || (GetS == 1'b1)) begin
  cache_line <= buffer [dir_addr_index];
 end else if ((cpu_write_request == 1'b1) || (cpu_read_request == 1'b1)) begin
  cache_line <= buffer [cpu_addr_index];
 end else begin
  cache_line <= 16'b0;
 end
end

always @ (posedge clk) begin
  if (rst_n == 1'b0) begin  //reset cache buffer, read and write ack 
    for (i= 0; i < `num_of_blocks; i = i + 1) begin
      buffer [i]  <= 16'b0; //reset the register file
    end
  end else if ((invalid_pulse_1 == 1'b1) && (cache_line [9:8] == dir_addr_tag) && (cache_line [12:10] != S_I)) begin
    buffer [dir_addr_index] [12:10] <= nxt_state; //on invalid request from directory, change state to invalid
  end else if (GetS_pulse_1 == 1'b1) begin
    buffer [dir_addr_index] [12:10] <= nxt_state; //FSM will give the next state when there is a shared request from directory
  end else if ((cpu_write_request_2 == 1'b1) && (cpu_write_request == 1'b1)) begin   //process a write request
    if (hit == 1'b1) begin  //if the block is present
      if ((cache_line [12:10] == S_M) || (cache_line [12:10] == S_E)) begin
            buffer [cpu_addr_index] [7:0]   <= nxt_data;
            buffer [cpu_addr_index] [12:10] <= nxt_state;
      end else if ((cache_line [12:10] == S_S) || (cache_line [12:10] == S_O)) begin //on a write request if the cache is not in Ex or M state then wait for ack of ReadEx request
          if (ReadEx_Ack == 1'b1) begin
            buffer [cpu_addr_index] [7:0]   <= nxt_data;
            buffer [cpu_addr_index] [12:10] <= nxt_state;
          end
      end
    end else if (hit == 1'b0) begin //on a write miss, wait for ReadEx_Ack and then allocate the block and copy the data
          //if ((ReadEx_Ack == 1'b1) && (cpu_write_ack == 1'b0)) begin //wait for the ack from directory
          if (ReadEx_Ack == 1'b1) begin //wait for the ack from directory
            buffer [cpu_addr_index] [15:0]   <= {3'b0,S_M,cpu_addr_tag,cpu_write_data};
          end
    end 
  end else if ((cpu_read_request_2 == 1'b1) && (cpu_read_request == 1'b1)) begin //process a read request
    if (hit == 1'b1) begin  //if the block is present (any state other than I)
              buffer [cpu_addr_index] [12:10] <= nxt_state;
    end else if (hit == 1'b0) begin //on a read miss wait for ack of ReadS request and then allocate block
            //if ((ReadS_Ack == 1'b1) && (cpu_read_ack == 1'b0)) begin
            if (ReadS_Ack == 1'b1) begin
              buffer [cpu_addr_index] <= {3'b0,nxt_state,cpu_addr_tag,nxt_data};
            end
    end 
  end else begin
    for (i= 0; i < `num_of_blocks; i = i + 1) begin
      buffer [i] <= buffer [i]; //preserve the values
    end
  end
end

//WB data 
always @ (posedge clk) begin
  if (rst_n == 1'b0) begin
       WB_data      <= 8'b0;
       owned_data   <= 8'b0;
  end else begin
       WB_data      <= nxt_wb_data; //send data to the directory/next level cache on invalidation or eviction 
       owned_data   <= nxt_owned_data; //send owned data to the cache that requested for a read 
  end 
end

//determine the state of block for which cpu/directory requests are made
always @ (posedge clk) begin
  if (rst_n == 1'b0) begin
    state    <= 3'b0;
  end else if ((invalid_pulse == 1'b1) || (GetS_pulse == 1'b1)) begin //get the state of address for which invalid request comes
    state    <= (buffer [dir_addr_index] & 16'b0001110000000000) >> 10;
  end else if (hit == 1'b1) begin //if hit, get the state of block for which CPU requests read/write
    state <= (buffer [cpu_addr_index] & 16'b0001110000000000) >> 10;
  end else begin
    state <= 3'b0; //default
  end
end

//Invalid Acknowledgement generation
always @ (posedge clk) begin
  if (rst_n == 1'b0) begin
       Invalid_Ack  <= 1'b0;
  end else if (invalid_pulse_1 == 1'b1) begin
       Invalid_Ack  <= nxt_invalid_ack;
  end else if (Invalid_Ack == 1'b1) begin
       Invalid_Ack  <= 1'b0;      //just generate a pulse for the invalid ack
  end else begin
       Invalid_Ack  <= 1'b0;
  end  
end

//GetS Acknowledgement generation
always @ (posedge clk) begin
  if (rst_n == 1'b0) begin
       GetS_Ack  <= 1'b0;
  end else if (GetS_pulse_1 == 1'b1) begin
       GetS_Ack  <= nxt_gets_ack;
  end else if (GetS_Ack == 1'b1) begin
       GetS_Ack  <= 1'b0;      //just generate a pulse for the invalid ack
  end else begin
       GetS_Ack  <= 1'b0;
  end  
end

//MOESI FSM
always @ (*) begin
  case (state)
    S_I: if (cpu_write_request_2 == 1'b1) begin
                nxt_readex      = 1'b1; //send exclusive assess request to directory along with the address
                nxt_cache_addr  = cpu_write_addr;
                nxt_reads       = 1'b0;
                nxt_owned_data  = 8'b0;
                if ((cpu_addr_tag != buffer [cpu_addr_index] [9:8]) && (buffer [cpu_addr_index] [12:10] != S_I)) begin //If the block to be evicted is not in I state, assert write_back request 
                  nxt_write_back = 1'b1;
                  nxt_wb_tag     = buffer [cpu_addr_index] [9:8];
                  nxt_wb_data    = buffer [cpu_addr_index] [7:0];
                end else begin
                  nxt_write_back = write_back;
                  nxt_wb_tag     = write_back_tag;
                  nxt_wb_data    = WB_data;
                end
                if (ReadEx_Ack) begin //once ack comes from dir, determine the next state and data to be stored in the newly allocated block
                  nxt_state  = S_M;
                  nxt_data   = Mem_cache_data;
                  nxt_readex = 1'b0;
                  nxt_write_back = 1'b0;
                  nxt_wb_tag     = 2'b0;
                  nxt_wb_data    = 8'b0;
                end else begin
                  nxt_state  = state;
                  nxt_data   = 8'b0;
                  nxt_readex = ReadEx;
                  nxt_write_back = write_back;
                  nxt_wb_tag     = write_back_tag;
                  nxt_wb_data    = WB_data;
                end
         end else if (cpu_read_request_2 == 1'b1) begin //should go to either S or E based on sharer information
                nxt_reads       = 1'b1;
                nxt_cache_addr  = cpu_read_addr;
                nxt_readex      = 1'b0; //send exclusive assess request to directory along with the address
                nxt_owned_data  = 8'b0;
                if ((cpu_addr_tag != buffer [cpu_addr_index] [9:8]) && (buffer [cpu_addr_index] [12:10] != S_I)) begin //If the block to be evicted is not in I state, assert write_back request 
                  nxt_write_back = 1'b1;
                  nxt_wb_tag     = buffer [cpu_addr_index] [9:8];
                  nxt_wb_data    = buffer [cpu_addr_index] [7:0];
                end else begin
                  nxt_write_back = write_back;
                  nxt_wb_tag     = write_back_tag;
                  nxt_wb_data    = WB_data;
                end
                if (ReadS_Ack) begin //check for ack from directory
                  if (shared == 1'b0) begin //if block is not present in other cpu then next state = E, else S
                    nxt_state = S_E;
                  end else begin
                    nxt_state = S_S;
                  end
                  nxt_data       = Mem_cache_data;
                  nxt_reads      = 1'b0;      //deassert ReadS request
                  nxt_write_back = 1'b0;
                  nxt_wb_tag     = 2'b0;
                  nxt_wb_data    = 8'b0;
                end else begin
                  nxt_state  = state;
                  nxt_data   = 8'b0;
                  nxt_reads = ReadS;
                  nxt_write_back = write_back;
                  nxt_wb_tag     = write_back_tag;
                  nxt_wb_data    = WB_data;
                end //ReadS_Ack
         end else begin //default 
            nxt_state       = S_I;
            nxt_data        = 8'b0;
            nxt_reads       = 1'b0;
            nxt_cache_addr  = 9'b0;
            nxt_readex      = 1'b0;
            nxt_write_back = 1'b0;
            nxt_wb_tag     = 2'b0;
            nxt_wb_data    = 8'b0;
            nxt_owned_data  = 8'b0;
         end 

    S_S: if (invalid_pulse_1 == 1'b1) begin // if invalid request comes, then change state to I and send ack 
		nxt_state       = S_I;
                nxt_invalid_ack = 1'b1;
                nxt_data        = 8'b0;
                nxt_readex      = 1'b0;
                nxt_cache_addr  = 9'b0;
                nxt_reads       = 1'b0;
                nxt_write_back  = 1'b0;
                nxt_wb_tag      = 2'b0;
                nxt_wb_data     = 8'b0;
                nxt_owned_data  = 8'b0;
         end else if (cpu_write_request_2 == 1'b1) begin //if write request comes from cpu change state to M, send read exclusive request to directory.
                nxt_readex      = 1'b1; //send exclusive assess request to directory along with the address
                nxt_cache_addr  = cpu_write_addr;
                nxt_reads       = 1'b0;
                nxt_write_back  = 1'b0;
                nxt_wb_tag      = 2'b0;
                nxt_wb_data     = 8'b0;
                nxt_owned_data  = 8'b0;
                if (ReadEx_Ack) begin //once ack comes from dir, determine the next state of the block
                  nxt_state = S_M;
                  nxt_data  = cpu_write_data;
                  nxt_readex = 1'b0;
                end else begin
                  nxt_state = state;
                  nxt_data  = 8'b0;
                  nxt_readex = ReadEx;
                end
         end else if (cpu_read_request_2 == 1'b1) begin //on cpu read request stay in S state 
                nxt_state = S_S;
                nxt_data        = 8'b0;
                nxt_readex      = 1'b0;
                nxt_cache_addr  = 9'b0;
                nxt_reads       = 1'b0;
                nxt_write_back  = 1'b0;
                nxt_wb_tag      = 2'b0;
                nxt_wb_data     = 8'b0;
                nxt_owned_data  = 8'b0;
         end else begin //default
                nxt_state       = S_S;
                nxt_data        = 8'b0;
                nxt_readex      = 1'b0;
                nxt_cache_addr  = 9'b0;
                nxt_reads       = 1'b0;
                nxt_write_back  = 1'b0;
                nxt_wb_tag      = 2'b0;
                nxt_wb_data     = 8'b0;
                nxt_owned_data  = 8'b0;
         end

    S_E: if (invalid_pulse_1 == 1'b1) begin // if invalid request comes then change state to I, write back the data to memory, and send ack 
		nxt_state = S_I;
                nxt_data  = 8'b0;
                nxt_wb_data = buffer [dir_addr_index] [7:0]; //is it required for E -> I transition ??
                nxt_write_back  = 1'b0;
                nxt_wb_tag      = 2'b0;
                nxt_invalid_ack = 1'b1;
                nxt_readex      = 1'b0;
                nxt_cache_addr  = 9'b0;
                nxt_reads       = 1'b0;
                nxt_owned_data  = 8'b0;
         end else if (GetS_pulse_1 == 1'b1) begin //on a shared request from directory, change the state to S and send ack
                nxt_state = S_S;
                nxt_data  = 8'b0;
                nxt_gets_ack = 1'b1;
                nxt_readex      = 1'b0;
                nxt_cache_addr  = 9'b0;
                nxt_reads       = 1'b0;
                nxt_write_back  = 1'b0;
                nxt_wb_tag      = 2'b0;
                nxt_wb_data     = 8'b0;
                nxt_owned_data  = 8'b0;
         end else if (cpu_write_request_2 == 1'b1) begin
                nxt_state = S_M;
                nxt_data  = cpu_write_data;
                nxt_readex      = 1'b0;
                nxt_cache_addr  = 9'b0;
                nxt_reads       = 1'b0;
                nxt_write_back  = 1'b0;
                nxt_wb_tag      = 2'b0;
                nxt_wb_data     = 8'b0;
                nxt_owned_data  = 8'b0;
         end else if  (cpu_read_request_2 == 1'b1) begin //should go to either S or E based on sharer information
                nxt_state       = S_E;
                nxt_data        = 8'b0;
                nxt_readex      = 1'b0;
                nxt_cache_addr  = 9'b0;
                nxt_reads       = 1'b0;
                nxt_write_back  = 1'b0;
                nxt_wb_tag      = 2'b0;
                nxt_wb_data     = 8'b0;
                nxt_owned_data  = 8'b0;
         end else begin   //default
                nxt_state       = S_E;
                nxt_data        = 8'b0;
                nxt_readex      = 1'b0;
                nxt_cache_addr  = 9'b0;
                nxt_reads       = 1'b0;
                nxt_write_back  = 1'b0;
                nxt_wb_tag      = 2'b0;
                nxt_wb_data     = 8'b0;
                nxt_owned_data  = 8'b0;
         end

    S_O: if (invalid_pulse_1 == 1'b1) begin // if invalid request comes then change state to I, write back the data to memory, and send ack 
		nxt_state       = S_I;
                nxt_wb_data     = buffer [dir_addr_index] [7:0]; // you are the owner, write back data to the memory or next level of cache
                nxt_invalid_ack = 1'b1;
                nxt_data        = 8'b0;
                nxt_readex      = 1'b0;
                nxt_cache_addr  = 9'b0;
                nxt_reads       = 1'b0;
                nxt_write_back  = 1'b0;
                nxt_wb_tag      = 2'b0;
                nxt_owned_data  = 8'b0;
         end else if (GetS_pulse_1 == 1'b1) begin //just send the data to the cpu requested and keep the state as O
                nxt_owned_data  = buffer [dir_addr_index] [7:0];
		nxt_gets_ack    = 1'b1;
                nxt_data        = 8'b0;
                nxt_state       = S_O;
                nxt_readex      = 1'b0;
                nxt_cache_addr  = 9'b0;
                nxt_reads       = 1'b0;
                nxt_write_back  = 1'b0;
                nxt_wb_tag      = 2'b0;
                nxt_wb_data     = 8'b0;
         end else if (cpu_write_request_2 == 1'b1) begin //if cpu requests for a write change state to M, send read exclusive request to directory.
                nxt_readex      = 1'b1; //send exclusive assess request to directory along with the address and data
                nxt_cache_addr  = cpu_write_addr;
                nxt_reads       = 1'b0;
                nxt_wb_data     = buffer [cpu_addr_index] [7:0]; // you are the owner, write back data to the memory or next level of cache
                nxt_write_back  = 1'b0;
                nxt_wb_tag      = 2'b0;
                nxt_owned_data  = 8'b0;
                if (ReadEx_Ack) begin //once ack comes from dir, determine the next state and data to be stored in the newly allocated block
                  nxt_state  = S_M;
                  nxt_data   = cpu_write_data;
                  nxt_readex = 1'b0;
                end else begin
                  nxt_state  = state;
                  nxt_data   = 8'b0;
                  nxt_readex = ReadEx;
                end
         end else if (cpu_read_request_2 == 1'b1) begin //should remain in O state.
                nxt_state       = S_O;
                nxt_data        = 8'b0;
                nxt_readex      = 1'b0;
                nxt_cache_addr  = 9'b0;
                nxt_reads       = 1'b0;
                nxt_write_back  = 1'b0;
                nxt_wb_tag      = 2'b0;
                nxt_wb_data     = 8'b0;
                nxt_owned_data  = 8'b0;
         end else begin
                nxt_state       = S_O;
                nxt_data        = 8'b0;
                nxt_readex      = 1'b0;
                nxt_cache_addr  = 9'b0;
                nxt_reads       = 1'b0;
                nxt_write_back  = 1'b0;
                nxt_wb_tag      = 2'b0;
                nxt_wb_data     = 8'b0;
                nxt_owned_data  = 8'b0;
         end

    S_M: if (invalid_pulse_1 == 1'b1) begin // if invalid request comes then change state to I, write back the data to memory, and send ack 
		nxt_state   = S_I;
                nxt_wb_data = buffer [dir_addr_index] [7:0]; // you have the latest data, write back data to the memory or next level of cache
                nxt_invalid_ack = 1'b1;
                nxt_data        = 8'b0;
                nxt_readex      = 1'b0;
                nxt_cache_addr  = 9'b0;
                nxt_reads       = 1'b0;
                nxt_write_back  = 1'b0;
                nxt_wb_tag      = 2'b0;
                nxt_owned_data  = 8'b0;
         end else if (GetS_pulse_1 == 1'b1) begin //send the data to the cpu requested and change the state as O
                nxt_owned_data      = buffer [dir_addr_index] [7:0];
                nxt_state       = S_O;
		nxt_gets_ack    = 1'b1;
                nxt_data        = 8'b0;
                nxt_readex      = 1'b0;
                nxt_cache_addr  = 9'b0;
                nxt_reads       = 1'b0;
                nxt_write_back  = 1'b0;
                nxt_wb_tag      = 2'b0;
                nxt_wb_data     = 8'b0;
         end else if (cpu_write_request_2 == 1'b1) begin //if cpu requests for a write stay in M, need not generate any request to directory 
                nxt_state       = S_M;
                nxt_data        = cpu_write_data;
                nxt_readex      = 1'b0;
                nxt_cache_addr  = 9'b0;
                nxt_reads       = 1'b0;
                nxt_write_back  = 1'b0;
                nxt_wb_tag      = 2'b0;
                nxt_wb_data     = 8'b0;
                nxt_owned_data  = 8'b0;
         end else if (cpu_read_request_2 == 1'b1) begin //should remain in O state.
                nxt_state       = S_M;
                nxt_data        = 8'b0;
                nxt_readex      = 1'b0;
                nxt_cache_addr  = 9'b0;
                nxt_reads       = 1'b0;
                nxt_write_back  = 1'b0;
                nxt_wb_tag      = 2'b0;
                nxt_wb_data     = 8'b0;
                nxt_owned_data  = 8'b0;
         end else begin
                nxt_state       = S_M;
                nxt_data        = 8'b0;
                nxt_readex      = 1'b0;
                nxt_cache_addr  = 9'b0;
                nxt_reads       = 1'b0;
                nxt_write_back  = 1'b0;
                nxt_wb_tag      = 2'b0;
                nxt_wb_data     = 8'b0;
                nxt_owned_data  = 8'b0;
         end
    default: begin
             nxt_state       = S_I; //default values for state, data, readex and reads
             nxt_data        = 8'b0;
             nxt_readex      = 1'b0;
             nxt_cache_addr  = 9'b0;
             nxt_reads       = 1'b0;
             nxt_write_back  = 1'b0;
             nxt_wb_tag      = 2'b0;
             nxt_wb_data     = 8'b0;
             nxt_owned_data  = 8'b0;
             end
  endcase
end //MOESI FSM

endmodule 
