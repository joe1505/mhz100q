-- $Id: scope_top.vhd,v 1.28 2009/06/19 14:56:46 jrothwei Exp $
-- Copyright 2009 Joseph Rothweiler
-- Joseph Rothweiler, Sensicomm LLC. Started 16Feb2009.
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
-- MHZ100Q oscilloscope driver top-level module.
-- For the Nexys 2 board from Digilent: http://www.digilentinc.com
-- Chip is XC3S500E FGG320 package, Speed Grade 5C/4I.
--
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;      -- Common things.
use IEEE.STD_LOGIC_ARITH.ALL;     -- Makes the "div+1" instruction work.
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity scope_top is
  Port (
    CLK_50M  : in  STD_LOGIC; -- Input: 50 MHz clock.
    SW       : in  STD_LOGIC_VECTOR(7 downto 0) ; -- Input control switch.
    BTN      : in  STD_LOGIC_VECTOR(3 downto 0) ; -- Input control pushbuttons.
    SEG7_SEG : out STD_LOGIC_VECTOR(7 downto 0);
    SEG7_DIG : out STD_LOGIC_VECTOR(3 downto 0);
    -- the USB interface. 56-pin package in 8-bit mode.
    U_FDATA  : inout STD_LOGIC_VECTOR(7 downto 0); -- USB FIFO data lines.
    U_FADDR  : out STD_LOGIC_VECTOR(1 downto 0); -- USB FIFO select lines.
    U_SLRD   : out STD_LOGIC;
    U_SLWR   : out STD_LOGIC;
    U_SLOE   : out STD_LOGIC;
    U_SLCS   : out STD_LOGIC; -- Or FLAGD.
    U_INT0   : out STD_LOGIC;
    U_PKTEND : out STD_LOGIC;
    U_FLAGA  : in  STD_LOGIC;
    U_FLAGB  : in  STD_LOGIC;
    U_FLAGC  : in  STD_LOGIC;
    U_IFCLK  : in  STD_LOGIC;
    -- DAC control signals.
    MCP492X_CS_N   : out STD_LOGIC;
    MCP492X_SCK    : out STD_LOGIC;
    MCP492X_SDI    : out STD_LOGIC;
    MCP492X_LDAC_N : out STD_LOGIC;
    --
    ADS7822_CS_N   : out STD_LOGIC;
    ADS7822_SCK    : out STD_LOGIC;
    ADS7822_SDO    : in  STD_LOGIC;
    --
    AD23_CLK       : out STD_LOGIC;
    AD23_PWRDN     : out STD_LOGIC;
    AD3_DATA       : in  STD_LOGIC_VECTOR(7 downto 0);
    AD2_DATA       : in  STD_LOGIC_VECTOR(7 downto 0);
    AD01_CLK       : out STD_LOGIC;
    AD01_PWRDN     : out STD_LOGIC;
    AD1_DATA       : in  STD_LOGIC_VECTOR(7 downto 0);
    AD0_DATA       : in  STD_LOGIC_VECTOR(7 downto 0);
    --
    VGA_RED        : out STD_LOGIC_VECTOR(2 downto 0);
    VGA_HS         : out STD_LOGIC;
    --
    LED       : out STD_LOGIC_VECTOR(7 downto 0)
  );
end scope_top;

architecture rtl of scope_top is
  attribute CLOCK_SIGNAL : string;
  attribute PERIOD       : string;
  attribute IOB          : string;

  component bytecmd is port (
    clk50m   : in   STD_LOGIC;  -- system clock.
    byteval  : in   STD_LOGIC_VECTOR (7 downto 0);  -- 
    req      : out  STD_LOGIC;
    ack      : in   STD_LOGIC;
    strobes  : out  STD_LOGIC_VECTOR (15 downto 0);  -- FIXE: Make size a parameter.
    accum    : out  STD_LOGIC_VECTOR (31 downto 0)   -- FIXE: Make size a parameter.
  );
  end component;
  component ex8from32 is port (
    leftpos  : in  STD_LOGIC_VECTOR( 4 downto 0); -- LSB position.
    data_in  : in  STD_LOGIC_VECTOR(31 downto 0); -- Input word.
    data_out : out STD_LOGIC_VECTOR( 7 downto 0)  -- Output byte.
  );
  end component;

  component cic3_down is generic (
    downwidth  : integer ; -- Maximum number of bits in the decimation factor.
    inwidth    : integer ; -- Length of 2's complement input, including sign bit.
    o3width    : integer   -- Length of output, typically inwidth+3*log2(downfactor).
  ) ; port (
    clk      : in  STD_LOGIC; -- System clock at the input sampling rate.
    down     : out STD_LOGIC; -- High for 1 clk cycle when a new outsig is generated.
    decimax  : in  STD_LOGIC_VECTOR(downwidth-1 downto 0); -- decimation_factor-1;
    insig    : in  STD_LOGIC_VECTOR(inwidth-1 downto 0);
    outsig   : out STD_LOGIC_VECTOR(o3width-1 downto 0)
  );
  end component;
  component debouncer is generic (
    portwidth   : integer ;
    counterbits : integer
  );
  port (
    clk50m   : in  STD_LOGIC;  -- system clock.
    raw      : in  STD_LOGIC_VECTOR(portwidth-1 downto 0);
    clean    : out STD_LOGIC_VECTOR(portwidth-1 downto 0)
  );
  end component;
  component xilinx_2kx9_3e is port (
    clock1   : in  STD_LOGIC;
    write1   : in  STD_LOGIC;
    addr1    : in  STD_LOGIC_VECTOR (10 downto 0);
    data1in  : in  STD_LOGIC_VECTOR ( 8 downto 0);
    data1out : out STD_LOGIC_VECTOR ( 8 downto 0);
    --
    clock2   : in  STD_LOGIC;
    write2   : in  STD_LOGIC;
    addr2    : in  STD_LOGIC_VECTOR (10 downto 0);
    data2in  : in  STD_LOGIC_VECTOR ( 8 downto 0);
    data2out : out STD_LOGIC_VECTOR ( 8 downto 0)
  );
  end component;
  component dcm_wrap is port (
    CLK_50M    : in  STD_LOGIC;
    CLK_100M   : out STD_LOGIC;
    CLK_100M_N : out STD_LOGIC
  ) ;
  end component;

  component seg7x4 is port (
    clk50m   : in   STD_LOGIC;  -- system clock.
    segments : out  STD_LOGIC_VECTOR (7 downto 0);  -- Active high.
    digits   : out  STD_LOGIC_VECTOR (3 downto 0);  -- Active high.
    word     : in   STD_LOGIC_VECTOR (15 downto 0); -- To be displayed.
    points   : in   STD_LOGIC_VECTOR (3 downto 0);  -- Decimal points.
    blank    : in   STD_LOGIC_VECTOR (3 downto 0)   -- Blank the digit.
  );
  end component;
  component adc_ads7822 is Port (
    clock      : in  STD_LOGIC;  -- The reference timing clock.
    adc_cs_n   : out STD_LOGIC;  -- Chip select. High powers down.
    adc_sck    : out STD_LOGIC;  -- Output clock (same as clock).
    adc_sdo    : in  STD_LOGIC;  -- Samples from the A/D.
    adc_data   : out STD_LOGIC_VECTOR(11 downto 0);
    adc_trig   : in  STD_LOGIC  -- Must be exactly 1 clock cycle long.
  );
  end component;
  component dac_mcp492x is Port (
    clock      : in  STD_LOGIC;  -- The reference timing clock.
    dac_cs_n   : out STD_LOGIC;
    dac_sck    : out STD_LOGIC;
    dac_sdi    : out STD_LOGIC;
    dac_ldac_n : out STD_LOGIC;
    dac_data   : in  STD_LOGIC_VECTOR(11 downto 0);
    dac_trig   : in  STD_LOGIC
  );
  end component;
  component fx2usb_async8b is Port (
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
    fifo2_end       : in  STD_LOGIC;
    fifo2_outbyte   : in  STD_LOGIC_VECTOR(7 downto 0);
    muxed_bytecount : out STD_LOGIC_VECTOR(31 downto 0);
    mux_sel         : in  STD_LOGIC_VECTOR(1 downto 0);
    debugvec        : out STD_LOGIC_VECTOR(7 downto 0)
  );
  end component;

  signal U_FADDR_i   : STD_LOGIC_VECTOR(1 downto 0);
  signal U_SLRD_i    : STD_LOGIC;
  signal U_SLWR_i    : STD_LOGIC;
  signal U_SLOE_i    : STD_LOGIC;
  signal U_SLCS_i    : STD_LOGIC;
  signal U_INT0_i    : STD_LOGIC;
  signal U_PKTEND_i  : STD_LOGIC;
  signal ifcounter   : STD_LOGIC_VECTOR(27 downto 0);
  signal data_enable : STD_LOGIC;  -- U_FDATA tristate line.
  signal slcs_enable : STD_LOGIC := '1';  -- U_SLCS tristate line. Set for now.
  --
  signal fifo0_hostbyte  : STD_LOGIC_VECTOR(7 downto 0);
  signal muxed_bytecount : STD_LOGIC_VECTOR(31 downto 0);
  signal usb_mux_sel     : STD_LOGIC_VECTOR(1 downto 0);
  signal fifo2_outbyte   : STD_LOGIC_VECTOR(7 downto 0);
  signal fifo0_req  : STD_LOGIC;
  signal fifo0_ack  : STD_LOGIC;
  signal fifo2_req  : STD_LOGIC;
  signal fifo2_ack  : STD_LOGIC;
  signal fifo2_end  : STD_LOGIC := '0';
  signal fdata_in  : STD_LOGIC_VECTOR(7 downto 0);
  signal fdata_out : STD_LOGIC_VECTOR(7 downto 0);
  signal fdata_oe  : STD_LOGIC;
  signal debugvec  : STD_LOGIC_VECTOR(7 downto 0);
  --
  signal dacword     : STD_LOGIC_VECTOR(11 downto 0);
  signal dacdiv      : STD_LOGIC_VECTOR(3 downto 0);
  signal dacpulsediv : STD_LOGIC_VECTOR(8 downto 0);
  signal dacpulse    : STD_LOGIC;
  signal dac_inclock : STD_LOGIC;
  --
  signal adc_data    : STD_LOGIC_VECTOR(11 downto 0);
  signal adc_pulse   : STD_LOGIC;
  signal adc_pulsecnt: STD_LOGIC_VECTOR(6 downto 0);
  signal adc_inclock : STD_LOGIC;
  signal adcdiv      : STD_LOGIC_VECTOR(4 downto 0);
  --
  signal seg_segs   : STD_LOGIC_VECTOR(7 downto 0);
  signal seg_digs   : STD_LOGIC_VECTOR(3 downto 0);
  signal seg_word   : STD_LOGIC_VECTOR(15 downto 0);
  signal seg_points : STD_LOGIC_VECTOR(3 downto 0);
  signal seg_blank  : STD_LOGIC_VECTOR(3 downto 0);
  --
  signal clk_100m  : STD_LOGIC;
  attribute CLOCK_SIGNAL of CLK_100M : signal is "yes";
  -- Next line seems to be ignored: Period is automatically inferred by DCM.
  -- attribute PERIOD       of CLK_100M : signal is "10.0 ns";
  signal clk_100mn : STD_LOGIC;
  signal clk_50_div : STD_LOGIC_VECTOR(26 downto 0);
  signal clk_100_div : STD_LOGIC_VECTOR(27 downto 0);
  -- 
  signal ram_write1    : STD_LOGIC;
  signal ram_addr1     : STD_LOGIC_VECTOR(31 downto 0); -- 11 bits + extra for debugging.
  signal ram3_data1in  : STD_LOGIC_VECTOR( 8 downto 0);
  signal ram3_data1out : STD_LOGIC_VECTOR( 8 downto 0);
  signal ram2_data1in  : STD_LOGIC_VECTOR( 8 downto 0);
  signal ram2_data1out : STD_LOGIC_VECTOR( 8 downto 0);
  signal ram1_data1in  : STD_LOGIC_VECTOR( 8 downto 0);
  signal ram1_data1out : STD_LOGIC_VECTOR( 8 downto 0);
  signal ram0_data1in  : STD_LOGIC_VECTOR( 8 downto 0);
  signal ram0_data1out : STD_LOGIC_VECTOR( 8 downto 0);
  --
  signal ram_write2    : STD_LOGIC := '0'; -- Not used.
  signal ram_addr2     : STD_LOGIC_VECTOR(31 downto 0); -- 10->0 + extra for debug.
  signal ram3_data2in  : STD_LOGIC_VECTOR( 8 downto 0);
  signal ram3_data2out : STD_LOGIC_VECTOR( 8 downto 0);
  signal ram2_data2in  : STD_LOGIC_VECTOR( 8 downto 0);
  signal ram2_data2out : STD_LOGIC_VECTOR( 8 downto 0);
  signal ram1_data2in  : STD_LOGIC_VECTOR( 8 downto 0);
  signal ram1_data2out : STD_LOGIC_VECTOR( 8 downto 0);
  signal ram0_data2in  : STD_LOGIC_VECTOR( 8 downto 0);
  signal ram0_data2out : STD_LOGIC_VECTOR( 8 downto 0);
  --
  -- See if init'ing cap_count will fix the "extra byte after power-up" problem. NO.
  signal cap_count      : STD_LOGIC_VECTOR(10 downto 0) := (OTHERS => '1');
  signal cap_count_init : STD_LOGIC_VECTOR(10 downto 0) := (OTHERS => '1');
  --
  signal ad3_input      : STD_LOGIC_VECTOR(7 downto 0); -- Try to force register into IOB.
  signal ad2_input      : STD_LOGIC_VECTOR(7 downto 0); -- Try to force register into IOB.
  signal ad1_input      : STD_LOGIC_VECTOR(7 downto 0); -- Try to force register into IOB.
  signal ad0_input      : STD_LOGIC_VECTOR(7 downto 0); -- Try to force register into IOB.
  attribute IOB of ad3_input : signal is "TRUE";
  attribute IOB of ad2_input : signal is "TRUE";
  attribute IOB of ad1_input : signal is "TRUE";
  attribute IOB of ad0_input : signal is "TRUE";
  --
  signal ad_capturing   : STD_LOGIC;
  signal ad_trigger     : STD_LOGIC;
  --
  signal btn_debounced  : STD_LOGIC_VECTOR(3 downto 0);
  --
  signal usb_trigger_ad : STD_LOGIC;
  signal usb_trigger_ad_req : STD_LOGIC;
  signal usb_trigger_upload : STD_LOGIC;
  signal usb_trigger_upload_req : STD_LOGIC;
  signal usb_upload_count : STD_LOGIC_VECTOR(12 downto 0);
  signal usb_upload_active: STD_LOGIC;
  signal usb_upload_state : STD_LOGIC_VECTOR(2 downto 0);
  --
  signal red_dac_val   : STD_LOGIC_VECTOR(3 downto 0);
  signal red_dac_count : STD_LOGIC_VECTOR(7 downto 0);
  signal red_dac_start : STD_LOGIC_VECTOR(7 downto 0) := "00000010";
  --
  signal valcollect     : STD_LOGIC_VECTOR(31 downto 0);
  --
  signal cmd_byte         : STD_LOGIC_VECTOR(7 downto 0);
  signal cmd_byte_strobe  : STD_LOGIC;
  signal cmd_byte_counter : STD_LOGIC_VECTOR(31 downto 0);
  --
  signal fifo2_req_bug      : STD_LOGIC;
  signal fifo2_req_bugcount : STD_LOGIC_VECTOR(15 downto 0);
  signal fifo2_ack_bug      : STD_LOGIC;
  signal fifo2_ack_bugcount : STD_LOGIC_VECTOR(15 downto 0);
  --
  signal cic_shift  : STD_LOGIC_VECTOR(4 downto 0);
  signal cic_enable : STD_LOGIC:= '0';
  signal cic_decimax: STD_LOGIC_VECTOR(7 downto 0) := X"03"; -- Decimation count - 1;
  --
  signal cic3_down3  : STD_LOGIC;
  signal cic3_in3    : STD_LOGIC_VECTOR( 7 downto 0);
  signal cic3_out3   : STD_LOGIC_VECTOR(31 downto 0);

  signal cic2_down3  : STD_LOGIC;
  signal cic2_in3    : STD_LOGIC_VECTOR( 7 downto 0);
  signal cic2_out3   : STD_LOGIC_VECTOR(31 downto 0);
 
  signal cic1_down3  : STD_LOGIC;
  signal cic1_in3    : STD_LOGIC_VECTOR( 7 downto 0);
  signal cic1_out3   : STD_LOGIC_VECTOR(31 downto 0);
   
  signal cic0_down3  : STD_LOGIC;
  signal cic0_in3    : STD_LOGIC_VECTOR( 7 downto 0);
  signal cic0_out3   : STD_LOGIC_VECTOR(31 downto 0);
  --
  signal ex8_c3_in     : STD_LOGIC_VECTOR(31 downto 0);
  signal ex8_c3_out    : STD_LOGIC_VECTOR( 7 downto 0);
  signal ex8_c2_in     : STD_LOGIC_VECTOR(31 downto 0);
  signal ex8_c2_out    : STD_LOGIC_VECTOR( 7 downto 0);
  signal ex8_c1_in     : STD_LOGIC_VECTOR(31 downto 0);
  signal ex8_c1_out    : STD_LOGIC_VECTOR( 7 downto 0);
  signal ex8_c0_in     : STD_LOGIC_VECTOR(31 downto 0);
  signal ex8_c0_out    : STD_LOGIC_VECTOR( 7 downto 0);
  --
  signal samplecapture : STD_LOGIC;
  --
  signal bytecmd_strobes : STD_LOGIC_VECTOR(15 downto 0);
  signal bytecmd_accum   : STD_LOGIC_VECTOR(31 downto 0);
  --
  -- Debugging only.
  signal ack_long : STD_LOGIC_VECTOR(7 downto 0);
  signal req_long : STD_LOGIC_VECTOR(7 downto 0);
begin
  ram3: xilinx_2kx9_3e port map (
    clock1   => clk_100m,
    write1   => ram_write1,
    addr1    => ram_addr1(10 downto 0),
    data1in  => ram3_data1in,
    data1out => ram3_data1out,
    --
    clock2   => clk_50m,  -- FIXME: maybe time against the USB clock?
    write2   => ram_write2,
    addr2    => ram_addr2(10 downto 0),
    data2in  => ram3_data2in,
    data2out => ram3_data2out
  );
  ram2: xilinx_2kx9_3e port map (
    clock1   => clk_100m,
    write1   => ram_write1,
    addr1    => ram_addr1(10 downto 0),
    data1in  => ram2_data1in,
    data1out => ram2_data1out,
    --
    clock2   => clk_50m,  -- FIXME: maybe time against the USB clock?
    write2   => ram_write2,
    addr2    => ram_addr2(10 downto 0),
    data2in  => ram2_data2in,
    data2out => ram2_data2out
  );
  ram1: xilinx_2kx9_3e port map (
    clock1   => clk_100m,
    write1   => ram_write1,
    addr1    => ram_addr1(10 downto 0),
    data1in  => ram1_data1in,
    data1out => ram1_data1out,
    --
    clock2   => clk_50m,  -- FIXME: maybe time against the USB clock?
    write2   => ram_write2,
    addr2    => ram_addr2(10 downto 0),
    data2in  => ram1_data2in,
    data2out => ram1_data2out
  );
   ram0: xilinx_2kx9_3e port map (
    clock1   => clk_100m,
    write1   => ram_write1,
    addr1    => ram_addr1(10 downto 0),
    data1in  => ram0_data1in,
    data1out => ram0_data1out,
    --
    clock2   => clk_50m,  -- FIXME: maybe time against the USB clock?
    write2   => ram_write2,
    addr2    => ram_addr2(10 downto 0),
    data2in  => ram0_data2in,
    data2out => ram0_data2out
  );
  dcm0: dcm_wrap port map (
    CLK_50M    => CLK_50M,
    CLK_100M   => clk_100m, -- _unused,
    CLK_100M_N => clk_100mn
  ) ;
  -- clk_100m <= CLK_50M;  -- FIXME: DCM seems to have too much jitter.
  seg7_0 : seg7x4 port map (
    clk50m   => CLK_50M,
    segments => seg_segs,
    digits   => seg_digs,
    word     => seg_word,
    points   => seg_points,
    blank    => seg_blank
  );
  adc0: adc_ads7822 port map (
    clock      => adc_inclock,
    adc_cs_n   => ADS7822_CS_N,
    adc_sck    => ADS7822_SCK,
    adc_sdo    => ADS7822_SDO,
    adc_data   => adc_data,
    adc_trig   => adc_pulse
  );
  dac0: dac_mcp492x port map (
    clock      => dac_inclock,
    dac_cs_n   => MCP492X_CS_N,
    dac_sck    => MCP492X_SCK,
    dac_sdi    => MCP492X_SDI,
    dac_ldac_n => MCP492X_LDAC_N,
    dac_data   => dacword,
    dac_trig   => dacpulse
  );
  fx2usb0 : fx2usb_async8b port map (
    fdata_in  => fdata_in,
    fdata_out => fdata_out,
    fdata_oe  => fdata_oe,
    faddr     => U_FADDR_i,
    slrd      => U_SLRD_i,
    slwr      => U_SLWR_i,
    sloe      => U_SLOE_i,
    slcs      => U_SLCS_i,
    int0      => U_INT0_i,
    pktend    => U_PKTEND_i,
    flaga     => U_FLAGA,
    flagb     => U_FLAGB,
    flagc     => U_FLAGC,
    ifclk     => U_IFCLK,
    fifo0_hostbyte  => fifo0_hostbyte,
    fifo0_req  => fifo0_req,
    fifo0_ack  => fifo0_ack,
    fifo2_req  => fifo2_req,
    fifo2_ack  => fifo2_ack,
    fifo2_end  => fifo2_end,
    fifo2_outbyte   => fifo2_outbyte,
    muxed_bytecount => muxed_bytecount,
    mux_sel         => usb_mux_sel,
    debugvec       => debugvec
  );
  bytecmd0: bytecmd port map (
    clk50m   => CLK_50M,
    byteval  => fifo0_hostbyte,
    req      => fifo0_req,
    ack      => fifo0_ack,
    strobes  => bytecmd_strobes,
    accum    => bytecmd_accum
  );
  debouncer0 : debouncer generic map (
    portwidth   => 4,
    counterbits => 17  -- Switches need to be stable for 2^17 clocks.
  ) port map (
    clk50m   => CLK_50M,
    raw      => BTN,
    clean    => btn_debounced
  );
  ex8_c3 : ex8from32 port map (
    leftpos  => cic_shift,
    data_in  => ex8_c3_in,
    data_out => ex8_c3_out
  );
  ex8_c2 : ex8from32 port map (
    leftpos  => cic_shift,
    data_in  => ex8_c2_in,
    data_out => ex8_c2_out
  );
  ex8_c1 : ex8from32 port map (
    leftpos  => cic_shift,
    data_in  => ex8_c1_in,
    data_out => ex8_c1_out
  );
  ex8_c0 : ex8from32 port map (
    leftpos  => cic_shift,
    data_in  => ex8_c0_in,
    data_out => ex8_c0_out
  );
  cic3 : cic3_down generic map (
    downwidth  =>  8,
    inwidth    =>  8,
    o3width    => 32
  ) port map (
    clk      => clk_100m,
    down     => cic3_down3,
    decimax  => cic_decimax,
    insig    => cic3_in3,
    outsig   => cic3_out3
  );
    cic2 : cic3_down generic map (
    downwidth  =>  8,
    inwidth    =>  8,
    o3width    => 32
  ) port map (
    clk      => clk_100m,
    down     => cic2_down3,
    decimax  => cic_decimax,
    insig    => cic2_in3,
    outsig   => cic2_out3
  );
    cic1 : cic3_down generic map (
    downwidth  =>  8,
    inwidth    =>  8,
    o3width    => 32
  ) port map (
    clk      => clk_100m,
    down     => cic1_down3,
    decimax  => cic_decimax,
    insig    => cic1_in3,
    outsig   => cic1_out3
  );
    cic0 : cic3_down generic map (
    downwidth  =>  8,
    inwidth    =>  8,
    o3width    => 32
  ) port map (
    clk      => clk_100m,
    down     => cic0_down3,
    decimax  => cic_decimax,
    insig    => cic0_in3,
    outsig   => cic0_out3
  );
  process(CLK_50M,fdata_oe,fdata_out,SW) begin
    -- Tristate control for the data lines.
    if(fdata_oe='1') then
      U_FDATA <= fdata_out;
    else
      U_FDATA <= (others=>'Z');  -- Tristated.
    end if;
    fdata_in <= U_FDATA;
    ---------------------------------------------------------------
--  The LED muxing doesn't need to be registered.
    case SW(7 downto 5) is
      when "000" => LED <=  "00" & ad_capturing & usb_trigger_ad_req &
                            "00" & usb_upload_active & usb_trigger_upload_req;
      when "001" => LED <= '0' & usb_trigger_upload_req & fifo2_req & fifo2_ack &
                           usb_upload_active & usb_upload_state(2 downto 0);
      when "111" => LED <= "11111111";
      when OTHERS => LED <= "00000000";
    end case;
  end process;
  ----------------------------------------------------------------
  -- Simple interpreter to process characters received from USB fifo0.
  -- 20090618 - bytecmd now does the processing; here we just
  -- handle the resulting strobes.
  -- strobes:
  -- 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
  --  0  0  0  z  y  x  w  v  u  t  s  r  q  p  + hx
  process(CLK_50M,bytecmd_accum,bytecmd_strobes) begin
    if (rising_edge(CLK_50M)) then
      if(bytecmd_strobes(2)='1') then cic_shift          <= bytecmd_accum( 4 downto 0); end if; --  2:p
      if(bytecmd_strobes(3)='1') then cic_decimax        <= bytecmd_accum( 7 downto 0); end if; --  3:q
      if(bytecmd_strobes(4)='1') then red_dac_start      <= bytecmd_accum( 7 downto 0); end if; --  4:r
      if(bytecmd_strobes(5)='1') then cic_enable         <= bytecmd_accum(          0); end if; --  5:s
      usb_trigger_ad     <= bytecmd_strobes(6);                                                 --  6:t
      usb_trigger_upload <= bytecmd_strobes(7);                                                 --  7:u
      if(bytecmd_strobes(8)='1') then dacword            <= bytecmd_accum(11 downto 0); end if; --  8:v
      if(bytecmd_strobes(9)='1') then fifo2_end          <= bytecmd_accum(          0); end if; --  9:w
    end if;
  end process;
  process(CLK_50M) begin
    if (rising_edge(CLK_50M)) then
      if(ad_capturing='1') then
        usb_trigger_ad_req <= '0';
      elsif (usb_trigger_ad='1') then
        usb_trigger_ad_req <= '1';
      end if;
      if(usb_upload_active='1') then
        usb_trigger_upload_req <= '0';
      elsif (usb_trigger_upload='1') then
        usb_trigger_upload_req <= '1';
      end if;
    end if;
  end process;
  ----------------------------------------------------------------
  -- Counter on the usb fifo clock.
  process(U_IFCLK) begin
    if (rising_edge(U_IFCLK)) then
      ifcounter <= ifcounter+1;
    end if;
  end process;
  ----------------------------------------------------------------
  -- Output pins.
  U_FADDR  <= U_FADDR_i;
  U_SLRD   <= U_SLRD_i;
  U_SLWR   <= U_SLWR_i;
  U_SLOE   <= U_SLOE_i;
  U_PKTEND <= U_PKTEND_i;
  U_INT0   <= U_INT0_i;
  process(slcs_enable,U_SLCS_i) begin
    if (slcs_enable='1') then
      U_SLCS   <= U_SLCS_i;
    else
      U_SLCS   <= 'Z';
    end if;
  end process;
  ----------------------------------------------------------------
  -- The DAC. For first test, just send switch signals.
  process(CLK_50M,SW,BTN,dac_inclock) begin
    -----------------------------------------------------
    -- Divide the clock by 10 to make a 5 MHz signal (spec is 20MHz max).
    -- Count from -5 to +4 so the output is symmetrical.
    if(rising_edge(CLK_50M)) then
      if(dacdiv="0100") then
        dacdiv <= "1011";
      else
        dacdiv <= dacdiv + 1;
      end if;
      dac_inclock <= dacdiv(3);
    end if;
    -----------------------------------------------------
    -- Divide the 5 MHz clock by  500 to make a 10 kHz
    -- timing pulse.
    if(falling_edge(dac_inclock)) then
      if(dacpulsediv="000000000") then
        dacpulsediv <= conv_std_logic_vector(499,9);
	dacpulse <= '1';
      else
        dacpulsediv <= dacpulsediv - 1;
	dacpulse <= '0';
      end if;
    end if;
    -----------------------------------------------------
    -- For test, latch the output value from the switches.
    -- if(rising_edge(CLK_50M)) then
    --   if(BTN(3)='1') then
    --     dacword(11 downto 4) <= SW;
    --   end if;
    --   if(BTN(2)='1') then
    --     dacword(3 downto 0) <= SW(3 downto 0);
    --   end if;
    -- end if;
  end process;
  ----------------------------------------------------------------
  -- The ADC. For first test, just display on the LED's,
  -- depending on the switch settings.
  process(CLK_50M,adcdiv) begin
    -- Divide by 40 to make a 1.25 MHz clock.
    if(rising_edge(CLK_50M)) then
        if(adcdiv = conv_std_logic_vector(-20,5)) then
          adcdiv <= conv_std_logic_vector(19,5);
	else
	  adcdiv <= adcdiv - 1;
	end if;
    end if;
    adc_inclock <= adcdiv(4);
    -- Now divide that by 125 to make a 10 kHz sampling pulse.
    if(rising_edge(adc_inclock)) then
      if(adc_pulsecnt = conv_std_logic_vector(0,7)) then
        adc_pulsecnt <= conv_std_logic_vector(124,7);
	adc_pulse <= '1';
      else
        adc_pulsecnt <= adc_pulsecnt - 1;
	adc_pulse <= '0';
      end if;
    end if;
  end process;
  -- Display a lot of test information on the 4 7-segment displays.
  usb_mux_sel <= SW(3) & '0'; -- See cases 0011? and 0111? below.
  process(CLK_50M,seg_segs,seg_digs,SW,valcollect,BTN) begin
    SEG7_SEG <= not seg_segs;
    SEG7_DIG <= not seg_digs;
    case SW(4 downto 0) is
    when "00000"   => seg_word <= X"0123";
    when "00001"   => seg_word <= X"4567";
    when "00010"   => seg_word <= X"89ab";
    when "00011"   => seg_word <= X"cdef";
    when "00100"   => seg_word <= bytecmd_accum(15 downto 0);
    when "00101"   => seg_word <= bytecmd_accum(31 downto 16);
    -- Note: SW(3) also controls usb_mux_sel, so 011? and 111? show different data.
    when "00110"   => seg_word <= muxed_bytecount(15 downto 0);
    when "00111"   => seg_word <= muxed_bytecount(31 downto 16);
    when "01110"   => seg_word <= muxed_bytecount(15 downto 0);  -- See note.
    when "01111"   => seg_word <= muxed_bytecount(31 downto 16); -- See note.
    when "01000"   => seg_word <= ram_addr1(15 downto 0);
    when "01001"   => seg_word <= ram_addr1(31 downto 16);
    when "01010"   => seg_word <= ram_addr2(15 downto 0);
    when "01011"   => seg_word <= ram_addr2(31 downto 16);
    when "01100"   => seg_word <= fifo2_req_bugcount(15 downto 0);
    when "01101"   => seg_word <= fifo2_ack_bugcount(15 downto 0);
    when "10000"   => seg_word <= X"a" & adc_data; -- Consistent with LED's.
    when "10001"   => seg_word <= X"a" & adc_data; -- Consistent with LED's.
    when "10010"   => seg_word <= X"d" & dacword;
    when "10100"   => seg_word <= "000"& cic_shift & cic_decimax;
    when "10101"   => seg_word <= X"00"& red_dac_start;
    when OTHERS => seg_word <= X"dead";
    end case;
    seg_points <= btn_debounced;
  end process;
  -- To test the DCM.
  process(CLK_50M) begin
    if(rising_edge(CLK_50M)) then
      clk_50_div <= clk_50_div + 1;
    end if;
  end process;
  process(CLK_100M) begin
    if(rising_edge(CLK_100M)) then
      clk_100_div <= clk_100_div + 1;
    end if;
  end process;
  ------------------------------------------------------------------------
  -- Capture the A/D input in a latch.
  -- Just 1 A/D for now.
  --------------------------------------------------
  AD23_CLK <= CLK_100M;  -- Clock (always on).
  AD01_CLK <= CLK_100M;  -- Clock (always on).
  AD23_PWRDN <= '0';    -- A/D always active.
  AD01_PWRDN <= '0';    -- A/D always active.
  process(AD0_DATA,AD1_DATA,AD2_DATA,AD3_DATA,CLK_100M) begin
    if (rising_edge(CLK_100M)) then
      cic3_in3 <= (not ad3_input(7)) & ad3_input(6 downto 0);
      cic2_in3 <= (not ad2_input(7)) & ad2_input(6 downto 0);
      cic1_in3 <= (not ad1_input(7)) & ad1_input(6 downto 0);
      cic0_in3 <= (not ad0_input(7)) & ad0_input(6 downto 0);
      ad3_input <= AD3_DATA;
      ad2_input <= AD2_DATA;
      ad1_input <= AD1_DATA;
      ad0_input <= AD0_DATA;
    end if;
  end process;
  --------------------------------------------------
  -- Write the captured data into the on-chip RAM.
  process(CLK_100M) begin
    if(cic_enable='0') then
      samplecapture <= '1';  -- Capture on every 100MHz clock.
    else
      samplecapture <= cic3_down3; -- Hack: assume cic[012]_down3 are the same.
    end if;
    if(rising_edge(CLK_100M)) then
      if(cic_enable='0') then
        -- Full-speed input, 2's complement.
        ram3_data1in <= '0' & cic3_in3;
        ram2_data1in <= '0' & cic2_in3;
        ram1_data1in <= '0' & cic1_in3;
        ram0_data1in <= '0' & cic0_in3;
      else
        -- Desampled.
        ram3_data1in <= '0' & ex8_c3_out;
        ram2_data1in <= '0' & ex8_c2_out;
        ram1_data1in <= '0' & ex8_c1_out;
        ram0_data1in <= '0' & ex8_c0_out;
      end if;
      ex8_c3_in <= cic3_out3;
      ex8_c2_in <= cic2_out3;
      ex8_c1_in <= cic1_out3;
      ex8_c0_in <= cic0_out3;
      if(ad_capturing='1') then
        if(samplecapture='1') then
          ram_write1 <= '1';
          ram_addr1 <= ram_addr1 + 1;
	  if(cap_count = 0) then
	    ad_capturing <= '0';
	  else
            cap_count <= cap_count - 1;
          end if;
	else
          ram_write1 <= '0';
	end if;
      elsif (ad_trigger='1') then
        ram_write1 <= '0';
        ad_capturing <= '1';
        cap_count <= cap_count_init;
      else
        ram_write1 <= '0';
      end if;
    end if;
  end process;
  ad_trigger <= usb_trigger_ad_req OR BTN(1);
  --------------------------------------------------
  -- Read from RAM Port B and send to host via USB.
  process(CLK_50M) begin
    if(rising_edge(CLK_50M)) then
      ack_long <= ack_long(6 downto 0) & fifo2_ack;
      req_long <= req_long(6 downto 0) & fifo2_req;
      if( (req_long="11111111") and (ack_long="11111111") ) then
        fifo2_req <= '0';
      elsif( (req_long="00000000") and (ack_long="00000000") ) then
        if (usb_upload_active='0') then
          if ( (btn_debounced(0)='1') or (usb_trigger_upload_req='1') ) then
            usb_upload_active <= '1';
          end if;
        else 
          if(usb_upload_count="0000000000000") then
            usb_upload_active <= '0';
          end if;
          fifo2_req <= '1';
        end if;
      end if;
      if( req_long="00001111") then
        usb_upload_count <= usb_upload_count+1;
        ram_addr2 <= ram_addr2 + 1;
      end if;
      case ram_addr2(12 downto 11) is
      when "00" => fifo2_outbyte <= ram0_data2out(7 downto 0);
      when "01" => fifo2_outbyte <= ram1_data2out(7 downto 0);
      when "10" => fifo2_outbyte <= ram2_data2out(7 downto 0);
      -- when "11" => fifo2_outbyte <= ram3_data2out(7 downto 0);
      when others => fifo2_outbyte <= ram3_data2out(7 downto 0);
      end case;
    end if;
  end process;
-----------------------------------------------------------------------
  -- Debugging counters.
  process(fifo2_req) begin
    if(rising_edge(fifo2_req)) then
      fifo2_req_bugcount <= fifo2_req_bugcount + 1;
    end if;
  end process;
  process(fifo2_ack) begin
    if(rising_edge(fifo2_ack)) then
      fifo2_ack_bugcount <= fifo2_ack_bugcount + 1;
    end if;
  end process;
  --------------------------------------------------
  -- 3-bit DAC, connected to the RED VGA output.
  process (CLK_100M,red_dac_val) begin
    if(rising_edge(CLK_100M)) then
      if(red_dac_count=0) then
        red_dac_count <= red_dac_start;
	red_dac_val <= red_dac_val + 1;
      else
        red_dac_count <= red_dac_count-1;
      end if;
    end if;
    -- Flip to make a triangle.
    if(red_dac_val(3)='1') then
      VGA_RED <= not red_dac_val(2 downto 0);
    else
      VGA_RED <= red_dac_val(2 downto 0);
    end if;
    VGA_HS <= red_dac_val(3); -- Just for debug and timing check.
  end process;

end rtl;
