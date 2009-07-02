/* $Id: kbhit_nowait.c,v 1.2 2009/07/02 21:37:53 jrothwei Exp $ */
/*************************************/
/* Joseph Rothweiler, Sensicomm LLC. Started 30Mar2009. */
/* This is a patched version of the Octave kbhit() command.
** In many versions of Octave, the builtin command doesn't
** work right on Linux.
** This code is heavily borrowed from src/sysdep.cc
** in the Octave source code.
** Compile with:
** mkoctfile -Wall --mex -o kbhit_nowait.mex kbhit_nowait.c
** Test script keytest.m:
** fprintf(1,'Test: hit any key. End with ctrl-c\n');
** while 1
**   c1 = kbhit_nowait();
**   if(isempty(c1))
**     sleep(0.1);  % Comment this out and CPU usage will be near 100%.
**   else
**     c1
**   end
** end
** Run the script with octave -q -i keytest.m
*/

#include "mex.h"
#include <stdio.h>
#include <usb.h>

#include <termios.h>

#include <sys/ioctl.h>

// Change terminal to "raw mode", or restore to "normal" mode.
// "Raw mode" means 
//	1. An outstanding read will complete on receipt of a single keystroke.
//	2. Input is not echoed.  
//	3. On output, \n is mapped to \r\n.
//	4. \t is NOT expanded into spaces.
//	5. Signal-causing characters such as ctrl-C (interrupt),
//	   etc. are NOT disabled.
// It doesn't matter whether an input \n is mapped to \r, or vice versa.

void
raw_mode (bool on, bool wait)
{
  static bool curr_on = 0;

  int tty_fd = STDIN_FILENO;
  if (! isatty (tty_fd)) {
    mexErrMsgIdAndTxt("patched_kbhit","Input is not a tty.");
  }

  if (on == curr_on) return;

  {
    struct termios s;
    static struct termios save_term;

    if (on)
      {
	// Get terminal modes.
	// mexPrintf("Going raw\n");

	tcgetattr (tty_fd, &s);

	// Save modes and set certain variables dependent on modes.

	save_term = s;
//	ospeed = s.c_cflag & CBAUD;
//	erase_char = s.c_cc[VERASE];
//	kill_char = s.c_cc[VKILL];

	// Set the modes to the way we want them.

	s.c_lflag &= ~(ICANON|ECHO|ECHOE|ECHOK|ECHONL);
	s.c_oflag |=  (OPOST|ONLCR);
#if defined (OCRNL)
	s.c_oflag &= ~(OCRNL);
#endif
#if defined (ONOCR)
	s.c_oflag &= ~(ONOCR);
#endif
#if defined (ONLRET)
	s.c_oflag &= ~(ONLRET);
#endif
	s.c_cc[VMIN] = wait ? 1 : 0;
	s.c_cc[VTIME] = 0;
      }      
    else
      {
	// mexPrintf("Going cooked\n");
	// Restore saved modes.

	s = save_term;
      }

    // tcsetattr (tty_fd, TCSAFLUSH, &s);
    tcsetattr (tty_fd, TCSADRAIN, &s);   // JHR 6/30/09
  }
  curr_on = on;
}
// Read one character from the terminal.
int
patched_kbhit (void)
{
  char c;
  int n;

  // mexPrintf("Starting raw_mode\n");
  raw_mode (1, 0);
  // mexPrintf("In raw_mode\n");

  n=read(STDIN_FILENO,&c,1);
  
  // mexPrintf("Exiting raw_mode\n");
  raw_mode (0,1);
  // mexPrintf("Out raw_mode n=%d c=%d\n",n,c);

  if(n==1) return c;
  else     return -1;
}
/*****************************************************************************/
void mexFunction(
  int nlhs, mxArray *plhs[],
  int nrhs, const mxArray *prhs[]
) {
	if( (nrhs<0) || (nrhs>0) ) {
		mexErrMsgIdAndTxt("patched_kbhit","Must have 0 arguments");
	}
	if( (nlhs<1)||(nlhs>1) ) {
		mexErrMsgIdAndTxt("patched_kbhit","Must have 1 return");
	}

	int ch;
	ch = patched_kbhit();

	/***********************
	 * Return the data.   */

	int ndims = 2;
	mwSize dims[2];
	if(ch<0) {
		dims[0] = 0;
		dims[1] = 0;
	} else {
		dims[0] = 1;
		dims[1] = 1;
	}
	plhs[0] = mxCreateNumericArray(ndims,dims,mxCHAR_CLASS,mxREAL);
	if(ch>=0) {
		char *bytes;
		bytes = mxGetData(plhs[0]);
		*bytes = ch;
	}
}
