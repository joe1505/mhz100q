-- $Id: dac_mcp492x.vhd,v 1.3 2009/04/15 12:41:54 jrothwei Exp $
-- Copyright 2009 Joseph Rothweiler
-- Joseph Rothweiler, Sensicomm LLC Started 23Feb2009.
-- Interface to the MCP4921 12-bit DAC.
--
-- DAC signals are:
-- dac_sck    - Same frequency as clock.
--              Latched on rising edge, but setup and hold times
--              are nonzero, so dac_sdi really needs to change on
--              the negative edge.
-- dac_cs_n   - goes low for 16 clock cycles
-- dac_sdi    - 4 control flags, then data msb first.
-- dac_ldac_n - Xfer data word to DAC output (async with dac_sck).
--
-- Control signals:
-- clock    - 20 MHz max.
-- dac_data - 12-bit unsigned.
-- dac_trig - Goes high for exactly 1 clock cycle.
--
-- Operation
-- When dac_trig is high, we generate the ldac signal. Simultaneously,
-- we latch the dac_data signal, to be transferred to the chip.
-- Next, we drop CS and clock out 16 control and data bytes.
-- Then, we raise CS.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;      -- Common things.
use IEEE.STD_LOGIC_ARITH.ALL;     -- Makes the "div+1" instruction work.
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity dac_mcp492x is
  Port (
    clock      : in  STD_LOGIC;  -- The reference timing clock.
    dac_cs_n   : out STD_LOGIC;
    dac_sck    : out STD_LOGIC;
    dac_sdi    : out STD_LOGIC;
    dac_ldac_n : out STD_LOGIC;
    dac_data   : in  STD_LOGIC_VECTOR(11 downto 0);
    dac_trig   : in  STD_LOGIC  -- Must be exactly 1 clock cycle long.
  );
end dac_mcp492x;

architecture rtl of dac_mcp492x is
  signal outreg   : STD_LOGIC_VECTOR(15 downto 0); -- Data to be shifted out.
  signal bitcount : STD_LOGIC_VECTOR(4 downto 0);
  signal datareg  : STD_LOGIC_VECTOR(11 downto 0);
begin
  process(clock) begin
    dac_sck <= clock;  -- Consider gating to conserve power.
    if(falling_edge(clock)) then
      -- If bitcount is 0 or 1, we need to set ldac active.
      -- Min width is 100ns, so we need 2 clock cycles worst case.
      if(bitcount(4 downto 1)="0000") then
        dac_ldac_n <= '0';
      else
        dac_ldac_n <= '1';
      end if;
      -- Need T_idle 40ns min, so do nothing during bitcount 2
      -- and drop CS on bitcount 3.
      -- Raise it on bitcount 18. (FIXME: starting with 20).
      if(bitcount="00011") then
        dac_cs_n <= '0' ; -- Set CS active.
      elsif (bitcount="10100") then
        dac_cs_n <= '1' ; -- Set CS inactive.
      end if;
      if(dac_trig='1') then
        bitcount <= "00000";
	datareg <= dac_data;
      elsif(bitcount/="11111") then
        bitcount <= bitcount + 1;
      end if;
      if(bitcount="00010") then
	outreg <=
	    '0'   -- DAC select. Always 0 for 1-channel chips.
	  & '0' -- Vref is unbuffered.
	  & '1' -- Output gain is 1x.
	  & '1' -- Active (not shutdown).
	  & datareg ;
      else
	outreg <= outreg(14 downto 0) & '0';
      end if;
      dac_sdi <= outreg(15);
    end if;
  end process;
end rtl;
