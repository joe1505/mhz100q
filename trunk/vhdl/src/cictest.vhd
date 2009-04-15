-- $Id: cictest.vhd,v 1.8 2009/04/15 12:41:17 jrothwei Exp jrothwei $
-- Copyright 2009 Joseph Rothweiler
-------------------------------------------------------------------------------
-- Test version. Start with first order.
-- Rev 1.1 works. Signal range is about +-40.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity cictest is
  port (
  clk      : in  STD_LOGIC; -- System clock at the input sampling rate.
  down     : out STD_LOGIC; -- High for 1 clk cycle when a new outsig is generated.
  insig    : in  STD_LOGIC_VECTOR(7 downto 0);
  outsig   : out STD_LOGIC_VECTOR(12 downto 0)
);
end cictest;

architecture Behavioral of cictest is
  signal in_sex : STD_LOGIC_VECTOR(31 downto 0);
  signal s1_in  : STD_LOGIC_VECTOR(31 downto 0);
  signal s1_dly : STD_LOGIC_VECTOR(31 downto 0);
  signal s1_out : STD_LOGIC_VECTOR(31 downto 0);
  signal d1_dly1  : STD_LOGIC_VECTOR(31 downto 0);
  signal d1_dly2 : STD_LOGIC_VECTOR(31 downto 0);
  signal d1_out : STD_LOGIC_VECTOR(31 downto 0);
  --
  signal dx_outd: STD_LOGIC_VECTOR(31 downto 0);
  --
  signal s2_in  : STD_LOGIC_VECTOR(31 downto 0);
  signal s2_dly : STD_LOGIC_VECTOR(31 downto 0);
  signal s2_out : STD_LOGIC_VECTOR(31 downto 0);
  signal d2_dly1  : STD_LOGIC_VECTOR(31 downto 0);
  signal d2_dly2 : STD_LOGIC_VECTOR(31 downto 0);
  signal d2_out : STD_LOGIC_VECTOR(31 downto 0);
  --
  signal s3_in  : STD_LOGIC_VECTOR(31 downto 0);
  signal s3_dly : STD_LOGIC_VECTOR(31 downto 0);
  signal s3_out : STD_LOGIC_VECTOR(31 downto 0);
  signal d3_dly1  : STD_LOGIC_VECTOR(31 downto 0);
  signal d3_dly2 : STD_LOGIC_VECTOR(31 downto 0);
  signal d3_out : STD_LOGIC_VECTOR(31 downto 0);
  --
  signal down_i      : STD_LOGIC;
  -- signal samplecount : STD_LOGIC_VECTOR(3 downto 0); -- 4 bits, 16x.
  signal samplecount : STD_LOGIC_VECTOR(1 downto 0); -- 2 bits, 4x.
begin
  down <= down_i;
  process(clk) begin
    if(rising_edge(clk)) then
      ---------------------------
      -- Full-rate adders.
      ---------------------------
      -- Stage 3.
      s3_out <= s3_dly;
      s3_dly <= s3_dly + s3_in;
      s3_in <= s2_out;
      -- Stage 2.
      s2_out <= s2_dly;
      s2_dly <= s2_dly + s2_in;
      s2_in <= s1_out;
      -- Stage 1.
      s1_out <= s1_dly;
      s1_dly <= s1_dly + s1_in;
      s1_in <= in_sex;
      -- Sign-extend the input signal.
      for k in 31 downto 8 loop
        in_sex(k) <= insig(7);
      end loop;
      in_sex(7 downto 0) <= insig;
    end if;
  end process;
  ---------------------------
  -- Make the lower-rate clock pulse.
  -- Width is 1 clk cycle.
  ---------------------------
  process(clk) begin
    if(rising_edge(clk)) then
      if(samplecount=0) then
	down_i <= '1';
      else
	down_i <= '0';
      end if;
      samplecount <= samplecount - 1;
    end if;
  end process;
  ---------------------------
  -- Lower-rate subtractors.
  ---------------------------
  process(clk) begin
    if(rising_edge(clk)) then
      if(down_i='1') then
        d3_out <= d3_dly1 - d3_dly2;
	d3_dly2 <= d3_dly1;
        d3_dly1 <= d2_out;
	--
        d2_out <= d2_dly1 - d2_dly2;
	d2_dly2 <= d2_dly1;
        d2_dly1 <= d1_out;
	--
        d1_out <= d1_dly1 - d1_dly2;
	d1_dly2 <= d1_dly1;
        d1_dly1 <= s3_out;
      end if;
      outsig <= dx_outd(19 downto  7);  -- Scaled. Good for 16x.
      outsig <= dx_outd(14 downto  2);  -- Scaled. 
      dx_outd <= d3_out;
    end if;
  end process;
end Behavioral;
