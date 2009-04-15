-- $Id: seg7x4.vhd,v 1.3 2009/04/15 12:43:13 jrothwei Exp jrothwei $
-- Copyright 2009 Joseph Rothweiler
-------------------------------------------------------------------------------
-- Branch of seg7.vhd,v 2.0 2007/05/30 17:46:46
-- Drive the 4-digit 7-segment displays on the Digilent Nexys.
-- Note that segment drives and digit selects are active-high.
-- The Nexys 1 (and maybe Nexys 2) is inverted.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use p_func.all;

entity seg7x4 is port (
  clk50m   : in   STD_LOGIC;  -- system clock.
  segments : out  STD_LOGIC_VECTOR (7 downto 0);  -- Active high.
  digits   : out  STD_LOGIC_VECTOR (3 downto 0);  -- Active high.
  word     : in   STD_LOGIC_VECTOR (15 downto 0); -- To be displayed.
  points   : in   STD_LOGIC_VECTOR (3 downto 0);  -- Decimal points.
  blank    : in   STD_LOGIC_VECTOR (3 downto 0)   -- Blank the digit.
);
end seg7x4;

architecture Behavioral of seg7x4 is
  signal counter: STD_LOGIC_VECTOR(18 downto 0);
  signal nybbl:  STD_LOGIC_VECTOR(3 downto 0);
begin
  process(clk50m,word,counter,blank,points)
    variable digcnt: STD_LOGIC_VECTOR(1 downto 0);
    variable digsel: STD_LOGIC_VECTOR(3 downto 0);
    variable blank1: STD_LOGIC;
    variable point1: STD_LOGIC;
  begin
    if(rising_edge(clk50m)) then
      counter <= counter + 1;
    end if;
    digcnt := counter(18 downto 17);
    if   (digcnt="00") then
      nybbl  <= word( 3 downto  0);
      digits <= "0001";
      blank1 := blank(0);
      point1 := points(0);
    elsif(digcnt="01") then
      nybbl  <= word( 7 downto  4);
      digits <= "0010";
      blank1 := blank(1);
      point1 := points(1);
    elsif(digcnt="10") then
      nybbl  <= word(11 downto  8);
      digits <= "0100";
      blank1 := blank(2);
      point1 := points(2);
    else
      nybbl  <= word(15 downto 12);
      digits <= "1000";
      blank1 := blank(3);
      point1 := points(3);
    end if;
    if(blank1='1') then
      segments <= point1 & "0000000";
    else
      segments <= point1 & hex_to_7seg(nybbl);
    end if;
  end process;
end Behavioral;
