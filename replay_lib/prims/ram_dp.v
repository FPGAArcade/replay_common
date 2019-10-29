//
// WWW.FPGAArcade.COM
//
// REPLAY Retro Gaming Platform
// No Emulation No Compromise
//
// All rights reserved
// Mike Johnson 
//
// Redistribution and use in source and synthezised forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// Redistributions in synthesized form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
//
// Neither the name of the author nor the names of other contributors may
// be used to endorse or promote products derived from this software without
// specific prior written permission.
//
// THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
// You are responsible for any legal issues arising from your use of this code.
//
// The latest version of this file can be found at: www.FPGAArcade.com
//
// Email support@fpgaarcade.com
//
// note false 0, true 1
// read first
module RAM_DP_V
 #(
    parameter g_width       = 16,
    parameter g_depth       = 10,
    parameter g_has_a_read  = 0,
    parameter g_has_b_write = 0,
    parameter g_use_init    = 1,
    parameter g_hex_init_filename = "none",
    parameter g_bin_init_filename = "none"
  ) (
    input  [g_depth-1:0] i_a_addr,
    input  [g_width-1:0] i_a_data,
    output [g_width-1:0] o_a_data,
    //
    input                i_a_write,
    input                i_a_ena,
    input                i_a_clk,
    //
    input  [g_depth-1:0] i_b_addr,
    input  [g_width-1:0] i_b_data,
    output [g_width-1:0] o_b_data,
    //
    input                i_b_write,
    input                i_b_ena,
    input                i_b_clk
  );

  localparam depth = 2**g_depth;
  reg [g_width-1:0] ram [depth-1:0];
  reg [g_width-1:0] a_data_reg;
  reg [g_width-1:0] b_data_reg;

  initial begin
    if (g_use_init && g_hex_init_filename != "none") begin
      $display("Loading hex file : %s",g_hex_init_filename);
      $readmemh(g_hex_init_filename, ram, 0, depth-1);
    end

    if (g_use_init && g_bin_init_filename != "none") begin
      $display("Loading bin file : %s",g_bin_init_filename);
      $readmemb(g_bin_init_filename, ram, 0, depth-1);
    end
  end
  //
  // A PORT
  //
  generate if (g_has_a_read) begin
    always @(posedge i_a_clk) begin
      if (i_a_ena) begin
        if (i_a_write) begin
          ram[i_a_addr] <= i_a_data;
          a_data_reg <= i_a_data;
        end
        a_data_reg <= ram[i_a_addr];
      end
    end
    assign o_a_data = a_data_reg;

  end else begin

    always @(posedge i_a_clk) begin
      if (i_a_ena) begin
        if (i_a_write) begin
          ram[i_a_addr] <= i_a_data;
        end
      end
    end
    assign o_a_data = 0;

  end
  endgenerate
  //
  // B PORT
  //
  generate if (g_has_b_write) begin

    always @(posedge i_b_clk) begin
      if (i_b_ena) begin
        if (i_b_write) begin
          ram[i_b_addr] <= i_b_data;
        end
        b_data_reg <= ram[i_b_addr];
      end
    end

  end else begin

    always @(posedge i_b_clk) begin
      if (i_b_ena) begin
        b_data_reg <= ram[i_b_addr];
      end
    end
  end
  endgenerate

  assign o_b_data = b_data_reg;
endmodule