/* $Id: usb_readbytes.c,v 1.4 2009/06/17 21:21:58 jrothwei Exp jrothwei $ */
/* Copyright 2009 Joseph Rothweiler **
*************************************/
/* Joseph Rothweiler, Sensicomm LLC. Started 17Mar2009. */
/* Creating a .mex file to open a USB device using libusb.
** Usage:
**   [bytes,err] = usb_readbytes(usbdev,ep,maxcount)
** bytes is a UINT8_T array.
** err is negative on error.
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
		mexErrMsgIdAndTxt("USB:readbytes","Must have 3 arguments");
	}
	if( (nlhs<1)||(nlhs>2) ) {
		mexErrMsgIdAndTxt("USB:readbytes","Must have 1 or 2 returns");
	}

	/**********************************************
	** Check the device. */
	int mrows, ncols;
	k=0;
	if(!mxIsUint64(prhs[k])) {
		mexErrMsgIdAndTxt("USB:readbytes","Argument %d must be Uint64",k+1);
	}
	mrows = mxGetM(prhs[k]);
	ncols = mxGetN(prhs[k]);
	if(mrows!=1 || ncols != 1) {
			mexErrMsgIdAndTxt("USB:readbytes","Argument %d must be scalar",k+1);
	}
	if(mxIsComplex(prhs[k])) {
		mexErrMsgIdAndTxt("USB:readbytes","Argument %d must be noncomplex",k+1);
	}
	struct usb_dev_handle *usbhandle;
	UINT64_T *hvalp;
	hvalp = mxGetData(prhs[k]);
	usbhandle = (struct usb_dev_handle *)(*hvalp);

	/**********************************************
	** Check the endpoint. */
	k=1;
	if(!mxIsNumeric(prhs[k])) {
		mexErrMsgIdAndTxt("USB:readbytes","Argument %d must be numeric",k+1);
	}
	if(mxIsComplex(prhs[k])) {
		mexErrMsgIdAndTxt("USB:readbytes","Argument %d must be noncomplex",k+1);
	}
	mrows = mxGetM(prhs[k]);
	ncols = mxGetN(prhs[k]);
	if(mrows!=1 || ncols != 1) {
			mexErrMsgIdAndTxt("USB:readbytes","Argument %d must be scalar",k+1);
	}
	int ep;
	ep = mxGetScalar(prhs[k]);

	/**********************************************
	** Check the maxbytes value. */
	k=2;
	if(!mxIsNumeric(prhs[k])) {
		mexErrMsgIdAndTxt("USB:readbytes","Argument %d must be numeric",k+1);
	}
	if(mxIsComplex(prhs[k])) {
		mexErrMsgIdAndTxt("USB:readbytes","Argument %d must be noncomplex",k+1);
	}
	mrows = mxGetM(prhs[k]);
	ncols = mxGetN(prhs[k]);
	if(mrows!=1 || ncols != 1) {
			mexErrMsgIdAndTxt("USB:readbytes","Argument %d must be scalar",k+1);
	}
	int maxbytes;
	maxbytes = mxGetScalar(prhs[k]);
	/* FIXME: minimum and maximum maxbytes? */

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
	rtn = usb_bulk_read(usbhandle,ep,(char *)inbytes,maxbytes,10); 
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
