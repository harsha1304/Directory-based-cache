`timescale 1ns/10ps

`define num_of_l2_blocks  256 //no: of entries in L2 cache
`define mem_addr_width 9   //no: of bits for memory address
`define data_width     8   //no: of bits for data

//models a directory controller and L2 cache related stuff
//
// Directory organization
//---------------------------------------------------------------------------
// Bits[19] | Bits [18:16] | Bits[15:12] | Bits[11:9] | Bits[8] | Bits[7:0] |
// --------------------------------------------------------------------------
//   Lock   |  Owner       |  Sharers    |   STATE    |  TAG    |   Data    |
//
//Owner information: 001 = cache0, 010 = cache1, 011 = cache2, 100 = cache3
//
module directory (clk,
	          rst_n,
                  cache0_ReadEx,
                  cache0_ReadEx_Ack,
                  cache0_Request_Addr,
                  cache0_Mem_data,
                  cache0_ReadS,
                  cache0_ReadS_Ack,
                  cache0_shared,
                  cache0_GetS,
                  cache0_GetS_Addr,
                  cache0_GetS_Ack,
                  cache1_ReadEx,
                  cache1_ReadEx_Ack,
                  cache1_Request_Addr,
                  cache1_Mem_data,
                  cache1_ReadS,
                  cache1_ReadS_Ack,
                  cache1_shared,
                  cache1_GetS,
                  cache1_GetS_Addr,
                  cache1_GetS_Ack,
                  cache2_ReadEx,
                  cache2_ReadEx_Ack,
                  cache2_Request_Addr,
                  cache2_Mem_data,
                  cache2_ReadS,
                  cache2_ReadS_Ack,
                  cache2_shared,
                  cache2_GetS,
                  cache2_GetS_Addr,
                  cache2_GetS_Ack,
                  cache3_ReadEx,
                  cache3_ReadEx_Ack,
                  cache3_Request_Addr,
                  cache3_Mem_data,
                  cache3_ReadS,
                  cache3_ReadS_Ack,
                  cache3_shared,
                  cache3_GetS,
                  cache3_GetS_Addr,
                  cache3_GetS_Ack,
                  cache0_Invalid,
                  cache0_Invalid_Addr,
                  cache0_WB_data,
                  cache0_Invalid_Ack,
                  cache0_write_back,
                  cache0_write_back_tag,
                  cache0_retry_request,
                  cache1_Invalid,
                  cache1_Invalid_Addr,
                  cache1_WB_data,
                  cache1_Invalid_Ack,
                  cache1_write_back,
                  cache1_write_back_tag,
                  cache1_retry_request,
                  cache2_Invalid,
                  cache2_Invalid_Addr,
                  cache2_WB_data,
                  cache2_Invalid_Ack,
                  cache2_write_back,
                  cache2_write_back_tag,
                  cache2_retry_request,
                  cache3_Invalid,
                  cache3_Invalid_Addr,
                  cache3_WB_data,
                  cache3_Invalid_Ack,
                  cache3_write_back,
                  cache3_write_back_tag,
                  cache3_retry_request,
                  Mem_Request,
                  Mem_Request_Addr,
                  Mem_Request_Ack,
                  Main_Mem_data,
                  WB_data,
                  write_back,
                  write_back_tag
                  //owned_requester
);

//Global clock reset
input clk;
input rst_n;

//cache0 <-> Directory/L2 signals
input                            cache0_ReadEx;
output reg                       cache0_ReadEx_Ack;
input  [`mem_addr_width-1:0]     cache0_Request_Addr; 
output reg [`data_width-1:0]     cache0_Mem_data;
input                            cache0_ReadS;
output reg                       cache0_ReadS_Ack;
output reg                       cache0_shared;
output reg                       cache0_GetS;
output reg [`mem_addr_width-1:0] cache0_GetS_Addr;
input                            cache0_GetS_Ack;
output reg                       cache0_Invalid;
output reg [`mem_addr_width-1:0] cache0_Invalid_Addr;
input      [`data_width-1:0]     cache0_WB_data;
input                            cache0_Invalid_Ack;
output reg                       cache0_retry_request;
input                            cache0_write_back;
input [1:0]                      cache0_write_back_tag;

//cache1 <-> Directory/L2 signals
input                            cache1_ReadEx;
output reg                       cache1_ReadEx_Ack;
input  [`mem_addr_width-1:0]     cache1_Request_Addr; 
output reg [`data_width-1:0]     cache1_Mem_data;
input                            cache1_ReadS;
output reg                       cache1_ReadS_Ack;
output reg                       cache1_shared;
output reg                       cache1_GetS;
output reg [`mem_addr_width-1:0] cache1_GetS_Addr;
input                            cache1_GetS_Ack;
output reg                       cache1_Invalid;
output reg [`mem_addr_width-1:0] cache1_Invalid_Addr;
input      [`data_width-1:0]     cache1_WB_data;
input                            cache1_Invalid_Ack;
output reg                       cache1_retry_request;
input                            cache1_write_back;
input [1:0]                      cache1_write_back_tag;

//cache2 <-> Directory/L2 signals
input                            cache2_ReadEx;
output reg                       cache2_ReadEx_Ack;
input  [`mem_addr_width-1:0]     cache2_Request_Addr; 
output reg [`data_width-1:0]     cache2_Mem_data;
input                            cache2_ReadS;
output reg                       cache2_ReadS_Ack;
output reg                       cache2_shared;
output reg                       cache2_GetS;
output reg [`mem_addr_width-1:0] cache2_GetS_Addr;
input                            cache2_GetS_Ack;
output reg                       cache2_Invalid;
output reg [`mem_addr_width-1:0] cache2_Invalid_Addr;
input      [`data_width-1:0]     cache2_WB_data;
input                            cache2_Invalid_Ack;
output reg                       cache2_retry_request;
input                            cache2_write_back;
input [1:0]                      cache2_write_back_tag;

//cache3 <-> Directory/L2 signals
input                            cache3_ReadEx;
output reg                       cache3_ReadEx_Ack;
input  [`mem_addr_width-1:0]     cache3_Request_Addr; 
output reg [`data_width-1:0]     cache3_Mem_data;
input                            cache3_ReadS;
output reg                       cache3_ReadS_Ack;
output reg                       cache3_shared;
output reg                       cache3_GetS;
output reg [`mem_addr_width-1:0] cache3_GetS_Addr;
input                            cache3_GetS_Ack;
output reg                       cache3_Invalid;
output reg [`mem_addr_width-1:0] cache3_Invalid_Addr;
input      [`data_width-1:0]     cache3_WB_data;
input                            cache3_Invalid_Ack;
output reg                       cache3_retry_request;
input                            cache3_write_back;
input [1:0]                      cache3_write_back_tag;

//signals to request for a block from main memory
output reg                       Mem_Request;
output reg [`mem_addr_width-1:0] Mem_Request_Addr;
input                            Mem_Request_Ack;
input      [`data_width-1:0]     Main_Mem_data;

//write back to main memory signals
output reg [`data_width-1:0]     WB_data;
output reg                       write_back;
output reg                       write_back_tag;

//MOESI FSM encoding
parameter S_M = 3'b100;
parameter S_O = 3'b011;
parameter S_E = 3'b010;
parameter S_S = 3'b001;
parameter S_I = 3'b000;

reg [19:0] buffer [0:255];
reg [19:0] cache0_access_line, cache1_access_line, cache2_access_line, cache3_access_line, cache_access_line;

reg [`mem_addr_width-1:0] cache0_address, cache1_address, cache2_address, cache3_address, cache_address;
reg [7:0] cache0_addr_index, cache1_addr_index, cache2_addr_index, cache3_addr_index, cache_addr_index;
reg cache0_addr_tag, cache1_addr_tag, cache2_addr_tag, cache3_addr_tag, cache_addr_tag;

reg [2:0]             state, nxt_state;
reg [`data_width-1:0] nxt_data;
reg cache0_ReadEx_1, cache0_ReadEx_2, cache1_ReadEx_1, cache1_ReadEx_2, cache2_ReadEx_1, cache2_ReadEx_2, cache3_ReadEx_1, cache3_ReadEx_2, cache0_ReadS_1, cache1_ReadS_1,cache0_ReadS_2, cache1_ReadS_2, cache2_ReadS_1, cache3_ReadS_1, cache2_ReadS_2, cache3_ReadS_2, cache_ReadEx_2, cache_ReadEx, cache_ReadS_2, cache_ReadS; 

reg hit, cache0_request_hit, cache1_request_hit, cache2_request_hit, cache3_request_hit; //L2 cache hit or miss
//reg cache0_read_pulse, cache1_read_pulse, cache2_read_pulse, cache3_read_pulse;

reg [2:0] invalidation_count, nxt_invalidation_count;

reg                       nxt_cache0_invalid, nxt_cache1_invalid, nxt_cache2_invalid, nxt_cache3_invalid;
reg [`mem_addr_width-1:0] nxt_cache0_invalid_addr, nxt_cache1_invalid_addr, nxt_cache2_invalid_addr, nxt_cache3_invalid_addr;
reg invalidation_broadcast_done, nxt_cache_readex_ack, nxt_cache_reads_ack;

reg nxt_write_back, nxt_wb_tag;
reg [`data_width-1:0] nxt_wb_data;

reg nxt_mem_request;
reg [`mem_addr_width-1:0] nxt_mem_addr;

reg [`mem_addr_width-1:0]  cache_Request_Addr;

reg [3:0] nxt_sharer;
reg [2:0] nxt_owner;

//determine tag and index of the cache request
always @ (*) begin
if ((cache0_ReadEx == 1'b1) || (cache0_ReadS == 1'b1)) begin
   cache0_address = cache0_Request_Addr;
end else begin
   cache0_address = 9'b0;
end 
cache0_addr_index = cache0_address % 256; //determine the index for a exclusive/shared access request from L1 cache
cache0_addr_tag   = cache0_address [8]; //determine the tag of incoming exclusive/shared request
end

always @ (*) begin
if ((cache1_ReadEx == 1'b1) || (cache1_ReadS == 1'b1)) begin
   cache1_address = cache1_Request_Addr;
end else begin
   cache1_address = 9'b0;
end 
cache1_addr_index = cache1_address % 256; //determine the index for a exclusive/shared access request from L1 cache
cache1_addr_tag   = cache1_address [8]; //determine the tag of incoming exclusive/shared request
end

always @ (*) begin
if ((cache2_ReadEx == 1'b1) || (cache2_ReadS == 1'b1)) begin
   cache2_address = cache2_Request_Addr;
end else begin
   cache2_address = 9'b0;
end 
cache2_addr_index = cache2_address % 256; //determine the index for a exclusive/shared access request from L1 cache
cache2_addr_tag   = cache2_address [8]; //determine the tag of incoming exclusive/shared request
end

always @ (*) begin
if ((cache3_ReadEx == 1'b1) || (cache3_ReadS == 1'b1)) begin
   cache3_address = cache3_Request_Addr;
end else begin
   cache3_address = 9'b0;
end 
cache3_addr_index = cache3_address % 256; //determine the index for a exclusive/shared access request from L1 cache
cache3_addr_tag   = cache3_address [8]; //determine the tag of incoming exclusive/shared request
end

always @ (posedge clk) begin
 if (rst_n == 1'b0) begin
   cache0_ReadEx_1 <= 1'b0;
   cache1_ReadEx_1 <= 1'b0;
   cache2_ReadEx_1 <= 1'b0;
   cache3_ReadEx_1 <= 1'b0;
   cache0_ReadEx_2 <= 1'b0;
   cache1_ReadEx_2 <= 1'b0;
   cache2_ReadEx_2 <= 1'b0;
   cache3_ReadEx_2 <= 1'b0;
   cache0_ReadS_1  <= 1'b0; 
   cache1_ReadS_1  <= 1'b0; 
   cache2_ReadS_1  <= 1'b0; 
   cache3_ReadS_1  <= 1'b0;
   cache0_ReadS_2 <= 1'b0;
   cache1_ReadS_2 <= 1'b0;
   cache2_ReadS_2 <= 1'b0;
   cache3_ReadS_2 <= 1'b0; 
 end else begin
   cache0_ReadEx_1 <= cache0_ReadEx;
   cache1_ReadEx_1 <= cache1_ReadEx;
   cache2_ReadEx_1 <= cache2_ReadEx;
   cache3_ReadEx_1 <= cache3_ReadEx;
   cache0_ReadEx_2 <= cache0_ReadEx_1;
   cache1_ReadEx_2 <= cache1_ReadEx_1;
   cache2_ReadEx_2 <= cache2_ReadEx_1;
   cache3_ReadEx_2 <= cache3_ReadEx_1;
   cache0_ReadS_1  <= cache0_ReadS; 
   cache1_ReadS_1  <= cache1_ReadS; 
   cache2_ReadS_1  <= cache2_ReadS; 
   cache3_ReadS_1  <= cache3_ReadS;
   cache0_ReadS_2  <= cache0_ReadS_1; 
   cache1_ReadS_2  <= cache1_ReadS_1; 
   cache2_ReadS_2  <= cache2_ReadS_1; 
   cache3_ReadS_2  <= cache3_ReadS_1;
 end
end

//at any time only reads or readex request can come from higher level cache 
//always @ (*) begin
//cache0_read_pulse = (((cache0_ReadEx ^ cache0_ReadEx_1) & cache0_ReadEx) | ((cache0_ReadS ^ cache0_ReadS_1) & cache0_ReadS));
//cache1_read_pulse = (((cache1_ReadEx ^ cache1_ReadEx_1) & cache1_ReadEx) | ((cache1_ReadS ^ cache1_ReadS_1) & cache1_ReadS));
//cache2_read_pulse = (((cache2_ReadEx ^ cache2_ReadEx_1) & cache2_ReadEx) | ((cache2_ReadS ^ cache2_ReadS_1) & cache2_ReadS));
//cache3_read_pulse = (((cache3_ReadEx ^ cache3_ReadEx_1) & cache3_ReadEx) | ((cache3_ReadS ^ cache3_ReadS_1) & cache3_ReadS));
//end

//obtain the content of cache line for which cache 0 has requested access
always @ (posedge clk) begin
 if (rst_n == 1'b0) begin
  cache0_access_line <= 18'b0;
 end else if ((cache0_ReadEx == 1'b1) || (cache0_ReadS == 1'b1)) begin
  cache0_access_line <= buffer [cache0_addr_index];
 end else begin
  cache0_access_line <= 18'b0;
 end
end

//obtain the content of cache line for which cache 0 has requested access
always @ (posedge clk) begin
 if (rst_n == 1'b0) begin
  cache1_access_line <= 18'b0;
 end else if ((cache1_ReadEx == 1'b1) || (cache1_ReadS == 1'b1)) begin
  cache1_access_line <= buffer [cache1_addr_index];
 end else begin
  cache1_access_line <= 18'b0;
 end
end

//obtain the content of cache line for which cache 0 has requested access
always @ (posedge clk) begin
 if (rst_n == 1'b0) begin
  cache2_access_line <= 18'b0;
 end else if ((cache2_ReadEx == 1'b1) || (cache2_ReadS == 1'b1)) begin
  cache2_access_line <= buffer [cache2_addr_index];
 end else begin
  cache2_access_line <= 18'b0;
 end
end

//obtain the content of cache line for which cache 0 has requested access
always @ (posedge clk) begin
 if (rst_n == 1'b0) begin
  cache3_access_line <= 18'b0;
 end else if ((cache3_ReadEx == 1'b1) || (cache3_ReadS == 1'b1)) begin
  cache3_access_line <= buffer [cache3_addr_index];
 end else begin
  cache3_access_line <= 18'b0;
 end
end

//Determine for a L1 cache request, if it is a hit or miss in L2 cache
always @ (*) begin
  if (((cache0_ReadEx_1 == 1'b1) && (cache0_ReadEx == 1'b1) && (cache0_ReadEx_Ack == 1'b0)) || 
      ((cache0_ReadS_1 == 1'b1) && (cache0_ReadS == 1'b1) && (cache0_ReadS_Ack == 1'b0))) begin 
    if ((cache0_access_line [8] == cache0_addr_tag) && (cache0_access_line [11:9] != S_I)) begin //check state and tag bits. If state is anything other than invalid then it is a hit
      cache0_request_hit = 1'b1;
    end else begin
      cache0_request_hit = 1'b0;
    end
  end else begin
      cache0_request_hit = 1'b0;
  end
end

always @ (*) begin
  if (((cache1_ReadEx_1 == 1'b1) && (cache1_ReadEx == 1'b1) && (cache1_ReadEx_Ack == 1'b0)) || 
      ((cache1_ReadS_1 == 1'b1) && (cache1_ReadS == 1'b1) && (cache1_ReadS_Ack == 1'b0))) begin 
    if ((cache1_access_line [8] == cache1_addr_tag) && (cache1_access_line [11:9] != S_I)) begin //check state and tag bits. If state is anything other than invalid then it is a hit
      cache1_request_hit = 1'b1;
    end else begin
      cache1_request_hit = 1'b0;
    end
  end else begin
      cache1_request_hit = 1'b0;
  end
end

always @ (*) begin
  if (((cache2_ReadEx_1 == 1'b1) && (cache2_ReadEx == 1'b1) && (cache2_ReadEx_Ack == 1'b0)) || 
      ((cache2_ReadS_1 == 1'b1) && (cache2_ReadS == 1'b1) && (cache2_ReadS_Ack == 1'b0))) begin 
    if ((cache2_access_line [8] == cache2_addr_tag) && (cache2_access_line [11:9] != S_I)) begin //check state and tag bits. If state is anything other than invalid then it is a hit
      cache2_request_hit = 1'b1;
    end else begin
      cache2_request_hit = 1'b0;
    end
  end else begin
      cache2_request_hit = 1'b0;
  end
end

always @ (*) begin
  if (((cache3_ReadEx_1 == 1'b1) && (cache3_ReadEx == 1'b1) && (cache3_ReadEx_Ack == 1'b0)) || 
      ((cache3_ReadS_1 == 1'b1) && (cache3_ReadS == 1'b1) && (cache3_ReadS_Ack == 1'b0))) begin 
    if ((cache3_access_line [8] == cache3_addr_tag) && (cache3_access_line [11:9] != S_I)) begin //check state and tag bits. If state is anything other than invalid then it is a hit
      cache3_request_hit = 1'b1;
    end else begin
      cache3_request_hit = 1'b0;
    end
  end else begin
      cache3_request_hit = 1'b0;
  end
end

integer i;

always @ (posedge clk) begin
  if (rst_n == 1'b0) begin  //reset cache buffer, read and write ack 
      for (i= 0; i < `num_of_l2_blocks; i = i + 1) begin
        buffer [i]  <= 20'b0; //reset the register file
      end
  end else if ((cache_ReadEx_2 == 1'b1) && (cache_ReadEx == 1'b1)) begin   //process a write request
    if (hit == 1'b1) begin  //if the block is present
      if ((invalidation_broadcast_done == 1'b1) && (invalidation_count == 0)) begin
            buffer [cache_addr_index] [18:16]   <= nxt_owner;
            buffer [cache_addr_index] [15:12]   <= nxt_sharer;
            buffer [cache_addr_index] [11:9]    <= nxt_state;
      end 
    end else if (hit == 1'b0) begin //on a write miss, wait for ReadEx_Ack and then allocate the block and copy the data
          if (Mem_Request_Ack == 1'b1) begin //wait for the ack from directory
            buffer [cache_addr_index]  <= {1'b0,nxt_owner,nxt_sharer,nxt_state,cache_addr_tag,Main_Mem_data};
          end
    end 
  end else if ((cache_ReadS_2 == 1'b1) && (cache_ReadS == 1'b1)) begin //process a read request
    if (hit == 1'b1) begin  //if the block is present (any state other than I)
            buffer [cache_addr_index] [18:16]   <= nxt_owner;
            buffer [cache_addr_index] [15:12]   <= nxt_sharer;
            buffer [cache_addr_index] [11:9]    <= nxt_state;
    end else if (hit == 1'b0) begin //on a read miss wait for ack of ReadS request and then allocate block
            //if ((ReadS_Ack == 1'b1) && (cpu_read_ack == 1'b0)) begin
            if (Mem_Request_Ack == 1'b1) begin
              buffer [cache_addr_index] <= {1'b0,nxt_owner,nxt_sharer,nxt_state,cache_addr_tag,Main_Mem_data};
            end
    end 
  end else begin
    for (i= 0; i < `num_of_l2_blocks; i = i + 1) begin
      buffer [i] <= buffer [i]; //preserve the values
    end
  end
end

//WB data 
always @ (posedge clk) begin
  if (rst_n == 1'b0) begin
       WB_data        <= 8'b0;
       write_back     <= 1'b0; 
       write_back_tag <= 1'b0;
  end else begin
       WB_data      <= nxt_wb_data;
       write_back     <= nxt_write_back; 
       write_back_tag <= nxt_wb_tag; 
  end 
end

//determine the state of block for which cpu/directory requests are made
always @ (posedge clk) begin
  if (rst_n == 1'b0) begin
    state    <= 3'b0;
    cache0_retry_request <= 1'b0;
    cache1_retry_request <= 1'b0;
    cache2_retry_request <= 1'b0;
    cache3_retry_request <= 1'b0;
  end else if (cache0_request_hit == 1'b1) begin
    if (cache0_access_line[19] == 1'b1) begin
       cache0_retry_request <= 1'b1;
    end else begin //get the state of address for which cache0 readex/reads request comes
       state    <= (buffer [cache0_addr_index] & 20'b00000000111000000000) >> 9;
    end
  end else if (cache1_request_hit == 1'b1) begin
    if (cache1_access_line[19] == 1'b1) begin
       cache1_retry_request <= 1'b1;
    end else begin //get the state of address for which cache1 readex/reads request comes
       state    <= (buffer [cache1_addr_index] & 20'b00000000111000000000) >> 9;
    end
  end else if (cache2_request_hit == 1'b1) begin
    if (cache2_access_line[19] == 1'b1) begin
       cache2_retry_request <= 1'b1;
    end else begin //get the state of address for which cache2 readex/reads request comes
       state    <= (buffer [cache2_addr_index] & 20'b00000000111000000000) >> 9;
    end 
  end else if (cache3_request_hit == 1'b1) begin
    if (cache3_access_line[19] == 1'b1) begin
       cache3_retry_request <= 1'b1;
    end else begin //get the state of address for which cache3 readex/reads request comes
       state    <= (buffer [cache3_addr_index] & 20'b00000000111000000000) >> 9;
    end
  end else begin
    state <= 3'b0; //default
    cache0_retry_request <= 1'b0;
    cache1_retry_request <= 1'b0;
    cache2_retry_request <= 1'b0;
    cache3_retry_request <= 1'b0; 
  end
end

//Memory request
always @ (posedge clk) begin
  if (rst_n == 1'b0) begin
       Mem_Request <= 1'b0;
       Mem_Request_Addr <= 9'b0;
  end else begin
       Mem_Request <= nxt_mem_request;
       Mem_Request_Addr <= nxt_mem_addr;
  end 
end

//Invalidation count
always @ (posedge clk) begin
  if (rst_n == 1'b0) begin
       invalidation_count <= 3'b0;
  end else if  ((cache0_Invalid_Ack || cache1_Invalid_Ack || cache2_Invalid_Ack || cache3_Invalid_Ack == 1'b1) && (invalidation_count != 3'b0)) begin
       invalidation_count <= invalidation_count - 1; 
  end else begin
       invalidation_count <= nxt_invalidation_count;
  end 
end

always @ (posedge clk) begin
 if (rst_n == 1'b0) begin
    invalidation_broadcast_done <= 1'b0; 
 end else if ((invalidation_broadcast_done == 1'b1) && (cache0_ReadEx_Ack || cache1_ReadEx_Ack || cache2_ReadEx_Ack || cache3_ReadEx_Ack)) begin
    invalidation_broadcast_done <= 1'b0; //an exclusive access acknowledgement being sent means all invalidations are completed
 end else if (invalidation_count == 3'b100) begin
    invalidation_broadcast_done <= 1'b1;
 //end else begin
 //   invalidation_broadcast_done <= 1'b0;
 end
end

//ReadEx acknowledgement
always @ (posedge clk) begin
 if (rst_n == 1'b0) begin
    cache0_ReadEx_Ack <= 1'b0; 
 end else if (cache0_ReadEx_Ack == 1'b1) begin //only generate a pulse
    cache0_ReadEx_Ack <= 1'b0;
 end else if (cache0_ReadEx == 1'b1) begin
    cache0_ReadEx_Ack <= nxt_cache_readex_ack;
 end else begin
    cache0_ReadEx_Ack <= 1'b0; 
 end
end

always @ (posedge clk) begin
 if (rst_n == 1'b0) begin
    cache1_ReadEx_Ack <= 1'b0; 
 end else if (cache1_ReadEx_Ack == 1'b1) begin //only generate a pulse
    cache1_ReadEx_Ack <= 1'b0;
 end else if (cache1_ReadEx == 1'b1) begin
    cache1_ReadEx_Ack <= nxt_cache_readex_ack;
 end else begin
    cache1_ReadEx_Ack <= 1'b0; 
 end
end

always @ (posedge clk) begin
 if (rst_n == 1'b0) begin
    cache2_ReadEx_Ack <= 1'b0; 
 end else if (cache2_ReadEx_Ack == 1'b1) begin //only generate a pulse
    cache2_ReadEx_Ack <= 1'b0;
 end else if (cache2_ReadEx == 1'b1) begin
    cache2_ReadEx_Ack <= nxt_cache_readex_ack;
 end else begin
    cache2_ReadEx_Ack <= 1'b0; 
 end
end

always @ (posedge clk) begin
 if (rst_n == 1'b0) begin
    cache3_ReadEx_Ack <= 1'b0; 
 end else if (cache3_ReadEx_Ack == 1'b1) begin //only generate a pulse
    cache3_ReadEx_Ack <= 1'b0;
 end else if (cache3_ReadEx == 1'b1) begin
    cache3_ReadEx_Ack <= nxt_cache_readex_ack;
 end else begin
    cache3_ReadEx_Ack <= 1'b0; 
 end
end

//ReadS acknowledgement
always @ (posedge clk) begin
 if (rst_n == 1'b0) begin
    cache0_ReadS_Ack <= 1'b0; 
 end else if (cache0_ReadS_Ack == 1'b1) begin //only generate a pulse
    cache0_ReadS_Ack <= 1'b0;
 end else if (cache0_ReadS == 1'b1) begin
    cache0_ReadS_Ack <= nxt_cache_reads_ack;
 end else begin
    cache0_ReadS_Ack <= 1'b0; 
 end
end

always @ (posedge clk) begin
 if (rst_n == 1'b0) begin
    cache1_ReadS_Ack <= 1'b0; 
 end else if (cache1_ReadS_Ack == 1'b1) begin //only generate a pulse
    cache1_ReadS_Ack <= 1'b0;
 end else if (cache1_ReadS == 1'b1) begin
    cache1_ReadS_Ack <= nxt_cache_reads_ack;
 end else begin
    cache1_ReadS_Ack <= 1'b0; 
 end
end

always @ (posedge clk) begin
 if (rst_n == 1'b0) begin
    cache2_ReadS_Ack <= 1'b0; 
 end else if (cache2_ReadS_Ack == 1'b1) begin //only generate a pulse
    cache2_ReadS_Ack <= 1'b0;
 end else if (cache2_ReadS == 1'b1) begin
    cache2_ReadS_Ack <= nxt_cache_reads_ack;
 end else begin
    cache2_ReadS_Ack <= 1'b0; 
 end
end

always @ (posedge clk) begin
 if (rst_n == 1'b0) begin
    cache3_ReadS_Ack <= 1'b0; 
 end else if (cache3_ReadS_Ack == 1'b1) begin //only generate a pulse
    cache3_ReadS_Ack <= 1'b0;
 end else if (cache3_ReadS == 1'b1) begin
    cache3_ReadS_Ack <= nxt_cache_reads_ack; 
 end else begin
    cache3_ReadS_Ack <= 1'b0;
 end
end

//arbitration logic
always @ (*) begin
  if ((cache0_ReadEx_2 == 1'b1) || (cache0_ReadS_2 == 1'b1)) begin
    cache_address = cache0_address;
    cache_addr_tag = cache0_addr_tag;
    cache_addr_index = cache0_addr_index;
    cache_Request_Addr = cache0_Request_Addr;
    cache_access_line = cache0_access_line;
    cache_ReadEx_2 = cache0_ReadEx_2;
    cache_ReadEx   = cache0_ReadEx;
    cache_ReadS_2 = cache0_ReadS_2;
    cache_ReadS   = cache0_ReadS;
    hit           = cache0_request_hit;
  end else if ((cache1_ReadEx_2 == 1'b1) || (cache1_ReadS_2 == 1'b1)) begin
    cache_address = cache1_address;
    cache_addr_tag = cache1_addr_tag;
    cache_addr_index = cache1_addr_index;
    cache_Request_Addr = cache1_Request_Addr;
    cache_access_line = cache1_access_line;
    cache_ReadEx_2 = cache1_ReadEx_2;
    cache_ReadEx   = cache1_ReadEx;
    cache_ReadS_2 = cache1_ReadS_2;
    cache_ReadS   = cache1_ReadS;
    hit           = cache1_request_hit;
  end else if ((cache2_ReadEx_2 == 1'b1) || (cache2_ReadS_2 == 1'b1)) begin
    cache_address = cache2_address;
    cache_addr_tag = cache2_addr_tag;
    cache_addr_index = cache2_addr_index;
    cache_Request_Addr = cache2_Request_Addr;
    cache_access_line = cache2_access_line;
    cache_ReadEx_2 = cache2_ReadEx_2;
    cache_ReadEx   = cache2_ReadEx;
    cache_ReadS_2 = cache2_ReadS_2;
    cache_ReadS   = cache2_ReadS;
    hit           = cache2_request_hit;
  end else if ((cache3_ReadEx_2 == 1'b1) || (cache3_ReadS_2 == 1'b1)) begin
    cache_address = cache3_address;
    cache_addr_tag = cache3_addr_tag;
    cache_addr_index = cache3_addr_index;
    cache_Request_Addr = cache3_Request_Addr;
    cache_access_line = cache3_access_line;
    cache_ReadEx_2 = cache3_ReadEx_2;
    cache_ReadEx   = cache3_ReadEx;
    cache_ReadS_2 = cache3_ReadS_2;
    cache_ReadS   = cache3_ReadS;
    hit           = cache3_request_hit;
  end else begin
    cache_address = 9'b0;
    cache_addr_tag = 1'b0;
    cache_addr_index = 8'b0;
    cache_Request_Addr = 9'b0;
    cache_access_line = 20'b0;
    cache_ReadEx_2 = 1'b0;
    cache_ReadEx   = 1'b0;
    cache_ReadS_2 = 1'b0;
    cache_ReadS   = 1'b0;
    hit           = 1'b0;
  end
end

//Invalid requests
always @ (posedge clk) begin
 if (rst_n == 1'b0) begin
   cache0_Invalid      <= 1'b0;
   cache0_Invalid_Addr <= 9'b0;
   cache1_Invalid      <= 1'b0;
   cache1_Invalid_Addr <= 9'b0;    
   cache2_Invalid      <= 1'b0;
   cache2_Invalid_Addr <= 9'b0;
   cache3_Invalid      <= 1'b0;
   cache3_Invalid_Addr <= 9'b0; 
 end else begin
   cache0_Invalid      <= nxt_cache0_invalid;
   cache0_Invalid_Addr <= nxt_cache0_invalid_addr;
   cache1_Invalid      <= nxt_cache1_invalid;
   cache1_Invalid_Addr <= nxt_cache1_invalid_addr;    
   cache2_Invalid      <= nxt_cache2_invalid;
   cache2_Invalid_Addr <= nxt_cache2_invalid_addr;
   cache3_Invalid      <= nxt_cache3_invalid;
   cache3_Invalid_Addr <= nxt_cache3_invalid_addr;
 end
end


//MOESI FSM
always @ (*) begin
  case (state)
    S_I: if ((cache_ReadEx_2 == 1'b1) || (cache_ReadS_2)) begin
                //nxt_mem_request = 1'b1; //get block from main memory
                //nxt_mem_addr  = cache_Request_Addr;
                nxt_cache3_invalid = 1'b0;
                nxt_cache3_invalid_addr = 9'b0;
                nxt_cache2_invalid = 1'b0;
                nxt_cache2_invalid_addr = 9'b0;
                nxt_cache1_invalid = 1'b0;
                nxt_cache1_invalid_addr = 9'b0;
                nxt_cache0_invalid = 1'b0;
                nxt_cache0_invalid_addr = 9'b0;
                nxt_invalidation_count = 3'b0;
                if ((cache_addr_tag != buffer [cache_addr_index] [8]) && (buffer [cache_addr_index] [11:9] != S_I)) begin //If the block to be evicted is not in I state, write back to main memory 
                  nxt_state  = S_I;
                  nxt_write_back = 1'b1;
                  nxt_wb_tag     = buffer [cache_addr_index] [8];
                  nxt_wb_data    = buffer [cache_addr_index] [7:0];
                  nxt_mem_request = 1'b0; // need not get block from main memory
                  nxt_mem_addr  = 9'b0;
                  nxt_sharer = 4'b0;
                  nxt_owner  = 3'b0;
                  nxt_data   = 8'b0;
                  nxt_cache_readex_ack = 1'b0;
                  nxt_cache_reads_ack = 1'b0;
                end else begin
                  nxt_state  = S_I;
                  nxt_write_back = write_back;
                  nxt_wb_tag     = write_back_tag;
                  nxt_wb_data    = WB_data;
                  nxt_mem_request = 1'b1; //get block from main memory
                  nxt_mem_addr  = cache_Request_Addr;
                  nxt_sharer = 4'b0;
                  nxt_owner  = 3'b0;
                  nxt_data   = 8'b0;
                  nxt_cache_readex_ack = 1'b0;
                  nxt_cache_reads_ack = 1'b0;
                end
                if (Mem_Request_Ack) begin //once ack comes from main memory, determine the next state and data to be stored in the newly allocated block
                  if (cache_ReadEx == 1'b1) begin
                    nxt_state  = S_M;
                    nxt_cache_readex_ack = 1'b1;
                    nxt_cache_reads_ack = 1'b0;
                  end else begin
                    nxt_state = S_E;
                    nxt_cache_readex_ack = 1'b0;
                    nxt_cache_reads_ack = 1'b1;
                  end
                  if (cache0_ReadEx_2) begin
                    nxt_sharer = 4'b0001;
                    nxt_owner  = 3'b001;
                  end else if (cache1_ReadEx_2) begin
                    nxt_sharer = 4'b0010;
                    nxt_owner  = 3'b010;
                  end else if (cache2_ReadEx_2) begin
                    nxt_sharer = 4'b0100;
                    nxt_owner  = 3'b011;
                  end else if (cache3_ReadEx_2) begin
                    nxt_sharer = 4'b1000;
                    nxt_owner  = 3'b100;
                  end else if (cache0_ReadS_2) begin
                    nxt_sharer = 4'b0001;
                    nxt_owner  = 3'b000;
                  end else if (cache1_ReadEx_2) begin
                    nxt_sharer = 4'b0010;
                    nxt_owner  = 3'b000;
                  end else if (cache2_ReadEx_2) begin
                    nxt_sharer = 4'b0100;
                    nxt_owner  = 3'b000;
                  end else if (cache3_ReadEx_2) begin
                    nxt_sharer = 4'b1000;
                    nxt_owner  = 3'b000;
                  end else begin
                    nxt_sharer = 4'b0000;
                    nxt_owner  = 3'b000;
                  end
                  nxt_data   = Main_Mem_data;
                  nxt_mem_request = 1'b0;
                  nxt_mem_addr  = 9'b0;
                  nxt_write_back = 1'b0;
                  nxt_wb_tag     = 1'b0;
                  nxt_wb_data    = 8'b0;
                end else begin
                  nxt_state  = S_I;
                  nxt_sharer = 4'b0;
                  nxt_owner  = 3'b0;
                  nxt_data   = 8'b0;
                  nxt_mem_request = Mem_Request;
                  nxt_mem_addr  = 9'b0;
                  nxt_write_back = write_back;
                  nxt_wb_tag     = write_back_tag;
                  nxt_wb_data    = WB_data;
                  nxt_cache_readex_ack = 1'b0;
                  nxt_cache_reads_ack = 1'b0;
                end
         end else begin //default 
            nxt_state       = S_I;
            nxt_data        = 8'b0;
            nxt_sharer = 4'b0;
            nxt_owner  = 3'b0;
            nxt_mem_request = Mem_Request;
            nxt_mem_addr   = 9'b0;
            nxt_write_back = 1'b0;
            nxt_wb_tag     = 1'b0;
            nxt_wb_data    = 8'b0;
            nxt_cache_readex_ack = 1'b0;
            nxt_cache_reads_ack = 1'b0;
            nxt_cache3_invalid = 1'b0;
            nxt_cache3_invalid_addr = 9'b0;
            nxt_cache2_invalid = 1'b0;
            nxt_cache2_invalid_addr = 9'b0;
            nxt_cache1_invalid = 1'b0;
            nxt_cache1_invalid_addr = 9'b0;
            nxt_cache0_invalid = 1'b0;
            nxt_cache0_invalid_addr = 9'b0;
            nxt_invalidation_count = 3'b0;
         end
         S_S: if ((cache_ReadEx_2 == 1'b1) || (cache_ReadS_2)) begin
                nxt_mem_request = 1'b0;
                nxt_mem_addr   = 9'b0;
                nxt_write_back = 1'b0;
                nxt_wb_tag     = 1'b0;
                nxt_wb_data    = 8'b0;
                nxt_data       = 8'b0;
                if (cache_ReadEx_2 == 1'b1) begin
                  if ((cache_access_line [15:12] != 4'b0) && (invalidation_count == 0) && (invalidation_broadcast_done == 1'b0)) begin //Broadcast invalidation requests to all the cores 
                           nxt_cache3_invalid = 1'b1;
                           nxt_cache3_invalid_addr = cache_address;
                           nxt_cache2_invalid = 1'b1;
                           nxt_cache2_invalid_addr = cache_address;
                           nxt_cache1_invalid = 1'b1;
                           nxt_cache1_invalid_addr = cache_address;
                           nxt_cache0_invalid = 1'b1;
                           nxt_cache0_invalid_addr = cache_address;
                           nxt_invalidation_count = 3'b100;
                           nxt_state  = S_S;
                           nxt_sharer = 4'b0000;
                           nxt_owner  = 3'b000;
                           nxt_cache_readex_ack = 1'b0;
                           nxt_cache_reads_ack  = 1'b0;
                  end else if (invalidation_count != 0) begin
                           nxt_cache3_invalid = cache3_Invalid;
                           nxt_cache3_invalid_addr = cache3_Invalid_Addr;
                           nxt_cache2_invalid = cache2_Invalid;
                           nxt_cache2_invalid_addr = cache2_Invalid_Addr;
                           nxt_cache1_invalid = cache1_Invalid;
                           nxt_cache1_invalid_addr = cache1_Invalid_Addr;
                           nxt_cache0_invalid = cache0_Invalid;
                           nxt_cache0_invalid_addr = cache0_Invalid_Addr;
                           nxt_invalidation_count = invalidation_count;
                           nxt_state  = S_S;
                           nxt_sharer = 4'b0000;
                           nxt_owner  = 3'b000;
                           nxt_cache_readex_ack = 1'b0;
                           nxt_cache_reads_ack  = 1'b0;
                  end else if ((invalidation_broadcast_done == 1'b1) && (invalidation_count == 0)) begin //all cores have invalidated their blocks  
                     nxt_state  = S_M;
                     if (cache0_ReadEx_2) begin
                       nxt_sharer = 4'b0001;
                       nxt_owner  = 3'b001;
                     end else if (cache1_ReadEx_2) begin
                       nxt_sharer = 4'b0010;
                       nxt_owner  = 3'b010;
                     end else if (cache2_ReadEx_2) begin
                       nxt_sharer = 4'b0100;
                       nxt_owner  = 3'b011;
                     end else if (cache3_ReadEx_2) begin
                       nxt_sharer = 4'b1000;
                       nxt_owner  = 3'b100;
                     end else begin
                       nxt_sharer = 4'b0000;
                       nxt_owner  = 3'b000;
                     end
                     nxt_cache_readex_ack = 1'b1; //send cache readex back
                     nxt_cache_reads_ack  = 1'b0;
                     nxt_cache3_invalid = 1'b0;
                     nxt_cache3_invalid_addr = 9'b0;
                     nxt_cache2_invalid = 1'b0;
                     nxt_cache2_invalid_addr = 9'b0;
                     nxt_cache1_invalid = 1'b0;
                     nxt_cache1_invalid_addr = 9'b0;
                     nxt_cache0_invalid = 1'b0;
                     nxt_cache0_invalid_addr = 9'b0;
                     nxt_invalidation_count = 3'b0;
                  end else begin
                     nxt_state  = S_S;
                     nxt_sharer = 4'b0000;
                     nxt_owner  = 3'b000;
                     nxt_cache_readex_ack = 1'b0; //send cache readex back
                     nxt_cache_reads_ack  = 1'b0;
                     nxt_cache3_invalid = 1'b0;
                     nxt_cache3_invalid_addr = 9'b0;
                     nxt_cache2_invalid = 1'b0;
                     nxt_cache2_invalid_addr = 9'b0;
                     nxt_cache1_invalid = 1'b0;
                     nxt_cache1_invalid_addr = 9'b0;
                     nxt_cache0_invalid = 1'b0;
                     nxt_cache0_invalid_addr = 9'b0;
                     nxt_invalidation_count = 3'b0;
                  end
               end else begin
                     nxt_state  = S_S;
                     if (cache0_ReadS_2) begin
                       nxt_sharer = cache_access_line[15:12] | 4'b0001;
                     end else if (cache1_ReadS_2) begin
                       nxt_sharer = cache_access_line[15:12] | 4'b0010;
                     end else if (cache2_ReadS_2) begin
                       nxt_sharer = cache_access_line[15:12] | 4'b0100;
                     end else if (cache3_ReadS_2) begin
                       nxt_sharer = cache_access_line[15:12] | 4'b1000;
                     end else begin
                        nxt_sharer = cache_access_line[15:12];
                     end
                     nxt_owner  = cache_access_line [18:16];
                     nxt_cache_readex_ack = 1'b0; 
                     nxt_cache_reads_ack  = 1'b1; //send cache reads ack back
                     nxt_cache3_invalid = 1'b0;
                     nxt_cache3_invalid_addr = 9'b0;
                     nxt_cache2_invalid = 1'b0;
                     nxt_cache2_invalid_addr = 9'b0;
                     nxt_cache1_invalid = 1'b0;
                     nxt_cache1_invalid_addr = 9'b0;
                     nxt_cache0_invalid = 1'b0;
                     nxt_cache0_invalid_addr = 9'b0;
                     nxt_invalidation_count = 3'b0;
               end 
         end else begin //default
            nxt_state       = S_S;
            nxt_data        = 8'b0;
            nxt_sharer = 4'b0;
            nxt_owner  = 3'b0;
            nxt_mem_request = 1'b0;
            nxt_mem_addr   = 9'b0;
            nxt_write_back = 1'b0;
            nxt_wb_tag     = 1'b0;
            nxt_wb_data    = 8'b0;
            nxt_cache_readex_ack = 1'b0;
            nxt_cache_reads_ack = 1'b0;
            nxt_cache3_invalid = 1'b0;
            nxt_cache3_invalid_addr = 9'b0;
            nxt_cache2_invalid = 1'b0;
            nxt_cache2_invalid_addr = 9'b0;
            nxt_cache1_invalid = 1'b0;
            nxt_cache1_invalid_addr = 9'b0;
            nxt_cache0_invalid = 1'b0;
            nxt_cache0_invalid_addr = 9'b0;
            nxt_invalidation_count = 3'b0; 
         end
         S_E: if ((cache_ReadEx_2 == 1'b1) || (cache_ReadS_2)) begin
                nxt_mem_request = 1'b0;
                nxt_mem_addr   = 9'b0;
                nxt_write_back = 1'b0;
                nxt_wb_tag     = 1'b0;
                nxt_wb_data    = 8'b0;
                nxt_data       = 8'b0;
                if (cache_ReadEx_2 == 1'b1) begin
                  if ((cache_access_line [15:12] != 4'b0) && (invalidation_count == 0) && (invalidation_broadcast_done == 1'b0)) begin //Broadcast invalidation requests to all the cores 
                           nxt_cache3_invalid = 1'b1;
                           nxt_cache3_invalid_addr = cache_address;
                           nxt_cache2_invalid = 1'b1;
                           nxt_cache2_invalid_addr = cache_address;
                           nxt_cache1_invalid = 1'b1;
                           nxt_cache1_invalid_addr = cache_address;
                           nxt_cache0_invalid = 1'b1;
                           nxt_cache0_invalid_addr = cache_address;
                           nxt_invalidation_count = 3'b100;
                           nxt_state  = S_E;
                           nxt_sharer = 4'b0000;
                           nxt_owner  = 3'b000;
                           nxt_cache_readex_ack = 1'b0;
                           nxt_cache_reads_ack  = 1'b0;
                  end else if (invalidation_count != 0) begin
                           nxt_cache3_invalid = cache3_Invalid;
                           nxt_cache3_invalid_addr = cache3_Invalid_Addr;
                           nxt_cache2_invalid = cache2_Invalid;
                           nxt_cache2_invalid_addr = cache2_Invalid_Addr;
                           nxt_cache1_invalid = cache1_Invalid;
                           nxt_cache1_invalid_addr = cache1_Invalid_Addr;
                           nxt_cache0_invalid = cache0_Invalid;
                           nxt_cache0_invalid_addr = cache0_Invalid_Addr;
                           nxt_invalidation_count = invalidation_count;
                           nxt_state  = S_E;
                           nxt_sharer = 4'b0000;
                           nxt_owner  = 3'b000;
                           nxt_cache_readex_ack = 1'b0;
                           nxt_cache_reads_ack  = 1'b0;
                  end else if ((invalidation_broadcast_done == 1'b1) && (invalidation_count == 0)) begin //all cores have invalidated their blocks  
                     nxt_state  = S_M;
                     if (cache0_ReadEx_2) begin
                       nxt_sharer = 4'b0001;
                       nxt_owner  = 3'b001;
                     end else if (cache1_ReadEx_2) begin
                       nxt_sharer = 4'b0010;
                       nxt_owner  = 3'b010;
                     end else if (cache2_ReadEx_2) begin
                       nxt_sharer = 4'b0100;
                       nxt_owner  = 3'b011;
                     end else if (cache3_ReadEx_2) begin
                       nxt_sharer = 4'b1000;
                       nxt_owner  = 3'b100;
                     end else begin
                       nxt_sharer = 4'b0000;
                       nxt_owner  = 3'b000;
                     end
                     nxt_cache_readex_ack = 1'b1; //send cache readex back
                     nxt_cache_reads_ack  = 1'b0;
                     nxt_cache3_invalid = 1'b0;
                     nxt_cache3_invalid_addr = 9'b0;
                     nxt_cache2_invalid = 1'b0;
                     nxt_cache2_invalid_addr = 9'b0;
                     nxt_cache1_invalid = 1'b0;
                     nxt_cache1_invalid_addr = 9'b0;
                     nxt_cache0_invalid = 1'b0;
                     nxt_cache0_invalid_addr = 9'b0;
                     nxt_invalidation_count = 3'b0;
                  end else begin
                     nxt_state  = S_E;
                     nxt_sharer = 4'b0000;
                     nxt_owner  = 3'b000;
                     nxt_cache_readex_ack = 1'b0; //send cache readex back
                     nxt_cache_reads_ack  = 1'b0;
                     nxt_cache3_invalid = 1'b0;
                     nxt_cache3_invalid_addr = 9'b0;
                     nxt_cache2_invalid = 1'b0;
                     nxt_cache2_invalid_addr = 9'b0;
                     nxt_cache1_invalid = 1'b0;
                     nxt_cache1_invalid_addr = 9'b0;
                     nxt_cache0_invalid = 1'b0;
                     nxt_cache0_invalid_addr = 9'b0;
                     nxt_invalidation_count = 3'b0;
                  end
               end else begin
                     nxt_state  = S_S;
                     if (cache0_ReadS_2) begin
                       nxt_sharer = cache_access_line[15:12] | 4'b0001;
                     end else if (cache1_ReadS_2) begin
                       nxt_sharer = cache_access_line[15:12] | 4'b0010;
                     end else if (cache2_ReadS_2) begin
                       nxt_sharer = cache_access_line[15:12] | 4'b0100;
                     end else if (cache3_ReadS_2) begin
                       nxt_sharer = cache_access_line[15:12] | 4'b1000;
                     end else begin
                        nxt_sharer = cache_access_line[15:12];
                     end
                     nxt_owner  = cache_access_line [18:16];
                     nxt_cache_readex_ack = 1'b0; 
                     nxt_cache_reads_ack  = 1'b1; //send cache reads ack back
                     nxt_cache3_invalid = 1'b0;
                     nxt_cache3_invalid_addr = 9'b0;
                     nxt_cache2_invalid = 1'b0;
                     nxt_cache2_invalid_addr = 9'b0;
                     nxt_cache1_invalid = 1'b0;
                     nxt_cache1_invalid_addr = 9'b0;
                     nxt_cache0_invalid = 1'b0;
                     nxt_cache0_invalid_addr = 9'b0;
                     nxt_invalidation_count = 3'b0;
               end 
         end else begin //default
            nxt_state       = S_E;
            nxt_data        = 8'b0;
            nxt_sharer = 4'b0;
            nxt_owner  = 3'b0;
            nxt_mem_request = 1'b0;
            nxt_mem_addr   = 9'b0;
            nxt_write_back = 1'b0;
            nxt_wb_tag     = 1'b0;
            nxt_wb_data    = 8'b0;
            nxt_cache_readex_ack = 1'b0;
            nxt_cache_reads_ack = 1'b0;
            nxt_cache3_invalid = 1'b0;
            nxt_cache3_invalid_addr = 9'b0;
            nxt_cache2_invalid = 1'b0;
            nxt_cache2_invalid_addr = 9'b0;
            nxt_cache1_invalid = 1'b0;
            nxt_cache1_invalid_addr = 9'b0;
            nxt_cache0_invalid = 1'b0;
            nxt_cache0_invalid_addr = 9'b0;
            nxt_invalidation_count = 3'b0; 
         end
         S_O: if ((cache_ReadEx_2 == 1'b1) || (cache_ReadS_2)) begin
                nxt_mem_request = 1'b0;
                nxt_mem_addr   = 9'b0;
                nxt_write_back = 1'b0;
                nxt_wb_tag     = 1'b0;
                nxt_wb_data    = 8'b0;
                nxt_data       = 8'b0;
                if (cache_ReadEx_2 == 1'b1) begin
                  if ((cache_access_line [15:12] != 4'b0) && (invalidation_count == 0) && (invalidation_broadcast_done == 1'b0)) begin //Broadcast invalidation requests to all the cores 
                           nxt_cache3_invalid = 1'b1;
                           nxt_cache3_invalid_addr = cache_address;
                           nxt_cache2_invalid = 1'b1;
                           nxt_cache2_invalid_addr = cache_address;
                           nxt_cache1_invalid = 1'b1;
                           nxt_cache1_invalid_addr = cache_address;
                           nxt_cache0_invalid = 1'b1;
                           nxt_cache0_invalid_addr = cache_address;
                           nxt_invalidation_count = 3'b100;
                           nxt_state  = S_O;
                           nxt_sharer = 4'b0000;
                           nxt_owner  = 3'b000;
                           nxt_cache_readex_ack = 1'b0;
                           nxt_cache_reads_ack  = 1'b0;
                  end else if (invalidation_count != 0) begin
                           nxt_cache3_invalid = cache3_Invalid;
                           nxt_cache3_invalid_addr = cache3_Invalid_Addr;
                           nxt_cache2_invalid = cache2_Invalid;
                           nxt_cache2_invalid_addr = cache2_Invalid_Addr;
                           nxt_cache1_invalid = cache1_Invalid;
                           nxt_cache1_invalid_addr = cache1_Invalid_Addr;
                           nxt_cache0_invalid = cache0_Invalid;
                           nxt_cache0_invalid_addr = cache0_Invalid_Addr;
                           nxt_invalidation_count = invalidation_count;
                           nxt_state  = S_O;
                           nxt_sharer = 4'b0000;
                           nxt_owner  = 3'b000;
                           nxt_cache_readex_ack = 1'b0;
                           nxt_cache_reads_ack  = 1'b0;
                  end else if ((invalidation_broadcast_done == 1'b1) && (invalidation_count == 0)) begin //all cores have invalidated their blocks  
                     nxt_state  = S_M;
                     if (cache0_ReadEx_2) begin
                       nxt_sharer = 4'b0001;
                       nxt_owner  = 3'b001;
                     end else if (cache1_ReadEx_2) begin
                       nxt_sharer = 4'b0010;
                       nxt_owner  = 3'b010;
                     end else if (cache2_ReadEx_2) begin
                       nxt_sharer = 4'b0100;
                       nxt_owner  = 3'b011;
                     end else if (cache3_ReadEx_2) begin
                       nxt_sharer = 4'b1000;
                       nxt_owner  = 3'b100;
                     end else begin
                       nxt_sharer = 4'b0000;
                       nxt_owner  = 3'b000;
                     end
                     nxt_cache_readex_ack = 1'b1; //send cache readex back
                     nxt_cache_reads_ack  = 1'b0;
                     nxt_cache3_invalid = 1'b0;
                     nxt_cache3_invalid_addr = 9'b0;
                     nxt_cache2_invalid = 1'b0;
                     nxt_cache2_invalid_addr = 9'b0;
                     nxt_cache1_invalid = 1'b0;
                     nxt_cache1_invalid_addr = 9'b0;
                     nxt_cache0_invalid = 1'b0;
                     nxt_cache0_invalid_addr = 9'b0;
                     nxt_invalidation_count = 3'b0;
                  end else begin
                     nxt_state  = S_O;
                     nxt_sharer = 4'b0000;
                     nxt_owner  = 3'b000;
                     nxt_cache_readex_ack = 1'b0; //send cache readex back
                     nxt_cache_reads_ack  = 1'b0;
                     nxt_cache3_invalid = 1'b0;
                     nxt_cache3_invalid_addr = 9'b0;
                     nxt_cache2_invalid = 1'b0;
                     nxt_cache2_invalid_addr = 9'b0;
                     nxt_cache1_invalid = 1'b0;
                     nxt_cache1_invalid_addr = 9'b0;
                     nxt_cache0_invalid = 1'b0;
                     nxt_cache0_invalid_addr = 9'b0;
                     nxt_invalidation_count = 3'b0;
                  end
               end else begin
                     nxt_state  = S_O;
                     if (cache0_ReadS_2) begin
                       nxt_sharer = cache_access_line[15:12] | 4'b0001;
                     end else if (cache1_ReadS_2) begin
                       nxt_sharer = cache_access_line[15:12] | 4'b0010;
                     end else if (cache2_ReadS_2) begin
                       nxt_sharer = cache_access_line[15:12] | 4'b0100;
                     end else if (cache3_ReadS_2) begin
                       nxt_sharer = cache_access_line[15:12] | 4'b1000;
                     end else begin
                        nxt_sharer = cache_access_line[15:12];
                     end
                     nxt_owner  = cache_access_line [18:16];
                     nxt_cache_readex_ack = 1'b0; 
                     nxt_cache_reads_ack  = 1'b1; //send cache reads ack back
                     nxt_cache3_invalid = 1'b0;
                     nxt_cache3_invalid_addr = 9'b0;
                     nxt_cache2_invalid = 1'b0;
                     nxt_cache2_invalid_addr = 9'b0;
                     nxt_cache1_invalid = 1'b0;
                     nxt_cache1_invalid_addr = 9'b0;
                     nxt_cache0_invalid = 1'b0;
                     nxt_cache0_invalid_addr = 9'b0;
                     nxt_invalidation_count = 3'b0;
               end 
         end else begin //default
            nxt_state       = S_O;
            nxt_data        = 8'b0;
            nxt_sharer = 4'b0;
            nxt_owner  = 3'b0;
            nxt_mem_request = 1'b0;
            nxt_mem_addr   = 9'b0;
            nxt_write_back = 1'b0;
            nxt_wb_tag     = 1'b0;
            nxt_wb_data    = 8'b0;
            nxt_cache_readex_ack = 1'b0;
            nxt_cache_reads_ack = 1'b0;
            nxt_cache3_invalid = 1'b0;
            nxt_cache3_invalid_addr = 9'b0;
            nxt_cache2_invalid = 1'b0;
            nxt_cache2_invalid_addr = 9'b0;
            nxt_cache1_invalid = 1'b0;
            nxt_cache1_invalid_addr = 9'b0;
            nxt_cache0_invalid = 1'b0;
            nxt_cache0_invalid_addr = 9'b0;
            nxt_invalidation_count = 3'b0; 
         end
         S_M: if ((cache_ReadEx_2 == 1'b1) || (cache_ReadS_2)) begin
                nxt_mem_request = 1'b0;
                nxt_mem_addr   = 9'b0;
                nxt_write_back = 1'b0;
                nxt_wb_tag     = 1'b0;
                nxt_wb_data    = 8'b0;
                nxt_data       = 8'b0;
                if (cache_ReadEx_2 == 1'b1) begin
                  if ((cache_access_line [15:12] != 4'b0) && (invalidation_count == 0) && (invalidation_broadcast_done == 1'b0)) begin //Broadcast invalidation requests to all the cores 
                           nxt_cache3_invalid = 1'b1;
                           nxt_cache3_invalid_addr = cache_address;
                           nxt_cache2_invalid = 1'b1;
                           nxt_cache2_invalid_addr = cache_address;
                           nxt_cache1_invalid = 1'b1;
                           nxt_cache1_invalid_addr = cache_address;
                           nxt_cache0_invalid = 1'b1;
                           nxt_cache0_invalid_addr = cache_address;
                           nxt_invalidation_count = 3'b100;
                           nxt_state  = S_M;
                           nxt_sharer = 4'b0000;
                           nxt_owner  = 3'b000;
                           nxt_cache_readex_ack = 1'b0;
                           nxt_cache_reads_ack  = 1'b0;
                  end else if (invalidation_count != 0) begin
                           nxt_cache3_invalid = cache3_Invalid;
                           nxt_cache3_invalid_addr = cache3_Invalid_Addr;
                           nxt_cache2_invalid = cache2_Invalid;
                           nxt_cache2_invalid_addr = cache2_Invalid_Addr;
                           nxt_cache1_invalid = cache1_Invalid;
                           nxt_cache1_invalid_addr = cache1_Invalid_Addr;
                           nxt_cache0_invalid = cache0_Invalid;
                           nxt_cache0_invalid_addr = cache0_Invalid_Addr;
                           nxt_invalidation_count = invalidation_count;
                           nxt_state  = S_M;
                           nxt_sharer = 4'b0000;
                           nxt_owner  = 3'b000;
                           nxt_cache_readex_ack = 1'b0;
                           nxt_cache_reads_ack  = 1'b0;
                  end else if ((invalidation_broadcast_done == 1'b1) && (invalidation_count == 0)) begin //all cores have invalidated their blocks  
                     nxt_state  = S_M;
                     if (cache0_ReadEx_2) begin
                       nxt_sharer = 4'b0001;
                       nxt_owner  = 3'b001;
                     end else if (cache1_ReadEx_2) begin
                       nxt_sharer = 4'b0010;
                       nxt_owner  = 3'b010;
                     end else if (cache2_ReadEx_2) begin
                       nxt_sharer = 4'b0100;
                       nxt_owner  = 3'b011;
                     end else if (cache3_ReadEx_2) begin
                       nxt_sharer = 4'b1000;
                       nxt_owner  = 3'b100;
                     end else begin
                       nxt_sharer = 4'b0000;
                       nxt_owner  = 3'b000;
                     end
                     nxt_cache_readex_ack = 1'b1; //send cache readex back
                     nxt_cache_reads_ack  = 1'b0;
                     nxt_cache3_invalid = 1'b0;
                     nxt_cache3_invalid_addr = 9'b0;
                     nxt_cache2_invalid = 1'b0;
                     nxt_cache2_invalid_addr = 9'b0;
                     nxt_cache1_invalid = 1'b0;
                     nxt_cache1_invalid_addr = 9'b0;
                     nxt_cache0_invalid = 1'b0;
                     nxt_cache0_invalid_addr = 9'b0;
                     nxt_invalidation_count = 3'b0;
                  end else begin
                     nxt_state  = S_S;
                     nxt_sharer = 4'b0000;
                     nxt_owner  = 3'b000;
                     nxt_cache_readex_ack = 1'b0; //send cache readex back
                     nxt_cache_reads_ack  = 1'b0;
                     nxt_cache3_invalid = 1'b0;
                     nxt_cache3_invalid_addr = 9'b0;
                     nxt_cache2_invalid = 1'b0;
                     nxt_cache2_invalid_addr = 9'b0;
                     nxt_cache1_invalid = 1'b0;
                     nxt_cache1_invalid_addr = 9'b0;
                     nxt_cache0_invalid = 1'b0;
                     nxt_cache0_invalid_addr = 9'b0;
                     nxt_invalidation_count = 3'b0;
                  end
               end else begin
                     nxt_state  = S_O;
                     if (cache0_ReadS_2) begin
                       nxt_sharer = cache_access_line[15:12] | 4'b0001;
                     end else if (cache1_ReadS_2) begin
                       nxt_sharer = cache_access_line[15:12] | 4'b0010;
                     end else if (cache2_ReadS_2) begin
                       nxt_sharer = cache_access_line[15:12] | 4'b0100;
                     end else if (cache3_ReadS_2) begin
                       nxt_sharer = cache_access_line[15:12] | 4'b1000;
                     end else begin
                        nxt_sharer = cache_access_line[15:12];
                     end
                     nxt_owner  = cache_access_line [18:16];
                     nxt_cache_readex_ack = 1'b0; 
                     nxt_cache_reads_ack  = 1'b1; //send cache reads ack back
                     nxt_cache3_invalid = 1'b0;
                     nxt_cache3_invalid_addr = 9'b0;
                     nxt_cache2_invalid = 1'b0;
                     nxt_cache2_invalid_addr = 9'b0;
                     nxt_cache1_invalid = 1'b0;
                     nxt_cache1_invalid_addr = 9'b0;
                     nxt_cache0_invalid = 1'b0;
                     nxt_cache0_invalid_addr = 9'b0;
                     nxt_invalidation_count = 3'b0;
               end 
         end else begin //default
            nxt_state       = S_M;
            nxt_data        = 8'b0;
            nxt_sharer = 4'b0;
            nxt_owner  = 3'b0;
            nxt_mem_request = 1'b0;
            nxt_mem_addr   = 9'b0;
            nxt_write_back = 1'b0;
            nxt_wb_tag     = 1'b0;
            nxt_wb_data    = 8'b0;
            nxt_cache_readex_ack = 1'b0;
            nxt_cache_reads_ack = 1'b0;
            nxt_cache3_invalid = 1'b0;
            nxt_cache3_invalid_addr = 9'b0;
            nxt_cache2_invalid = 1'b0;
            nxt_cache2_invalid_addr = 9'b0;
            nxt_cache1_invalid = 1'b0;
            nxt_cache1_invalid_addr = 9'b0;
            nxt_cache0_invalid = 1'b0;
            nxt_cache0_invalid_addr = 9'b0;
            nxt_invalidation_count = 3'b0; 
         end
      
    default: begin 
             nxt_state       = S_S;
             nxt_data        = 8'b0;
             nxt_sharer = 4'b0;
             nxt_owner  = 3'b0;
             nxt_mem_request = Mem_Request;
             nxt_mem_addr   = 9'b0;
             nxt_write_back = 1'b0;
             nxt_wb_tag     = 1'b0;
             nxt_wb_data    = 8'b0;
             nxt_cache_readex_ack = 1'b0;
             nxt_cache_reads_ack = 1'b0;
             nxt_cache3_invalid = 1'b0;
             nxt_cache3_invalid_addr = 9'b0;
             nxt_cache2_invalid = 1'b0;
             nxt_cache2_invalid_addr = 9'b0;
             nxt_cache1_invalid = 1'b0;
             nxt_cache1_invalid_addr = 9'b0;
             nxt_cache0_invalid = 1'b0;
             nxt_cache0_invalid_addr = 9'b0;
             nxt_invalidation_count = 3'b0;
             end
  endcase
end

endmodule //directory
