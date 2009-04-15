/* $Id: usb_readbytes.c,v 1.1 2009/04/15 14:57:44 jrothwei Exp jrothwei $ */
/* Copyright 2009 Joseph Rothweiler **
*************************************/
/* Joseph Rothweiler, Sensicomm LLC. Started 17Mar2009. */
/* Creating a .mex file to open a USB device using libusb.
** Usage:
**   bytes = usb_readbytes(usbdev,ep,maxcount)
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
		mexErrMsgTxt("usb_readbytes must have 3 arguments");
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
	** Check the maxbytes value. */
	k=2;
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
	int maxbytes;
	maxbytes = mxGetScalar(prhs[k]);
	/* FIXME: minimum and maximum maxbytes? */

	/**********************************************
	** set up the output value, as a uint8 array.
	*/
	int ndims = 2;
	int dims[2];
	dims[0] = 1;
	dims[1] = maxbytes;
	plhs[0] = mxCreateNumericArray(ndims,dims,mxUINT8_CLASS,mxREAL);
	UINT8_T *bytes;
	bytes = mxGetData(plhs[0]);
	
	int rtn, ngot;
	rtn = usb_bulk_read(usbhandle,ep,bytes,maxbytes,10); 
	if(rtn<0) {
		mexPrintf("read returned %d\n",rtn);
		ngot = 0;
	}else {
		mexPrintf("read %d bytes\n",rtn);
		ngot = rtn;
	}
	// for(k=0;k<ngot;k++) bytes[k] = 0x80+(k%8);

	if(ngot>=0) {
		if(ngot>maxbytes) {
			mexPrintf("read returned %d . max was %d\n",ngot,maxbytes);
		} else if(ngot<maxbytes) {
			dims[1] = ngot;
			void *pr;
			/* Change the dimensions. This doesn't change the allocation. */
			// mxSetDimensions(plhs[0],dims,ndims);
			if(ngot==0) ngot = 1;  /* Avoid possible allocation problems. */
			pr = mxGetPr(plhs[0]);
			// mxRealloc(bytes,ngot*sizeof(*bytes));
			// mxRealloc(pr,ngot*sizeof(*bytes));
		}
	}
}
