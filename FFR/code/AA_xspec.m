function [Cxy, Pxy, F]=AA_xspec(X, ERPF, FSx, FSy, varargin)
%% DESCRIPTION:
%
%   Function to perform cross-spectral analyses between a reference signal
%   (e.g., a stimulus file like MMBF7.WAV) and time-averaged waveforms. At
%   present, this serves as a wrapper for more generalized functions (e.g.,
%   AA_cpsd_mscohere) and provides additional plotting options that are not
%   provided in the core functions invoked. 
%
% INPUT:
%   
%   Required:
%
%       X:  time series or full path to wav file containing time series.
%       ERPF:   cell array, each element is the full path to an ERP file.
%               Typically one entry per subject.
%
%   Optional:
%       'plev': XXX
%       'nsem': 
%       'frange':   
%
%       
% OUTPUT:
%
%   XXX
%
%   Plots galore!
%   And I imagine some other stuff
%
% Christopher W. Bishop
%   University of Washington
%   3/14

%% INPUT CHECK
% Convert inputs to structure
%   Users may also pass a parameter structure directly, which makes CWB's
%   life a lot easier. 
if length(varargin)>1
    p=struct(varargin{:}); 
else 
    p=varargin{1};
end %

%% INITIALIZE VARIABLES
Cxy=[];
Pxy=[]; 
F=[];

%% LOOP THROUGH SUBJECTS
for s=1:length(ERPF)
    [cxy, pxy, F]=AA_cpsd_mscohere(X, ERPF{s}, FSx, FSy, ...
        'bins', p.bins, ...
        'chans', p.chans, ...
        'xsig', p.wsig, ...
        'ysig', p.tsig, ...
        'window', p.xspec_window, ...
        'noverlap', p.xspec_nover, ...
        'nfft', p.xspec_nfft);
    
    Cxy(:,:,s)=cxy;
    Pxy(:,:,s)=pxy; 
end % for s=1:length(ERPF)

%% PLOT DATA
