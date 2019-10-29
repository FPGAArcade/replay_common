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
entity FIFO_ASync is
  generic (
    g_width       : in  integer := 18;
    g_depth       : in  integer := 10
    );
  port (
    i_w_data      : in  word(g_width-1 downto 0);
    i_w_ena       : in  bit1;
    o_w_full      : out bit1;
    o_w_level     : out word(g_depth   downto 0); -- lags read side
    -- note fall through
    o_r_data      : out word(g_width-1 downto 0);
    i_r_taken     : in  bit1;
    o_r_valid     : out bit1;
    --
    i_rst         : in  bit1; -- async. Will be synced to both clocks internally
    i_clk_w       : in  bit1;
    i_clk_r       : in  bit1
    );
end;

architecture RTL of FIFO_ASync is

  constant depth        : integer := 2 ** g_depth;
  signal rst_w_meta     : bit1;
  signal rst_w          : bit1;
  signal rst_r_meta     : bit1;
  signal rst_r          : bit1;

  signal w_ena          : bit1;
  signal r_ena          : bit1;

  signal r_addr_next_bin : word(g_depth   downto 0);
  signal r_addr_next_gry : word(g_depth   downto 0);
  signal r_addr_bin      : word(g_depth   downto 0);
  signal r_addr_gry      : word(g_depth   downto 0);
  signal wt1_r_addr_gry  : word(g_depth   downto 0);
  signal wt2_r_addr_gry  : word(g_depth   downto 0);

  signal w_addr_next_bin : word(g_depth   downto 0);
  signal w_addr_next_gry : word(g_depth   downto 0);
  signal w_addr_bin      : word(g_depth   downto 0);
  signal w_addr_gry      : word(g_depth   downto 0);
  signal rt1_w_addr_gry  : word(g_depth   downto 0);
  signal rt2_w_addr_gry  : word(g_depth   downto 0);

  signal w_full          : bit1;
  signal r_empty         : bit1;
  signal r_valid         : bit1;

  -- note these only work for len >=3
  function to_gray (ip : word) return word is
    constant t : natural := ip'length-1;
    variable r : word(t downto 0);
  begin
    r(t) := ip(t);
    for i in 0 to t-1 loop
      r(i) := ip(i+1) xor ip(i);
    end loop;
    return r;
  end function;

function to_bin (ip : word) return word is
    constant t : natural := ip'length-1;
    variable r : word(t downto 0);
  begin
    r(t) := ip(t);
    for i in t-1 downto 0 loop
      r(i) := ip(i) xor r(i+1);
    end loop;
    return r;
  end function;

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
    i_a_addr      => w_addr_bin(g_depth-1 downto 0),
    i_a_data      => i_w_data,
    i_a_write     => w_ena,
    i_a_ena       => '1',
    i_a_clk       => i_clk_w,

    i_b_addr      => r_addr_bin(g_depth-1 downto 0),
    o_b_data      => o_r_data,
    i_b_ena       => r_ena,
    i_b_clk       => i_clk_r
    );
  --
  -- reset resync
  --
  p_rst_w_meta : process(i_clk_w, i_rst)
  begin
    if (i_rst = '1') then
      rst_w_meta <= '1';
    elsif rising_edge(i_clk_w) then
      rst_w_meta <= '0';
    end if;
  end process;

  p_rst_w : process
  begin
    wait until rising_edge(i_clk_w);
    rst_w <= rst_w_meta;
  end process;

  p_rst_r_meta : process(i_clk_r, i_rst)
  begin
    if (i_rst = '1') then
      rst_r_meta <= '1';
    elsif rising_edge(i_clk_r) then
      rst_r_meta <= '0';
    end if;
  end process;

  p_rst_r : process
  begin
    wait until rising_edge(i_clk_r);
    rst_r <= rst_r_meta;
  end process;
  --
  --
  --
  p_control : process(i_w_ena, w_full, i_r_taken, r_valid, r_empty)
  begin
    w_ena  <= i_w_ena and not w_full;
    r_ena  <= (i_r_taken or not r_valid) and (not r_empty);
  end process;

  p_w_check : process
  begin
    wait until rising_edge(i_clk_w);
    if (rst_w = '0') then
      if (w_full = '1' and i_w_ena = '1') then
        assert false report "FIFO written when full" severity error;
      end if;
    end if;
  end process;

  p_valid  : process(i_clk_r, rst_r)
  begin
    if (rst_r = '1') then
      r_valid <= '0';
    elsif rising_edge(i_clk_r) then
      if (r_empty = '0') then
         r_valid <= '1';
      elsif (i_r_taken = '1') then
        r_valid <= '0';
      end if;
    end if;
  end process;
  o_r_valid <= r_valid;
  --
  -- write side
  --
  p_w_addr_next : process(w_ena, w_addr_bin)
  begin
    w_addr_next_bin <= w_addr_bin;
    if (w_ena = '1') then
      w_addr_next_bin <= w_addr_bin + "1";
    end if;
  end process;
  w_addr_next_gry <= to_gray(w_addr_next_bin);

  p_w_addr : process (i_clk_w, rst_w)
  begin
    if (rst_w = '1') then
      w_addr_bin <= (others => '0');
      w_addr_gry <= (others => '0');
      w_full     <= '0';
    elsif rising_edge(i_clk_w) then
      w_addr_bin <= w_addr_next_bin;
      w_addr_gry <= w_addr_next_gry;

      w_full     <= '0';
      if ( (not wt2_r_addr_gry(g_depth downto g_depth-1)) & wt2_r_addr_gry(g_depth-2 downto 0) = w_addr_next_gry ) then
        w_full   <= '1';
      end if;
    end if;
  end process;

  p_w_level : process (i_clk_w, rst_w)
    variable r_bin : word(g_depth downto 0);
  begin
    if (rst_w = '1') then
      o_w_level <= (others => '0');
    elsif rising_edge(i_clk_w) then

      r_bin := to_bin(wt2_r_addr_gry);
      o_w_level <= (w_addr_next_bin - r_bin);
    end if;
  end process;

  --
  -- read side
  --
  p_r_addr_next : process(r_ena, r_addr_bin)
  begin
    r_addr_next_bin <= r_addr_bin;
    if (r_ena = '1') then
      r_addr_next_bin <= r_addr_bin + "1";
    end if;
  end process;
  r_addr_next_gry <= to_gray(r_addr_next_bin);

  p_r_addr : process (i_clk_r, rst_r)
  begin
    if (rst_r = '1') then
      r_addr_bin <= (others => '0');
      r_addr_gry <= (others => '0');
      r_empty    <= '1';
    elsif rising_edge(i_clk_r) then
      r_addr_bin <= r_addr_next_bin;
      r_addr_gry <= r_addr_next_gry;
      r_empty    <= '0';
      if (r_addr_next_gry = rt2_w_addr_gry) then
        r_empty    <= '1';
      end if;
    end if;
  end process;
  --
  -- sync write to read
  --
  p_sync_w_to_r : process(i_clk_r, rst_r)
  begin
    if (rst_r = '1') then
      rt1_w_addr_gry <= (others => '0');
      rt2_w_addr_gry <= (others => '0');
    elsif rising_edge(i_clk_r) then
      rt1_w_addr_gry <=     w_addr_gry;
      rt2_w_addr_gry <= rt1_w_addr_gry;
    end if;
  end process;
  --
  -- sync read to write
  --
  p_sync_r_to_w : process(i_clk_w, rst_w)
  begin
    if (rst_w = '1') then
      wt1_r_addr_gry <= (others => '0');
      wt2_r_addr_gry <= (others => '0');
    elsif rising_edge(i_clk_w) then
      wt1_r_addr_gry <=     r_addr_gry;
      wt2_r_addr_gry <= wt1_r_addr_gry;
    end if;
  end process;

  o_w_full  <= w_full;

end;