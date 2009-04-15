/* $Id: usb_writestring.c,v 1.1 2009/04/15 14:57:48 jrothwei Exp jrothwei $ */
/* Copyright 2009 Joseph Rothweiler **
*************************************/
/* Joseph Rothweiler, Sensicomm LLC. Started 17Mar2009. */
/* Creating a .mex file to open a USB device using libusb.
** Usage:
**   usbdev = usb_writestring(usbdev,ep,string)
** usbdev returns an integer value, which is the pointer.
*/

#include "mex.h"
#include <stdio.h>
#include <usb.h>

void mexFunction(
  int nlhs, mxArray *plhs[],
  int nrhs, const mxArray *prhs[]
) {
	int k;

	if(nrhs!=3) {
		mexErrMsgTxt("usb_writestring must have 3 arguments");
	}

	/**********************************************
	** Check the device. */
	int mrows, ncols;
	k=0;
	mrows = mxGetM(prhs[k]);
	ncols = mxGetN(prhs[k]);
	if(mrows!=1 || ncols != 1) {
			mexPrintf("Argument %d bad.",k+1);
			mexErrMsgTxt("Must be scalar");
	}
	if(mxIsComplex(prhs[k])) {
		mexPrintf("Argument %d bad.",k+1);
		mexErrMsgTxt("Must be noncomplex");
	}
	if(!mxIsUint64(prhs[k])) {
		mexPrintf("Argument %d bad.",k+1);
		mexErrMsgTxt("Must be Uint64");
	}
	struct usb_dev_handle *usbhandle;
	UINT64_T *hvalp;
	hvalp = mxGetData(prhs[k]);
	usbhandle = (struct usb_dev_handle *)(*hvalp);

	/**********************************************
	** Check the endpoint. */
	k=1;
	mrows = mxGetM(prhs[k]);
	ncols = mxGetN(prhs[k]);
	if(mrows!=1 || ncols != 1) {
			mexPrintf("Argument %d bad.",k+1);
			mexErrMsgTxt("Must be scalar");
	}
	if(mxIsComplex(prhs[k])) {
		mexPrintf("Argument %d bad.",k+1);
		mexErrMsgTxt("Must be noncomplex");
	}
	if(!mxIsNumeric(prhs[k])) {
		mexPrintf("Argument %d bad.",k+1);
		mexErrMsgTxt("Must be numeric");
	}
	int ep;
	ep = mxGetScalar(prhs[k]);

	/**********************************************
	** Check and extract the string. Tricky:
	** Matlab uses 16-bit chars (UTF-16, with only
	** the 16-bit chars allowed? Essentially UCS-2? )
	** FIXME: mxChar is 8 bits in Octave, 16 bits in Matlab.
	*/
	k=2;
	mrows = mxGetM(prhs[k]);
	ncols = mxGetN(prhs[k]);
	mexPrintf("rows %d cols %d\n",mrows,ncols);
	mxChar *mxch;
	mxch = mxGetChars(prhs[k]);
	mexPrintf("size of mxChar is %d vs char %d\n",sizeof(mxChar),sizeof(char));
	int p;
	if(mxch==0) mexPrintf("mxch is NULL\n");
	else {
		for(p=0;p<mrows*ncols;p++) mexPrintf("%d %4.4x %c %lc\n",
			p,mxch[p],mxch[p],mxch[p]);
	}
	if(mrows!=1) {
		mexErrMsgTxt("usb_writestring: can only handle 1-row character arrays");
	}
	char *str;
	str = mxCalloc(ncols+1,sizeof(char));
	if(str==NULL) {
		mexErrMsgTxt("usb_writestring: Trouble allocating internal memory");
	}
	/* Copy, possibly with a lossy conversion from 16 to 8 bits. */
	for(p=0;p<ncols;p++) str[p] = mxch[p];
	str[p] = '\0';  /* Not needed. */
	mexPrintf("handle %x ep %d %x Output string %s\n",
		usbhandle,ep,ep, str);
	int rtn;
	rtn = usb_bulk_write(usbhandle,0x02,str,ncols,10); 

	int ndims = 1;
	int dims[1] = {1};
	double *val;
	plhs[0] = mxCreateNumericArray(ndims,dims,mxDOUBLE_CLASS,mxREAL);
	val = mxGetData(plhs[0]);
	if(nlhs>1) {
		plhs[1] = 0;
	}

	*val = rtn;
}
