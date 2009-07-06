% Joseph Rothweiler, Sensicomm LLC. started 23Jun2009
% Starting to build a command-line controller.

global RCSID;
RCSID="$Id: mhz100q.m,v 1.5 2009/07/06 19:22:54 jrothwei Exp jrothwei $";
1;  %
function y = testit(x)
	y=2*x;
end
function bigreset(usbdev)
  fprintf(2,'bigreset\n');
  % Flush any junk in the pipelines.
  usb_writestring(usbdev,2,"1w");  % End-packet to EP6.
  usb_writestring(usbdev,2,"0w");
  usb_writestring(usbdev,2,"1y");  % End-packet to EP8.
  usb_writestring(usbdev,2,"0y");
  usb_writestring(usbdev,2,"1z");  % Reset the counters.
  usb_writestring(usbdev,2,"0z");

end
function showsignal(bytes)
  plotlen = 512;
  plotoff = 0;
  x=plotoff:(plotoff+plotlen-1);
  idx=x+1;
  nn=length(bytes);
  fprintf(2,'Signal: got %d bytes\n',nn);
  if(nn==8192)
    sig=cast(typecast(bytes,'int8'),'double');
    figure(1);
    clf;
    hold on;
      xlabel('Samples');
      ylabel('Steps');
      plot(x,sig(   0+idx),'r');
      plot(x,sig(2048+idx),'g');
      plot(x,sig(4096+idx),'b');
      plot(x,sig(6144+idx),'m');
    hold off;
  end
end
function showstatus(bytes)
  nn=length(bytes);
  fprintf(2,'Status: got %d bytes\n',nn);
  for k=1:16:nn
    p=k+15;
    if(p>nn) p = nn; end;
    fprintf(2,'%4.4x:',k);
    fprintf(2,' %2.2x',bytes(k:p));
    fprintf(2,'\n');
  end
end
function setupshift(signedval)
  global mhz100q;
  theshift = mhz100q.baseshift + signedval;
  signedval
  theshift
  if (theshift<0)|(theshift>0x1f)
    fprintf(2,'"S": value %d (0x%x) must be between 0 and %d (0x%x)\n', ...
      theshift,theshift,0x1f,0x1f);
  else
    mhz100q.shiftfactor=theshift;
    usb_writestring(mhz100q.usbdev,2,sprintf("+%xp",mhz100q.shiftfactor));
  end
  mhz100q.shiftfactor
end
function setdownsample(cmdval)
  global mhz100q;
  if (cmdval<0)|(cmdval>0x1f)
    fprintf(2,'"F": value %d (0x%x) must be between 0 and %d (0x%x)\n', ...
      cmdval,cmdval,0x1f,0x1f);
  else
    mhz100q.downfactor=cmdval;
    usb_writestring(mhz100q.usbdev,2,sprintf("+%xq",mhz100q.downfactor));
    mhz100q.downsample = (cmdval~=0);
    if(mhz100q.downsample) % Full(0) or reduced(1) speed.
    	tmpval = 1;
    else
    	tmpval = 0;
    end
    if mhz100q.autoupload
      tmpval = tmpval + 2; % bit 1 selects autoupload.
    end
    if mhz100q.testsignal
      tmpval = tmpval + 4; % bit 1 selects autoupload.
    end
    usb_writestring(mhz100q.usbdev,2,sprintf("+%xs",tmpval));
  end
  % Compute the recommended shift factor.
  sfac = 0;
  smask = 1;
  for k=0:32   % Number of bits to represent downfactor. 6 is enough.
    if((2^k)>mhz100q.downfactor) break; end
  end
  mhz100q.baseshift=3*k;
  fprintf(' kfactor %d shift %d\n',k,3*k);
  setupshift(0);
end
function printcurrent
  global RCSID;
  global mhz100q;
  fprintf(2,'Version %s\n',RCSID);
  fprintf(2,'Downsample ');
  if(mhz100q.downsample)
    fprintf(2,'on ');
    SamFreq = 100e6/cast((mhz100q.downfactor+1),'double');
  else
    fprintf(2,'off');
    SamFreq = 100e6;
  end
  fprintf(2,' factor %d',mhz100q.downfactor);
  if(SamFreq>=1e6)
    fprintf(2,' Sample Rate %g MHz',SamFreq/1e6);
  else
    fprintf(2,' Sample Rate %g KHz',SamFreq/1e3);
  end
  fprintf(2,' Bit shift base %d actual %d\n',mhz100q.baseshift,mhz100q.shiftfactor);
end
function imalldone
  disp('Im all done now.');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Start of script.
global mhz100q;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Open the USB device.
% No errorstring return, so we get an
% automatic error() on failed open.
usbdev = usb_opendev(0x0547,0x2131,'',1);
mhz100q.usbdev = usbdev;
atexit("imalldone");

% Set the test signal generation via the VGA port.
usb_writestring(usbdev,2,"+1fr");

mhz100q.autoupload = 1;
mhz100q.testsignal = 1;
setdownsample(0);  % full speed.
setupshift(0);

bigreset(usbdev);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Command loop.
cmdval=uint32(0);
cmdvalsign=int32(1);
fprintf(2,'type "?" for help, "q" to exit\n> ');
while 1
  % First, check for data to be uploaded.
  signalbytes=usb_readbytes(usbdev,6,8192,100);
  if(~isempty(signalbytes)) showsignal(signalbytes); end;
  statusbytes=usb_readbytes(usbdev,8,512,100);
  if(~isempty(statusbytes)) showstatus(statusbytes); end;
  c1=kbhit_nowait();  % kbhit(1) has a bug in Octave 3.2 and earlier. Use this instead.
  if isempty(c1)
    sleep(0.2)
  else
    fprintf(2,'Key 0x%x\n',toascii(c1));
    switch(c1)
    case '?'
      fprintf(2,'Help command\n');
      fprintf(2,'0-9,a-f Hex characters\n');
      fprintf(2,'? Print this help\n');
      fprintf(2,'t Trigger a single capture\n');
      fprintf(2,'u Trigger a USB upload\n');
      fprintf(2,'x Trigger a status upload\n');
      fprintf(2,'F Set downsampling factor (0 to 1f)\n');
      fprintf(2,'S Set downsampling shift (gain) factor (0 to 1f)\n');
      printcurrent;
    case char(4) % ^D.
      fprintf(2,'Ctrl-D exit\n');
      break;
    case 'q'
      fprintf(2,'Exiting\n');
      break;
    case 't'
      usb_writestring(usbdev,2,'t');
    case 'u'
      usb_writestring(usbdev,2,'u');
    case 'x'
      usb_writestring(usbdev,2,'01000020x');
      sleep(0.1);
      usb_writestring(usbdev,2,'1y');
      usb_writestring(usbdev,2,'0y');
    case '+'
      cmdval = 0;
      cmdvalsign = 1;
    case '-'
      cmdval = 0;
      cmdvalsign = -1;
    case 'F'
      setdownsample(cmdval);
      if(mhz100q.downsample)
        fprintf(2,'Downsampling on. Factor %d. Sampling Frequency %g\n', ...
	  mhz100q.downfactor, 100e6/mhz100q.downfactor);
      else
        fprintf(2,'Downsampling off.\n');
      end
    case 'S'
      fprintf(2,'S : sign %d val %d mix %d\n',cmdvalsign,cmdval,cmdvalsign*typecast(cmdval,'int32'));
      setupshift(cmdvalsign*typecast(cmdval,'int32'));
    otherwise
      chr = toascii(c1);
      if  ( (chr >= toascii('0')) && (chr <= toascii('9') ) )
	cmdval = bitshift(cmdval,4) + uint32(chr - toascii('0'));
      elseif( (chr >= toascii('a')) && (chr <= toascii('f') ) )
	cmdval = bitshift(cmdval,4) + uint32(chr - toascii('a') + 10);
      else
        fprintf(2,'Bad key %c (0x%x)\n',c1,toascii(c1));
      end
      fprintf(2,'sign %d cmdval %d 0x%x type %s\n',cmdvalsign,cmdval,cmdval,typeinfo(cmdval));
    end
  end
end
