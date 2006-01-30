function c = AddInstrumentOutput(instrument, daqname, hwchannel, outputname, varargin)
%
% ADDINSTRUMENTOUTPUT Adds an output to an instrument. 
%
% Each output is associated with an analoginput channel on the DAQ hardware
% and is basically an aichannel object.  Multiple aichannel objects can be
% associated with a single hardware channel on a device, which allows the
% same data to be read with different units or gain.
%
% chan = ADDINSTRUMENTOUTPUT(instrument, daqname, hwchannel, outputname, [props])
%
% instrument - the name of an instrument in the control structure
% daqname    - the name of a daq device
% hwchannel  - the hardware channel (generally the BNC port number)
% outputname - the name of the output
% props      - channel properties to set on the new channel
%
% chan       - returns a pointer to the new channel
%
% See also INITINSTRUMENT, ADDINSTRUMENTINPUT, PRIVATE/ADDCHANNEL
%
% $Id: AddInstrumentOutput.m,v 1.4 2006/01/30 19:23:06 meliza Exp $


daq = GetDAQ(daqname);
c   = addchannel(daq, hwchannel, outputname);

set(c,varargin{:})
AddInstrumentChannel(instrument, outputname, c)


    