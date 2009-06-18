-- $Id: cic3_down.vhd,v 1.4 2009/04/20 15:59:57 jrothwei Exp $
-- Copyright 2009 Joseph Rothweiler
-------------------------------------------------------------------------------
-- Joseph Rothweiler, Sensicomm LLC. Started 31Mar2009.
-- Implementation of a 3-stage Cascaded Integrator Comb (CIC) decimation filter.
-- For a CIC filter, DC gain is G = (RM)**N , where
--   R is decimation factor,
--   M is differential delay (1 here),
--   N is the number of stages (3 here).
-- So the bit growth is log2(G) = 3*log2(R).
-- Examples:
--    R       G Growth
--    2       8      3
--    4      64      6
--   16    4096     12
--  256 1677216     24
-- 
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity cic3_down is
  generic (
    downwidth  : integer ; -- Maximum number of bits in the decimation factor.
    inwidth    : integer ; -- Length of 2's complement input, including sign bit.
    o3width    : integer   -- Length of output, typically inwidth+3*log2(downfactor).
  ) ;
  port (
  clk      : in  STD_LOGIC; -- System clock at the input sampling rate.
  down     : out STD_LOGIC; -- High for 1 clk cycle when a new outsig is generated.
  decimax  : in  STD_LOGIC_VECTOR(downwidth-1 downto 0); -- decimation_factor-1;
  insig    : in  STD_LOGIC_VECTOR(inwidth-1 downto 0);
  outsig   : out STD_LOGIC_VECTOR(o3width-1 downto 0)
);
end cic3_down;

architecture Behavioral of cic3_down is
  signal in_sex   : STD_LOGIC_VECTOR(o3width-1 downto 0);
  signal s1_in    : STD_LOGIC_VECTOR(o3width-1 downto 0);
  signal s1_dly   : STD_LOGIC_VECTOR(o3width-1 downto 0);
  signal s1_out   : STD_LOGIC_VECTOR(o3width-1 downto 0);
  signal d1_dly1  : STD_LOGIC_VECTOR(o3width-1 downto 0);
  signal d1_dly2  : STD_LOGIC_VECTOR(o3width-1 downto 0);
  signal d1_out   : STD_LOGIC_VECTOR(o3width-1 downto 0);
  --
  signal dx_outd  : STD_LOGIC_VECTOR(o3width-1 downto 0);
  --
  signal s2_in    : STD_LOGIC_VECTOR(o3width-1 downto 0);
  signal s2_dly   : STD_LOGIC_VECTOR(o3width-1 downto 0);
  signal s2_out   : STD_LOGIC_VECTOR(o3width-1 downto 0);
  signal d2_dly1  : STD_LOGIC_VECTOR(o3width-1 downto 0);
  signal d2_dly2  : STD_LOGIC_VECTOR(o3width-1 downto 0);
  signal d2_out   : STD_LOGIC_VECTOR(o3width-1 downto 0);
  --
  signal s3_in    : STD_LOGIC_VECTOR(o3width-1 downto 0);
  signal s3_dly   : STD_LOGIC_VECTOR(o3width-1 downto 0);
  signal s3_out   : STD_LOGIC_VECTOR(o3width-1 downto 0);
  signal d3_dly1  : STD_LOGIC_VECTOR(o3width-1 downto 0);
  signal d3_dly2  : STD_LOGIC_VECTOR(o3width-1 downto 0);
  signal d3_out   : STD_LOGIC_VECTOR(o3width-1 downto 0);
  --
  signal down_i      : STD_LOGIC;
  signal samplecount : STD_LOGIC_VECTOR(downwidth-1 downto 0);
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
      for k in o3width-1 downto inwidth loop
        in_sex(k) <= insig(inwidth-1);
      end loop;
      in_sex( inwidth-1 downto 0) <= insig;
    end if;
  end process;
  ---------------------------
  -- Make the lower-rate clock pulse.
  -- Width is 1 clk cycle.
  ---------------------------
  process(clk) begin
    if(rising_edge(clk)) then
      if(samplecount=0) then
        -- samplecount <= conv_std_logic_vector((downfactor-1), samplecount'length) ;
        samplecount <= decimax;
	down_i <= '1';
      else
        samplecount <= samplecount - 1;
	down_i <= '0';
      end if;
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
      outsig <= dx_outd;  -- Scaled. 
      dx_outd <= d3_out;  -- Delay for timing. FIXME: is this necessary?
    end if;
  end process;
end Behavioral;
