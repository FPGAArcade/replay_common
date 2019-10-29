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
  use work.Replay_CoreIO_Pack.all;

--
-- A RAM/ROM which is loadable/readable from the ARM cfgio bus
-- the read port (o_data) is clocked
-- also has a static load option
--
entity Cfg_RAM_W8 is
  generic (
    g_depth                     : in  integer := 10;
    g_addr                      : in  word(31 downto 0); -- 31 and 3..0 not used
    g_mask                      : in  word(31 downto 0) := x"FFFFFFFF"; -- use to mask off any other bits in the compare
    g_use_init                  : in  boolean := true;
    g_hex_init_filename         : in  string := "none";
    g_bin_init_filename         : in  string := "none"
    );
  port (
    -- ARM interface
    i_cfgio_to_core             : in  r_Cfgio_to_core := z_Cfgio_to_core;
    --
    i_cfgio_fm_core             : in  r_Cfgio_fm_core := z_Cfgio_fm_core; -- cascade input. Must be z_cfgio_fm_core on first memory
    o_cfgio_fm_core             : out r_Cfgio_fm_core; -- output back to LIB, or cascade into i_cfgio_fm_core on next memory
    --
    i_clk_sys                   : in  bit1 := '0';
    i_ena_sys                   : in  bit1 := '0';
    --
    i_addr                      : in  word(g_depth-1 downto 0);
    i_data                      : in  word( 7 downto 0);
    i_ena                       : in  std_logic;          -- read/write clock enable
    i_wen                       : in  bit1;               -- high for a write
    o_data                      : out word( 7 downto 0);
    --
    i_clk                       : in  std_logic
    );
end;

architecture RTL of Cfg_RAM_W8 is
  constant depth                : integer := 2 ** g_depth;

  signal cfgio_match            : bit1;
  signal cfgio_cycle            : bit1 := '0';
  signal cfgio_ena              : bit1;
  signal cfgio_we               : bit1;
  signal cfgio_re               : bit1;
  signal cfgio_dout             : word(7 downto 0);
  signal cfgio_dout_g           : word(7 downto 0);

begin
  g_check_max : if (depth > 65536) generate
    assert false report "Max depth 65536" severity error;
  end generate;

  g_check_min : if (depth < 16) generate
    assert false report "Min depth 16" severity error;
  end generate;

  p_sel : process(i_cfgio_to_core)
  begin
    cfgio_match <= '0';
    if (i_cfgio_to_core.addr(30 downto 4) and g_mask(30 downto 4)) = (g_addr(30 downto 4) and g_mask(30 downto 4)) then
      cfgio_match <= '1';
    end if;
  end process;

  p_mio : process
  begin
    wait until rising_edge(i_clk_sys);
    if (i_ena_sys = '1') then
      cfgio_cycle <= '0';
      cfgio_we    <= '0';

      if (cfgio_match = '1') and (i_cfgio_to_core.valid = '1') and (cfgio_cycle = '0') then
        cfgio_cycle <= '1';
        cfgio_we    <= not i_cfgio_to_core.rw_l;
      end if;
    end if;
  end process;

  cfgio_ena <= i_ena_sys and cfgio_cycle;

  u_ram : entity work.RAM_DP
  generic map (
    g_width             => 8,
    g_depth             => g_depth,
    g_has_a_read        => true,
    g_has_b_write       => true,
    g_use_init          => g_use_init,
    g_hex_init_filename => g_hex_init_filename,
    g_bin_init_filename => g_bin_init_filename
    )
  port map (
    i_a_addr      => i_cfgio_to_core.addr(g_depth-1 downto 0),
    i_a_data      => i_cfgio_to_core.w_data,
    o_a_data      => cfgio_dout,
    i_a_write     => cfgio_we,
    i_a_ena       => cfgio_ena,
    i_a_clk       => i_clk_sys,

    i_b_addr      => i_addr(g_depth-1 downto 0),
    i_b_data      => i_data,
    o_b_data      => o_data,
    i_b_write     => i_wen,
    i_b_ena       => i_ena,
    i_b_clk       => i_clk
    );

  p_out : process
  begin
    wait until rising_edge(i_clk_sys);
    if (i_ena_sys = '1') then
      cfgio_re <= cfgio_cycle and not cfgio_we;
    end if;
  end process;

  cfgio_dout_g <= cfgio_dout when (cfgio_re = '1') else (others => '0');

  o_cfgio_fm_core.taken  <= cfgio_cycle  or i_cfgio_fm_core.taken;
  o_cfgio_fm_core.r_we   <= cfgio_re     or i_cfgio_fm_core.r_we;
  o_cfgio_fm_core.r_data <= cfgio_dout_g or i_cfgio_fm_core.r_data;
end;
