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
// single port block RAM, read first
module RAM_SP_V
 #(
    parameter g_width       = 16,
    parameter g_depth       = 10,
    parameter g_use_init    = 1,
    parameter g_hex_init_filename = "none",
    parameter g_bin_init_filename = "none"
  ) (
    input  [g_depth-1:0] i_addr,
    input  [g_width-1:0] i_data,
    output [g_width-1:0] o_data,
    //
    input                i_write,
    input                i_ena,
    input                i_clk
  );

  localparam depth = 2**g_depth;
  reg [g_width-1:0] ram [depth-1:0];
  reg [g_width-1:0] data_reg;

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

  always @(posedge i_clk) begin
    if (i_ena) begin
      if (i_write) begin
        ram[i_addr] <= i_data;
        data_reg <= i_data;
      end
      data_reg <= ram[i_addr];
    end
  end

  assign o_data = data_reg;

endmodule
