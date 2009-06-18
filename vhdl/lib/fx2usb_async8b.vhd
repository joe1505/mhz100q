-- $Id: fx2usb_async8b.vhd,v 1.6 2009/06/10 16:51:18 jrothwei Exp $
-- Copyright 2009 Joseph Rothweiler
-- Joseph Rothweiler, Sensicomm LLC. Branch 12Mar2009.
-- from usb_fifos.vhd 1.5 2009/03/04 02:21:17
-- http://www.sensicomm.com
--
-- Copyright 2009 Joseph Rothweiler
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-------------------------------------------------------------------------------
-- Interface to the 4 FIFO's of the Cypress USB chip.
-- The configuration as set by the associated USB firmware is:
-- FIFO flags are set to Active-High, and indicate the state
-- of the fifo selected by the faddr lines:
-- A : Programmable level (not used here).
-- B : Full.
-- C : Empty.
-- Using Default Alternate-1 settings:
-- faddr EP  Host
--   00   2  OUT
--   01   4  OUT
--   10   6   IN
--   11   8   IN
-- EP2 and EP6 are best used for high-capacity transfers.
-- I plan to use 4 and 8 for control signals. They may or may not exist,
-- depending on the flag settings in the firmware.
-- EP0 and EP1 are not handled through the FIFO's.
-- Asynchronous mode is being used on the control signals. ifclk_div
-- is derived from the 48MHz USB clock, and is slow enough to be well
-- within the async mode timing requirements. Faster transfers would
-- be possible with synchronous mode or less conservative timing.
--
-- Every byte from EP2 is presented on fifo0_hostbyte, and a pulse
-- is generated on fifo0_req. The total byte count is fifo0_bytecount.
-- When fifo2_req is high, fifo2_outbyte is written to fifo2 (EP6).
-- A total byte count is accumulated in fifo2_bytecount.
--
-- Interface to the rest of the system
-- Host-to-device:
-- fifo0_req   ______-----------_______
-- fifo0_ack   ________------------____
--                   a b       c   d
-- a: External sets req line.
-- b: Internal detects request, gets next byte (or word),
--    raises ack to signal data is ready on fifo0_inword lines.
-- c: External detects ack, drops req line.
-- d: Internal detects req low, drops ack.
--
-- Device-to-host is similar:
-- External makes data available at a,
-- Internal has finished with the data at b.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;      -- Common things.
use IEEE.STD_LOGIC_ARITH.ALL;     -- Makes the "div+1" instruction work.
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity fx2usb_async8b is
  Port (
    -- the USB interface. 56-pin package in 8-bit mode.
    fdata_in  : in  STD_LOGIC_VECTOR(7 downto 0); -- USB FIFO data lines.
    fdata_out : out STD_LOGIC_VECTOR(7 downto 0); -- USB FIFO data lines.
    fdata_oe  : out STD_LOGIC;                    -- Enable drivers.
    faddr     : out STD_LOGIC_VECTOR(1 downto 0); -- USB FIFO select lines.
    slrd      : out STD_LOGIC;
    slwr      : out STD_LOGIC;
    sloe      : out STD_LOGIC;
    slcs      : out STD_LOGIC; -- Or FLAGD.
    int0      : out STD_LOGIC;
    pktend    : out STD_LOGIC;
    flaga     : in  STD_LOGIC; -- Not currently used.
    flagb     : in  STD_LOGIC;
    flagc     : in  STD_LOGIC;
    ifclk     : in  STD_LOGIC; --The USB clock. Set to 48MHz by the FX2 firmware.
    fifo0_hostbyte  : out STD_LOGIC_VECTOR(7 downto 0);
    fifo0_req       : in  STD_LOGIC;
    fifo0_ack       : out STD_LOGIC;
    fifo2_req       : in  STD_LOGIC;
    fifo2_ack       : out STD_LOGIC;
    fifo2_outbyte   : in  STD_LOGIC_VECTOR(7 downto 0);
    fifo2_end       : in  STD_LOGIC;  -- Set to request a pktend signal.
    muxed_bytecount : out STD_LOGIC_VECTOR(31 downto 0);
    mux_sel         : in  STD_LOGIC_VECTOR(1 downto 0);
    debugvec        : out STD_LOGIC_VECTOR(7 downto 0)
  );
end fx2usb_async8b;

architecture rtl of fx2usb_async8b is
  -- *_i signals are copies of corresponding Port signals.
  -- out signals are write-only, so I need these copies to remember
  -- what the signal values are.
  signal faddr_i    : STD_LOGIC_VECTOR(1 downto 0);  -- Internal version of faddr.
  signal fdata_oe_i : STD_LOGIC;
  signal slrd_i     : STD_LOGIC;
  signal slwr_i     : STD_LOGIC;
  signal sloe_i     : STD_LOGIC;
  signal pktend_i   : STD_LOGIC;
  signal fifo0_ack_i : STD_LOGIC;
  signal fifo0_bytecount_i : STD_LOGIC_VECTOR(31 downto 0);
  signal fifo2_ack_i : STD_LOGIC;
  signal fifo2_ack_reset : STD_LOGIC;
  signal fifo2_bytecount_i  : STD_LOGIC_VECTOR(31 downto 0);
  signal sequencer : STD_LOGIC_VECTOR(5 downto 0);   -- Counter to sequence the fifo signals.
  signal ifclk_div : STD_LOGIC_VECTOR(7 downto 0);   -- To divide down the USB clock.
begin
  -- These are unused for now.
  int0   <= '0';
  slcs   <= '0';
  pktend <= pktend_i;
  -- Connect internal to external.
  slrd           <= slrd_i;
  slwr           <= slwr_i;
  sloe           <= sloe_i;
  faddr          <= faddr_i;
  fifo0_ack <= fifo0_ack_i;
  process(mux_sel) begin
    if(mux_sel="00") then
      muxed_bytecount  <= fifo0_bytecount_i;
    elsif(mux_sel="10") then
      muxed_bytecount  <= fifo2_bytecount_i;
    else
      muxed_bytecount  <= X"00000000";
    end if;
  end process;
  fifo2_ack <= fifo2_ack_i;
  fdata_oe       <= fdata_oe_i;
  ------------------------------------------
  -- Divide down the ifclk, as a quick fix.
  process(ifclk) begin
    if(rising_edge(ifclk)) then
      ifclk_div <= ifclk_div + 1;
    end if;
  end process;
  ------------------------------------------
  -- Cycle through the fifo's.
  process(ifclk_div(2)) begin
    if(rising_edge(ifclk_div(2))) then
      sequencer <= sequencer + 1;
      ---------------------------------------------------------
      -- Generate the control lines.
      case sequencer(4 downto 0) is
      ----------------------------------
      -- Cases for OUT fifo 0 reads.
      ----------------------------------
      when "00000" =>    -- Select FIFO 0, Get ready for a cycle.
        faddr_i <= "00";
        sloe_i  <= '1';
        slrd_i  <= '0';
        slwr_i  <= '0';
      when "00001" =>    -- Start the FIFO 0 read cycle.
        faddr_i <= "00";
        sloe_i  <= '1';
	-- Do a read if:
	if( (fifo0_ack_i = '0')     -- Last transaction is complete.
	    and (fifo0_req = '1') -- New input has been requested.
	    and (flagc = '0')     -- Input data is available in the fifo.
	  ) then
          slrd_i  <= '1';
	else
          slrd_i  <= '0'; -- Else do nothing.
	end if;
        slwr_i  <= '0';
      when "00010" =>    -- Complete the FIFO 0 read cycle.
        if(slrd_i = '1') then -- Reading.
	  fifo0_hostbyte <= fdata_in;             -- Capture the data.
	  fifo0_bytecount_i <= fifo0_bytecount_i + 1; -- Increment the byte count.
	  fifo0_ack_i <= '1'; -- Signal that data has been captured.
	end if;
        faddr_i <= "00";
        sloe_i  <= '0';
        slrd_i  <= '0'; -- Read cycle done.
        slwr_i  <= '0';
      ----------------------------------
      -- Cases for IN fifo 2 writes.
      -- Skipping a few numbers for now.
      ----------------------------------
      when "00111" =>    -- Set to write to fifo 2.
        faddr_i <= "10";
        sloe_i  <= '0';
        slrd_i  <= '0';
        slwr_i  <= '0';
      when "01000" =>    -- Set to write to fifo 2.
        -- Set up for a write if there is data to send and fifo is not full.
	if( (fifo2_ack_i = '0')     -- Last transaction is complete.
	    and (fifo2_req = '1') -- New output has been requested.
	    and (flagb = '0')     -- Space is available in the fifo.
          ) then
	  fdata_out <= fifo2_outbyte; -- Put the data on the bus,
	  fifo2_bytecount_i <= fifo2_bytecount_i + 1; -- For debugging.
	  fdata_oe_i <= '1';
	elsif( (fifo2_ack_i = '0')     -- Last transaction is complete.
	    and (fifo2_end = '1') -- End-of-packet signal requested.
	    and (flagb = '0')     -- Space is available in the fifo.
          ) then
	  fdata_oe_i <= '0';
	  pktend_i <= '1';
	else
	  fdata_oe_i <= '0';
	end if;
        faddr_i <= "10";
        sloe_i  <= '0';
        slrd_i  <= '0';
        slwr_i  <= '0';   -- Write cycle starts on the next clock.
      when "01001" =>    -- Do the write.
        debugvec <= faddr_i & slrd_i & slwr_i     & fifo2_req & fifo2_ack_i & flagb & flagc;
        faddr_i <= "10";
        sloe_i  <= '0';
        slrd_i  <= '0';
	if (fdata_oe_i = '1') then
          slwr_i  <= '1';  
	  fifo2_ack_i <= '1'; -- Signal that data has been captured.
	else
          slwr_i  <= '0';  
	end if;
      when "01010" =>    -- Write finished.
        pktend_i <= '0';  -- De-assert (whether or not it was asserted).
        faddr_i <= "10";
        sloe_i  <= '0';
        slrd_i  <= '0';
        slwr_i  <= '0';
	fdata_oe_i <= '0';
      when "01011" => -- Stretch the ack length.
	if(fifo2_req = '0') then
		fifo2_ack_reset <= '1';
	else
		fifo2_ack_reset <= '0';
	end if;
      when "01100" =>
	if(fifo2_ack_reset = '1') then
		fifo2_ack_i <= '0';
	end if;
      when others =>
        faddr_i <= "00";
        sloe_i  <= '0';
        slrd_i  <= '0';
        slwr_i  <= '0';
	if(fifo0_req = '0') then
		fifo0_ack_i <= '0';
	end if;
      end case;
    end if;
  end process;
end rtl;
