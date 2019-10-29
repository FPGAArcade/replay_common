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
-- Ram model with two read/write ports with individual clocks
-- clocked read
-- paranoid generics for optimization...
-- potentially extend to have different read/write widths
--
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

  use work.Replay_Pack.all;

entity RAM_DP is
  generic (
    g_width             : in integer := 16;
    g_depth             : in integer := 10;
    g_has_a_read        : in boolean := false; -- need to set to true if using o_a_data
    g_has_b_write       : in boolean := false; -- need to set to true if using i_b_data
    g_use_init          : in boolean := true;
    g_hex_init_filename : in string := "none";
    g_bin_init_filename : in string := "none"
    );
  port (
    i_a_addr      : in  word(g_depth-1 downto 0);
    i_a_data      : in  word(g_width-1 downto 0) := (others => '0');
    o_a_data      : out word(g_width-1 downto 0);
    --
    i_a_write     : in  bit1 := '0';
    i_a_ena       : in  bit1 := '1'; -- clock enable
    i_a_clk       : in  bit1;

    i_b_addr      : in  word(g_depth-1 downto 0);
    i_b_data      : in  word(g_width-1 downto 0) := (others => '0');
    o_b_data      : out word(g_width-1 downto 0);

    i_b_write     : in  bit1 := '0';
    i_b_ena       : in  bit1 := '1';
    i_b_clk       : in  bit1
  );
end entity;

architecture RTL of RAM_DP is

  constant depth   : integer := 2 ** g_depth;

  constant g_has_a_read_int  : integer := bool_to_int(g_has_a_read);
  constant g_has_b_write_int : integer := bool_to_int(g_has_b_write);
  constant g_use_init_int    : integer := bool_to_int(g_use_init);

  component RAM_DP_V
    generic (
      g_width             : in integer;
      g_depth             : in integer;
      g_has_a_read        : in integer;
      g_has_b_write       : in integer;
      g_use_init          : in integer;
      g_hex_init_filename : in string;
      g_bin_init_filename : in string
      );
    port (
      i_a_addr      : in  word(g_depth-1 downto 0);
      i_a_data      : in  word(g_width-1 downto 0);
      o_a_data      : out word(g_width-1 downto 0);
      --
      i_a_write     : in  bit1;
      i_a_ena       : in  bit1;
      i_a_clk       : in  bit1;

      i_b_addr      : in  word(g_depth-1 downto 0);
      i_b_data      : in  word(g_width-1 downto 0);
      o_b_data      : out word(g_width-1 downto 0);

      i_b_write     : in  bit1 := '0';
      i_b_ena       : in  bit1 := '1';
      i_b_clk       : in  bit1
    );
  end component;

begin

  g_check : if (depth > 65536) generate
    assert false report "Max depth 65536" severity error;
  end generate;

  u_ram : RAM_DP_V
  generic map (
    g_width             => g_width,
    g_depth             => g_depth,
    g_has_a_read        => g_has_a_read_int,
    g_has_b_write       => g_has_b_write_int,
    g_use_init          => g_use_init_int,
    g_hex_init_filename => g_hex_init_filename,
    g_bin_init_filename => g_bin_init_filename
    )
  port map (
    i_a_addr       => i_a_addr,
    i_a_data       => i_a_data,
    o_a_data       => o_a_data,
    --
    i_a_write      => i_a_write,
    i_a_ena        => i_a_ena,
    i_a_clk        => i_a_clk,
    --
    i_b_addr       => i_b_addr,
    i_b_data       => i_b_data,
    o_b_data       => o_b_data,
    --
    i_b_write      => i_b_write,
    i_b_ena        => i_b_ena,
    i_b_clk        => i_b_clk
    );

end;