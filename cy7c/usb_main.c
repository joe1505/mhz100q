/* $Id: usb_main.c,v 1.2 2009/02/27 20:26:02 jrothwei Exp $ */
/* Joseph Rothweiler, Sensicomm LLC. Started 16Feb2009. */
/* http://www.sensicomm.com
**
** Copyright 2009 Joseph Rothweiler
**
** This program is free software: you can redistribute it and/or modify
** it under the terms of the GNU General Public License as published by
** the Free Software Foundation, either version 3 of the License, or
** (at your option) any later version.
**
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program.  If not, see <http://www.gnu.org/licenses/>.
******************************************************************************/
/* Setting up the CY7c68013A on the Digilent Nexys2 FPGA board.
** Designed to compile using SDCC (sdcc.sourceforge.net)
** fx2regs.h and delay.h are from fx2lib (fx2lib.wiki.sourceforge.net)
*/

#include "fx2regs.h"
#include "delay.h"

#define SYNCDELAY SYNCDELAY4

void td_init(void);

int main() {
	USBCS |= bmDISCON;      /* Disconnect. */
	USBCS &= ~(bmRENUM);    /* Stay in default configuration. */

	/* Setting up the FIFO's. */

	td_init();

	USBCS &= ~(bmDISCON);   /* Reconnect. */

	/* EP2 and EP6 are the workhorse endpoints. */
	
	/* p. 116:
	 * IFCONFIG       - NT R OE NG A G M1 M0
	 *                   1 1  1  0 1 0 1   1
	 *                  NT:  - 1: Internal IFCLK, 0: External IFCLK.
	 *                  R:   - Internal IFCLK is 30(0) or 48(1) MHz.
	 *                  OE:  - IFCLK Output Enable.
	 *                  NG:  - Negate IFCLK.
	 *                  A    - FIFO Asynch mode.
	 *                  G    - Gstate (1 is for debugging only).
	 *                  M1:0 - Mode. 0:Ports 1:XXX 2:GPIF 3:FIFO.
	 * PINFLAGSAB - B3 B2 B1 B0 A3 A2 A1 A0
	 * PINFLAGSCD - D3 D2 D1 D0 C3 C2 C1 C0
	 * For each of the 4:
	 *  1:0 Selects the endpoint 0:EP2 1:EP4 2:EP6 3:EP8
	 *  3:2 Selects the condition 0: Reserved 1:P 2:E 3:F
	 *  All 0000 for Select by FADDR pins: FLAGA:P FLAGB:F FLAGC:E.
	 * FIFORESET  - NAK 0 0 0 N3 N2 N1 N0
	 *  Set nak bit, set N3:0 to 2,4,6 or 8, clear nak bit.
	 * FIFOPINPOLAR - 0 0 PKTEND SLOE SLRD SLWR EF FF
	 * Set 1 to Make the pin active-high.  What about PF???
	 * EPxCFG         - VALID DIR TYPE1 TYPE0 SIZE 0 BUF1 BUF0
	 *                - VALID: 1 to activate
	 *                - DIR: 0:OUT (from host) 1:IN (to host)
	 *                - TYPE: 0:XX 1:ISO 2:BULK 3:INT
	 *                -- SIZE and BUF on EP2 and EP6 only.
	 *                - SIZE: 0:512 1:1024
	 *                - BUF: 00:Quad 01:XX 10:Double  11:Triple
	 * EPxFIFOCFG  - 0 INFM1 OEP1 AUTOOUT AUTOIN ZEROLENIN 0 WORDWIDE
	 *             - INFM1, OEP1: Change synchronous timing.
	 *             - AUTOOUT, AUTOIN: Automatically move packets (See EP.AUTOINLEN).
	 *             - ZEROLENIN - Allow PKTEND to send 0-length packets.
	 *             - WORDWIDE: 1: 16 bits.
	 * EXxAUTOINLENH:L - When to trigger a packet. Should be <= buffer len.
	 * EPxFIFOPFH:L - DECIS PKTSTAT X X X PF9 X PF8 // PF7 PF6 Pf5 PF4 PF3 PF2 PF1 PF0
	 * 	        - Trigger level for the Programmable flag (PF) pin.
	 * 	        - DECIS: PF high when count <= val(0) or >= val(1).
	 * 	        - Other pins depend on buf size, speed, etc.
	 * PORTACFG :   FLAGD SLCS  0 0  0 0 INT1 INT0
	 *              FLAGD: 1: PA7 is FLAGD.
	 *              SLCS:  1: PA7 is SLCS.
	 *              INT1:0 : PA1:0 as interrupt pins.
	 * INPKTEND : SKIP 0 0 0 N3 N2 N1 N0
	 * OUTPKTEND : SKIP 0 0 0 N3 N2 N1 N0
	 *            Force end of packet on endpoint N (2,4,6,8) SKIP skips the packet.
	 * EPxFIFOIE
	 * EPxFIFOIRQ
	 * EPxFIFOBCH:L - Read current fifo byte count.
	 * EPxFLAGS - 0 0 0 0 0 PF EF FF
	 * EP{2,4,6,8}FIFOBUF - To access the buffers.
	 *
	 * REVCTL - 0 0 0 0 0 0 A B
	 *          A,B must be 1 for FIFO's.
	 */

	return 0;
}
void td_init(void) {
	/* Example from ref manual */
	IFCONFIG = 0xeb;   /* Internal clock, FIFO mode. */
	SYNCDELAY;
	REVCTL = 0x03;
	SYNCDELAY;
	EP2CFG = 0xa2;  /* Out, bulk, 512, 2x */
	SYNCDELAY;
	FIFORESET = 0x80; /* Set NAK's to everything. */
	SYNCDELAY;
	FIFORESET = 0x82; /* Reset EP2. */
	SYNCDELAY;
	FIFORESET = 0x00; /* un-NAK. */
	SYNCDELAY;
	OUTPKTEND = 0x82; /* Arm both EP2 buffers to "prime the pump." */
	SYNCDELAY;
	OUTPKTEND = 0x82; /* Arm both EP2 buffers to "prime the pump." */
	SYNCDELAY;
	EP2FIFOCFG = 0x10; /* Autoout = 1, autoin = 0, zerolen = 0, wordwide = 0 */
	SYNCDELAY;

	EP6CFG = 0xe2;  /* In, bulk, 512, 2x */
	SYNCDELAY;
	FIFORESET = 0x80; /* NAK's. */
	SYNCDELAY;
	FIFORESET = 0x82; /* Reset. */
	SYNCDELAY;
	FIFORESET = 0x84; /* Reset. */
	SYNCDELAY;
	FIFORESET = 0x86; /* Reset. */
	SYNCDELAY;
	FIFORESET = 0x88; /* Reset. */
	SYNCDELAY;
	FIFORESET = 0x00; /* un-NAK */
	SYNCDELAY;
	EP6FIFOCFG = 0x0C; /* Autoout = 0, autoin = 1, zerolen = 1, wordwide = 0 */
	SYNCDELAY;
	PINFLAGSAB = 0x00; /* A prog=level, B full, C empty */
	SYNCDELAY;
	PINFLAGSCD = 0x00; /* A prog=level, B full, C empty */
	SYNCDELAY;
	PORTACFG = 0x00;  /* PA7 is port, not fifo pin. */
	SYNCDELAY;
	FIFOPINPOLAR = 0x3f;  /* All active high. */
	SYNCDELAY;
	EP6AUTOINLENH = 0x02;  /* Autocommit 512-byte pkts. */
	SYNCDELAY;
	EP6AUTOINLENL = 0x00;
	SYNCDELAY;
	EP6FIFOPFH = 0x80;  /* FLAGA level. */
	SYNCDELAY;
	EP6FIFOPFL = 0x00;

	SYNCDELAY;
}
