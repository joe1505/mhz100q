-- $Id: mhz100q2_ocscope.vhd,v 1.15 2011/10/21 19:17:40 jrothwei Exp $
-- Copyright 2011 Joseph Rothweiler, Sensicomm LLC. Started 28Aug2011.
-- Top-level oscilloscope function for the Sensicomm MHZ100Q2 PCB,
-- using the opencores USB driver.
--
-- Want AD?_DATA to be placed in the I/O blocks:
-- GUI: Implement Design -> Process Properties ->
--   Map Properties -> -pr (Pack I/O Registers/Latches into IOBs -> For Inputs and Outputs)

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;     -- Makes the "div+1" instruction work.
use ieee.std_logic_unsigned.all;

entity mhz100q2_ocscope is
  Port (
    CLK_50M  : in  STD_LOGIC; -- Input: 50 MHz system clock.

    -- USB Connections -----------------

    USB_ON  : out STD_LOGIC;    -- Activates 1.5k pullup to 3.3v.
    dplus   : inout std_logic;  -- D+ data line.
    dminus  : inout std_logic;  -- D- data line.

    -- A/D Connections. ---------------

    AD0_DATA     : in  STD_LOGIC_VECTOR(7 downto 0);
    AD1_DATA     : in  STD_LOGIC_VECTOR(7 downto 0);
    AD0_CLK      : out STD_LOGIC; -- Sampling clock.
    AD1_CLK      : out STD_LOGIC; -- Sampling clock.
    AD0_CLK_LOOP : in  STD_LOGIC; -- Clock loopback, not used.
    AD1_CLK_LOOP : in  STD_LOGIC; -- Clock loopback, not used.
    AD0_PWRDN    : out STD_LOGIC; --
    AD1_PWRDN    : out STD_LOGIC; --

    -- I/O pins -----------------------

    TP9          : out STD_LOGIC_VECTOR(7 downto 0); -- Upright near front.

    -- The status LED -----------------

    LED1    : out STD_LOGIC
  );
end mhz100q2_ocscope;
-------------------------------------------------------------------------------
architecture rtl of mhz100q2_ocscope is
  ---------------------------------------------------------
  -- Define the components.
  ---------------------------------------------------------
  component sinetable_f08b is Port (
    clock1   : in  STD_LOGIC;
    addr1    : in  STD_LOGIC_VECTOR (10 downto 0);
    data1out : out STD_LOGIC_VECTOR ( 7 downto 0);
    --
    clock2   : in  STD_LOGIC;
    addr2    : in  STD_LOGIC_VECTOR (10 downto 0);
    data2out : out STD_LOGIC_VECTOR ( 7 downto 0)
  );
  end component;

  component ascii_cmd is
    generic (
      addrwidth    : integer :=  4 ; -- Length of address output in bits.
      datawidth    : integer := 32   -- Length of data output in bits.
    ) ; port (
      clk      : in   STD_LOGIC;  -- system clock.
      byteval  : in   STD_LOGIC_VECTOR (7 downto 0);  -- Input byte to decode.
      enable   : in   STD_LOGIC; -- High for 1 clock cycle when byteval is valid.
      addr     : out  STD_LOGIC_VECTOR (addrwidth-1 downto 0);
      data     : out  STD_LOGIC_VECTOR (datawidth-1 downto 0);
      addrstrb : out  STD_LOGIC; -- High for 1 cycle when addr is set. (@)
      datastrb : out  STD_LOGIC  -- High for 1 cycle when data is set. (=)
  );
  end component;

  component scopechan is
    Port (
      CLK_48M      : in  STD_LOGIC; --  48 MHz USB clock.
      CLK_100M     : in  STD_LOGIC; -- 100 MHz system clock.
      downcmd      : in  STD_LOGIC; -- CIC strobe, 1 CLK_100M cycle.
      rt_shift     : in  STD_LOGIC_VECTOR( 5 downto 0); -- Right shift scaling after CIC.
      cic_out_pos  : out STD_LOGIC_VECTOR(39 downto 0);
      cic_out_neg  : out STD_LOGIC_VECTOR(39 downto 0);
      a2d_in_max   : out STD_LOGIC_VECTOR( 7 downto 0);
      a2d_in_min   : out STD_LOGIC_VECTOR( 7 downto 0);
      triggerlevel : in  STD_LOGIC_VECTOR( 7 downto 0);
      triggerline  : out STD_LOGIC;
      write_addr1  : in  STD_LOGIC_VECTOR(10 downto 0); -- Increments on downcmd and cic_write.

      a2d_data     : in  STD_LOGIC_VECTOR( 7 downto 0); -- A/D input data.
      cic_write    : in  STD_LOGIC;                     -- Enables CIC output write to RAM.
      hilo_reset   : in  STD_LOGIC;                     -- Reset for the high-low bit finder.
      read_addr    : in  STD_LOGIC_VECTOR(10 downto 0); -- Address for read channel.
      read_data    : out STD_LOGIC_VECTOR( 7 downto 0)  -- Data for read channel.
    );
  end component;

  -- To generate a 48 MHz clock from the 50 MHz input clock.
  component dcm_updn is
    generic (
      upfactor  : integer ; -- Up conversion: 2 to 32.
      dnfactor  : integer   -- Down conversion: 1 to 32.
    ) ;
    port (
      CLK_IN     : in  STD_LOGIC;
      CLK_OUTP   : out STD_LOGIC;
      CLK_OUTN   : out STD_LOGIC
    ) ;
  end component;
  -- component usb_phy is encapsulated inside usb1_core.
  -- The endpoint definitions here must be consistent with the
  -- configuration data defined in usb1_rom1.v.
  component usb1_core is port (
    clk_i                : in std_logic;
    ep1_bf_en            : in std_logic;
    ep1_bf_size          : in std_logic_vector (6 downto 0);
    ep1_cfg              : in std_logic_vector (13 downto 0);
    ep1_din              : in std_logic_vector (7 downto 0);
    ep1_empty            : in std_logic;
    ep1_full             : in std_logic;
    ep2_bf_en            : in std_logic;
    ep2_bf_size          : in std_logic_vector (6 downto 0);
    ep2_cfg              : in std_logic_vector (13 downto 0);
    ep2_din              : in std_logic_vector (7 downto 0);
    ep2_empty            : in std_logic;
    ep2_full             : in std_logic;
    ep3_bf_en            : in std_logic;
    ep3_bf_size          : in std_logic_vector (6 downto 0);
    ep3_cfg              : in std_logic_vector (13 downto 0);
    ep3_din              : in std_logic_vector (7 downto 0);
    ep3_empty            : in std_logic;
    ep3_full             : in std_logic;
    ep4_bf_en            : in std_logic;
    ep4_bf_size          : in std_logic_vector (6 downto 0);
    ep4_cfg              : in std_logic_vector (13 downto 0);
    ep4_din              : in std_logic_vector (7 downto 0);
    ep4_empty            : in std_logic;
    ep4_full             : in std_logic;
    ep5_bf_en            : in std_logic;
    ep5_bf_size          : in std_logic_vector (6 downto 0);
    ep5_cfg              : in std_logic_vector (13 downto 0);
    ep5_din              : in std_logic_vector (7 downto 0);
    ep5_empty            : in std_logic;
    ep5_full             : in std_logic;
    ep6_bf_en            : in std_logic;
    ep6_bf_size          : in std_logic_vector (6 downto 0);
    ep6_cfg              : in std_logic_vector (13 downto 0);
    ep6_din              : in std_logic_vector (7 downto 0);
    ep6_empty            : in std_logic;
    ep6_full             : in std_logic;
    ep7_bf_en            : in std_logic;
    ep7_bf_size          : in std_logic_vector (6 downto 0);
    ep7_cfg              : in std_logic_vector (13 downto 0);
    ep7_din              : in std_logic_vector (7 downto 0);
    ep7_empty            : in std_logic;
    ep7_full             : in std_logic;
    phy_tx_mode          : in std_logic;
    rst_i                : in std_logic;
    rx_d                 : in std_logic;
    rx_dn                : in std_logic;
    rx_dp                : in std_logic;
    vendor_data          : in std_logic_vector (15 downto 0);
    crc16_err            : out std_logic;
    dropped_frame        : out std_logic;
    ep1_dout             : out std_logic_vector (7 downto 0);
    ep1_re               : out std_logic;
    ep1_we               : out std_logic;
    ep2_dout             : out std_logic_vector (7 downto 0);
    ep2_re               : out std_logic;
    ep2_we               : out std_logic;
    ep3_dout             : out std_logic_vector (7 downto 0);
    ep3_re               : out std_logic;
    ep3_we               : out std_logic;
    ep4_dout             : out std_logic_vector (7 downto 0);
    ep4_re               : out std_logic;
    ep4_we               : out std_logic;
    ep5_dout             : out std_logic_vector (7 downto 0);
    ep5_re               : out std_logic;
    ep5_we               : out std_logic;
    ep6_dout             : out std_logic_vector (7 downto 0);
    ep6_re               : out std_logic;
    ep6_we               : out std_logic;
    ep7_dout             : out std_logic_vector (7 downto 0);
    ep7_re               : out std_logic;
    ep7_we               : out std_logic;
    ep_sel               : out std_logic_vector (3 downto 0);
    misaligned_frame     : out std_logic;
    tx_dn                : out std_logic;
    tx_dp                : out std_logic;
    tx_oe                : out std_logic; -- Active low??
    usb_busy             : out std_logic;
    usb_rst              : out std_logic;
    v_set_feature        : out std_logic;
    v_set_int            : out std_logic;
    wIndex               : out std_logic_vector (15 downto 0);
    wValue               : out std_logic_vector (15 downto 0)
  );
  end component;
  ---------------------------------------------------------
  -- Signals.
  ---------------------------------------------------------
  -- Definitions: Make sure these match the definitions in usb1_defines.v
  constant K_IN   : std_logic_vector(13 downto 0) :=  "00001000000000";
  constant K_OUT  : std_logic_vector(13 downto 0) :=  "00010000000000";
  constant K_CTRL : std_logic_vector(13 downto 0) :=  "10100000000000";
  constant K_ISO  : std_logic_vector(13 downto 0) :=  "01000000000000";
  constant K_BULK : std_logic_vector(13 downto 0) :=  "10000000000000";
  constant K_INT  : std_logic_vector(13 downto 0) :=  "00000000000000";

  -- Synthesized clocks.
  signal clk_100m       : std_logic;
  signal clk_100m_neg   : std_logic; -- No used.
  signal clk_usb48m     : std_logic;
  signal clk_usb48m_neg : std_logic; -- No used.
  -- For the usb core.
  signal c_clk_i        : std_logic;
  -- Endpoint signals: IN and OUT are USB transfer direction relative to the HOST PC.
  -- r and w are read-from and write-to the usb1_core ports.
  ----------- EP1
  -- Use ep1 for host-to-device (OUT) transfers.
  signal c_ep1_cfg      : std_logic_vector (13 downto 0) := K_ISO or K_IN or conv_std_logic_vector(256,14) ;
  signal c_ep1_dout     : std_logic_vector (7 downto 0);          -- IN w Unused.
  signal c_ep1_we       : std_logic;                              -- OUT r Not implemented yet.
  signal c_ep1_full     : std_logic := '1';                       -- OUT w Not implemented yet.
  signal c_ep1_din      : std_logic_vector (7 downto 0) := X"22"; -- OUT r Not implemented yet.
  signal c_ep1_re       : std_logic;                              -- IN r Unused.
  signal c_ep1_empty    : std_logic := '0';                       -- IN w Unused.
  signal c_ep1_bf_en    : std_logic := '1';
  signal c_ep1_bf_size  : std_logic_vector (6 downto 0) := conv_std_logic_vector(7,7);
  ----------- EP2
  -- Use ep2 for device-to-host (IN) transfers.
  signal c_ep2_cfg      : std_logic_vector (13 downto 0) := K_ISO or  K_OUT or conv_std_logic_vector(256,14) ;

  signal c_ep2_dout     : std_logic_vector (7 downto 0);          -- IN w 
  signal c_ep2_we       : std_logic;                              -- OUT r Not implemented yet.
  signal c_ep2_full     : std_logic := '0';                       -- OUT w Not implemented yet.

  signal c_ep2_din      : std_logic_vector (7 downto 0) := X"24"; -- OUT r Not implemented yet.
  signal c_ep2_re       : std_logic;                              -- IN r Ignored for now.
  signal c_ep2_empty    : std_logic := '1';                       -- IN w Constant 1 for now.

  signal c_ep2_bf_en    : std_logic := '1';
  signal c_ep2_bf_size  : std_logic_vector (6 downto 0) := conv_std_logic_vector(7,7);
  ----------- EP3 (IN device-to-host only)
  signal c_ep3_cfg      : std_logic_vector (13 downto 0) := K_BULK or K_IN or conv_std_logic_vector(64,14);

  signal c_ep3_dout     : std_logic_vector(7 downto 0); -- Out to a fifo. Unused.
  signal c_ep3_we       : std_logic;        -- fifo write-enable. Unused.
  signal c_ep3_full     : std_logic := '1'; -- fifo always full, so never writes.

  signal c_ep3_din      : std_logic_vector (7 downto 0) := X"26"; -- host is receiving hex 26.
  signal c_ep3_re       : std_logic := '1';
  signal c_ep3_empty    : std_logic := '0';

  signal c_ep3_bf_en    : std_logic := '1';
  signal c_ep3_bf_size  : std_logic_vector (6 downto 0) := conv_std_logic_vector(7,7);
  ----------- EP4 (OUT - host-to-device only)
  signal c_ep4_cfg      : std_logic_vector (13 downto 0) := K_BULK or K_OUT or conv_std_logic_vector(64,14);

  signal c_ep4_dout     : std_logic_vector(7 downto 0);
  signal c_ep4_we       : std_logic;         -- To a FIFO's write-enable input.
  signal c_ep4_full     : std_logic := '0';  -- A FIFO's input-full signal. Never full here.

  signal c_ep4_din      : std_logic_vector (7 downto 0) := X"28";
  signal c_ep4_re       : std_logic;         -- To a FIFO's read-enable input.
  signal c_ep4_empty    : std_logic := '1';  -- A FIFO's output-empty signal. Always empty here.

  signal c_ep4_bf_en    : std_logic := '1';
  signal c_ep4_bf_size  : std_logic_vector (6 downto 0) := conv_std_logic_vector(7,7);
  ----------- EP5
  signal c_ep5_cfg      : std_logic_vector (13 downto 0) := K_INT or K_IN or conv_std_logic_vector(64,14);

  signal c_ep5_dout     : std_logic_vector (7 downto 0);
  signal c_ep5_we       : std_logic;
  signal c_ep5_full     : std_logic := '1';

  signal c_ep5_din      : std_logic_vector (7 downto 0) := X"2a";
  signal c_ep5_re       : std_logic;
  signal c_ep5_empty    : std_logic;

  signal c_ep5_bf_en    : std_logic := '1';
  signal c_ep5_bf_size  : std_logic_vector (6 downto 0) := conv_std_logic_vector(7,7);
  ----------- EP6
  signal c_ep6_cfg      : std_logic_vector (13 downto 0) := conv_std_logic_vector(0,14);

  signal c_ep6_dout     : std_logic_vector (7 downto 0);
  signal c_ep6_we       : std_logic;
  signal c_ep6_full     : std_logic := '0';

  signal c_ep6_din      : std_logic_vector (7 downto 0) := X"2c";
  signal c_ep6_re       : std_logic;
  signal c_ep6_empty    : std_logic := '0';

  signal c_ep6_bf_en    : std_logic := '1';
  signal c_ep6_bf_size  : std_logic_vector (6 downto 0) := conv_std_logic_vector(7,7);
  ----------- EP7
  signal c_ep7_cfg      : std_logic_vector (13 downto 0) := conv_std_logic_vector(0,14);

  signal c_ep7_dout     : std_logic_vector (7 downto 0);
  signal c_ep7_we       : std_logic;
  signal c_ep7_full     : std_logic := '0';

  signal c_ep7_din      : std_logic_vector (7 downto 0) := X"2e";
  signal c_ep7_re       : std_logic;
  signal c_ep7_empty    : std_logic := '0';

  signal c_ep7_bf_en    : std_logic := '1';
  signal c_ep7_bf_size  : std_logic_vector (6 downto 0) := conv_std_logic_vector(7,7);
  -----------
  signal c_phy_tx_mode          : std_logic;
  signal c_rst_i                : std_logic := '0'; -- Power-up in reset mode. Active-low??
  signal c_rx_d                 : std_logic;
  signal c_rx_dn                : std_logic;
  signal c_rx_dp                : std_logic;
  signal c_vendor_data          : std_logic_vector (15 downto 0);
  signal c_crc16_err            : std_logic;
  signal c_dropped_frame        : std_logic;
  signal c_ep_sel               : std_logic_vector (3 downto 0);
  signal c_misaligned_frame     : std_logic;
  signal c_tx_dn                : std_logic;
  signal c_tx_dp                : std_logic;
  signal c_tx_oe                : std_logic;
  signal c_usb_busy             : std_logic;
  signal c_usb_rst              : std_logic;
  signal c_v_set_feature        : std_logic;
  signal c_v_set_int            : std_logic;
  signal c_wIndex               : std_logic_vector (15 downto 0);
  signal c_wValue               : std_logic_vector (15 downto 0);
  -- Other signals.
  signal usb_on_delay : STD_LOGIC_VECTOR(29 downto 0);
  signal usb_on_local : STD_LOGIC := '0';
  signal time1scounter         : std_logic_vector(28 downto 0); -- 10-second counter.
  signal time1spip             : std_logic; -- Pip every second.
  signal ep5_active            : std_logic;
  signal ep5_sendcount         : std_logic_vector( 7 downto 0) := X"ff";
  signal led1_local            : std_logic;
  signal chan0_read_addr_flag  : STD_LOGIC;
  signal chan0_read_left_flag  : STD_LOGIC;
  signal chan0_read_addr       : STD_LOGIC_VECTOR(10 downto 0);
  signal chan0_read_left       : STD_LOGIC_VECTOR(10 downto 0);
  signal chan0_read_data       : STD_LOGIC_VECTOR( 7 downto 0);
  signal chan0_a2d_data        : STD_LOGIC_VECTOR( 7 downto 0);
  signal chan0_a2d_latch       : STD_LOGIC_VECTOR( 7 downto 0);
  signal chanx_downcmd         : STD_LOGIC;
  signal chanx_downcounter     : STD_LOGIC_VECTOR( 7 downto 0);
  signal chanx_downcounter_set : STD_LOGIC_VECTOR( 7 downto 0);
  signal chanx_rightshift      : STD_LOGIC_VECTOR( 5 downto 0);
  signal cmd_enable            : STD_LOGIC;
  signal cmd_addr              : STD_LOGIC_VECTOR( 3 downto 0);
  signal cmd_data              : STD_LOGIC_VECTOR(31 downto 0);
  signal cmd_addrstrb          : STD_LOGIC;
  signal cmd_datastrb          : STD_LOGIC;
  -----
  signal dbg1_count            : STD_LOGIC_VECTOR( 7 downto 0);
  signal dbg2_count            : STD_LOGIC_VECTOR( 7 downto 0);
  -----
  signal sinetab_addr1 : STD_LOGIC_VECTOR(10 downto 0);
  signal sinetab_data1 : STD_LOGIC_VECTOR( 7 downto 0);
  signal sinetab_addr2 : STD_LOGIC_VECTOR(10 downto 0);
  signal sinetab_data2 : STD_LOGIC_VECTOR( 7 downto 0);
  signal dac8sig        : STD_LOGIC_VECTOR(31 downto 0);
  signal dac8step       : STD_LOGIC_VECTOR(31 downto 0) := X"00200000"; -- X"00200000" ~ 50kHz.
  -----
  signal chan0_cic_out_pos  : STD_LOGIC_VECTOR(39 downto 0);
  signal chan0_cic_out_neg  : STD_LOGIC_VECTOR(39 downto 0);
  signal chanx_cic_write    : STD_LOGIC := '1';
  signal chanx_cic_write_set: STD_LOGIC;
  signal chanx_hilo_reset   : STD_LOGIC := '0';
  signal chan0_a2d_in_max   : STD_LOGIC_VECTOR( 7 downto 0);
  signal chan0_a2d_in_min   : STD_LOGIC_VECTOR( 7 downto 0);
  signal chanx_triggerlevel : STD_LOGIC_VECTOR( 7 downto 0);
  signal chan0_triggerline  : STD_LOGIC;
  signal chanx_write_addr1  : STD_LOGIC_VECTOR(10 downto 0);
  signal ep5_send64         : STD_LOGIC_VECTOR(63 downto 0);
  signal chanx_posttrig     : STD_LOGIC_VECTOR(11 downto 0);
  signal posttrig_initial   : STD_LOGIC_VECTOR(11 downto 0);
  signal trigger_enable     : STD_LOGIC;
  signal trigger_on_rising  : STD_LOGIC;
  signal triggerline_d      : STD_LOGIC;
  signal trigger_manual     : STD_LOGIC;
  signal chanx_capcount     : STD_LOGIC_VECTOR(3 downto 0);
  signal chanx_cap_done_s100  : STD_LOGIC;
  signal chanx_cap_done_s48   : STD_LOGIC;
  signal chanx_cap_done_async : STD_LOGIC;
  signal ep5_trigger_req    : STD_LOGIC;
  signal ep5_trigger_ack    : STD_LOGIC;
  signal ep5_trigger_s48    : STD_LOGIC;
begin
-------------------------------------------------------------------------------
  sinetable_f08b_0: sinetable_f08b port map (
    clock1   => clk_100m,
    addr1    => sinetab_addr1,
    data1out => sinetab_data1,
    --
    clock2   => clk_100m,
    addr2    => sinetab_addr2,
    data2out => sinetab_data2
  );
  ---------------------------------------------------------
  cmd: ascii_cmd generic map (
      addrwidth => 4,
      datawidth => 32
    )  port map (
      clk      => clk_usb48m,
      byteval  => c_ep4_dout,
      enable   => cmd_enable,
      addr     => cmd_addr,
      data     => cmd_data,
      addrstrb => cmd_addrstrb,
      datastrb => cmd_datastrb
  );
  ---------------------------------------------------------
  chan0: scopechan port map (
      CLK_48M      => clk_usb48m,
      CLK_100M     => clk_100m,
      downcmd      => chanx_downcmd,
      cic_out_pos  => chan0_cic_out_pos,
      cic_out_neg  => chan0_cic_out_neg,
      a2d_in_max   => chan0_a2d_in_max,
      a2d_in_min   => chan0_a2d_in_min,
      triggerlevel => chanx_triggerlevel,
      triggerline  => chan0_triggerline,
      write_addr1  => chanx_write_addr1,
      rt_shift     => chanx_rightshift,
      a2d_data     => chan0_a2d_data,
      cic_write    => chanx_cic_write,
      hilo_reset   => chanx_hilo_reset,
      read_addr    => chan0_read_addr,
      read_data    => chan0_read_data
    );
  ---------------------------------------------------------
  -- Connect the command processor to the
  -- USB OUT (host->device) path, EP4.
  ---------------------------------------------------------

  cmd_enable <= c_ep4_we; -- FIXME: Can I just connect directly?

  ---------------------------------------------------------
  -- Make the 100 MHz clock.
  ---------------------------------------------------------
  dcm_updn100 : dcm_updn generic map (
      upfactor  => 2, -- 50MHz*(2/1)
      dnfactor  => 1 
    ) port map (
      CLK_IN     => CLK_50M,
      CLK_OUTP   => clk_100m,
      CLK_OUTN   => clk_100m_neg -- Not used.
    ) ;
  ---------------------------------------------------------
  -- Make the 48 MHz clock.
  ---------------------------------------------------------
  dcm_updn48 : dcm_updn generic map (
      upfactor  => 24, -- (50MHz/25)*24 gives 48MHz output.
      dnfactor  => 25
    ) port map (
      CLK_IN     => CLK_50M,
      CLK_OUTP   => clk_usb48m,
      CLK_OUTN   => clk_usb48m_neg -- Not used.
    ) ;
  ---------------------------------------------------------
  -- CIC strobe for the channels.
  ---------------------------------------------------------
  process(CLK_100M) begin
    if rising_edge(CLK_100M) then
      if chanx_downcounter=0 then
        chanx_downcmd <= '1';
        -- chanx_downcounter_set is on a different clock, so we can get
        -- a glitch if it changes while this is happening. That doesn't
        -- happen during normal continuous operation.
        -- chanx_downcounter_set can be 0, in which case the CIC just passes
        -- data without modification.
        chanx_downcounter <= chanx_downcounter_set;
      else
        chanx_downcmd <= '0';
        chanx_downcounter <= chanx_downcounter - 1 ;
      end if;
    end if;
    -- Increment the write address at the CIC output rate.
    if rising_edge(CLK_100M) then
      if chanx_downcmd='1' and  chanx_cic_write='1' then
        chanx_write_addr1 <= chanx_write_addr1 + 1;
      end if;
    end if;
  end process;
  ---------------------------------------------------------
  -- Connect up the USB components.
  ---------------------------------------------------------
  usb1_core0 : usb1_core port map(
    clk_i            => c_clk_i            ,
    ep1_bf_en        => c_ep1_bf_en        ,
    ep1_bf_size      => c_ep1_bf_size      ,
    ep1_cfg          => c_ep1_cfg          ,
    ep1_din          => c_ep1_din          ,
    ep1_empty        => c_ep1_empty        ,
    ep1_full         => c_ep1_full         ,
    ep2_bf_en        => c_ep2_bf_en        ,
    ep2_bf_size      => c_ep2_bf_size      ,
    ep2_cfg          => c_ep2_cfg          ,
    ep2_din          => c_ep2_din          ,
    ep2_empty        => c_ep2_empty        ,
    ep2_full         => c_ep2_full         ,
    ep3_bf_en        => c_ep3_bf_en        ,
    ep3_bf_size      => c_ep3_bf_size      ,
    ep3_cfg          => c_ep3_cfg          ,
    ep3_din          => c_ep3_din          ,
    ep3_empty        => c_ep3_empty        ,
    ep3_full         => c_ep3_full         ,
    ep4_bf_en        => c_ep4_bf_en        ,
    ep4_bf_size      => c_ep4_bf_size      ,
    ep4_cfg          => c_ep4_cfg          ,
    ep4_din          => c_ep4_din          ,
    ep4_empty        => c_ep4_empty        ,
    ep4_full         => c_ep4_full         ,
    ep5_bf_en        => c_ep5_bf_en        ,
    ep5_bf_size      => c_ep5_bf_size      ,
    ep5_cfg          => c_ep5_cfg          ,
    ep5_din          => c_ep5_din          ,
    ep5_empty        => c_ep5_empty        ,
    ep5_full         => c_ep5_full         ,
    ep6_bf_en        => c_ep6_bf_en        ,
    ep6_bf_size      => c_ep6_bf_size      ,
    ep6_cfg          => c_ep6_cfg          ,
    ep6_din          => c_ep6_din          ,
    ep6_empty        => c_ep6_empty        ,
    ep6_full         => c_ep6_full         ,
    ep7_bf_en        => c_ep7_bf_en        ,
    ep7_bf_size      => c_ep7_bf_size      ,
    ep7_cfg          => c_ep7_cfg          ,
    ep7_din          => c_ep7_din          ,
    ep7_empty        => c_ep7_empty        ,
    ep7_full         => c_ep7_full         ,
    phy_tx_mode      => c_phy_tx_mode      ,
    rst_i            => c_rst_i            ,
    rx_d             => c_rx_d             ,
    rx_dn            => c_rx_dn            ,
    rx_dp            => c_rx_dp            ,
    vendor_data      => c_vendor_data      ,
    crc16_err        => c_crc16_err        ,
    dropped_frame    => c_dropped_frame    ,
    ep1_dout         => c_ep1_dout         ,
    ep1_re           => c_ep1_re           ,
    ep1_we           => c_ep1_we           ,
    ep2_dout         => c_ep2_dout         ,
    ep2_re           => c_ep2_re           ,
    ep2_we           => c_ep2_we           ,
    ep3_dout         => c_ep3_dout         ,
    ep3_re           => c_ep3_re           ,
    ep3_we           => c_ep3_we           ,
    ep4_dout         => c_ep4_dout         ,
    ep4_re           => c_ep4_re           ,
    ep4_we           => c_ep4_we           ,
    ep5_dout         => c_ep5_dout         ,
    ep5_re           => c_ep5_re           ,
    ep5_we           => c_ep5_we           ,
    ep6_dout         => c_ep6_dout         ,
    ep6_re           => c_ep6_re           ,
    ep6_we           => c_ep6_we           ,
    ep7_dout         => c_ep7_dout         ,
    ep7_re           => c_ep7_re           ,
    ep7_we           => c_ep7_we           ,
    ep_sel           => c_ep_sel           ,
    misaligned_frame => c_misaligned_frame ,
    tx_dn            => c_tx_dn            ,
    tx_dp            => c_tx_dp            ,
    tx_oe            => c_tx_oe            ,
    usb_busy         => c_usb_busy         ,
    usb_rst          => c_usb_rst          ,
    v_set_feature    => c_v_set_feature    ,
    v_set_int        => c_v_set_int        ,
    wIndex           => c_wIndex           ,
    wValue           => c_wValue
  );
  ---------------------------------------------------------
  -- Connect to the A/D
  ---------------------------------------------------------

  process(clk_100m,AD0_DATA) begin
    if rising_edge(clk_100m) then
      chan0_a2d_latch <= AD0_DATA;
      chan0_a2d_data <= chan0_a2d_latch;
    end if;
    AD0_CLK   <= clk_100m;
    AD0_PWRDN <= '0'; -- Always active for now.
    AD1_CLK   <= '0'; -- Off for now.
    AD1_PWRDN <= '1'; -- Off for now.
  end process;
  ---------------------------------------------------------
  -- Connect to the I/O pins.
  process(c_tx_dn,c_tx_dp,c_tx_oe) begin
    -- Wire up the tristate pins.
    if(c_tx_oe='0') then
      dplus  <= c_tx_dp;
      dminus <= c_tx_dn;
    else
      dplus  <= 'Z';
      dminus <= 'Z';
    end if;
    c_rx_dp <= dplus;
    c_rx_dn <= dminus;
    c_rx_d  <= dplus;   -- FIXME: is this right??
    -- The USB clock (I hope this is 48 MHz).
    c_clk_i <= clk_usb48m;

    c_phy_tx_mode <= '1'; -- FIXME: I think 1 gives differential mode.
  end process;
  ---------------------------------------------------------
  -- Control the EP3 output data.
  -- EP3 transfers data back to the host when requested.
  process(clk_usb48m) begin
    if rising_edge(clk_usb48m) then
      -- chan0_read_addr_flag and chan0_read_left_flag cannot occur simultaneously.
      -- We may miss a byte if either flag occurs while a transfer is active, but
      -- that's an abort/cancel condition so we expect funny things to happen.
      -- Transfers can start any time after chan0_read_left becomes nonzero, so
      -- the host must set chan0_read_addr first.
      if chan0_read_addr_flag='1' then
        chan0_read_addr <= cmd_data(chan0_read_addr'length-1 downto 0);
        dbg1_count <= dbg1_count + 1;
      elsif chan0_read_left_flag='1' then
        chan0_read_left <= cmd_data(chan0_read_left'length-1 downto 0);
        dbg2_count <= dbg2_count + 1;
      elsif c_ep3_re='1' then
        -- c_ep3_empty <= '0'; -- ack.
        c_ep3_din <= chan0_read_data;
        chan0_read_addr <= chan0_read_addr +1;
        if chan0_read_left/=0 then
          chan0_read_left <= chan0_read_left -1;
        end if;
      end if;
      if chan0_read_left=0 then
        c_ep3_empty <= '1';
      else
        c_ep3_empty <= '0'; -- CHECK: I think this will prevent ep3_re from going high.
      end if;
    end if;
  end process;
  ---------------------------------------------------------
  -- Control the EP5 output data.
  -- chan0_cic_out_pos 40
  -- chan0_cic_out_neg 40
  -- chan0_a2d_in_max 8
  -- chan0_a2d_in_min 8
  -- chanx_write_addr1 11
  -- cmd_data 32
  process(clk_usb48m) begin
    case ep5_sendcount(ep5_sendcount'length-1 downto 3) is
    when "00000" => ep5_send64 <= chan0_cic_out_neg(23 downto 0) & chan0_cic_out_pos;
    --when "00000" => ep5_send64 <= X"22" & chan0_a2d_in_min & chan0_a2d_in_max & chan0_cic_out_pos(39 downto 8) & X"66"; -- Debug
    when "00001" => ep5_send64 <=
                     cmd_data &
                     chan0_a2d_in_min & chan0_a2d_in_max &
                     chan0_cic_out_neg(39 downto 24);
    when "00010" => ep5_send64 <= conv_std_logic_vector(0,64-16-8) &
                     "000" & chanx_cic_write & chanx_capcount &  -- 8 bits.
                     "00000" & chanx_write_addr1;                -- 16 bits.
    when others => ep5_send64 <= X"0123_4567_89ab_cdef";
    end case;
    if rising_edge(clk_usb48m) then
      if (c_ep5_re='1') and (ep5_active='1') then
        if ep5_sendcount=conv_std_logic_vector(-1,ep5_sendcount'length) then -- Stop on all-one's condition.
          ep5_active<='0';
        else
          ep5_sendcount<=ep5_sendcount-1;
        end if;
        c_ep5_din(7 downto 4) <=  X"5";
        c_ep5_din(3 downto 0) <=  cmd_data(3 downto 0);
        case ep5_sendcount(2 downto 0) is
        when "000" => c_ep5_din <= ep5_send64( 7 downto  0);
        when "001" => c_ep5_din <= ep5_send64(15 downto  8);
        when "010" => c_ep5_din <= ep5_send64(23 downto 16);
        when "011" => c_ep5_din <= ep5_send64(31 downto 24);
        when "100" => c_ep5_din <= ep5_send64(39 downto 32);
        when "101" => c_ep5_din <= ep5_send64(47 downto 40);
        when "110" => c_ep5_din <= ep5_send64(55 downto 48);
        when others => c_ep5_din <= ep5_send64(63 downto 56); -- "111" case.
        -- c_ep5_din(3 downto 0) <=  c_ep5_din(3 downto 0) + 1;
        end case;
      elsif (ep5_active='0') then
          -- if time1spip='1' then
          --   ep5_active<='1';
          --   -- ep5_sendcount<=conv_std_logic_vector(256,ep5_sendcount'length);
          --   ep5_sendcount<=(others=>'1');
          -- end if;
          c_ep5_din(7 downto 4) <=  X"6";
      else
          c_ep5_din(7 downto 4) <=  X"7";
      end if;
      if ep5_sendcount=conv_std_logic_vector(-1,ep5_sendcount'length) then -- Stop on all-one's condition.
        -- Counter is all-ones, so EP5 is idle.
        c_ep5_empty <= '1'; -- Stop USB transfers.
        -- Start next transmission on strobe from the input command port.
        if ep5_trigger_req='1' then
          ep5_trigger_ack<='1';
          ep5_active<='1';
          ep5_sendcount<=conv_std_logic_vector(31,ep5_sendcount'length); -- Set to count-1.
        end if;
      else
        c_ep5_empty <= '0';
        ep5_trigger_ack<='0';
      end if;
    end if;
    -- An EP5 trigger is requested by a one-clock-cycle pulse. Sources are:
    -- ep5_trigger_s48    From the USB input command port.
    -- time1spip          Interval timer.
    -- chanx_cap_done_s48 Capture complete.
    if rising_edge(clk_usb48m) then
      if ep5_trigger_s48='1' or time1spip='1' or chanx_cap_done_s48='1' then
        ep5_trigger_req<='1';
      elsif ep5_trigger_ack='1' then
        ep5_trigger_req<='0';
      end if;
    end if;
  end process;
  ---------------------------------------------------------
  -- Now a multiple second counter.
  process(clk_usb48m) begin
    if rising_edge(clk_usb48m) then
      if time1scounter=0 then
        time1scounter <= conv_std_logic_vector(10*48e6-1,time1scounter'length);
	time1spip <= '1';
      else
        time1scounter <= time1scounter - 1;
	time1spip <= '0';
      end if;
    end if;
  end process;
  ---------------------------------------------------------
  -- Handle the ascii commands.
  process(clk_usb48m) begin
    if rising_edge(clk_usb48m) then
      if cmd_datastrb='1' then
        if cmd_addr="0000" then
          chan0_read_addr_flag <= '1';
        else
          chan0_read_addr_flag <= '0';
        end if;
        if cmd_addr="0001" then
          chan0_read_left_flag <= '1';
        else
          chan0_read_left_flag <= '0';
        end if;
        if cmd_addr="0010" then
          chanx_downcounter_set <= cmd_data(chanx_downcounter_set'length-1 downto 0);
        end if;
        if cmd_addr="0011" then
          chanx_rightshift <= cmd_data(chanx_rightshift'length-1 downto 0);
        end if;
        if cmd_addr="0100" then
          dac8step <= cmd_data(dac8step'length-1 downto 0);
        end if;
        if cmd_addr="0101" then -- Strobe lines.
          chanx_hilo_reset    <= cmd_data(0); -- FIXME: Need to cross from CLK_48M to CLK_100M domain.
          trigger_enable      <= cmd_data(1);
          trigger_on_rising   <= cmd_data(2); -- Trigger polarity.
          trigger_manual      <= cmd_data(3); -- FIXME: this should trigger a single capture.
          ep5_trigger_s48     <= cmd_data(4); -- Single pulse at 48MHz clock.
          chanx_cic_write_set <= cmd_data(5);
        else
          --  chanx_hilo_reset <= '0';
          ep5_trigger_s48     <= '0';
          chanx_cic_write_set <= '0';
        end if;
        if cmd_addr="0110" then
          posttrig_initial <= cmd_data(posttrig_initial'length-1 downto 0);
        end if;
      else
        chan0_read_addr_flag <= '0';
        chan0_read_left_flag <= '0';
        ep5_trigger_s48      <= '0';
        chanx_cic_write_set  <= '0';
        --chanx_hilo_reset <= '0';
      end if;
    end if;
  end process;
  ---------------------------------------------------------
  -- Enable the USB port after a fairly long delay.
  process(clk_usb48m) begin
    if rising_edge(clk_usb48m) then
      usb_on_delay <= usb_on_delay+1;              -- Increment counter on every clock.
    end if;

    -- Don't signal our presence until we've had time to set up.
    if(usb_on_delay(18) = '1') then
      c_rst_i <= '1'; -- Un-reset the USB before signaling our presence.
    end if;
    if(usb_on_delay(19) = '1') then
      usb_on_local <= '1';
    end if;
    USB_ON <= usb_on_local;

    if(usb_on_local = '0') then
      led1_local <= usb_on_delay(26);  -- Slow blink.
    else
      -- led1_local <= usb_on_delay(23);  -- Fast blink.
      -- led1_local <= time1scounter(time1scounter'length-1);
      if rising_edge(clk_usb48m) then
        if time1spip='1' then
          led1_local <= not led1_local;
        end if;
      end if;
    end if;
  end process;
  LED1<= led1_local;
  ---------------------------------------------------------
  -- Capture/trigger:
  process(CLK_100M) begin
    if(rising_edge(CLK_100M)) then
      if chanx_cic_write='1' then
        if chanx_posttrig=0 then
          chanx_capcount <= chanx_capcount + 1;
          chanx_cap_done_s100<='1';
        else
          if trigger_enable='1' then
            chanx_posttrig <= chanx_posttrig - 1;
          end if;
          chanx_cap_done_s100<='0';
        end if;
      else
        -- Idling. Wait for trigger.
        if ( trigger_enable and (
             (trigger_on_rising and ( chan0_triggerline and not triggerline_d) ) or
             (not trigger_on_rising and ( not chan0_triggerline and triggerline_d) )
           ) ) = '1'  then
          chanx_posttrig <= posttrig_initial;
        elsif trigger_manual='1' then
          chanx_posttrig <= posttrig_initial;
        end if;
        chanx_cap_done_s100<='0';
      end if;
      triggerline_d <= chan0_triggerline;
    end if;
  end process;
  -- Generate a single-cycle pulse upon completion of every capture.
  -- This pulse triggers a USB interrupt transfer, so it's in the clk_usb48m domain.
  -- p is a single pulse at 100MHz, q is a single pulse at 48MHz.
  -- chanx_cap_done_s100  is p
  -- chanx_cap_done_s48   is q
  -- chanx_cap_done_async is the intermediate value.
  --        100        48
  --       .----.    .----.
  --  p -> |J  Q|--->|D  Q|----> q
  --       | R  |    |    |  |
  --       `----'    `----'  |
  --         ^               |
  --         `---------------'
  process(CLK_100M,clk_usb48m,chanx_cap_done_s100) begin
    if chanx_cap_done_s48='1' then
      chanx_cap_done_async<='0';
    elsif rising_edge(CLK_100M) then
      if chanx_cap_done_s100='1' then
        chanx_cap_done_async<='0';
      end if;
    end if;
    if rising_edge(clk_usb48m) then
        chanx_cap_done_s48<=chanx_cap_done_async;
    end if;
  end process;
  ---------------------------------------------------------
  -- Enable/disable write to RAM. (chanx_cic_write)
  -- Enabled via strobe from the USB command channel.
  -- Disabled when trigger times out.
  -- These are 2 different clock domains, so use
  -- a flipflop with asynchronous set and synchronous clear.
  process(CLK_100M,chanx_cap_done_s100) begin
  if chanx_cic_write_set='1' then
    chanx_cic_write <= '1';
  elsif rising_edge(CLK_100M) and (chanx_cap_done_s100='1') then
    chanx_cic_write <= '0';
  end if;
  end process;
  ---------------------------------------------------------
  -- Generate a test digital sine wave.
  process(CLK_100M,dac8sig) begin
    if(rising_edge(CLK_100M)) then
      dac8sig <= dac8sig + dac8step;
      sinetab_addr1 <= dac8sig(31 downto 21);
      -- sinetab output is 2's complement (-128 to +127), so
      -- flip the sign bit to make unsigned (0 to 255).
      TP9 <=  ( NOT sinetab_data1(7) ) & sinetab_data1(6 downto 0);
    end if;
  end process;
  ---------------------------------------------------------
end rtl;
