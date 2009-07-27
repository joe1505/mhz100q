-- $Id: edgetrig.vhd,v 1.1 2009/07/21 02:23:17 jrothwei Exp $
-- Copyright 2009 Joseph Rothweiler
-------------------------------------------------------------------------------
-- Joseph Rothweiler, Sensicomm LLC. Started 20Jul2009.
-- Convert rising edge to a single clock-wide pulse.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity edgetrig is
  port (
  clk      : in   STD_LOGIC;  -- system clock.
  sig      : in  STD_LOGIC;
  puls     : out STD_LOGIC
  );
end edgetrig;

architecture Behavioral of edgetrig is
  signal grabber     : STD_LOGIC;
  signal local_reset : STD_LOGIC;
begin
  process(sig,local_reset) begin
    if(local_reset='1') then
      grabber <= '0';
    elsif(rising_edge(sig)) then
      grabber <= '1';
    end if;
  end process;
  process(clk,grabber) begin
    if(rising_edge(clk)) then
      local_reset <= grabber;
      puls <= local_reset;
    end if;
  end process;
end Behavioral;
