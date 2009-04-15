/* $Id: usb_opendev.c,v 1.1 2009/04/15 14:57:40 jrothwei Exp jrothwei $ */
/* Copyright 2009 Joseph Rothweiler **
*************************************/
/* Joseph Rothweiler, Sensicomm LLC. Started 17Mar2009. */
/* Creating a .mex file to open a USB device using libusb.
** Usage:
**   usbdev = usb_opendev(mfr,dev,serno)
**  mfr, dev, and serno default to 0.
** Note: mfr and dev are integers.
** serno needs to be a character string.
**
** usbdev returns an integer value, which is the pointer.
*/

#include "mex.h"
#include <stdio.h>
#include <usb.h>


static void initialize(void) {
	/* Initialize libusb. */
	usb_init();
	/* usb_set_debug(1);*/
	usb_find_busses();
	usb_find_devices();
}
static struct usb_device *findvps(int vend,int prod, int ixx,int *numdev) {
	/* Search for the first device with the specified
	** Vendor and Product ID's. */
	int numfound;
	struct usb_bus *bus;
	struct usb_device *thedev;

	numfound = 0;
	thedev = (struct usb_device *)0;
	for(bus = usb_get_busses();bus ; bus = bus->next) {
    		struct usb_device *dev;
		for( dev = bus->devices ; dev ; dev = dev->next ) {
			int match;
			match = 1;
			if( (vend!=0) && ( vend!=dev->descriptor.idVendor)  ) match = 0;
			if( (prod!=0) && ( vend!=dev->descriptor.idProduct) ) match = 0;
			/* FIXME: add serial number search. */
			if( dev->descriptor.idVendor == 0x0547 &&
			    dev->descriptor.idProduct == 0x2131 ) {
				if(numfound==0) thedev = dev;
				numfound++;
			}
		}
	}
	*numdev = numfound;
	return thedev;
}
static struct usb_dev_handle *openinterface(struct usb_device *thedev, int altif) {
	struct usb_dev_handle *usbhandle;
	int n, k;
	mexPrintf("Opening handle\n");
	usbhandle = usb_open( thedev );
	mexPrintf("handle 0x%x\n",(UINT32_T)usbhandle);
	n = usb_set_configuration(usbhandle,1);
	if(n<0) {
		mexPrintf("usb_set_configuration failed\n");
		usb_close(usbhandle);
		usbhandle = (struct usb_dev_handle *)0;
	} else n = usb_claim_interface(usbhandle,0);
	if(n<0) {
		mexPrintf("usb_claim_interface failed\n");
		usb_close(usbhandle);
		usbhandle = (struct usb_dev_handle *)0;
	} else if(altif>=0) {
		n = usb_set_altinterface(usbhandle,altif);
		if(n<0) {
			mexPrintf("usb_set_altinterface failed\n");
			/* FIXME: This is a problem. Needs a warning. */
		}
	}
	return usbhandle;
}
void mexFunction(
  int nlhs, mxArray *plhs[],
  int nrhs, const mxArray *prhs[]
) {
	int k;

	/* nrhs can be 0 through 3. */
	if(nrhs>3) mexErrMsgTxt("Too many inputs");
	if(nlhs<1) mexErrMsgTxt("Need at least 1 output");

	for(k=0;k<(nrhs>3?3:nrhs);k++) {
		int mrows, ncols;
		mrows = mxGetM(prhs[k]);
		ncols = mxGetN(prhs[k]);
		if(mrows!=1 || ncols != 1) {
			char tmp[40];
			sprintf(tmp,"Arg %d must be scalar",k+1);
			mexErrMsgTxt(tmp);
		}
		if(mxIsComplex(prhs[0])) {
			char tmp[40];
			sprintf(tmp,"Arg %d must be non-complex",k+1);
			mexErrMsgTxt(tmp);
		}
		if(!mxIsDouble(prhs[0])) {
			char tmp[40];
			sprintf(tmp,"Arg %d must be double",k+1);
			mexErrMsgTxt(tmp);
		}
	}
	int imfr, idev, ixxx;
	/* All have been checked to be numeric, scalar, noncomplex. */
	imfr = idev = ixxx = 0;
	if(nrhs>=1) imfr=mxGetScalar(prhs[0]);
	if(nrhs>=2) idev=mxGetScalar(prhs[1]);
	if(nrhs>=3) ixxx=mxGetScalar(prhs[2]);
	mexPrintf("Seeking mfr 0x%x dev 0x%x 0x%x\n",
		imfr,idev,ixxx);

	initialize();

	struct usb_device *thedev;
	int numdev;
	thedev = findvps(imfr, idev,ixxx,&numdev) ;
	if(numdev==0) {
		char tmp[40];
		sprintf(tmp,"USB device 0x%x 0x%x 0x%x not found\n",
			imfr,idev,ixxx);
		mexErrMsgTxt(tmp);
	} else if(numdev > 1) {
		mexWarnMsgTxt("Multiple devices found. Using the first one.\n");
	}

	static struct usb_dev_handle *devhandle;
	devhandle = openinterface(thedev, 1) ;
	if(devhandle == 0) {
		mexErrMsgTxt("Trouble opening USB device.\n");
	}

	/* Return the handle cast to a 64-bit integer value.
	** This is nonportable, but should work on most systems.
	*/

	int ndims = 1;
	int dims[1] = {1};
	UINT64_T *val;
	plhs[0] = mxCreateNumericArray(ndims,dims,mxUINT64_CLASS,mxREAL);
	val = mxGetData(plhs[0]);
	if(nlhs>1) {
		plhs[1] = 0;
	}

	*val = (UINT64_T)devhandle;
}
