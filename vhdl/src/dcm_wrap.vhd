-- $Id: dcm_wrap.vhd,v 1.4 2009/04/15 12:41:24 jrothwei Exp jrothwei $
-- Copyright 2009 Joseph Rothweiler
-- 3/24/09: Trying 3/2 clock multiply, so the output clock is really 75MHz.
-------------------------------------------------------------------------------
-- Wrapper for an instace of the Xilinx digital clock multiplier
-- for the spartan 3E/3A.
--
-- DCM_SP: Digital Clock Manager Circuit
--         Spartan-3E/3A
-- Xilinx HDL Language Template, version 10.1.3
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

entity dcm_wrap is port (
  CLK_50M    : in  STD_LOGIC;
  CLK_100M   : out STD_LOGIC;
  CLK_100M_N : out STD_LOGIC
) ;
end dcm_wrap;

architecture Behavioral of dcm_wrap is
   signal CLK180    : STD_LOGIC;
   signal CLK270    : STD_LOGIC;
   signal CLK90     : STD_LOGIC;
   signal CLK2X     : STD_LOGIC;
   signal CLK2X180  : STD_LOGIC;
   signal CLKDV     : STD_LOGIC;
   signal CLKFX     : STD_LOGIC;
   signal CLKFX180  : STD_LOGIC;
   signal LOCKED    : STD_LOGIC;
   signal PSDONE    : STD_LOGIC;
   signal STATUS    : STD_LOGIC_VECTOR(7 downto 0);
   signal CLKFB     : STD_LOGIC;
   signal PSCLK     : STD_LOGIC := '0';
   signal PSEN      : STD_LOGIC := '0';
   signal PSINCDEC  : STD_LOGIC := '0';
   signal RST       : STD_LOGIC := '0';
begin
   DCM_SP_inst : DCM_SP
   generic map (
      CLKDV_DIVIDE => 2.0, --  Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
                           --     7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
      CLKFX_DIVIDE => 1,   --  Can be any interger from 1 to 32
      CLKFX_MULTIPLY => 2, --  Can be any integer from 1 to 32
      CLKIN_DIVIDE_BY_2 => FALSE, --  TRUE/FALSE to enable CLKIN divide by two feature
      CLKIN_PERIOD => 20.0, --  Specify period of input clock (ns??)
      CLKOUT_PHASE_SHIFT => "NONE", --  Specify phase shift of "NONE", "FIXED" or "VARIABLE" 
      CLK_FEEDBACK => "1X",         --  Specify clock feedback of "NONE", "1X" or "2X" 
      DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", -- "SOURCE_SYNCHRONOUS", "SYSTEM_SYNCHRONOUS" or
                                             --     an integer from 0 to 15
      DLL_FREQUENCY_MODE => "LOW",     -- "HIGH" or "LOW" frequency mode for DLL
      DUTY_CYCLE_CORRECTION => TRUE, --  Duty cycle correction, TRUE or FALSE
      PHASE_SHIFT => 0,        --  Amount of fixed phase shift from -255 to 255
      STARTUP_WAIT => FALSE) --  Delay configuration DONE until DCM_SP LOCK, TRUE/FALSE
   port map (
      CLK0   => CLKFB,        -- 0 degree DCM CLK ouptput
      CLK180 => CLK180,       -- 180 degree DCM CLK output
      CLK270 => CLK270,       -- 270 degree DCM CLK output
      CLK2X => CLK2X,         -- 2X DCM CLK output
      CLK2X180 => CLK2X180,   -- 2X, 180 degree DCM CLK out
      CLK90 => CLK90,         -- 90 degree DCM CLK output
      CLKDV => CLKDV,         -- Divided DCM CLK out (CLKDV_DIVIDE)
      CLKFX => CLK_100M,      -- DCM CLK synthesis out (M/D)
      CLKFX180 => CLK_100M_N, -- 180 degree CLK synthesis out
      LOCKED => LOCKED,       -- DCM LOCK status output
      PSDONE => PSDONE,       -- Dynamic phase adjust done output
      STATUS => STATUS,       -- 8-bit DCM status bits output
      CLKFB => CLKFB,         -- DCM clock feedback
      CLKIN => CLK_50M,       -- Clock input (from IBUFG, BUFG or DCM)
      PSCLK => PSCLK,         -- Dynamic phase adjust clock input
      PSEN => PSEN,           -- Dynamic phase adjust enable input
      PSINCDEC => PSINCDEC,   -- Dynamic phase adjust increment/decrement
      RST => RST              -- DCM asynchronous reset input
   );
end Behavioral;
