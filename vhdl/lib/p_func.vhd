-- $Id: p_func.vhd,v 1.2 2009/04/15 12:42:04 jrothwei Exp jrothwei $
-- Copyright 2009 Joseph Rothweiler
-- Branch of miscpack.vhd,v 2.0 2007/05/30 17:46:33

library IEEE;
use IEEE.STD_LOGIC_1164.all;

-------------------------------------------------------------------------------
-- Package Definition

package p_func is
  function hex_to_7seg(
    signal hval: in STD_LOGIC_VECTOR(3 downto 0)
  ) return STD_LOGIC_VECTOR;
end p_func;


-------------------------------------------------------------------------------
-- Package Body

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Map a 4-bit nybble to 7 segment values.
--     0
--     -
--  5 | | 1
--     -6
--  4 | | 2
--     -
--     3
-- Decimal point is 7 (not included here).
-- Bit values assume '1' is ON.
--
package body p_func is
  function hex_to_7seg (
      signal hval: in STD_LOGIC_VECTOR(3 downto 0)
    ) return STD_LOGIC_VECTOR is
    begin
      case hval is
        when "0000" => return "0111111" ; -- 0
        when "0001" => return "0000110" ; -- 1
        when "0010" => return "1011011" ; -- 2
        when "0011" => return "1001111" ; -- 3
        when "0100" => return "1100110" ; -- 4
        when "0101" => return "1101101" ; -- 5
        when "0110" => return "1111101" ; -- 6
        when "0111" => return "0000111" ; -- 7
        when "1000" => return "1111111" ; -- 8
        when "1001" => return "1101111" ; -- 9
        when "1010" => return "1110111" ; -- A
        when "1011" => return "1111100" ; -- b
        when "1100" => return "0111001" ; -- C
        when "1101" => return "1011110" ; -- d
        when "1110" => return "1111001" ; -- E
        when "1111" => return "1110001" ; -- F
        when OTHERS => return "0000000" ; -- Should not happen.
      end case;
    end hex_to_7seg;
end p_func;
