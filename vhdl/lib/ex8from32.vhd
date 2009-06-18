-- $Id: ex8from32.vhd,v 1.2 2009/04/20 19:20:48 jrothwei Exp $
-- Copyright 2009 Joseph Rothweiler
-- Joseph Rothweiler, Sensicomm LLC. Started 20Apr2009.
-- http://www.sensicomm.com
-------------------------------------------------------------------------------
-- C equivalent: data_out = 0xff & (data_in << leftpos);
-- Valid leftpos range is 0 to 24, so 5 bits needed to represent leftpos.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;      -- Common things.
use IEEE.STD_LOGIC_ARITH.ALL;     -- Makes the "div+1" instruction work.
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ex8from32 is
  Port (
    leftpos  : in  STD_LOGIC_VECTOR( 4 downto 0); -- LSB position.
    data_in  : in  STD_LOGIC_VECTOR(31 downto 0); -- Input word.
    data_out : out STD_LOGIC_VECTOR( 7 downto 0)  -- Output byte.
  );
end ex8from32;

architecture rtl of ex8from32 is
  signal intermed : STD_LOGIC_VECTOR(22 downto 0);
begin
  process(data_in,leftpos) begin
    if(leftpos(4)='1') then
      for k in 22 downto 16 loop
        intermed(k) <= data_in(31);
      end loop;
      intermed(15 downto 0) <= data_in(31 downto 16);
    else
      intermed <= data_in(22 downto  0);
    end if;
    case leftpos(3 downto 0) is
    when "0000" =>  data_out <= intermed( 7 downto  0);
    when "0001" =>  data_out <= intermed( 8 downto  1);
    when "0010" =>  data_out <= intermed( 9 downto  2);
    when "0011" =>  data_out <= intermed(10 downto  3);
    when "0100" =>  data_out <= intermed(11 downto  4);
    when "0101" =>  data_out <= intermed(12 downto  5);
    when "0110" =>  data_out <= intermed(13 downto  6);
    when "0111" =>  data_out <= intermed(14 downto  7);
    when "1000" =>  data_out <= intermed(15 downto  8);
    when "1001" =>  data_out <= intermed(16 downto  9);
    when "1010" =>  data_out <= intermed(17 downto 10);
    when "1011" =>  data_out <= intermed(18 downto 11);
    when "1100" =>  data_out <= intermed(19 downto 12);
    when "1101" =>  data_out <= intermed(20 downto 13);
    when "1110" =>  data_out <= intermed(21 downto 14);
    when "1111" =>  data_out <= intermed(22 downto 15);
    when others =>  data_out <= intermed( 7 downto  0); -- Should never happen.
    end case;
  end process;
end rtl;
