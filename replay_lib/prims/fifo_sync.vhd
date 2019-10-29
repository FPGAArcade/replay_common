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

-- max 32K deep
entity FIFO_Sync is
  generic (
    g_width       : in  integer := 18;
    g_depth       : in  integer := 10
    );
  port (
    i_w_data      : in  word(g_width-1 downto 0);
    i_w_ena       : in  bit1;
    o_w_full      : out bit1;
    -- note fall through
    o_r_data      : out word(g_width-1 downto 0);
    i_r_taken     : in  bit1;
    o_r_valid     : out bit1;
    --
    o_level       : out word(g_depth downto 0); -- words in FIFO, 100.0 downto 00.0
    --
    i_ena         : in  bit1;
    i_rst         : in  bit1; -- sync
    i_clk         : in  bit1
    );
end;

architecture RTL of FIFO_Sync is
  constant depth        : integer := 2 ** g_depth;
  signal w_ena          : bit1;
  signal r_ena          : bit1;
  signal r_ena_g        : bit1;

  signal r_addr         : word(g_depth-1 downto 0);
  signal w_addr         : word(g_depth-1 downto 0);
  signal level          : word(g_depth   downto 0);

  signal full_i         : bit1;
  signal empty_i        : bit1;
  signal valid          : bit1;

  constant c_Full       : word(g_depth downto 0) := to_word(depth,   g_depth+1);
  constant c_Full_m1    : word(g_depth downto 0) := to_word(depth-1, g_depth+1);
  constant c_Empty_p1   : word(g_depth downto 0) := to_word(1,       g_depth+1);
  constant c_Empty      : word(g_depth downto 0) := to_word(0,       g_depth+1);


  type array_x is array (natural range <>) of word(g_width-1 downto 0);
  signal ram : array_x(depth-1 downto 0);

begin

  g_check_max : if (depth > 32768) generate
    assert false report "Max depth 32768" severity error;
  end generate;

  g_check_min : if (depth < 16) generate
    assert false report "Min depth 16" severity error;
  end generate;

  u_ram : entity work.RAM_DP
  generic map (
    g_width      => g_width,
    g_depth      => g_depth
    )
  port map (
    i_a_addr      => w_addr,
    i_a_data      => i_w_data,

    i_a_write     => w_ena,
    i_a_ena       => i_ena,
    i_a_clk       => i_clk,

    i_b_addr      => r_addr,
    o_b_data      => o_r_data,
    i_b_ena       => r_ena_g,
    i_b_clk       => i_clk
    );

  p_gate  : process(full_i, i_w_ena, empty_i, i_r_taken, valid)
  begin
    w_ena <= i_w_ena and not full_i;
    r_ena <= (i_r_taken or not valid) and (not empty_i);
  end process;
  r_ena_g <= i_ena and r_ena;

  p_valid  : process
  begin
    wait until rising_edge(i_clk);
    if (i_rst = '1') then
      valid <= '0';
    elsif (i_ena = '1') then
      if (empty_i = '0') then
         valid <= '1';
      elsif (i_r_taken = '1') then
        valid <= '0';
      end if;
    end if;
  end process;

  p_addr : process
    variable offset : std_logic_vector(g_depth downto 0);
    variable sel    : std_logic_vector( 1 downto 0);
  begin
    wait until rising_edge(i_clk);
    if (i_rst = '1') then
      w_addr  <= (others => '0');
      r_addr  <= (others => '0');
      level   <= (others => '0');
      full_i  <= '0';
      empty_i <= '1';
    elsif (i_ena = '1') then
      if (w_ena = '1') then
        w_addr <= w_addr + "1";
      end if;

      if (r_ena = '1') then
        r_addr <= r_addr + "1";
      end if;

      offset := (others => '0');
      sel := w_ena & r_ena;
      case sel is
        when "10" => offset(0) := '1'; -- +1
                     if (level = c_Full_m1 ) then full_i  <= '1'; end if;
                     if (level = c_Empty   ) then empty_i <= '0'; end if;

        when "01" => offset    := (others => '1'); -- -1
                     if (level = c_Full    ) then full_i  <= '0'; end if;
                     if (level = c_Empty_p1) then empty_i <= '1'; end if;

        when others => null;
      end case;
      level <= level + offset;
    end if;
  end process;

  o_w_full  <= full_i;
  o_r_valid <= valid;
  o_level   <= level;
end;