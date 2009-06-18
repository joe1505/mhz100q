/* $Id: usb_opendev.c,v 1.7 2009/06/17 18:11:08 jrothwei Exp $ */
/* Copyright 2009 Joseph Rothweiler **
*************************************/
/* Joseph Rothweiler, Sensicomm LLC. Started 17Mar2009. */
/* Creating a .mex file to open a USB device using libusb.
** Usage:
**   [usbdev,errmsg] = usb_opendev(mfr,dev,serno)
**  mfr, dev, and serno default to 0.
** Note: mfr and dev are integers.
** serno needs to be a character string.
** 
** Normal return:
** usbdev contains an integer value, which is the
** USB device handle.
** errmsg is a zero-length string.
**
** Errors;
** Calling errors (eg, bad arguments) cause an error
** condition - Call to mexErrMsgTxt, which stops
** the program.
** Runtime errors (device not found, etc):
** usbdev is a zero-length matrix, and errmsg contains
** a string describing the error. If errmsg is not
** specified, mexErrMsgTxt is called.
**
** History
** 2009-03-17: Started
** 2009-06-17: Bug fixes, general cleanup, better error handling.
*/

#include "mex.h"
#include <stdio.h>
#include <usb.h>

static int initialize(int dbg) {
	int n;
	/* Initialize libusb. */
	usb_init();
	if(dbg&1) usb_set_debug(1);
	n=usb_find_busses();
	if(n<0) return n;
	n=usb_find_devices();
	if(n<0) return n;
	return 1;
}
static struct usb_device *findvps(int vend,int prod, char *serno,int *numdev) {
	/* Search for the first device with the specified
	** Vendor, Product ID, and/or Serial Number. */
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
			if( (vend>=0) && ( vend!=dev->descriptor.idVendor)  ) match = 0;
			if( (prod>=0) && ( prod!=dev->descriptor.idProduct) ) match = 0;
			// mexPrintf("***** Searching: match %d serno %s\n",match,serno);
			if( match && (serno!=NULL) && (serno[0]!='\0') ) {
				char str[16];
				if (dev->descriptor.iSerialNumber) {
					int ret;
					usb_dev_handle *han;
					han = usb_open(dev);
					if(han < 0) {
						mexPrintf("Can't open device\n");
					} else {
						ret = usb_get_string_simple(han,
							dev->descriptor.iSerialNumber,
							str, 16);
						if (ret > 0) mexPrintf("- Serial Number: %s\n", str);
						else mexPrintf("Unable to fetch serial number\n");
						ret=usb_close(han);
						if(ret<0) {
							mexPrintf("Trouble closing device\n");
						}
					}
				} else mexPrintf("No serial number\n");
			}
			if( match ) {
				if(numfound==0) thedev = dev;
				numfound++;
			}
		}
	}
	*numdev = numfound;
	return thedev;
}
static struct usb_dev_handle *openinterface(
  char *errstr,
  int errlen,
  struct usb_device *thedev,
  int altif) {
	struct usb_dev_handle *usbhandle;
	int n;
	int confignum = 1; /* 1 for fx2. Cfg# nearly always 1: /proc/bus/usb/devices */
	int intfcnum  = 0; /* Nearly always 0. A few devices have multiple: not handled yet. */

	errstr[0] = '\0';
	// mexPrintf("Opening handle\n");
	usbhandle = usb_open( thedev );
	// mexPrintf("handle 0x%x\n",(UINT32_T)usbhandle);
	if(usbhandle == NULL) {
		snprintf(errstr,errlen,"usb_open failed");
		return usbhandle;
	}
	if(confignum>=0) n = usb_set_configuration(usbhandle,confignum);
	else             n = 0;
	if(n<0) {
		snprintf(errstr,errlen,"usb_set_configuration %d failed",confignum);
		usb_close(usbhandle);
 		// mexPrintf("Device closed\n");
		usbhandle = (struct usb_dev_handle *)0;
	} else {
		n = usb_claim_interface(usbhandle,intfcnum);
		if(n<0) {
			snprintf(errstr,errlen,"usb_claim_interface %d failed\n",intfcnum);
			usb_close(usbhandle);
			// mexPrintf("Device closed\n");
			usbhandle = (struct usb_dev_handle *)0;
		} else if(altif>=0) {
			n = usb_set_altinterface(usbhandle,altif);
			if(n<0) {
				snprintf(errstr,errlen,"usb_set_altinterface %d failed\n",altif);
				usb_close(usbhandle);
				// mexPrintf("Device closed\n");
				usbhandle = (struct usb_dev_handle *)0;
			}
		}
	}
	return usbhandle;
}
/****************************************************************
** Handle an argument that must be a single number.            **
** Return values are:                                          **
**  0 : zero-length array.                                     **
**  1 : Good. *dblval returns the number, converted to double. **
** <0 : Bad value.                                             **
****************************************************************/
int mex_isreal1(const mxArray *mxa, double *dblval) {
	mxClassID mid;
	int itsgood;
	double val;
	int rtn;

	rtn = -1;
	val = 0.0;

	/* Test: Is it a class I can handle? */
	mid = mxGetClassID(mxa);
	itsgood = 1;
	switch(mid) {
	case mxDOUBLE_CLASS :
	case mxSINGLE_CLASS :
	case mxINT8_CLASS   :
	case mxUINT8_CLASS  :
	case mxINT16_CLASS  :
	case mxUINT16_CLASS :
	case mxINT32_CLASS  :
	case mxUINT32_CLASS :
	case mxINT64_CLASS  :
	case mxUINT64_CLASS :
		break;
	default:
		itsgood = 0;
		rtn = -2;
	}
	/* Must be noncomplex, nonsparse. */
	if(itsgood && mxIsComplex(mxa)) {
		itsgood = 0;
		rtn = -3;
	}
	if(itsgood && mxIsSparse(mxa)) {
		itsgood = 0;
		rtn = -4;
	}
	/* Must be a scalar - ie, 1x1 matrix. */
	if(itsgood) {
		int ndim;
		const int *dims;
		int p;
		ndim = mxGetNumberOfDimensions(mxa);
		dims = mxGetDimensions(mxa);
		for(p=0;p<ndim;p++) {
			if(dims[p]==0) {
				itsgood = 0;
				rtn = 0;    /* zero-length array. */
				break;
			}
			if(dims[p]!=1) {
				itsgood = 0;
				rtn = -5;  /* Length > 1 */
				break;
			}
		}
	}
	/* Done, convert the value to a double. */
	if(itsgood) {
		void *datap;
		rtn = 1;    /* The value is good. */
		datap = mxGetData(mxa);
		switch(mid) {
		case mxDOUBLE_CLASS : val = *( (double *)datap);
			break;
		case mxSINGLE_CLASS : val = *( (float *)datap);
			break;
		case mxINT8_CLASS   : val = *( (INT8_T *)datap);
			break;
		case mxUINT8_CLASS  : val = *( (UINT8_T *)datap);
			break;
		case mxINT16_CLASS  : val = *( (INT16_T *)datap);
			break;
		case mxUINT16_CLASS : val = *( (UINT16_T *)datap);
			break;
		case mxINT32_CLASS  : val = *( (INT32_T *)datap);
			break;
		case mxUINT32_CLASS : val = *( (UINT32_T *)datap);
			break;
		case mxINT64_CLASS  : val = *( (INT64_T *)datap);
			break;
		case mxUINT64_CLASS : val = *( (UINT64_T *)datap);
			break;  /* FIXME: This could be a loss of precision. */
		default:
			rtn = -7; /* FIXME: This should never happen. */
		}
	} 
	// mexPrintf("mex_isreal1 returning %d val %g\n",rtn,val);
	*dblval = val;
	return rtn;
}
/**************************************************************
** Convert a scalar to int, and be sure it's UINT16_T range. **
** Returns:                                                  **
** 0-65535 : Good values.                                    **
**  -1     : NULL.                                           **
** <-1     : Error.                                          */
int mex_to_16b(const mxArray *mxa) {
	double dblval;
	int rtn;
	int n;
	n = mex_isreal1(mxa,&dblval);
	if(n>=1) {  /* It's a numeric scalar. */
		if( (dblval >= 0) && (dblval <= 65535) ) {
			rtn = dblval;
		} else {
			rtn = -6; /* Bad value. */
		}
	} else if(n==0) { /* value not specified. */
		rtn = -1;
	} else {
		rtn = n; /* Bad value. */
	}
	return rtn;
}
/*****************************************************************************/
static void errorcheck(int val, char *id) {
	static char *ErrId = "USB:opendev"; /* Seen with Octave lasterror()  */
	if(val >= -1) return;
	switch(val) {
	case -2:
		mexErrMsgIdAndTxt(ErrId,"Argument %s error %d:non-numeric\n",id,val);
		break;
	case -3:
		mexErrMsgIdAndTxt(ErrId,"Argument %s error %d:complex\n",id,val);
		break;
	case -4:
		mexErrMsgIdAndTxt(ErrId,"Argument %s error %d:sparse\n",id,val);
		break;
	case -5:
		mexErrMsgIdAndTxt(ErrId,"Argument %s error %d:must be scalar\n",id,val);
		break;
	case -6:
		mexErrMsgIdAndTxt(ErrId,"Argument %s error %d: must be 0 to 65535\n",id,val);
		break;
	case -7:
		mexErrMsgIdAndTxt(ErrId,"Argument %s error %d:sparse\n",id,val);
		break;
	default:
		mexErrMsgIdAndTxt(ErrId,"Argument %s error %d: undefined\n",id,val);
		break;
	}
}
/*****************************************************************************/
void mexFunction(
  int nlhs, mxArray *plhs[],
  int nrhs, const mxArray *prhs[]
) {
	int imfr, idev;
	char *serno_str = NULL;
	int ialt;
	int errlev = 0;

	if((nlhs<1)||(nlhs>2)) mexErrMsgTxt("Need 1 or 2 outputs");

	/* Process the Manufacturer code. */
	if(nrhs>=1) imfr = mex_to_16b(prhs[0]) ;
	else        imfr = -1; /* value not specified. */
	errorcheck(imfr,"MFRcode");

	/* Process the Device code. */
	if(nrhs>=2) idev = mex_to_16b(prhs[1]) ;
	else        idev = -1; /* value not specified. */
	errorcheck(idev,"DeviceID");

	/* Process the serial number string. */
	if(nrhs>=3) {
		const int *dims;
		if(!mxIsChar(prhs[2])) {
			mexErrMsgIdAndTxt("USB:open","Serial number must be a string\n");
		}
		if(mxGetNumberOfDimensions(prhs[2])!=2) {
			mexErrMsgIdAndTxt("USB:open","Serial number must be a string vector\n");
		}
		dims = mxGetDimensions(prhs[2]);
		if(dims[0]==0) {
			serno_str = NULL;
		} else if(dims[0]==1) {
			size_t buflen;
			buflen = (dims[0]*dims[1])*sizeof(mxChar) + 1;
			serno_str = mxCalloc(buflen,sizeof(char));
			if(serno_str==NULL) {
				mexErrMsgIdAndTxt("USB:open","MxCalloc problem for serial number.\n");
			} else {
				mxGetString(prhs[2],serno_str,buflen);
			}
		} else {
			mexErrMsgIdAndTxt("USB:open","Serial number must be a single string\n");
		}
	} else {
		serno_str = NULL;
	}

	/* Process the altif number. */
	if(nrhs>=4) ialt = mex_to_16b(prhs[3]) ;
	else        ialt = -1; /* value not specified. */

	/* Process the error level. */
	if(nrhs>=5) errlev = mex_to_16b(prhs[4]) ;
	else        errlev = -1; /* value not specified. */

	if(errlev == -1) errlev = 0; /* No value specified becomes 0 in this case. */

	// mexPrintf("Seeking mfr 0x%x dev 0x%x serial \"%s\" config 0x%x errlev 0x%x\n",
	// 	imfr,idev,serno_str,ialt,errlev);
	
	if(errlev>= 0xffff) return;  /* Debugging option. */

	if( (imfr == -1) && (idev == -1) ) {
		mexErrMsgIdAndTxt("USB:open","Must specify at least 1 of mfr and device.\n");
	}

	/**********************************************************
	 * Done processing the args. Find the specified device.  */

	int rtn;
	char errorstring[200];
	errorstring[0]='\0';
	rtn = initialize(errlev);
	// mexPrintf("initialize returned %d\n",rtn);
	if(rtn < 0) {
		snprintf(errorstring,200,"Trouble accessing USB bus.");
	}

	struct usb_device *thedev;
	int numdev;
	thedev = findvps(imfr, idev,serno_str,&numdev) ;
	// mexPrintf("findvps numdev %d thedev %d\n",numdev,thedev);
	if(numdev==0) {
		snprintf(errorstring,200,"USB device 0x%x 0x%x %s not found.",
			imfr,idev,serno_str);
	} else if(numdev > 1) {
		mexWarnMsgTxt("Multiple devices found. Using the first one.\n");
	}

	UINT64_T inthandle = 0;
	if(errorstring[0]=='\0') {
		static struct usb_dev_handle *devhandle, *dummyhandle;
		devhandle = openinterface(errorstring,200,thedev, ialt) ;
		// mexPrintf("Handle: %d 0x%x\n",devhandle,devhandle);
		if(errorstring[0]=='\0') {
			/* Return the handle cast to a 64-bit integer value.     **
			** This is nonportable, but should work on most systems. */
			/* With GCC on 32-bit system, expect:                         **
			** warning: cast to/from pointer to integer of different size */
			inthandle = (UINT64_T)devhandle;
			dummyhandle = (struct usb_dev_handle *)inthandle;
			/* Check. */
			if(dummyhandle != devhandle) {
				mexErrMsgIdAndTxt("USB:open",
					"Internal error: bad usb device handle.\n");
				/* If this error happens, the devhandle pointer
				 * isn't being represented correctly as a 64-bit
				 * integer. Need to look at the internals and change
				 * to something else. */
			}
		}
	}

	// mexPrintf("Done. errorstring \"%s\"\n",errorstring);
	if(errorstring[0]!='\0') {
		int ndims = 2;
		int dims[2] = {0,0};
		/* Return the handle. */
		plhs[0] = mxCreateNumericArray(ndims,dims,mxUINT64_CLASS,mxREAL);
		if(plhs[0]==NULL) {
			mexErrMsgIdAndTxt("USB:open","Internal error: Can't create numeric array.\n");
		}
		/* return the error string. */
		if(nlhs>1) {
			plhs[1] = mxCreateString(errorstring);
			if(plhs[1]==NULL) {
				mexErrMsgIdAndTxt("USB:open","Internal error: Can't create string.\n");
			}
		} else {
			mexErrMsgIdAndTxt("USB:open","%s\n",errorstring);
		}
		
	} else {
		int ndims = 2;
		int dims[2] = {1,1};
		UINT64_T *val;
		/* Return the handle. */
		plhs[0] = mxCreateNumericArray(ndims,dims,mxUINT64_CLASS,mxREAL);
		if(plhs[0]==NULL) {
			mexErrMsgIdAndTxt("USB:open","Internal error: Can't create numeric array.\n");
		}
		val = mxGetData(plhs[0]);
		*val = inthandle;
		/* return a zero-length error string. */
		if(nlhs>1) {
			plhs[1] = mxCreateString("");
			if(plhs[1]==NULL) {
				mexErrMsgIdAndTxt("USB:open","Internal error: Can't create string.\n");
			}
		}
	}

	if(serno_str!=NULL) mxFree(serno_str);
}
