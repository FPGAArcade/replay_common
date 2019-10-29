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
-- Ram model with one read/write port
--
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

  use work.Replay_Pack.all;

entity RAM_SP is
  generic (
    g_width             : in  integer := 16;
    g_depth             : in  integer := 10;
    g_use_init          : in boolean := true;
    g_hex_init_filename : in string := "none";
    g_bin_init_filename : in string := "none"
    );
  port (
    i_addr         : in  word(g_depth-1 downto 0);
    i_data         : in  word(g_width-1 downto 0) := (others => '0');
    o_data         : out word(g_width-1 downto 0);
    --
    i_write        : in  bit1 := '0';
    i_ena          : in  bit1 := '1';
    i_clk          : in  bit1
  );
end entity;

architecture RTL of RAM_SP is

  constant depth   : integer := 2 ** g_depth;
  constant g_use_init_int    : integer := bool_to_int(g_use_init);

  component RAM_SP_V
    generic (
      g_width             : in integer;
      g_depth             : in integer;
      g_use_init          : in integer;
      g_hex_init_filename : in string;
      g_bin_init_filename : in string
      );
    port (
      i_addr            : in  word(g_depth-1 downto 0);
      i_data            : in  word(g_width-1 downto 0);
      o_data            : out word(g_width-1 downto 0);
      --
      i_write           : in  bit1; -- write enable
      i_ena             : in  bit1; -- write enable
      i_clk             : in  bit1
      );
  end component;

begin

  g_check : if (depth > 65536) generate
    assert false report "Max depth 65536" severity error;
  end generate;

  u_ram : RAM_SP_V
  generic map (
    g_width             => g_width,
    g_depth             => g_depth,
    g_use_init          => g_use_init_int,
    g_hex_init_filename => g_hex_init_filename,
    g_bin_init_filename => g_bin_init_filename
    )
  port map (
    i_addr       => i_addr,
    i_data       => i_data,
    o_data       => o_data,
    --
    i_write      => i_write,
    i_ena        => i_ena,
    i_clk        => i_clk
    );

end;