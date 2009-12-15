/* $Id: usb_readbytes.c,v 1.6 2009/12/15 16:22:10 jrothwei Exp $ */
/* Copyright 2009 Joseph Rothweiler **
*************************************/
/* Joseph Rothweiler, Sensicomm LLC. Started 17Mar2009. */
/* Creating a .mex file to open a USB device using libusb.
** Usage:
**   [bytes,err] = usb_readbytes(usbdev,ep,maxcount[,timeout[,do_int]])
** bytes is a UINT8_T array.
** err is negative on error.
*/

#include "mex.h"
#include <stdio.h>
#include <usb.h>

static double scalarcheck(
  const mxArray *matval,  /* The input array to check. */
  const int k,            /* Argument number, for debugging. */
  const int mytype        /* 0: numeric, 1: for usb_dev_handle. */
) {
	int mrows, ncols;

	if(mytype == 0) {
		if(!mxIsNumeric(matval)) {
			mexErrMsgIdAndTxt("USB:writestring","Argument %d must be numeric",k+1);
		}
	} else {
		if(!mxIsUint64(matval)) {
			mexErrMsgIdAndTxt("USB:writestring","Argument %d must be Uint64",k+1);
		}
	}
	if(mxIsComplex(matval)) {
		mexErrMsgIdAndTxt("USB:writestring","Argument %d must be noncomplex",k+1);
	}
	mrows = mxGetM(matval);
	ncols = mxGetN(matval);
	if(mrows!=1 || ncols != 1) {
			mexErrMsgIdAndTxt("USB:writestring","Argument %d must be scalar",k+1);
	}
	return mxGetScalar(matval);
}
/*****************************************************************************/
void mexFunction(
  int nlhs, mxArray *plhs[],
  int nrhs, const mxArray *prhs[]
) {
	int k;

	if( (nrhs<3) || (nrhs>5) ) {
		mexErrMsgIdAndTxt("USB:readbytes","Must have 3 to 5 arguments");
	}
	if( (nlhs<1)||(nlhs>2) ) {
		mexErrMsgIdAndTxt("USB:readbytes","Must have 1 or 2 returns");
	}

	/**********************************************
	** Check the device. */
	k=0;
	struct usb_dev_handle *usbhandle;
	UINT64_T hval;
	hval = scalarcheck(prhs[k],k,1);
	usbhandle = (struct usb_dev_handle *)(hval);

	/**********************************************
	** Check the endpoint. */
	k=1;
	int ep;
	ep = scalarcheck(prhs[k],k,0);

	/**********************************************
	** Check the maxbytes value. */
	k=2;
	int maxbytes;
	maxbytes = scalarcheck(prhs[k],k,0);
	/* FIXME: minimum and maximum maxbytes? */

	/**********************************************
	** Check the delay value. */

	int usbtimeout = 10;
	if(nrhs > 3) {
		k=3;
		usbtimeout = scalarcheck(prhs[k],k,0);
	}
	// mexPrintf("Setting timeout to %d ms\n",usbtimeout);

	/**********************************************
	** Check the bulk/int flag. */

	int do_int = 0;
	if(nrhs > 4) {
		k=4;
		do_int = scalarcheck(prhs[k],k,0);
	}
	if( (do_int!=0) && (do_int!=1) ) {
		mexErrMsgIdAndTxt("USB:readbytes","Read type is %d. Must be 0(bulk) or 1(int)",do_int);
	}

	/**********************************************
	** set up the output value, as a uint8 array.
	** FIXME: should I change to INT8 (or make it an option?)
	*/
	UINT8_T *inbytes;
	inbytes = mxCalloc(maxbytes>0?maxbytes:1,sizeof(*inbytes));
	if(inbytes==NULL) {
		mexErrMsgIdAndTxt("USB:readbytes","trouble allocating %d bytes",maxbytes);
	}

	/*************************
	 * Do the read.         */

	int rtn, ngot;
	if(do_int==0) {
		rtn = usb_bulk_read(usbhandle,ep,(char *)inbytes,maxbytes,usbtimeout);
	} else {
		rtn = usb_interrupt_read(usbhandle,ep,(char *)inbytes,maxbytes,usbtimeout);
	}
	if(rtn<0) {
		// mexPrintf("read returned %d\n",rtn);
		ngot = 0;
	} else {
		// mexPrintf("read %d bytes\n",rtn);
		ngot = rtn;
	}

	/***********************
	 * Return the data.   */

	int ndims = 2;
	mwSize dims[2];
	// dims = (mwSize *) mxMalloc (ndims * sizeof(mwSize));
	if(ngot==0) {
		dims[0] = 0;
		dims[1] = 0;
	} else {
		dims[0] = 1;
		dims[1] = ngot;
	}
	plhs[0] = mxCreateNumericArray(ndims,dims,mxUINT8_CLASS,mxREAL);
	UINT8_T *bytes;
	bytes = mxGetData(plhs[0]);
	for(k=0;k<ngot;k++) bytes[k] = inbytes[k];
	mxFree(inbytes);
	// for(k=0;k<ngot;k++) bytes[k] = 0x80+(k%8);

	if(nlhs>1) {
		dims[0] = dims[1] = 1;
		double *dval;
		plhs[1] = mxCreateNumericArray(ndims,dims,mxDOUBLE_CLASS,mxREAL);
		dval = mxGetData(plhs[1]);
		*dval = rtn;
	} else if(rtn < 0) {
		/* -110 is a timeout. That's not really an error. */
		if(rtn != -110) mexErrMsgIdAndTxt("USB:readbytes",
			"trouble reading %d bytes. Error %d",maxbytes,rtn);
	}
}
