-- $Id: bytecmd.vhd,v 1.4 2009/06/22 17:15:42 jrothwei Exp $
-- Joseph Rothweiler, Sensicomm LLC. Started 11Jun2009.
-- Copyright 2009 Joseph Rothweiler
-------------------------------------------------------------------------------
-- Accept a single byte, and map to a pulse value.
--
-- For compatibility with the fx2 usb interface, I need to work as a master:
--  : bytecmd generates the req signal.
--  : fx2 usb sees req, puts 1 byte on the bus, raises ack.
--  : bytecmd sees ack, captures data, lowers req.
--  : fx2 usb sees req low, lowers ack.
--  : output strobe goes high (1 of n).
-------------
-- Checking the timing (each char is 1 clock tick):
-- req ______------_________
-- ack ________/-------\____
-- evt          a bc
-- trig 00000000137000000
-- strobe _________-________
-- a: Detect that ack is high, save byte value.
--    Decode of byte_save to flag_* starts and (hopefully) completes
--    during this cycle.
-- b: accum is updated this cycle.
-- c: Timing strobe during this cycle, and set req low again.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use p_func.all;

entity bytecmd is port (
  clk50m   : in   STD_LOGIC;  -- system clock.
  byteval  : in   STD_LOGIC_VECTOR (7 downto 0);  -- 
  req      : out  STD_LOGIC;
  ack      : in   STD_LOGIC;
  strobes  : out  STD_LOGIC_VECTOR (15 downto 0);  -- FIXE: Make size a parameter.
  accum    : out  STD_LOGIC_VECTOR (31 downto 0)   -- FIXE: Make size a parameter.
);
end bytecmd;

architecture Behavioral of bytecmd is
  signal trig:      STD_LOGIC_VECTOR(2 downto 0);
  signal byte_save: STD_LOGIC_VECTOR(7 downto 0);
  signal req_i:     STD_LOGIC;
  signal hexdigit:  STD_LOGIC_VECTOR(3 downto 0);
  signal accum_i :  STD_LOGIC_VECTOR(31 downto 0);
  signal digitflag: STD_LOGIC;
  signal flag_plus: STD_LOGIC;
  signal flag_p:    STD_LOGIC;
  signal flag_q:    STD_LOGIC;
  signal flag_r:    STD_LOGIC;
  signal flag_s:    STD_LOGIC;
  signal flag_t:    STD_LOGIC;
  signal flag_u:    STD_LOGIC;
  signal flag_v:    STD_LOGIC;
  signal flag_w:    STD_LOGIC;
  signal flag_x:    STD_LOGIC;
  signal flag_y:    STD_LOGIC;
  signal flag_z:    STD_LOGIC;
begin
  req   <= req_i;
  accum <= accum_i;
  ------------------------------------------------------------------
  -- This is the slave version.
  -- Manage the req and ack signals.
  -- process(clk50m,byteval,req) begin
  --   if(rising_edge(clk50m)) then
  --     if(req='1' and ack_i='0') then
  --       byte_save <= byteval;
  --       ack_i <='1';
  --       trig <= trig(0) & '1';
  --     elsif(req='0' and ack_i='1') then
  --       ack_i <='0';
  --       trig <= trig(0) & '0';
  --     else
  --       trig <= trig(0) & '0';
  --     end if;
  --   end if;
  -- end process;
  -- This is the master version.
  -- Manage the req and ack signals.
  process(clk50m,byteval,ack) begin
    if(rising_edge(clk50m)) then
      if(req_i='0' and ack='0') then
        req_i <='1';
        --trig <= trig(1 downto 0) & '0';
        trig <= "000";
      elsif(req_i='1' and ack='1') then  -- Event 'a'
        byte_save <= byteval; -- FIXME: this should only happen once. !!!
        if(trig="111") then
          req_i <= '0';
	  trig <= "000";
        else
          trig <= trig(1 downto 0) & '1';
	end if;
      end if;
    end if;
  end process;
  ------------------------------------------------------------------
  -- Decode the saved byte.
  process(byte_save) begin
    ------------------------------------
    -- ASCII digits 0-7 are X"30" - X"37".
    if(byte_save(7 downto 3) = "00110") then
      hexdigit <= '0' & byte_save(2 downto 0);
      digitflag <= '1';
    ------------------------------------
    -- ASCII digits 8-9 are X"38" - X"39".
    elsif(byte_save(7 downto 1) = "0011100") then
      hexdigit <= "100" & byte_save(0);
      digitflag <= '1';
    ------------------------------------
    -- ASCII digits a-f (lower case) are X"61" - X"66".
    elsif(
          (byte_save(7 downto 3) = "01100")   -- 60-67
      and (byte_save(2 downto 0) /=  "000")   -- not 60
      and (byte_save(2 downto 0) /=  "111")   -- not 67
    ) then
      hexdigit <= "1001" + byte_save(3 downto 0) ; -- (byte-0x61+10) => (byte%8)+9.
      digitflag <= '1';
    else
      -- hexdigit <= "0000"; -- Don't care about the value in this case.
      digitflag <= '0';
    end if;
    if(byte_save=X"2b") then flag_plus <= '1'; else flag_plus <= '0'; end if; -- '+'
    if(byte_save=X"70") then flag_p <= '1'; else flag_p <= '0'; end if; -- 'p'
    if(byte_save=X"71") then flag_q <= '1'; else flag_q <= '0'; end if; -- 'q'
    if(byte_save=X"72") then flag_r <= '1'; else flag_r <= '0'; end if; -- 'r'
    if(byte_save=X"73") then flag_s <= '1'; else flag_s <= '0'; end if; -- 's'
    if(byte_save=X"74") then flag_t <= '1'; else flag_t <= '0'; end if; -- 't'
    if(byte_save=X"75") then flag_u <= '1'; else flag_u <= '0'; end if; -- 'u'
    if(byte_save=X"76") then flag_v <= '1'; else flag_v <= '0'; end if; -- 'v'
    if(byte_save=X"77") then flag_w <= '1'; else flag_w <= '0'; end if; -- 'w'
    if(byte_save=X"78") then flag_x <= '1'; else flag_x <= '0'; end if; -- 'x'
    if(byte_save=X"79") then flag_y <= '1'; else flag_y <= '0'; end if; -- 'y'
    if(byte_save=X"7a") then flag_z <= '1'; else flag_z <= '0'; end if; -- 'z'
  end process;
  ------------------------------------------------------------------
  -- Process the value if it's a digit.
  process(clk50m,trig,digitflag,hexdigit) begin
    if(rising_edge(clk50m)) then
      if( (digitflag='1') and (trig = "011") ) then
        accum_i <= accum_i(27 downto 0) & hexdigit;
      elsif( (flag_plus='1') and (trig = "011") ) then
        accum_i <= (OTHERS => '0');
      end if;
    end if;
  end process;
  process(clk50m,digitflag,flag_plus,flag_p,flag_q,flag_r,flag_s,flag_t,flag_u,flag_v,trig) begin
    if(rising_edge(clk50m)) then
      if(trig = "111") then
        strobes(15 downto 0) <=
	   '0' &    '0' &    '0'    & flag_z    &
	flag_y & flag_x & flag_w    & flag_v    &
	flag_u & flag_t & flag_s    & flag_r    &
	flag_q & flag_p & flag_plus & digitflag ;
      else
        strobes(15 downto 0) <= (others => '0');
      end if;
      -- Leftover from debugging:
      -- if(trig="000") then strobes(15) <= '1'; else strobes(15) <= '0'; end if;
      -- if(trig="001") then strobes(14) <= '1'; else strobes(14) <= '0'; end if;
      -- if(trig="011") then strobes(13) <= '1'; else strobes(13) <= '0'; end if;
      -- if(trig="111") then strobes(12) <= '1'; else strobes(12) <= '0'; end if;
    end if;
  end process;
end Behavioral;
