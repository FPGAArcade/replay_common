--
-- WWW.FPGAArcade.COM
--
-- REPLAY Retro Gaming Platform
-- No Emulation No Compromise
--
-- All rights reserved
-- Mike Johnson 2015
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

Package Replay_Pack is

  subtype bit1      is std_logic;
  subtype word      is std_logic_vector;

  type array64 is array (natural range <>) of word (63 downto 0);
  type array32 is array (natural range <>) of word (31 downto 0);
  type array16 is array (natural range <>) of word (15 downto 0);
  type array10 is array (natural range <>) of word ( 9 downto 0);
  type array8  is array (natural range <>) of word ( 7 downto 0);
  type array7  is array (natural range <>) of word ( 6 downto 0);
  type array4  is array (natural range <>) of word ( 3 downto 0);
  type array2  is array (natural range <>) of word ( 1 downto 0);
  type array1  is array (natural range <>) of word ( 0 downto 0);

  function to_word (i : integer; size: integer := 32) return word;
  function red_or(w : word) return bit1;
  function red_and(w : word) return bit1;
  function sel_and(w : word; sel : bit1) return word;
  function bool_to_int(i : boolean) return integer;

end;

package body Replay_Pack is

  function to_word (i : integer; size: integer := 32) return word is
    variable result : word(size-1 downto 0);
  begin
    result := word(to_unsigned(i, size));
    return result;
  end to_word;

  function red_or(w : word) return bit1 is
  begin
    if (w = (w'range => '0')) then
      return '0';
    else
      return '1';
    end if;
  end function;

  function red_and(w : word) return bit1 is
  begin
    if (w = (w'range => '1')) then
      return '1';
    else
      return '0';
    end if;
  end function;

  function sel_and(w : word; sel : bit1) return word is
  begin
    return w and (w'range => sel);
  end function;

  function bool_to_int(i : boolean) return integer is
  begin
    if i then
      return 1;
    else
      return 0;
    end if;
  end function;
end;