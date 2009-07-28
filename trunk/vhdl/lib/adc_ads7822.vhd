-- $Id: adc_ads7822.vhd,v 1.2 2009/03/26 20:00:43 jrothwei Exp $
-- Joseph Rothweiler, Sensicomm LLC Started 05Mar2009.
-- Interface to the TI ADS7822 12-bit ADC.
--
-- ADC signals are:
-- adc_sck    - Same frequency as clock.
--              Data changes on falling edge.
-- adc_cs_n   - Low Samples the input and starts conversion.
-- adc_sdo    - Data out. First 2 cycles start conversion, then 12 bits MSB first.
--
-- Control signals:
-- clock    - Data sheet recommends 1.2 MHz. Must be >= 16x sample rate.
-- adc_data - 12-bit unsigned output.
-- adc_trig - Goes high for exactly 1 clock cycle to start conversion.
--
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;      -- Common things.
use IEEE.STD_LOGIC_ARITH.ALL;     -- Makes the "div+1" instruction work.
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity adc_ads7822 is
  Port (
    clock      : in  STD_LOGIC;  -- The reference timing clock.
    adc_cs_n   : out STD_LOGIC;  -- Chip select. High powers down.
    adc_sck    : out STD_LOGIC;  -- Output clock (same as clock).
    adc_sdo    : in  STD_LOGIC;  -- Samples from the A/D.
    adc_data   : out STD_LOGIC_VECTOR(11 downto 0);
    adc_trig   : in  STD_LOGIC  -- Must be exactly 1 clock cycle long.
  );
end adc_ads7822;

architecture rtl of adc_ads7822 is
  signal bitcount : STD_LOGIC_VECTOR(3 downto 0);
  signal datareg  : STD_LOGIC_VECTOR(11 downto 0);
  signal adc_cs_n_i  : STD_LOGIC; -- Internal copy.
begin
  process(clock,adc_cs_n_i) begin
    adc_sck <= clock;
    adc_cs_n <= adc_cs_n_i;
    if(falling_edge(clock)) then
      -- Idle state is bitcount=0
      if(bitcount="0000") then
        if(adc_trig='1') then
	  adc_cs_n_i <= '0';  -- Set CS low.
	  bitcount <= conv_std_logic_vector(15,4);
	end if;
      else
        bitcount <= bitcount - 1;
      end if;
      if(bitcount="0001") then
	adc_cs_n_i <= '1';  -- End of cycle.
	adc_data <= datareg;
      end if;
    end if;
    if(rising_edge(clock)) then
      if(adc_cs_n_i='0') then
        -- if active, shift in the next bit.
        datareg <= datareg(10 downto 0) & adc_sdo;
      end if;
    end if;
  end process;
end rtl;
