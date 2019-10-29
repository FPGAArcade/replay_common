--
-- WWW.FPGAArcade.COM
--
-- REPLAY Retro Gaming Platform
-- No Emulation No Compromise
--
-- All rights reserved
-- Mike Johnson 
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- You are responsible for any legal issues arising from your use of this code.
--
-- The latest version of this file can be found at: www.FPGAArcade.com
--
-- Email support@fpgaarcade.com
--
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

  use work.Replay_Pack.all;

-- VHDL wrappers for RAM_LUT.V
-- COMBINATORIAL READ
-- all map to RAM16X1D arrays on Xilinx

entity RAM_LUT is
  generic (
    g_width             : in integer := 8;
    g_depth             : in integer := 4; -- note BITS here
    g_has_a_write       : in boolean := true;
    g_has_a_read        : in boolean := false;
    g_use_init          : in boolean := true;
    g_hex_init_filename : in string := "none";
    g_bin_init_filename : in string := "none"
    );
  port (
    i_a_addr       : in  word(g_depth-1 downto 0) := (others => '0');
    i_a_data       : in  word(g_Width-1 downto 0) := (others => '0');
    o_a_data       : out word(g_Width-1 downto 0); -- optional op
    i_a_write      : in  bit1 := '0'; -- write enable
    i_a_clk        : in  bit1 := '0';

    i_b_addr       : in  word(g_depth-1 downto 0);
    o_b_data       : out word(g_Width-1 downto 0)
    );
end;

architecture RTL of RAM_LUT is
  constant depth             : integer := 2 ** g_depth;

  constant g_has_a_write_int : integer := bool_to_int(g_has_a_write);
  constant g_has_a_read_int  : integer := bool_to_int(g_has_a_read);
  constant g_use_init_int    : integer := bool_to_int(g_use_init);

  component RAM_LUT_V
    generic (
      g_width             : in integer;
      g_depth             : in integer;
      g_has_a_write       : in integer;
      g_has_a_read        : in integer;
      g_use_init          : in integer;
      g_hex_init_filename : in string;
      g_bin_init_filename : in string
      );
    port (
      i_a_addr            : in  word(g_depth-1 downto 0);
      i_a_data            : in  word(g_width-1 downto 0);
      o_a_data            : out word(g_width-1 downto 0);
      i_a_write           : in  bit1; -- write enable
      i_a_clk             : in  bit1;

      i_b_addr            : in  word(g_depth-1 downto 0);
      o_b_data            : out word(g_Width-1 downto 0)
      );
  end component;

begin

  g_check : if (depth > 4096) generate
    assert false report "Max depth 4096" severity error;
  end generate;

  u_ram : RAM_LUT_V
  generic map (
    g_width             => g_width,
    g_depth             => g_depth,
    g_has_a_write       => g_has_a_write_int,
    g_has_a_read        => g_has_a_read_int,
    g_use_init          => g_use_init_int,
    g_hex_init_filename => g_hex_init_filename,
    g_bin_init_filename => g_bin_init_filename
    )
  port map (
    i_a_addr       => i_a_addr,
    i_a_data       => i_a_data,
    o_a_data       => o_a_data,
    i_a_write      => i_a_write,
    i_a_clk        => i_a_clk,

    i_b_addr       => i_b_addr,
    o_b_data       => o_b_data
    );

end;