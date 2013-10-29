function MSPE_clear
%% DESCRIPTION:
%
%   MATLAB is dumb and breaks if you try to clear the DAQ on consecutive
%   lines of code. So, we have to isolate the clearing functions. Dumb.  I
%   tried using the WAIT function, but it doesn't work as advertised.  I'm
%   shocked! Really! ... 
%
% INPUT:
%
%   NONE
%
% OUTPUT:
%
%   NONE
%
% Bishop, Chris Miller Lab 2010

delete(daqfind);
clear Ao Vo hw;