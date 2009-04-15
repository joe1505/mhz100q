-- $Id: debounce.vhd,v 1.2 2009/04/15 12:41:57 jrothwei Exp jrothwei $
-- Copyright 2009 Joseph Rothweiler
-------------------------------------------------------------------------------
-- Joseph Rothweiler, Sensicomm LLC. Started 13Mar2009.
-- Generic debouncer for pushbutton switches.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity debouncer is
  generic (
    portwidth   : integer ;
    counterbits : integer
  ) ;
  port (
  clk50m   : in   STD_LOGIC;  -- system clock.
  raw      : in  STD_LOGIC_VECTOR(portwidth-1 downto 0);
  clean    : out STD_LOGIC_VECTOR(portwidth-1 downto 0)
);
end debouncer;

architecture Behavioral of debouncer is
  signal counter  : STD_LOGIC_VECTOR(counterbits-1 downto 0);
  signal rawstate : STD_LOGIC_VECTOR(portwidth-1 downto 0);
begin
  process(clk50m) begin
    if(rising_edge(clk50m)) then
      if(counter=0) then
        counter<=(OTHERS=>'1');
	clean <= rawstate;
      elsif (raw=rawstate) then
        counter <= counter-1;
      else
        counter<=(OTHERS=>'1');
	rawstate<=raw;
      end if;
    end if;
  end process;
end Behavioral;
